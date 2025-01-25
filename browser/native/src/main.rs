use byteorder::{NativeEndian, ReadBytesExt, WriteBytesExt};
use serde::{Deserialize, Serialize};
use std::io::{self, Read, Write};
use std::fs::OpenOptions;
use std::net::TcpStream;
use chrono;

#[derive(Serialize, Deserialize, Debug)]
struct Message {
    action: String,
    data: serde_json::Value,
}

fn log_to_file(msg: &str) {
    if let Ok(mut file) = OpenOptions::new()
        .create(true)
        .append(true)
        .open("/tmp/Routine/native_messaging.log")
    {
        let _ = writeln!(file, "{}: {}", chrono::Local::now(), msg);
    }
}

fn handle_browser_message(message: Message, tcp_stream: &mut TcpStream) -> io::Result<()> {
    log_to_file(&format!("Processing browser message: {:?}", message));
    
    // Forward the message to Flutter app
    let message_bytes = serde_json::to_vec(&message)?;
    tcp_stream.write_u32::<NativeEndian>(message_bytes.len() as u32)?;
    tcp_stream.write_all(&message_bytes)?;
    tcp_stream.flush()?;
    
    // Read response from Flutter app
    let mut len_bytes = [0u8; 4];
    tcp_stream.read_exact(&mut len_bytes)?;
    let response_len = u32::from_ne_bytes(len_bytes);
    
    let mut response_buffer = vec![0; response_len as usize];
    tcp_stream.read_exact(&mut response_buffer)?;
    
    // Forward Flutter's response back to browser
    let response: Message = serde_json::from_slice(&response_buffer)?;
    write_message(&response)
}

fn read_message() -> io::Result<Message> {
    let mut stdin = io::stdin();
    
    let message_length = stdin.read_u32::<NativeEndian>()?;
    let mut buffer = vec![0; message_length as usize];
    stdin.read_exact(&mut buffer)?;
    
    match serde_json::from_slice(&buffer) {
        Ok(message) => Ok(message),
        Err(e) => Err(io::Error::new(io::ErrorKind::InvalidData, e))
    }
}

fn write_message(message: &Message) -> io::Result<()> {
    let mut stdout = io::stdout();
    let message_bytes = serde_json::to_vec(&message)?;
    
    stdout.write_u32::<NativeEndian>(message_bytes.len() as u32)?;
    stdout.write_all(&message_bytes)?;
    stdout.flush()?;
    Ok(())
}

fn main() -> io::Result<()> {
    log_to_file("Native messaging host started");
    
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
    
    // Handle browser messages
    while let Ok(message) = read_message() {
        if let Err(e) = handle_browser_message(message, &mut tcp_stream) {
            log_to_file(&format!("Error handling message: {}", e));
        }
    }
    
    log_to_file("Native messaging host stopped");
    Ok(())
}
