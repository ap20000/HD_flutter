import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/socket_service.dart';
import '../../domain/entities/call_status.dart';
import '../../domain/entities/signal.dart';
import '../../domain/repositories/consultation_repository.dart';
import '../datasources/webrtc_datasource.dart';

class ConsultationRepositoryImpl implements ConsultationRepository {
  final WebRTCDatasource webrtcDatasource;
  final SocketService socketService;

  final _callStatusController = StreamController<CallStatus>.broadcast();
  final _errorController = StreamController<String?>.broadcast();
  StreamSubscription? _connectionStateSub;

  ConsultationRepositoryImpl({
    required this.webrtcDatasource,
    required this.socketService,
  }) {
    // Listen to connection state changes from WebRTC and map them to domain states
    _connectionStateSub = webrtcDatasource.connectionStateStream.listen((state) {
      print('ConsultationRepositoryImpl: Received Connection State: $state');
      final lowerState = state.toLowerCase();
      if (lowerState.endsWith('connected') || lowerState.endsWith('completed')) {
        _callStatusController.add(CallStatus.connected);
      } else if (lowerState.contains('disconnected') || lowerState.contains('failed') || lowerState.contains('closed')) {
        _callStatusController.add(CallStatus.disconnected);
      }
    });
  }

  @override
  Future<Either<Failure, void>> initCall(bool isVideo) async {
    try {
      print('ConsultationRepositoryImpl: Initializing call components (isVideo: $isVideo)');
      await webrtcDatasource.initLocalStream(isVideo);
      await webrtcDatasource.initializePeerConnection();
      return const Right(null);
    } catch (e) {
      print('ConsultationRepositoryImpl: Error in initCall: $e');
      _errorController.add(e.toString());
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RTCSessionDescription>> startCall(bool isVideo) async {
    try {
      print('ConsultationRepositoryImpl: Starting outgoing call sequence...');
      _callStatusController.add(CallStatus.calling);
      
      await webrtcDatasource.initLocalStream(isVideo);
      await webrtcDatasource.initializePeerConnection();
      
      final offer = await webrtcDatasource.createOffer();
      return Right(offer);
    } catch (e) {
      print('ConsultationRepositoryImpl: Error in startCall: $e');
      _callStatusController.add(CallStatus.error);
      _errorController.add(e.toString());
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RTCSessionDescription>> acceptCall(CallSignal offer) async {
    try {
      print('ConsultationRepositoryImpl: Accepting incoming call...');
      final isVideo = offer.callType == 'video';
      
      await webrtcDatasource.initLocalStream(isVideo);
      await webrtcDatasource.initializePeerConnection();
      
      final sdpOffer = RTCSessionDescription(offer.sdp, 'offer');
      final answer = await webrtcDatasource.createAnswer(sdpOffer);
      
      _callStatusController.add(CallStatus.connected);
      return Right(answer);
    } catch (e) {
      print('ConsultationRepositoryImpl: Error in acceptCall: $e');
      _callStatusController.add(CallStatus.error);
      _errorController.add(e.toString());
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setAnswer(CallSignal answer) async {
    try {
      print('ConsultationRepositoryImpl: Setting remote answer SDP...');
      final sdpAnswer = RTCSessionDescription(answer.sdp, 'answer');
      await webrtcDatasource.setRemoteDescription(sdpAnswer);
      return const Right(null);
    } catch (e) {
      print('ConsultationRepositoryImpl: Error in setAnswer: $e');
      _errorController.add(e.toString());
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addCandidate(CallSignal candidate) async {
    try {
      print('ConsultationRepositoryImpl: Parsing and applying remote ICE candidate...');
      if (candidate.candidate != null) {
        final rtcCandidate = RTCIceCandidate(
          candidate.candidate,
          candidate.sdpMid,
          candidate.sdpMLineIndex,
        );
        await webrtcDatasource.addIceCandidate(rtcCandidate);
      }
      return const Right(null);
    } catch (e) {
      print('ConsultationRepositoryImpl: Error in addCandidate: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> endCall() async {
    try {
      print('ConsultationRepositoryImpl: Ending current call session...');
      await webrtcDatasource.dispose();
      _callStatusController.add(CallStatus.disconnected);
      return const Right(null);
    } catch (e) {
      print('ConsultationRepositoryImpl: Error in endCall: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleMute(bool isMuted) async {
    try {
      webrtcDatasource.toggleMute(isMuted);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleCamera(bool isCameraOn) async {
    try {
      webrtcDatasource.toggleCamera(isCameraOn);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> switchCamera() async {
    try {
      webrtcDatasource.switchCamera();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<MediaStream> get localStreamStream => webrtcDatasource.localStreamStream;

  @override
  Stream<MediaStream> get remoteStreamStream => webrtcDatasource.remoteStreamStream;

  @override
  Stream<CallStatus> get callStatusStream => _callStatusController.stream;

  @override
  Stream<String?> get errorStream => _errorController.stream;

  @override
  Stream<RTCIceCandidate> get iceCandidateStream => webrtcDatasource.iceCandidateStream;

  void dispose() {
    print('ConsultationRepositoryImpl: Disposing resources...');
    _connectionStateSub?.cancel();
    _callStatusController.close();
    _errorController.close();
  }
}
