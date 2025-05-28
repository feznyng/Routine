use byteorder::{NativeEndian, ReadBytesExt, WriteBytesExt};
use serde::{Deserialize, Serialize};
use std::io::{self, Read, Write, BufReader, BufWriter};
use std::fs::OpenOptions;
use std::net::TcpStream;
use chrono;
use std::thread;
use std::sync::mpsc;

#[derive(Serialize, Deserialize, Debug, Clone)]
struct Message {
    action: String,
    data: serde_json::Value,
}

fn log_to_file(msg: &str) {
    if let Ok(mut file) = OpenOptions::new()
        .create(true)
        .append(true)
        .open("/tmp/native_messaging.log")
    {
        let _ = writeln!(file, "{}: {}", chrono::Local::now(), msg);
    }
}

// Read a message from stdin (browser extension)
// Write a message to the Flutter app
fn write_flutter_message(stream: &mut TcpStream, message: &Message) -> io::Result<()> {
    let mut writer = BufWriter::new(stream);
    let json = serde_json::to_string(message)?;
    let length = json.len() as u32;
    writer.write_all(&length.to_be_bytes())?;
    writer.write_all(json.as_bytes())?;
    writer.flush()?;
    Ok(())
}

// Read a message from the Flutter app
fn read_flutter_message(stream: &mut TcpStream) -> io::Result<Message> {
    let mut reader = BufReader::new(stream);
    let mut length_bytes = [0u8; 4];
    reader.read_exact(&mut length_bytes)?;
    let length = u32::from_be_bytes(length_bytes) as usize;
    log_to_file(&format!("Reading message of length {}", length));
    
    let mut json_bytes = vec![0u8; length];
    reader.read_exact(&mut json_bytes)?;
    
    let json_str = String::from_utf8(json_bytes)
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
    
    serde_json::from_str(&json_str)
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))
}

fn read_browser_message() -> io::Result<Message> {
    let mut stdin = io::stdin();
    let message_length = stdin.read_u32::<NativeEndian>()?;
    let mut buffer = vec![0; message_length as usize];
    stdin.read_exact(&mut buffer)?;
    
    match serde_json::from_slice(&buffer) {
        Ok(message) => {
            log_to_file(&format!("Browser -> Flutter: {:?}", message));
            Ok(message)
        },
        Err(e) => Err(io::Error::new(io::ErrorKind::InvalidData, e))
    }
}

// Write a message to stdout (browser extension)
fn write_browser_message(message: &Message) -> io::Result<()> {
    let mut stdout = io::stdout();
    let message_bytes = serde_json::to_vec(&message)?;
    
    stdout.write_u32::<NativeEndian>(message_bytes.len() as u32)?;
    stdout.write_all(&message_bytes)?;
    stdout.flush()?;
    log_to_file(&format!("Flutter -> Browser: {:?}", message));
    Ok(())
}

fn get_app_support_dir() -> io::Result<std::path::PathBuf> {
    let home = std::env::var("HOME").map_err(|e| io::Error::new(io::ErrorKind::NotFound, e))?;
    Ok(std::path::PathBuf::from(home)
        .join("Library/Containers/com.solidsoft.routine/Data/Library/Application Support/com.solidsoft.routine"))
}

fn get_server_port() -> io::Result<u16> {
    let app_support_dir = get_app_support_dir()?;
    let port_file = app_support_dir.join("routine_server_port");
    log_to_file(&format!("Attempting to read port from: {}", port_file.display()));
    let port_str = std::fs::read_to_string(&port_file)
        .map_err(|e| {
            log_to_file(&format!("Error reading port file: {}", e));
            e
        })?
        .trim()
        .to_string();
    
    port_str.parse::<u16>()
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))
}

fn main() -> io::Result<()> {
    log_to_file("Native messaging host started");
    
    // Channel for communication between threads
    let (tx, rx) = mpsc::channel();
        
    // Thread for reading from browser extension
    thread::spawn(move || {
        loop {
            match read_browser_message() {
                Ok(message) => {
                    if let Err(e) = tx.send(message) {
                        log_to_file(&format!("Failed to send message to channel: {}", e));
                        break;
                    }
                },
                Err(e) => {
                    log_to_file(&format!("Failed to read browser message: {}", e));
                    break;
                }
            }
        }
    });

    // Get port from file and connect to Flutter app's TCP server with retries
    let mut flutter_stream = None;
    let mut retry_count = 0;
    const MAX_RETRIES: u32 = 10;
    const RETRY_DELAY_MS: u64 = 500;
    
    while retry_count < MAX_RETRIES {
        match get_server_port() {
            Ok(port) => {
                log_to_file(&format!("Attempt {} - Connecting to port {}", retry_count + 1, port));
                match TcpStream::connect(format!("127.0.0.1:{}", port)) {
                    Ok(stream) => {
                        log_to_file("Connected to Flutter app's TCP server");
                        flutter_stream = Some(stream);
                        break;
                    },
                    Err(e) => {
                        log_to_file(&format!("Failed to connect to Flutter app: {}", e));
                        retry_count += 1;
                        if retry_count < MAX_RETRIES {
                            thread::sleep(std::time::Duration::from_millis(RETRY_DELAY_MS));
                        }
                    }
                }
            },
            Err(e) => {
                log_to_file(&format!("Failed to read port file: {}", e));
                retry_count += 1;
                if retry_count < MAX_RETRIES {
                    thread::sleep(std::time::Duration::from_millis(RETRY_DELAY_MS));
                }
            }
        }
    }
    
    let mut flutter_stream = match flutter_stream {
        Some(stream) => stream,
        None => {
            log_to_file("Failed to connect to Flutter app after all retries");
            return Err(io::Error::new(io::ErrorKind::NotFound, "Could not connect to Flutter app"));
        }
    };

    // Thread for handling messages from browser extension
    let mut flutter_stream_clone = flutter_stream.try_clone()?;
    thread::spawn(move || {
        for message in rx {
            if let Err(e) = write_flutter_message(&mut flutter_stream_clone, &message) {
                log_to_file(&format!("Failed to write message to Flutter: {}", e));
                break;
            }
        }
    });

    // Main thread reads messages from Flutter
    loop {
        match read_flutter_message(&mut flutter_stream) {
            Ok(message) => {
                if let Err(e) = write_browser_message(&message) {
                    log_to_file(&format!("Failed to write message to browser: {}", e));
                    break;
                }
            },
            Err(e) => {
                log_to_file(&format!("Failed to read Flutter message: {}", e));
                break;
            }
        }
    }

    Ok(())
}
