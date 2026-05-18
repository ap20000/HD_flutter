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

    _socket = io.io(ApiConstants.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.onConnect((_) => print('Connected to socket server'));
    _socket!.onDisconnect((_) => print('Disconnected from socket server'));

    _socket!.on('receive_message', (data) {
      _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('call_signal', (data) {
      _signalController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('reject_call', (_) => _callRejectedController.add(null));
    _socket!.on('end_call', (_) => _callEndedController.add(null));

    _socket!.connect();
  }

  void joinConsultation(String consultationId) {
    _socket?.emit('join_consultation', consultationId);
  }

  void sendMessage(String consultationId, String senderId, String text) {
    _socket?.emit('send_message', {
      'consultationId': consultationId,
      'senderId': senderId,
      'text': text,
    });
  }

  void sendSignal(String consultationId, Map<String, dynamic> signal) {
    _socket?.emit('call_signal', {
      'consultationId': consultationId,
      ...signal,
    });
  }

  void rejectCall(String consultationId) {
    _socket?.emit('reject_call', {'consultationId': consultationId});
  }

  void endCall(String consultationId) {
    _socket?.emit('end_call', {'consultationId': consultationId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    _messageController.close();
    _signalController.close();
    _callRejectedController.close();
    _callEndedController.close();
    disconnect();
  }
}
