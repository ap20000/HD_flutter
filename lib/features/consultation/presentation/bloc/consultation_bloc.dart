import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/socket_service.dart';
import '../../../doctor_dashboard/domain/usecases/doctor_dashboard_usecases.dart';
import '../../domain/entities/call_status.dart';
import '../../domain/entities/signal.dart';
import '../../domain/repositories/consultation_repository.dart';
import 'consultation_event.dart';
import 'consultation_state.dart';

class ConsultationBloc extends Bloc<ConsultationEvent, ConsultationState> {
  final SocketService socketService;
  final ConsultationRepository consultationRepository;
  final GetConsultationByIdUseCase getConsultationByIdUseCase;

  String? _consultationId;
  StreamSubscription? _msgSub;
  StreamSubscription? _sigSub;
  StreamSubscription? _endSub;
  StreamSubscription? _rejectSub;
  StreamSubscription? _localStreamSub;
  StreamSubscription? _remoteStreamSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _iceCandidateSub;
  Timer? _callTimer;

  ConsultationBloc({
    required this.socketService,
    required this.consultationRepository,
    required this.getConsultationByIdUseCase,
  }) : super(const ConsultationState()) {
    on<JoinConsultation>(_onJoinConsultation);
    on<SendChatMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<StartCall>(_onStartCall);
    on<HandleCallSignal>(_onHandleCallSignal);
    on<ToggleMute>(_onToggleMute);
    on<ToggleCamera>(_onToggleCamera);
    on<SwitchCamera>(_onSwitchCamera);
    on<EndConsultationCall>(_onEndCall);
    on<AcceptCall>(_onAcceptCall);
    on<RejectCall>(_onRejectCall);
    on<UpdateCallDuration>((event, emit) {
      emit(state.copyWith(callDuration: event.duration));
    });

    // 1. Subscribe to Socket events
    _msgSub = socketService.messages.listen((msg) => add(MessageReceived(msg)));
    _sigSub = socketService.signals.listen((sig) => add(HandleCallSignal(sig)));
    _endSub = socketService.callEnded.listen((_) => add(const EndConsultationCall(isRemote: true)));
    _rejectSub = socketService.callRejected.listen((_) => add(const EndConsultationCall(isRemote: true)));

    // 2. Subscribe to Repository streams to update UI state reactively
    _localStreamSub = consultationRepository.localStreamStream.listen((stream) {
      print('ConsultationBloc: Local stream updated in Bloc.');
      emit(state.copyWith(localStream: stream));
    });

    _remoteStreamSub = consultationRepository.remoteStreamStream.listen((stream) {
      print('ConsultationBloc: Remote stream updated in Bloc.');
      emit(state.copyWith(
        remoteStream: stream,
        remoteStreamVersion: state.remoteStreamVersion + 1,
      ));
    });

    _statusSub = consultationRepository.callStatusStream.listen((status) {
      print('ConsultationBloc: Call status changed to: $status');
      if (status == CallStatus.connected) {
        emit(state.copyWith(isCallActive: true));
      } else if (status == CallStatus.disconnected) {
        emit(state.copyWith(
          isCallActive: false,
          localStream: null,
          remoteStream: null,
        ));
      }
    });

    _errorSub = consultationRepository.errorStream.listen((err) {
      if (err != null) {
        emit(state.copyWith(error: err));
      }
    });

    _iceCandidateSub = consultationRepository.iceCandidateStream.listen((candidate) {
      if (_consultationId != null) {
        print('ConsultationBloc: Local ICE candidate gathered. Sending over socket...');
        socketService.sendSignal(_consultationId!, {
          'type': 'candidate',
          'signal': {
            'candidate': {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            }
          }
        });
      }
    });
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    add(const UpdateCallDuration(0));
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(UpdateCallDuration(timer.tick));
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  Future<void> _onJoinConsultation(
    JoinConsultation event,
    Emitter<ConsultationState> emit,
  ) async {
    print('ConsultationBloc: Joining room: ${event.consultationId}');
    _consultationId = event.consultationId;
    socketService.connect();
    socketService.joinConsultation(event.consultationId);

    // Mock sessions do not require DB fetch
    if (event.consultationId.contains('_session')) {
      return;
    }

    final result = await getConsultationByIdUseCase(event.consultationId);
    result.fold(
      (failure) => print('ConsultationBloc: Failed to fetch past messages: ${failure.message}'),
      (consultation) {
        emit(state.copyWith(messages: consultation.messages));
      },
    );
  }

  Future<void> _onSendMessage(
    SendChatMessage event,
    Emitter<ConsultationState> emit,
  ) async {
    if (_consultationId != null) {
      socketService.sendMessage(_consultationId!, event.senderId, event.text);
    }
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ConsultationState> emit,
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
    Emitter<ConsultationState> emit,
  ) async {
    print('ConsultationBloc: Request to start call (isVideo: ${event.isVideo})');
    emit(state.copyWith(
      isVideoCall: event.isVideo,
      isCameraOn: event.isVideo,
      isMuted: false,
    ));

    final result = await consultationRepository.startCall(event.isVideo);
    result.fold(
      (failure) => emit(state.copyWith(error: 'Failed to start call: ${failure.message}')),
      (offer) {
        if (_consultationId != null) {
          print('ConsultationBloc: Sending offer signal over socket...');
          socketService.sendSignal(_consultationId!, {
            'type': 'offer',
            'callType': event.isVideo ? 'video' : 'audio',
            'signal': {
              'type': 'offer',
              'sdp': offer.sdp,
            },
          });
        }
        emit(state.copyWith(isCallActive: true));
      },
    );
  }

  Future<void> _onHandleCallSignal(
    HandleCallSignal event,
    Emitter<ConsultationState> emit,
  ) async {
    final signal = CallSignal.fromJson(event.signal);
    print('ConsultationBloc: Processing incoming signal type: ${signal.type}');

    switch (signal.type) {
      case 'offer':
        final bool isVideo = signal.callType == 'video' || event.signal['isVideo'] == true;
        print('ConsultationBloc: Incoming call offer received. (isVideo: $isVideo)');
        emit(state.copyWith(
          hasIncomingCall: true,
          pendingOffer: event.signal,
          isVideoCall: isVideo,
          isCameraOn: isVideo,
        ));
        break;

      case 'answer':
        print('ConsultationBloc: Answer received. Applying...');
        await consultationRepository.setAnswer(signal);
        _startCallTimer();
        break;

      case 'candidate':
        print('ConsultationBloc: Remote ICE candidate received. Forwarding to repository...');
        await consultationRepository.addCandidate(signal);
        break;
      
      default:
        print('ConsultationBloc: Unknown signal type: ${signal.type}');
        break;
    }
  }

  Future<void> _onAcceptCall(
    AcceptCall event,
    Emitter<ConsultationState> emit,
  ) async {
    print('ConsultationBloc: Accepting call request...');
    final offerMap = state.pendingOffer;
    if (offerMap == null) return;

    final offer = CallSignal.fromJson(offerMap);
    emit(state.copyWith(hasIncomingCall: false, pendingOffer: null));

    final result = await consultationRepository.acceptCall(offer);
    result.fold(
      (failure) => emit(state.copyWith(error: 'Failed to accept call: ${failure.message}')),
      (answer) {
        if (_consultationId != null) {
          print('ConsultationBloc: Sending answer signal over socket...');
          socketService.sendSignal(_consultationId!, {
            'type': 'answer',
            'signal': {
              'type': 'answer',
              'sdp': answer.sdp,
            },
          });
        }
        _startCallTimer();
        emit(state.copyWith(isCallActive: true));
      },
    );
  }

  void _onRejectCall(
    RejectCall event,
    Emitter<ConsultationState> emit,
  ) {
    print('ConsultationBloc: Rejecting incoming call request...');
    if (_consultationId != null) {
      socketService.rejectCall(_consultationId!);
    }
    emit(state.copyWith(hasIncomingCall: false, pendingOffer: null));
  }

  void _onToggleMute(ToggleMute event, Emitter<ConsultationState> emit) {
    final nextMute = !state.isMuted;
    print('ConsultationBloc: Toggle Mute -> $nextMute');
    consultationRepository.toggleMute(nextMute);
    emit(state.copyWith(isMuted: nextMute));
  }

  void _onToggleCamera(ToggleCamera event, Emitter<ConsultationState> emit) {
    final nextCamera = !state.isCameraOn;
    print('ConsultationBloc: Toggle Camera -> $nextCamera');
    consultationRepository.toggleCamera(nextCamera);
    emit(state.copyWith(isCameraOn: nextCamera));
  }

  void _onSwitchCamera(SwitchCamera event, Emitter<ConsultationState> emit) {
    print('ConsultationBloc: Switch Camera...');
    consultationRepository.switchCamera();
  }

  Future<void> _onEndCall(
    EndConsultationCall event,
    Emitter<ConsultationState> emit,
  ) async {
    print('ConsultationBloc: End call session triggered. (isRemote: ${event.isRemote})');
    _stopCallTimer();
    if (_consultationId != null && !event.isRemote) {
      socketService.endCall(_consultationId!);
    }
    await consultationRepository.endCall();
    emit(state.copyWith(
      isCallActive: false,
      localStream: null,
      remoteStream: null,
      callDuration: 0,
    ));
  }

  @override
  Future<void> close() {
    print('ConsultationBloc: Closing Bloc subscriptions...');
    _msgSub?.cancel();
    _sigSub?.cancel();
    _endSub?.cancel();
    _rejectSub?.cancel();
    _localStreamSub?.cancel();
    _remoteStreamSub?.cancel();
    _statusSub?.cancel();
    _errorSub?.cancel();
    _iceCandidateSub?.cancel();
    _callTimer?.cancel();
    consultationRepository.endCall();
    return super.close();
  }
}
