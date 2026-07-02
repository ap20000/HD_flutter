import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/constants.dart';

class SocketService {
  io.Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _signalController = StreamController<Map<String, dynamic>>.broadcast();
  final _callRejectedController = StreamController<void>.broadcast();
  final _callEndedController = StreamController<void>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<Map<String, dynamic>> get signals => _signalController.stream;
  Stream<void> get callRejected => _callRejectedController.stream;
  Stream<void> get callEnded => _callEndedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null && _socket!.connected) return;

    print('SocketService: Connecting to ${ApiConstants.baseUrl}...');
    _socket = io.io(ApiConstants.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.onConnect((_) => print('SocketService: Connected to socket server'));
    _socket!.onDisconnect((_) => print('SocketService: Disconnected from socket server'));
    _socket!.onConnectError((err) => print('SocketService: Connect error: $err'));

    _socket!.on('receive_message', (data) {
      print('SocketService: Message received: $data');
      _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('call_signal', (data) {
      print('SocketService: Call signal received: ${data['type']}');
      _signalController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('reject_call', (_) {
      print('SocketService: Call rejected event');
      _callRejectedController.add(null);
    });
    
    _socket!.on('end_call', (_) {
      print('SocketService: Call ended event');
      _callEndedController.add(null);
    });

    _socket!.connect();
  }

  void joinConsultation(String consultationId) {
    print('SocketService: Joining consultation: $consultationId');
    _socket?.emit('join_consultation', consultationId);
  }

  void sendMessage(String consultationId, String senderId, String text) {
    print('SocketService: Sending message: $text');
    _socket?.emit('send_message', {
      'consultationId': consultationId,
      'senderId': senderId,
      'text': text,
    });
  }

  void sendSignal(String consultationId, Map<String, dynamic> signal) {
    print('SocketService: Sending signal: ${signal['type']}');
    _socket?.emit('call_signal', {
      'consultationId': consultationId,
      ...signal,
    });
  }

  void rejectCall(String consultationId) {
    print('SocketService: Rejecting call: $consultationId');
    _socket?.emit('reject_call', {'consultationId': consultationId});
  }

  void endCall(String consultationId) {
    print('SocketService: Ending call: $consultationId');
    _socket?.emit('end_call', {'consultationId': consultationId});
  }

  void disconnect() {
    print('SocketService: Disconnecting...');
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    print('SocketService: Disposing controllers and socket...');
    _messageController.close();
    _signalController.close();
    _callRejectedController.close();
    _callEndedController.close();
    disconnect();
  }
}
