
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class BrowserConnection {
  final Socket socket;
  List<int> buffer = [];
  int? len;

  BrowserConnection({required this.socket});

  void sendMessage(String action, Map<String, dynamic> data) {
    final message = json.encode({'action': action, 'data': data});
    final messageBytes = utf8.encode(message);
    final lengthBytes = ByteData(4)..setUint32(0, messageBytes.length, Endian.little);
    socket.add(lengthBytes.buffer.asUint8List());
    socket.add(messageBytes);
  }
}