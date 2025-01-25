use byteorder::{NativeEndian, ReadBytesExt, WriteBytesExt};
use serde::{Deserialize, Serialize};
use std::io::{self, Read, Write};
use std::fs::OpenOptions;
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
        .open("/tmp/native_host.log")
    {
        let _ = writeln!(file, "{}: {}", chrono::Local::now(), msg);
    }
}

fn read_message() -> io::Result<Message> {
    let mut stdin = io::stdin();
    
    // Read the message length (first 4 bytes)
    let message_length = match stdin.read_u32::<NativeEndian>() {
        Ok(len) => {
            log_to_file(&format!("Received message length: {}", len));
            len
        },
        Err(e) => {
            log_to_file(&format!("Error reading message length: {}", e));
            return Err(e);
        }
    };

    // Read the message content
    let mut buffer = vec![0; message_length as usize];
    match stdin.read_exact(&mut buffer) {
        Ok(_) => {
            log_to_file(&format!("Read message content: {}", String::from_utf8_lossy(&buffer)));
        },
        Err(e) => {
            log_to_file(&format!("Error reading message content: {}", e));
            return Err(e);
        }
    }
    
    // Parse the JSON message
    match serde_json::from_slice(&buffer) {
        Ok(message) => {
            log_to_file(&format!("Parsed message successfully"));
            Ok(message)
        },
        Err(e) => {
            log_to_file(&format!("Error parsing message: {}", e));
            Err(io::Error::new(io::ErrorKind::InvalidData, e))
        }
    }
}

fn write_message(message: &Message) -> io::Result<()> {
    let mut stdout = io::stdout();
    
    let message_bytes = serde_json::to_vec(&message)?;
    log_to_file(&format!("Sending message of length {}: {}", 
        message_bytes.len(), 
        String::from_utf8_lossy(&message_bytes)
    ));
    
    stdout.write_u32::<NativeEndian>(message_bytes.len() as u32)?;
    stdout.write_all(&message_bytes)?;
    stdout.flush()?;
    Ok(())
}

fn main() -> io::Result<()> {
    log_to_file("Native messaging host started");
    
    while let Ok(message) = read_message() {
        log_to_file(&format!("Processing message: {:?}", message));
        
        // Handle the message based on the action
        let response = Message {
            action: "response".to_string(),
            data: match message.action.as_str() {
                "ping" => serde_json::json!({ "status": "pong" }),
                _ => serde_json::json!({ "error": "Unknown action" }),
            },
        };
        
        if let Err(e) = write_message(&response) {
            log_to_file(&format!("Error writing response: {}", e));
        }
    }
    
    log_to_file("Native messaging host stopped");
    Ok(())
}
