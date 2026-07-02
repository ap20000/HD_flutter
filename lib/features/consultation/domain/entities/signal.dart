class CallSignal {
  final String type; // 'offer', 'answer', 'candidate'
  final String? sdp;
  final String? candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;
  final String? callType; // 'audio', 'video'

  CallSignal({
    required this.type,
    this.sdp,
    this.candidate,
    this.sdpMid,
    this.sdpMLineIndex,
    this.callType,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (sdp != null) 'sdp': sdp,
      if (candidate != null) 'candidate': candidate,
      if (sdpMid != null) 'sdpMid': sdpMid,
      if (sdpMLineIndex != null) 'sdpMLineIndex': sdpMLineIndex,
      if (callType != null) 'callType': callType,
    };
  }

  factory CallSignal.fromJson(Map<String, dynamic> json) {
    // Check if the signal is nested inside a 'signal' property
    final Map<String, dynamic> signalData = json['signal'] != null && json['signal'] is Map
        ? Map<String, dynamic>.from(json['signal'])
        : json;

    // Check if 'candidate' is nested further inside candidate signal data (WebRTC standard serialization)
    String? parsedCandidate;
    String? parsedSdpMid;
    int? parsedSdpMLineIndex;

    if (signalData['candidate'] != null) {
      if (signalData['candidate'] is Map) {
        final candMap = Map<String, dynamic>.from(signalData['candidate']);
        parsedCandidate = candMap['candidate'];
        parsedSdpMid = candMap['sdpMid'];
        parsedSdpMLineIndex = candMap['sdpMLineIndex'];
      } else {
        parsedCandidate = signalData['candidate'].toString();
        parsedSdpMid = signalData['sdpMid'];
        parsedSdpMLineIndex = signalData['sdpMLineIndex'];
      }
    }

    return CallSignal(
      type: json['type'] ?? signalData['type'] ?? '',
      sdp: signalData['sdp'],
      candidate: parsedCandidate,
      sdpMid: parsedSdpMid ?? signalData['sdpMid'],
      sdpMLineIndex: parsedSdpMLineIndex ?? signalData['sdpMLineIndex'],
      callType: json['callType'] ?? signalData['callType'],
    );
  }
}
