import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _isVideoCall = true;

  // Stream controllers to publish state to BLoC/Repository dynamically
  final StreamController<MediaStream> _localStreamController = StreamController<MediaStream>.broadcast();
  final StreamController<MediaStream> _remoteStreamController = StreamController<MediaStream>.broadcast();
  final StreamController<String> _connectionStateController = StreamController<String>.broadcast();
  final StreamController<RTCIceCandidate> _iceCandidateController = StreamController<RTCIceCandidate>.broadcast();

  Stream<MediaStream> get localStreamStream => _localStreamController.stream;
  Stream<MediaStream> get remoteStreamStream => _remoteStreamController.stream;
  Stream<String> get connectionStateStream => _connectionStateController.stream;
  Stream<RTCIceCandidate> get iceCandidateStream => _iceCandidateController.stream;

  // Queue to hold ICE candidates received before the remote description (SDP) is set.
  final List<RTCIceCandidate> _remoteIceCandidateQueue = [];
  bool _isRemoteDescriptionSet = false;

  final Map<String, dynamic> _iceConfiguration = {
    'sdpSemantics': 'unified-plan',
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  /// Dynamically request necessary permissions for call.
  /// No hard timeouts that would cause a crash on slow user response.
  Future<bool> requestPermissions(bool isVideo) async {
    print('WebRTCService: Requesting permissions (isVideo: $isVideo)...');
    try {
      final List<Permission> permissions = [Permission.microphone];
      if (isVideo) {
        permissions.add(Permission.camera);
      }
      
      // Request bluetoothConnect on Android (API >= 31) for audio routing support
      if (!kIsWeb && Platform.isAndroid) {
        permissions.add(Permission.bluetoothConnect);
      }

      final status = await permissions.request();
      final micGranted = status[Permission.microphone] == PermissionStatus.granted;
      final cameraGranted = !isVideo || (status[Permission.camera] == PermissionStatus.granted);
      
      print('WebRTCService: Permissions status - Microphone: $micGranted, Camera (if video): $cameraGranted');
      
      if (!kIsWeb && Platform.isAndroid) {
        final btGranted = status[Permission.bluetoothConnect] == PermissionStatus.granted;
        print('WebRTCService: BluetoothConnect status: $btGranted');
        // Do not fail the whole call setup if bluetooth permission is denied,
        // since the default built-in mic/speaker will still function.
      }
      
      return micGranted && cameraGranted;
    } catch (e) {
      print('WebRTCService: Exception during permission request: $e');
      return false;
    }
  }

  Future<void> _configureAndroidAudio() async {
    if (!kIsWeb && Platform.isAndroid) {
      print('WebRTCService: Setting up AndroidAudioConfiguration...');
      try {
        final androidConfig = AndroidAudioConfiguration(
          manageAudioFocus: true,
          androidAudioMode: AndroidAudioMode.inCommunication,
          androidAudioFocusMode: AndroidAudioFocusMode.gain,
          androidAudioStreamType: AndroidAudioStreamType.voiceCall,
          androidAudioAttributesUsageType: AndroidAudioAttributesUsageType.voiceCommunication,
          androidAudioAttributesContentType: AndroidAudioAttributesContentType.speech,
        );
        await Helper.setAndroidAudioConfiguration(androidConfig);
        print('WebRTCService: AndroidAudioConfiguration applied successfully.');
      } catch (e) {
        print('WebRTCService: Failed to set AndroidAudioConfiguration: $e');
      }
    }
  }

  /// Initialize camera/microphone stream.
  Future<void> initLocalStream(bool isVideo) async {
    print('WebRTCService: Initializing local stream (video: $isVideo)...');
    _isVideoCall = isVideo;

    // Apply Android-specific audio configuration before starting
    await _configureAndroidAudio();
    
    if (_localStream != null) {
      print('WebRTCService: Local stream already exists. Disposing old stream...');
      for (var track in _localStream!.getTracks()) {
        try {
          track.stop();
        } catch (e) {
          print('WebRTCService: Error stopping track during re-init: $e');
        }
      }
      try {
        await _localStream!.dispose();
      } catch (e) {
        print('WebRTCService: Error disposing old local stream: $e');
      }
      _localStream = null;
    }

    // Attempt permission request first without rigid timeouts
    final permissionsGranted = await requestPermissions(isVideo);
    if (!permissionsGranted) {
      print('WebRTCService: Permissions not granted.');
      throw Exception('Required hardware permissions were not granted.');
    }

    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': isVideo
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
              'frameRate': {'ideal': 30},
            }
          : false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      print('WebRTCService: Local stream initialized successfully.');
      _localStreamController.add(_localStream!);
      
      // Set initial audio routing
      print('WebRTCService: Setting speakerphone routing (isVideo: $isVideo)');
      if (isVideo) {
        await Helper.setSpeakerphoneOnButPreferBluetooth();
      } else {
        await Helper.setSpeakerphoneOn(false);
      }
    } catch (e) {
      print('WebRTCService: Failed to get user media: $e');
      rethrow;
    }
  }

  /// Set up RTCPeerConnection, tracks, and listeners.
  Future<void> initializePeerConnection() async {
    print('WebRTCService: Initializing PeerConnection...');
    _isRemoteDescriptionSet = false;

    // Apply Android-specific audio configuration before starting
    await _configureAndroidAudio();

    try {
      if (_peerConnection != null) {
        print('WebRTCService: PeerConnection already exists. Disposing before creating a new one...');
        _peerConnection!.onIceCandidate = null;
        _peerConnection!.onTrack = null;
        _peerConnection!.onConnectionState = null;
        _peerConnection!.onIceConnectionState = null;
        _peerConnection!.onSignalingState = null;
        try {
          await _peerConnection!.close();
        } catch (e) {
          print('WebRTCService: Error closing old peer connection: $e');
        }
        try {
          await _peerConnection!.dispose();
        } catch (e) {
          print('WebRTCService: Error disposing old peer connection: $e');
        }
        _peerConnection = null;
      }
      _peerConnection = await createPeerConnection(_iceConfiguration);
      print('WebRTCService: PeerConnection created successfully.');

      // Setup state event listeners
      _peerConnection!.onIceCandidate = (candidate) {
        print('WebRTCService: Local ICE candidate gathered.');
        _iceCandidateController.add(candidate);
      };

      _peerConnection!.onTrack = (event) async {
        print('WebRTCService: onTrack event fired. Kind: ${event.track.kind}');
        if (event.track.kind == 'audio' || event.track.kind == 'video') {
          event.track.enabled = true;
        }
        if (event.streams.isNotEmpty) {
          print('WebRTCService: Remote stream track found.');
          _remoteStream = event.streams[0];
          _remoteStreamController.add(_remoteStream!);
        } else {
          print('WebRTCService: event.streams is empty. Creating dynamic remote stream container.');
          _remoteStream ??= await createLocalMediaStream('remote_stream');
          await _remoteStream!.addTrack(event.track);
          _remoteStreamController.add(_remoteStream!);
        }
      };

      _peerConnection!.onConnectionState = (state) {
        final stateStr = state.toString().split('.').last;
        print('WebRTCService: Connection state changed: $stateStr');
        _connectionStateController.add(stateStr);
        if (stateStr.toLowerCase().endsWith('connected')) {
          print('WebRTCService: PeerConnection connected. Setting speakerphone routing (isVideo: $_isVideoCall) with delay...');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_isVideoCall) {
              Helper.setSpeakerphoneOnButPreferBluetooth().catchError((e) {
                print('WebRTCService: Error setting speakerphone on connect: $e');
              });
            } else {
              Helper.setSpeakerphoneOn(false).catchError((e) {
                print('WebRTCService: Error setting speakerphone on connect: $e');
              });
            }
          });

          // Inject user requested stats logging
          Timer.periodic(const Duration(seconds: 2), (timer) async {
            if (_peerConnection == null) {
              timer.cancel();
              return;
            }
            try {
              final senders = await _peerConnection!.getSenders();
              for (final sender in senders) {
                if (sender.track?.kind == 'video') {
                  final stats = await sender.getStats();
                  print('--- FLUTTER VIDEO SENDER STATS ---');
                  for (var stat in stats) {
                    print(stat.values);
                  }
                }
              }
            } catch (e) {
              print('Stats error: $e');
            }
          });
        }
      };

      _peerConnection!.onIceConnectionState = (state) {
        final stateStr = state.toString().split('.').last;
        print('WebRTCService: ICE Connection state changed: $stateStr');
        _connectionStateController.add('ice_$stateStr');
      };

      _peerConnection!.onSignalingState = (state) {
        print('WebRTCService: Signaling state changed: $state');
      };

      // Add local media stream tracks to peer connection
      if (_localStream != null) {
        print('WebRTCService: Adding local tracks to peer connection...');
        for (var track in _localStream!.getTracks()) {
          print('WebRTCService: Adding track: ${track.kind}');
          await _peerConnection!.addTrack(track, _localStream!);
        }
      } else {
        print('WebRTCService: WARNING: _localStream is null when adding tracks.');
      }
      
      print('WebRTCService: PeerConnection setup completed.');
    } catch (e) {
      print('WebRTCService: Failed to initialize PeerConnection: $e');
      rethrow;
    }
  }

  /// Create WebRTC offer (SDP) and set as local description.
  Future<RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) throw StateError('PeerConnection not initialized');
    
    print('WebRTCService: Creating offer SDP...');
    try {
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      print('WebRTCService: Setting local description (Offer)...');
      print('--- FLUTTER OFFER SDP ---');
      print(offer.sdp);
      await _peerConnection!.setLocalDescription(offer);
      return offer;
    } catch (e) {
      print('WebRTCService: Error creating offer: $e');
      rethrow;
    }
  }

  /// Create WebRTC answer (SDP), set remote offer description, then set local answer.
  Future<RTCSessionDescription> createAnswer(RTCSessionDescription offer) async {
    if (_peerConnection == null) throw StateError('PeerConnection not initialized');

    print('WebRTCService: Setting remote description (Offer)...');
    try {
      await _peerConnection!.setRemoteDescription(offer);
      _onRemoteDescriptionApplied();

      print('WebRTCService: Creating answer SDP...');
      RTCSessionDescription answer = await _peerConnection!.createAnswer();

      print('WebRTCService: Setting local description (Answer)...');
      print('--- FLUTTER ANSWER SDP ---');
      print(answer.sdp);
      await _peerConnection!.setLocalDescription(answer);
      return answer;
    } catch (e) {
      print('WebRTCService: Error creating answer: $e');
      rethrow;
    }
  }

  /// Set remote description for incoming Answer SDP.
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    if (_peerConnection == null) {
      print('WebRTCService: WARNING: setRemoteDescription called when PeerConnection is null.');
      return;
    }

    if (description.type == 'answer') {
      print("Current signalingState: ${_peerConnection?.signalingState}");
      print("Received answer SDP");
    }

    print('WebRTCService: Setting remote description (${description.type})...');
    try {
      await _peerConnection!.setRemoteDescription(description);
      _onRemoteDescriptionApplied();
    } catch (e) {
      print('WebRTCService: Error setting remote description: $e');
      rethrow;
    }
  }

  /// Buffered candidate addition logic. Queues candidates until remote description is set.
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) {
      print('WebRTCService: Buffered candidate because PeerConnection is not ready.');
      _remoteIceCandidateQueue.add(candidate);
      return;
    }

    if (!_isRemoteDescriptionSet) {
      print('WebRTCService: Queued candidate because remote description is not set yet.');
      _remoteIceCandidateQueue.add(candidate);
      return;
    }

    print('WebRTCService: Adding ICE candidate: ${candidate.candidate?.substring(0, 15)}...');
    try {
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      print('WebRTCService: Error adding ICE candidate: $e');
    }
  }

  /// Internal callback triggered once remote SDP is successfully set.
  /// Safely flushes all queued candidates.
  void _onRemoteDescriptionApplied() async {
    print('WebRTCService: Remote description set. Flushing ${_remoteIceCandidateQueue.length} queued ICE candidates...');
    _isRemoteDescriptionSet = true;
    
    // Copy the list to avoid concurrent modification exceptions
    final candidates = List<RTCIceCandidate>.from(_remoteIceCandidateQueue);
    _remoteIceCandidateQueue.clear();

    for (var candidate in candidates) {
      print('WebRTCService: Applying queued candidate: ${candidate.candidate?.substring(0, 15)}...');
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        print('WebRTCService: Error applying queued ICE candidate: $e');
      }
    }
  }

  void toggleMute(bool isMuted) {
    print('WebRTCService: Toggling mute (isMuted: $isMuted)');
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMuted;
    });
  }

  void toggleCamera(bool isCameraOn) {
    print('WebRTCService: Toggling camera (isCameraOn: $isCameraOn)');
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isCameraOn;
    });
  }

  void switchCamera() {
    print('WebRTCService: Switching camera...');
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      Helper.switchCamera(_localStream!.getVideoTracks()[0]);
    }
  }

  /// Cleanly closes connections and disposes resources.
  /// Vital to nullify all listeners to prevent native thread exits (Exit 255).
  Future<void> dispose() async {
    print('WebRTCService: Disposing resources...');
    
    // 1. Unbind and nullify native listeners first to prevent crashes from callbacks firing during cleanup
    if (_peerConnection != null) {
      print('WebRTCService: Nullifying connection callbacks...');
      _peerConnection!.onIceCandidate = null;
      _peerConnection!.onTrack = null;
      _peerConnection!.onConnectionState = null;
      _peerConnection!.onIceConnectionState = null;
      _peerConnection!.onSignalingState = null;
    }

    // 2. Stop and release local stream tracks
    if (_localStream != null) {
      print('WebRTCService: Stopping local media stream tracks...');
      for (var track in _localStream!.getTracks()) {
        try {
          track.stop();
        } catch (e) {
          print('WebRTCService: Error stopping local track ${track.kind}: $e');
        }
      }
      try {
        await _localStream!.dispose();
      } catch (e) {
        print('WebRTCService: Error disposing local stream: $e');
      }
      _localStream = null;
    }

    // 3. Clear remote stream reference (the tracks are managed by the connection lifecycle)
    _remoteStream = null;

    // 4. Close and dispose PeerConnection
    if (_peerConnection != null) {
      print('WebRTCService: Closing and disposing PeerConnection...');
      try {
        await _peerConnection!.close();
      } catch (e) {
        print('WebRTCService: Error closing PeerConnection: $e');
      }
      try {
        await _peerConnection!.dispose();
      } catch (e) {
        print('WebRTCService: Error disposing PeerConnection: $e');
      }
      _peerConnection = null;
    }

    _isRemoteDescriptionSet = false;
    _remoteIceCandidateQueue.clear();
    print('WebRTCService: Disposal sequence completed.');
  }
}
