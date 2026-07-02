import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ConsultationState extends Equatable {
  final List<Map<String, dynamic>> messages;
  final bool isVideoCall;
  final bool isMuted;
  final bool isCameraOn;
  final bool isCallActive;
  final MediaStream? localStream;
  final MediaStream? remoteStream;
  final int remoteStreamVersion;
  final bool hasIncomingCall;
  final Map<String, dynamic>? pendingOffer;
  final String? error;
  final int callDuration;

  const ConsultationState({
    this.messages = const [],
    this.isVideoCall = true,
    this.isMuted = false,
    this.isCameraOn = true,
    this.isCallActive = false,
    this.localStream,
    this.remoteStream,
    this.remoteStreamVersion = 0,
    this.hasIncomingCall = false,
    this.pendingOffer,
    this.error,
    this.callDuration = 0,
  });

  ConsultationState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isVideoCall,
    bool? isMuted,
    bool? isCameraOn,
    bool? isCallActive,
    dynamic localStream = _sentinel,
    dynamic remoteStream = _sentinel,
    int? remoteStreamVersion,
    bool? hasIncomingCall,
    dynamic pendingOffer = _sentinel,
    dynamic error = _sentinel,
    int? callDuration,
  }) {
    return ConsultationState(
      messages: messages ?? this.messages,
      isVideoCall: isVideoCall ?? this.isVideoCall,
      isMuted: isMuted ?? this.isMuted,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      isCallActive: isCallActive ?? this.isCallActive,
      localStream: localStream == _sentinel ? this.localStream : (localStream as MediaStream?),
      remoteStream: remoteStream == _sentinel ? this.remoteStream : (remoteStream as MediaStream?),
      remoteStreamVersion: remoteStreamVersion ?? this.remoteStreamVersion,
      hasIncomingCall: hasIncomingCall ?? this.hasIncomingCall,
      pendingOffer: pendingOffer == _sentinel ? this.pendingOffer : (pendingOffer as Map<String, dynamic>?),
      error: error == _sentinel ? this.error : (error as String?),
      callDuration: callDuration ?? this.callDuration,
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
        remoteStreamVersion,
        hasIncomingCall,
        pendingOffer,
        error,
        callDuration,
      ];
}

class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();
