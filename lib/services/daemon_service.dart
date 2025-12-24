import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dartzmq/dartzmq.dart';

class DaemonService {
  final ZContext _context = ZContext();
  late final ZSocket _socket;
  final StreamController<Map<String, dynamic>> _eventController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  void connect() {
    _socket = _context.createSocket(SocketType.dealer);
    _socket.connect('tcp://127.0.0.1:9002');
    print('[Flutter] Connected to nestd IPC (Dealer)');

    _socket.messages.listen(
      (message) {
        for (var frame in message) {
          if (frame.payload.isEmpty) continue;
          try {
            // FIX: Use UTF8 Decode
            final String jsonString = utf8.decode(frame.payload);
            
            // Ignore non-JSON fragments (ZMQ noise)
            if (!jsonString.trim().startsWith('{')) continue; 

            final Map<String, dynamic> data = jsonDecode(jsonString);
            
            // DEBUG: Print status packets to see why UI isn't updating
            if (data['event'] == 'status') {
               print("[Flutter] Status Packet: ${data['payload']}");
            }
            
            _eventController.add(data);
          } catch (e) {
            print('[Flutter] JSON/Rx Error: $e');
          }
        }
      },
      onError: (e) {
        print('[ZMQ Warning] $e'); 
      },
      cancelOnError: false, 
    );
  }

  void sendCommand(String command, Map<String, dynamic> payload) {
    try {
      final jsonStr = jsonEncode({
        'command': command,
        'payload': payload,
      });
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));
      _socket.send(bytes);
    } catch (e) {
      print('[Flutter] Send Error: $e');
    }
  }

  void dispose() {
    _socket.close();
    _context.stop();
    _eventController.close();
  }
}