use byteorder::{NativeEndian, ReadBytesExt, WriteBytesExt};
use serde::{Deserialize, Serialize};
use std::io::{self, Read, Write};
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

// Read a message from TCP (Flutter app)
fn read_flutter_message(stream: &mut TcpStream) -> io::Result<Message> {
    let mut len_bytes = [0u8; 4];
    stream.read_exact(&mut len_bytes)?;
    let message_len = u32::from_ne_bytes(len_bytes);
    
    let mut buffer = vec![0; message_len as usize];
    stream.read_exact(&mut buffer)?;
    
    match serde_json::from_slice(&buffer) {
        Ok(message) => {
            log_to_file(&format!("Flutter -> Browser: {:?}", message));
            Ok(message)
        },
        Err(e) => Err(io::Error::new(io::ErrorKind::InvalidData, e))
    }
}

// Write a message to TCP (Flutter app)
fn write_flutter_message(stream: &mut TcpStream, message: &Message) -> io::Result<()> {
    let message_bytes = serde_json::to_vec(&message)?;
    stream.write_u32::<NativeEndian>(message_bytes.len() as u32)?;
    stream.write_all(&message_bytes)?;
    stream.flush()?;
    log_to_file(&format!("Browser -> Flutter: {:?}", message));
    Ok(())
}

fn main() -> io::Result<()> {
    log_to_file("Native messaging host started");
    
    // Channel for communication between threads
    let (tx, rx) = mpsc::channel();
    let tx_clone = tx.clone();
    
    // Connect to Flutter app
    let mut tcp_stream = match TcpStream::connect("127.0.0.1:54321") {
        Ok(stream) => {
            log_to_file("Connected to Flutter app successfully");
            stream
        },
        Err(e) => {
            log_to_file(&format!("Failed to connect to Flutter app: {}", e));
            return Err(e);
        }
    };
    
    let mut tcp_stream_clone = tcp_stream.try_clone()?;
    
    // Thread for reading from browser (stdin)
    thread::spawn(move || {
        while let Ok(message) = read_browser_message() {
            if let Err(e) = tx.send(("browser", message)) {
                log_to_file(&format!("Error sending browser message to channel: {}", e));
                break;
            }
        }
    });
    
    // Thread for reading from Flutter (TCP)
    thread::spawn(move || {
        while let Ok(message) = read_flutter_message(&mut tcp_stream_clone) {
            if let Err(e) = tx_clone.send(("flutter", message)) {
                log_to_file(&format!("Error sending Flutter message to channel: {}", e));
                break;
            }
        }
    });
    
    // Main thread handles message routing
    for (source, message) in rx {
        match source {
            "browser" => {
                if let Err(e) = write_flutter_message(&mut tcp_stream, &message) {
                    log_to_file(&format!("Error forwarding browser message to Flutter: {}", e));
                }
            },
            "flutter" => {
                if let Err(e) = write_browser_message(&message) {
                    log_to_file(&format!("Error forwarding Flutter message to browser: {}", e));
                }
            },
            _ => unreachable!(),
        }
    }
    
    log_to_file("Native messaging host stopped");
    Ok(())
}
