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

fn main() -> io::Result<()> {
    log_to_file("Native messaging host started");
    
    // Channel for communication between threads
    let (tx, rx) = mpsc::channel();
    let tx_clone = tx.clone();
    
    // Create TCP server
    let listener = match std::net::TcpListener::bind("127.0.0.1:54322") {
        Ok(listener) => {
            log_to_file("TCP server started on port 54322");
            listener
        },
        Err(e) => {
            log_to_file(&format!("Failed to start TCP server: {}", e));
            return Err(e);
        }
    };

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

    // Thread for accepting TCP connections and handling Flutter clients
    let listener_handle = thread::spawn(move || {
        // Accept connections in a loop
        for stream in listener.incoming() {
            match stream {
                Ok(tcp_stream) => {
                    let addr = tcp_stream.peer_addr().unwrap_or_else(|_| "unknown".parse().unwrap());
                    log_to_file(&format!("Flutter app connected from {}", addr));
                    
                    // Clone necessary handles for the new client thread
                    let tx_flutter = tx_clone.clone();
                    let mut tcp_stream_clone = match tcp_stream.try_clone() {
                        Ok(clone) => clone,
                        Err(e) => {
                            log_to_file(&format!("Failed to clone TCP stream: {}", e));
                            continue;
                        }
                    };

                    // Spawn a new thread for each client
                    thread::spawn(move || {
                        loop {
                            match read_flutter_message(&mut tcp_stream_clone) {
                                Ok(message) => {
                                    if let Err(e) = tx_flutter.send(message) {
                                        log_to_file(&format!("Failed to send message to channel: {}", e));
                                        break;
                                    }
                                },
                                Err(e) => {
                                    log_to_file(&format!("Failed to read Flutter message: {}", e));
                                    break;
                                }
                            }
                        }
                        log_to_file(&format!("Flutter client {} disconnected", addr));
                    });
                },
                Err(e) => {
                    log_to_file(&format!("Error accepting connection: {}", e));
                }
            }
        }
    });

    // Main thread handles message broadcasting to all connected clients
    for message in rx {
        // Forward messages to browser
        if let Err(e) = write_browser_message(&message) {
            log_to_file(&format!("Failed to write browser message: {}", e));
        }
    }

    // Wait for the listener thread (this won't actually be reached in normal operation)
    if let Err(e) = listener_handle.join() {
        log_to_file(&format!("TCP listener thread panicked: {:?}", e));
    }

    Ok(())
}
