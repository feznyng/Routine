
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class BrowserConnection {
  final Socket socket;
  List<int> buffer = [];
  int? len;

  /// Socket.flush() marks the sink as bound for as long as it is in flight, so
  /// an add() or flush() from an overlapping send throws "Bad state: StreamSink
  /// is bound to a stream". Sends are chained so only one is ever in flight per
  /// connection - callers (routine evaluation, connection events) are not
  /// coordinated with each other.
  Future<void> _writes = Future.value();

  BrowserConnection({required this.socket});

  Future<void> sendMessage(String action, Map<String, dynamic> data) {
    final message = json.encode({'action': action, 'data': data});
    final messageBytes = utf8.encode(message);
    final lengthBytes = ByteData(4)..setUint32(0, messageBytes.length, Endian.little);

    final done = _writes.then((_) async {
      socket.add(lengthBytes.buffer.asUint8List());
      socket.add(messageBytes);
      await socket.flush();
    });

    // Swallow failures in the chain itself, so one failed send does not block
    // every later send on this connection. The caller still sees the error.
    _writes = done.catchError((_) {});

    return done;
  }
}
