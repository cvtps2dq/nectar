import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dartzmq/dartzmq.dart';

class DaemonService {
  final ZContext _context = ZContext();
  late final ZSocket _socket;
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  void connect() {
    _socket = _context.createSocket(SocketType.dealer);
    _socket.connect('tcp://127.0.0.1:9002');
    print('[Flutter] Connected to nestd IPC (Dealer)');

    // FIX: Add onError handler
    _socket.messages.listen(
      (message) {
        for (var frame in message) {
          if (frame.payload.isEmpty) continue;
          try {
            final String jsonString = String.fromCharCodes(frame.payload);
            final Map<String, dynamic> data = jsonDecode(jsonString);
            _eventController.add(data);
          } catch (e) {
            print('JSON Parse Error: $e');
          }
        }
      },
      onError: (e) {
        // Log but don't crash
        print('[ZMQ Error] $e');
        // If the error is fatal (socket closed), we might need to reconnect.
        // For EAGAIN (35), we can usually ignore it, but dart_zmq might stop the stream.
        // If stream stops, we should try to reconnect after a delay?
        // For now, logging prevents the "Unhandled Exception" crash.
      }, 
      cancelOnError: false // Critical: Keep listening!
    );
  }

  void sendCommand(String command, Map<String, dynamic> payload) {
    final jsonStr = jsonEncode({'command': command, 'payload': payload});
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    _socket.send(bytes);
  }

  void dispose() {
    _socket.close();
    _context.stop();
    _eventController.close();
  }
}
