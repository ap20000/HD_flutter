import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../injection_container.dart';
import '../bloc/consultation_room_bloc.dart';
import 'prescription_page.dart';

Uint8List? _getAvatarBytes(String? base64Str) {
  if (base64Str == null || base64Str.isEmpty) return null;
  try {
    String cleaned = base64Str;
    if (base64Str.contains(',')) {
      cleaned = base64Str.split(',').last;
    }
    return base64Decode(cleaned);
  } catch (e) {
    return null;
  }
}

class ConsultationRoomPage extends StatefulWidget {
  final String consultationId;
  final String currentUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final bool isDoctor;

  const ConsultationRoomPage({
    super.key,
    required this.consultationId,
    required this.currentUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.isDoctor = false,
  });

  @override
  State<ConsultationRoomPage> createState() => _ConsultationRoomPageState();
}

class _ConsultationRoomPageState extends State<ConsultationRoomPage> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    try {
      print('ConsultationRoomPage: Initializing renderers...');
      await Future.wait([
        _localRenderer.initialize().timeout(const Duration(seconds: 5)),
        _remoteRenderer.initialize().timeout(const Duration(seconds: 5)),
      ]);
      await _requestPermissions();
      print('ConsultationRoomPage: Renderers initialized.');
    } catch (e) {
      print('ConsultationRoomPage: Error during renderer init: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hardware initialization issue: $e')),
        );
      }
    }
  }

  Future<void> _requestPermissions() async {
    try {
      await [Permission.camera, Permission.microphone].request().timeout(const Duration(seconds: 5));
    } catch (e) {
      print('ConsultationRoomPage: Permission request timeout or error: $e');
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ConsultationRoomBloc>()..add(JoinConsultationRoom(widget.consultationId)),
      child: BlocConsumer<ConsultationRoomBloc, ConsultationRoomState>(
        listener: (context, state) {
          if (state.localStream != null) _localRenderer.srcObject = state.localStream;
          if (state.remoteStream != null) _remoteRenderer.srcObject = state.remoteStream;
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return PopScope(
            onPopInvokedWithResult: (didPop, result) {
              if (didPop && state.isCallActive) {
                context.read<ConsultationRoomBloc>().add(EndConsultationCall());
              }
            },
            child: Scaffold(
              resizeToAvoidBottomInset: !state.isCallActive,
              backgroundColor: const Color(0xFFF8FAFC), // Premium light background
              appBar: _buildAppBar(context, state),
              body: Stack(
                children: [
                  if (!state.isCallActive) _buildChatView(context, state),
                  if (state.isCallActive) _buildCallOverlay(context, state),
                  if (state.hasIncomingCall) _buildIncomingCallOverlay(context, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ConsultationRoomState state) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE8F0FF),
                backgroundImage: _getAvatarBytes(widget.otherUserAvatar) != null
                    ? MemoryImage(_getAvatarBytes(widget.otherUserAvatar)!)
                    : null,
                child: _getAvatarBytes(widget.otherUserAvatar) == null
                    ? const Icon(Icons.person, size: 20, color: Color(0xFF004AC6))
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981), // success green
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  state.isCallActive ? 'In Video Call' : 'Active Session',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Prescription Action Button
        IconButton(
          icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF004AC6), size: 22),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PrescriptionPage(
                  patientName: widget.isDoctor ? widget.otherUserName : 'Samyog',
                  isDoctor: widget.isDoctor,
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Color(0xFF004AC6), size: 22),
          onPressed: () => context.read<ConsultationRoomBloc>().add(const StartCall(isVideo: false)),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Color(0xFF004AC6), size: 22),
          onPressed: () => context.read<ConsultationRoomBloc>().add(const StartCall(isVideo: true)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildChatView(BuildContext context, ConsultationRoomState state) {
    // Generate list of messages combined with default high-fidelity mock messages
    final List<Map<String, dynamic>> mockMessages = [
      {
        'senderId': 'doctor', // Dr. Aradhana
        'text': "Good morning. I've reviewed your previous logs. How have you been feeling since we adjusted your medication last week?",
        'type': 'text',
      },
      {
        'senderId': widget.currentUserId, // Patient Samyog
        'text': "I'm feeling much better, but I did notice a slight palpitation yesterday evening while resting.",
        'type': 'text',
      },
      {
        'senderId': widget.currentUserId,
        'text': "Medical_Report_Oct.pdf",
        'type': 'file',
        'fileSize': '2.4 MB • PDF Document',
      },
      {
        'senderId': 'doctor',
        'text': "Understood. That's a helpful detail. Based on the report you shared, I'll update your prescription to better manage those fluctuations.",
        'type': 'text',
      },
    ];

    // Map database messages
    final List<Map<String, dynamic>> realMessages = state.messages.map((m) => {
      'senderId': m['senderId'],
      'text': m['text'],
      'type': 'text',
    }).toList();

    final bool isMockSession = widget.consultationId.contains('_session');
    final List<Map<String, dynamic>> allMessages = isMockSession
        ? [...mockMessages, ...realMessages]
        : realMessages;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            reverse: true,
            itemCount: allMessages.length,
            itemBuilder: (context, index) {
              final msg = allMessages[allMessages.length - 1 - index];
              final isMe = msg['senderId'] == widget.currentUserId;
              final isFile = msg['type'] == 'file';

              if (isFile) {
                return _buildFileBubble(msg['text'] ?? 'Document.pdf', msg['fileSize'] ?? '0 KB • Document', isMe);
              }
              return _buildMessageBubble(msg['text'] ?? '', isMe);
            },
          ),
        ),
        _buildMessageInput(context),
      ],
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF004AC6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          border: isMe ? null : Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
          boxShadow: [
            if (!isMe)
              const BoxShadow(
                color: Color(0x050F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: isMe ? Colors.white : const Color(0xFF1E293B),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildFileBubble(String fileName, String fileSize, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: AppCard(
          padding: const EdgeInsets.all(14),
          borderRadius: 20,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fileSize,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 15,
            offset: Offset(0, -5),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (_messageController.text.isNotEmpty) {
                context.read<ConsultationRoomBloc>().add(SendChatMessage(_messageController.text, widget.currentUserId));
                _messageController.clear();
              }
            },
            child: Container(
              height: 46,
              width: 46,
              decoration: const BoxDecoration(
                color: Color(0xFF004AC6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallOverlay(BuildContext context, ConsultationRoomState state) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          if (state.remoteStream != null)
            RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFF004AC6))),
          
          Positioned(
            right: 20,
            top: 40,
            child: Container(
              width: 110,
              height: 165,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 2),
                boxShadow: const [BoxShadow(blurRadius: 15, color: Colors.black38)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
              ),
            ),
          ),

          // Header Overlay
          Positioned(
            left: 20,
            top: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'END-TO-END ENCRYPTED',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          _buildCallControls(context, state),
        ],
      ),
    );
  }

  Widget _buildCallControls(BuildContext context, ConsultationRoomState state) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CallControlButton(
            icon: state.isMuted ? Icons.mic_off : Icons.mic,
            onPressed: () => context.read<ConsultationRoomBloc>().add(ToggleMute()),
            color: state.isMuted ? const Color(0xFFEF4444) : Colors.white24,
          ),
          const SizedBox(width: 24),
          _CallControlButton(
            icon: Icons.call_end,
            onPressed: () => context.read<ConsultationRoomBloc>().add(EndConsultationCall()),
            color: const Color(0xFFEF4444),
            isLarge: true,
          ),
          const SizedBox(width: 24),
          _CallControlButton(
            icon: state.isCameraOn ? Icons.videocam : Icons.videocam_off,
            onPressed: () => context.read<ConsultationRoomBloc>().add(ToggleCamera()),
            color: state.isCameraOn ? Colors.white24 : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingCallOverlay(BuildContext context, ConsultationRoomState state) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 54,
              backgroundColor: Color(0xFFE8F0FF),
              child: Icon(Icons.person, size: 54, color: Color(0xFF004AC6)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Incoming Video Call',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.otherUserName,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 64),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => context.read<ConsultationRoomBloc>().add(RejectCall()),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.read<ConsultationRoomBloc>().add(AcceptCall()),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final bool isLarge;

  const _CallControlButton({required this.icon, required this.onPressed, required this.color, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: isLarge ? 64 : 52,
        width: isLarge ? 64 : 52,
        decoration: BoxDecoration(
          color: color, 
          shape: BoxShape.circle,
          boxShadow: [
            if (isLarge)
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
          ],
        ),
        child: Icon(icon, color: Colors.white, size: isLarge ? 30 : 22),
      ),
    );
  }
}
