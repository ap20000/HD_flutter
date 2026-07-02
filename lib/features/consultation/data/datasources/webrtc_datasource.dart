import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../core/webrtc/webrtc_service.dart';

abstract class WebRTCDatasource {
  Future<void> initLocalStream(bool isVideo);
  Future<void> initializePeerConnection();
  Future<RTCSessionDescription> createOffer();
  Future<RTCSessionDescription> createAnswer(RTCSessionDescription offer);
  Future<void> setRemoteDescription(RTCSessionDescription description);
  Future<void> addIceCandidate(RTCIceCandidate candidate);
  void toggleMute(bool isMuted);
  void toggleCamera(bool isCameraOn);
  void switchCamera();
  Future<void> dispose();

  Stream<MediaStream> get localStreamStream;
  Stream<MediaStream> get remoteStreamStream;
  Stream<String> get connectionStateStream;
  Stream<RTCIceCandidate> get iceCandidateStream;
}

class WebRTCDatasourceImpl implements WebRTCDatasource {
  final WebRTCService webrtcService;

  WebRTCDatasourceImpl({required this.webrtcService});

  @override
  Future<void> initLocalStream(bool isVideo) => webrtcService.initLocalStream(isVideo);

  @override
  Future<void> initializePeerConnection() => webrtcService.initializePeerConnection();

  @override
  Future<RTCSessionDescription> createOffer() => webrtcService.createOffer();

  @override
  Future<RTCSessionDescription> createAnswer(RTCSessionDescription offer) => webrtcService.createAnswer(offer);

  @override
  Future<void> setRemoteDescription(RTCSessionDescription description) => webrtcService.setRemoteDescription(description);

  @override
  Future<void> addIceCandidate(RTCIceCandidate candidate) => webrtcService.addIceCandidate(candidate);

  @override
  void toggleMute(bool isMuted) => webrtcService.toggleMute(isMuted);

  @override
  void toggleCamera(bool isCameraOn) => webrtcService.toggleCamera(isCameraOn);

  @override
  void switchCamera() => webrtcService.switchCamera();

  @override
  Future<void> dispose() => webrtcService.dispose();

  @override
  Stream<MediaStream> get localStreamStream => webrtcService.localStreamStream;

  @override
  Stream<MediaStream> get remoteStreamStream => webrtcService.remoteStreamStream;

  @override
  Stream<String> get connectionStateStream => webrtcService.connectionStateStream;

  @override
  Stream<RTCIceCandidate> get iceCandidateStream => webrtcService.iceCandidateStream;
}
