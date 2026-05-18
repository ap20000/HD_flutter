import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCHelper {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function(RTCIceCandidate)? onIceCandidate;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  Future<void> initLocalStream(bool isVideo) async {
    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': isVideo ? {
        'facingMode': 'user',
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      } : false,
    };

    print('WebRTCHelper: Initializing local stream (video: $isVideo)...');
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Camera/Microphone initialization timed out'),
      );
      print('WebRTCHelper: Local stream initialized successfully.');
      onLocalStream?.call(_localStream!);
    } catch (e) {
      print('WebRTCHelper: Error initializing local stream: $e');
      rethrow;
    }
  }

  Future<void> initializePeerConnection() async {
    print('WebRTCHelper: Initializing PeerConnection...');
    _peerConnection = await createPeerConnection(_configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      print('WebRTCHelper: New ICE candidate generated.');
      onIceCandidate?.call(candidate);
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        print('WebRTCHelper: Remote track received.');
        _remoteStream = event.streams[0];
        onRemoteStream?.call(_remoteStream!);
      }
    };

    _localStream?.getTracks().forEach((track) {
      print('WebRTCHelper: Adding track: ${track.kind}');
      _peerConnection!.addTrack(track, _localStream!);
    });
    print('WebRTCHelper: PeerConnection initialized.');
  }

  Future<RTCSessionDescription> createOffer() async {
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer(RTCSessionDescription offer) async {
    await _peerConnection!.setRemoteDescription(offer);
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    if (_peerConnection != null) {
      await _peerConnection!.setRemoteDescription(description);
    }
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection != null) {
      await _peerConnection!.addCandidate(candidate);
    }
  }

  void toggleMute(bool isMuted) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMuted;
    });
  }

  void toggleCamera(bool isVideoOn) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isVideoOn;
    });
  }

  void switchCamera() {
    Helper.switchCamera(_localStream!.getVideoTracks()[0]);
  }

  Future<void> dispose() async {
    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    await _peerConnection?.close();
    await _peerConnection?.dispose();
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
  }
}
