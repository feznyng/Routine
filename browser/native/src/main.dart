import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

const int maxMessageSize = 1024 * 1024;

Future<Socket?> getRoutineSocket() async {
  for (int port = 54320; port <= 54330; port++) {
    try {
      stderr.writeln('Attempting to connect via $port');
      return await Socket.connect(InternetAddress.loopbackIPv4, port);
    } catch (e) {
      stderr.writeln('Failed to connect to Routine app via port $port: $e');
    }
  }

  return null;
}

void main(List<String> args) async {  
  Socket? routineSocket = await getRoutineSocket();

  if (routineSocket == null) {
    stderr.writeln("Couldn't connect to app");
    exit(1);
  }

  // Handle messages from the browser extension (stdin)
  stdin.listen(
    (List<int> data) async {
      try {
        // First 4 bytes are the message length in native-endian format
        if (data.length < 4) {
          stderr.writeln('Received incomplete length prefix from extension');
          return;
        }
        
        // Read the message length (little-endian uint32)
        final view = ByteData.view(Uint8List.fromList(data).buffer, 0, 4);
        final messageLength = view.getUint32(0, Endian.little);
        stderr.writeln('Received message length from extension: $messageLength bytes');
        
        if (messageLength > maxMessageSize) {
          stderr.writeln('Message too large: $messageLength bytes exceeds limit of $maxMessageSize bytes');
          return;
        }
        
        // Extract and validate the message content
        final messageBytes = data.sublist(4);
        stderr.writeln('Actual received message size: ${messageBytes.length} bytes');
        
        if (messageBytes.length != messageLength) {
          stderr.writeln('Received incomplete message: got ${messageBytes.length} bytes, expected $messageLength');
          return;
        }

        final message = utf8.decode(messageBytes);
        stderr.writeln('Decoded message from extension: $message');

        // Forward message to Routine app
        if (routineSocket != null) {
          final bytes = utf8.encode(message);
          if (bytes.length > maxMessageSize) {
            stderr.writeln('Cannot forward message: ${bytes.length} bytes exceeds size limit');
            return;
          }

          // Send message length in big-endian format as expected by the Routine app
          final lengthBytes = ByteData(4)..setUint32(0, bytes.length, Endian.little);
          routineSocket.add(Uint8List.fromList([...lengthBytes.buffer.asUint8List(), ...bytes]));
          await routineSocket.flush();
          stderr.writeln('Sent message: $message');
        }
      } catch (e, st) {
        stderr.writeln('Error processing message from extension: $e\n$st');
      }
    },
    onError: (error) {
      stderr.writeln('Error reading from stdin: $error');
      exit(1);
    },
    onDone: () {
      stderr.writeln('stdin stream closed');
      exit(0);
    },
  );

  List<int> routineBuffer = [];
  int? expectedLength;

  // Handle messages from the Routine app
  routineSocket.listen(
    (List<int> data) async {
      try {
        stderr.writeln('Received ${data.length} bytes from Routine app');
        routineBuffer.addAll(data);

        // Keep processing messages while we have enough data
        while (routineBuffer.length >= 4) {
          if (expectedLength == null) {
            final view = ByteData.view(Uint8List.fromList(routineBuffer.sublist(0, 4)).buffer);
            expectedLength = view.getUint32(0, Endian.little);
            
            if (expectedLength! > maxMessageSize) {
              stderr.writeln('Error: Message too large: $expectedLength bytes');
              routineBuffer.clear();
              expectedLength = null;
              break;
            }

            if (routineBuffer.length < expectedLength! + 4) {
              break;
            }
          }

          final messageBytes = routineBuffer.sublist(4, expectedLength! + 4);
          final message = utf8.decode(messageBytes);

          routineBuffer = routineBuffer.sublist(expectedLength! + 4);
          expectedLength = null;

          final bytes = utf8.encode(message);
          
          if (bytes.length > maxMessageSize) {
            stderr.writeln('Cannot send message: ${bytes.length} bytes exceeds Chrome limit of $maxMessageSize bytes');
            continue;
          }
          
          final messageLengthBytes = Uint8List(4);
          final view = ByteData.view(messageLengthBytes.buffer);
          view.setUint32(0, bytes.length, Endian.little);
          
          stdout.add(messageLengthBytes);
          stdout.add(bytes);
          await stdout.flush();
        }
      } catch (e) {
        stderr.writeln('Error processing message from Routine app: $e');
      }
    },
    onError: (error) {
      stderr.writeln('Error reading from Routine app: $error');
      exit(1);
    },
    onDone: () {
      stderr.writeln('Connection to Routine app closed');
      exit(0);
    },
  );
}