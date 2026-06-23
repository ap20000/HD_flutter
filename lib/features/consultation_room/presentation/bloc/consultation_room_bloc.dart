import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../core/services/socket_service.dart';
import '../../core/webrtc_helper.dart';
import '../../../doctor_dashboard/domain/usecases/doctor_dashboard_usecases.dart';

// Events
abstract class ConsultationRoomEvent extends Equatable {
  const ConsultationRoomEvent();
  @override
  List<Object?> get props => [];
}

class JoinConsultationRoom extends ConsultationRoomEvent {
  final String consultationId;
  const JoinConsultationRoom(this.consultationId);
}

class SendChatMessage extends ConsultationRoomEvent {
  final String text;
  final String senderId;
  const SendChatMessage(this.text, this.senderId);
}

class MessageReceived extends ConsultationRoomEvent {
  final Map<String, dynamic> message;
  const MessageReceived(this.message);
}

class StartCall extends ConsultationRoomEvent {
  final bool isVideo;
  const StartCall({required this.isVideo});
}

class HandleCallSignal extends ConsultationRoomEvent {
  final Map<String, dynamic> signal;
  const HandleCallSignal(this.signal);
}

class ToggleMute extends ConsultationRoomEvent {}

class ToggleCamera extends ConsultationRoomEvent {}

class EndConsultationCall extends ConsultationRoomEvent {}

class AcceptCall extends ConsultationRoomEvent {}

class RejectCall extends ConsultationRoomEvent {}

// States
class ConsultationRoomState extends Equatable {
  final List<Map<String, dynamic>> messages;
  final bool isVideoCall;
  final bool isMuted;
  final bool isCameraOn;
  final bool isCallActive;
  final MediaStream? localStream;
  final MediaStream? remoteStream;
  final bool hasIncomingCall;
  final Map<String, dynamic>? pendingOffer;
  final String? error;

  const ConsultationRoomState({
    this.messages = const [],
    this.isVideoCall = true,
    this.isMuted = false,
    this.isCameraOn = true,
    this.isCallActive = false,
    this.localStream,
    this.remoteStream,
    this.hasIncomingCall = false,
    this.pendingOffer,
    this.error,
  });

  ConsultationRoomState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isVideoCall,
    bool? isMuted,
    bool? isCameraOn,
    bool? isCallActive,
    MediaStream? localStream,
    MediaStream? remoteStream,
    bool? hasIncomingCall,
    Map<String, dynamic>? pendingOffer,
    String? error,
  }) {
    return ConsultationRoomState(
      messages: messages ?? this.messages,
      isVideoCall: isVideoCall ?? this.isVideoCall,
      isMuted: isMuted ?? this.isMuted,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      isCallActive: isCallActive ?? this.isCallActive,
      localStream: localStream ?? this.localStream,
      remoteStream: remoteStream ?? this.remoteStream,
      hasIncomingCall: hasIncomingCall ?? this.hasIncomingCall,
      pendingOffer: pendingOffer ?? this.pendingOffer,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    isVideoCall,
    isMuted,
    isCameraOn,
    isCallActive,
    localStream,
    remoteStream,
    error,
  ];
}

