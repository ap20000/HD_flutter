import 'package:dartz/dartz.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../core/error/failures.dart';
import '../entities/call_status.dart';
import '../entities/signal.dart';

abstract class ConsultationRepository {
  Future<Either<Failure, void>> initCall(bool isVideo);
  Future<Either<Failure, RTCSessionDescription>> startCall(bool isVideo);
  Future<Either<Failure, RTCSessionDescription>> acceptCall(CallSignal offer);
  Future<Either<Failure, void>> setAnswer(CallSignal answer);
  Future<Either<Failure, void>> addCandidate(CallSignal candidate);
  Future<Either<Failure, void>> endCall();
  Future<Either<Failure, void>> toggleMute(bool isMuted);
  Future<Either<Failure, void>> toggleCamera(bool isCameraOn);
  Future<Either<Failure, void>> switchCamera();

  Stream<MediaStream> get localStreamStream;
  Stream<MediaStream> get remoteStreamStream;
  Stream<CallStatus> get callStatusStream;
  Stream<String?> get errorStream;
  Stream<RTCIceCandidate> get iceCandidateStream;
}