// BLoC
class ConsultationRoomBloc
    extends Bloc<ConsultationRoomEvent, ConsultationRoomState> {
  final SocketService socketService;
  final WebRTCHelper webrtcHelper;
  final GetConsultationByIdUseCase getConsultationByIdUseCase;
  String? _consultationId;
  StreamSubscription? _msgSub;
  StreamSubscription? _sigSub;
  StreamSubscription? _endSub;

  ConsultationRoomBloc({
    required this.socketService,
    required this.webrtcHelper,
    required this.getConsultationByIdUseCase,
  }) : super(const ConsultationRoomState()) {
    on<JoinConsultationRoom>(_onJoinRoom);
    on<SendChatMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<StartCall>(_onStartCall);
    on<HandleCallSignal>(_onHandleSignal);
    on<ToggleMute>(_onToggleMute);
    on<ToggleCamera>(_onToggleCamera);
    on<EndConsultationCall>(_onEndCall);
    on<AcceptCall>(_onAcceptCall);
    on<RejectCall>(_onRejectCall);

    _msgSub = socketService.messages.listen((msg) => add(MessageReceived(msg)));
    _sigSub = socketService.signals.listen((sig) => add(HandleCallSignal(sig)));
    _endSub = socketService.callEnded.listen((_) => add(EndConsultationCall()));
  }

  Future<void> _onJoinRoom(
    JoinConsultationRoom event,
    Emitter<ConsultationRoomState> emit,
  ) async {
    _consultationId = event.consultationId;
    socketService.connect();
    socketService.joinConsultation(event.consultationId);

    // If it's a mock session id, do not fetch from backend
    if (event.consultationId.contains('_session')) {
      return;
    }

    final result = await getConsultationByIdUseCase(event.consultationId);
    result.fold(
      (failure) => print('Failed to fetch past messages: $failure'),
      (consultation) {
        emit(state.copyWith(messages: consultation.messages));
      },
    );
  }

  Future<void> _onSendMessage(
    SendChatMessage event,
    Emitter<ConsultationRoomState> emit,
  ) async {
    if (_consultationId != null) {
      socketService.sendMessage(_consultationId!, event.senderId, event.text);
    }
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ConsultationRoomState> emit,
  ) {
    final Map<String, dynamic> mappedMsg = {
      'senderId': event.message['sender'] ?? event.message['senderId'] ?? '',
      'text': event.message['text'] ?? '',
      'timestamp': event.message['timestamp'] ?? '',
    };
    emit(state.copyWith(messages: [...state.messages, mappedMsg]));
  }

  Future<void> _onStartCall(
    StartCall event,
    Emitter<ConsultationRoomState> emit,
  ) async {
    emit(state.copyWith(isVideoCall: event.isVideo, isCallActive: true));

    webrtcHelper.onLocalStream = (stream) =>
        add(HandleCallSignal({'type': 'local_stream', 'stream': stream}));
    webrtcHelper.onRemoteStream = (stream) =>
        add(HandleCallSignal({'type': 'remote_stream', 'stream': stream}));
    webrtcHelper.onIceCandidate = (candidate) {
      if (_consultationId != null) {
        socketService.sendSignal(_consultationId!, {
          'type': 'candidate',
          'signal': {
            'candidate': candidate.toMap(),
          },
        });
      }
    };

    try {
      await webrtcHelper.initLocalStream(event.isVideo);
      await webrtcHelper.initializePeerConnection();

      final offer = await webrtcHelper.createOffer();
      if (_consultationId != null) {
        socketService.sendSignal(_consultationId!, {
          'type': 'offer',
          'callType': event.isVideo ? 'video' : 'audio',
          'signal': {
            'type': 'offer',
            'sdp': offer.sdp,
          },
        });
      }
    } catch (e) {
      emit(state.copyWith(error: 'Failed to start call: $e', isCallActive: false));
    }
  }

  Future<void> _onHandleSignal(
    HandleCallSignal event,
    Emitter<ConsultationRoomState> emit,
  ) async {
    final type = event.signal['type'];

    if (type == 'local_stream') {
      emit(state.copyWith(localStream: event.signal['stream']));
    } else if (type == 'remote_stream') {
      emit(state.copyWith(remoteStream: event.signal['stream']));
    } else if (type == 'offer') {
      final bool isVideo = event.signal['callType'] == 'video' || event.signal['isVideo'] == true;
      emit(state.copyWith(
        hasIncomingCall: true,
        pendingOffer: event.signal,
        isVideoCall: isVideo,
      ));
    } else if (type == 'answer') {
      final sdp = event.signal['signal'] != null ? event.signal['signal']['sdp'] : event.signal['sdp'];
      await webrtcHelper.setRemoteDescription(
        RTCSessionDescription(sdp, 'answer'),
      );
    } else if (type == 'candidate') {
      final cand = event.signal['signal'] != null ? event.signal['signal']['candidate'] : event.signal['candidate'];
      if (cand != null) {
        await webrtcHelper.addIceCandidate(
          RTCIceCandidate(
            cand['candidate'],
            cand['sdpMid'],
            cand['sdpMLineIndex'],
          ),
        );
      }
    }
  }

  void _onToggleMute(ToggleMute event, Emitter<ConsultationRoomState> emit) {
    final newMute = !state.isMuted;
    webrtcHelper.toggleMute(newMute);
    emit(state.copyWith(isMuted: newMute));
  }

  void _onToggleCamera(
    ToggleCamera event,
    Emitter<ConsultationRoomState> emit,
  ) {
    final newCamera = !state.isCameraOn;
    webrtcHelper.toggleCamera(newCamera);
    emit(state.copyWith(isCameraOn: newCamera));
  }

  Future<void> _onEndCall(
    EndConsultationCall event,
    Emitter<ConsultationRoomState> emit,
  ) async {
    if (_consultationId != null) socketService.endCall(_consultationId!);
    await webrtcHelper.dispose();
    emit(
      state.copyWith(
        isCallActive: false,
        localStream: null,
        remoteStream: null,
      ),
    );
  }

  Future<void> _onAcceptCall(
    AcceptCall event,
    Emitter<ConsultationRoomState> emit,
  ) async {
    final offer = state.pendingOffer;
    if (offer != null) {
      try {
        await webrtcHelper.initLocalStream(state.isVideoCall);
        await webrtcHelper.initializePeerConnection();
        final sdp = offer['signal'] != null ? offer['signal']['sdp'] : offer['sdp'];
        final answer = await webrtcHelper.createAnswer(
          RTCSessionDescription(sdp, 'offer'),
        );
        if (_consultationId != null) {
          socketService.sendSignal(_consultationId!, {
            'type': 'answer',
            'signal': {
              'type': 'answer',
              'sdp': answer.sdp,
            },
          });
        }
        emit(
          state.copyWith(
            isCallActive: true,
            hasIncomingCall: false,
            pendingOffer: null,
          ),
        );
      } catch (e) {
        emit(state.copyWith(error: 'Failed to accept call: $e', hasIncomingCall: false));
      }
    }
  }

  void _onRejectCall(
    RejectCall event,
    Emitter<ConsultationRoomState> emit,
  ) {
    if (_consultationId != null) {
      socketService.rejectCall(_consultationId!);
    }
    emit(state.copyWith(hasIncomingCall: false, pendingOffer: null));
  }

  @override
  Future<void> close() {
    _msgSub?.cancel();
    _sigSub?.cancel();
    _endSub?.cancel();
    webrtcHelper.dispose();
    return super.close();
  }
}
