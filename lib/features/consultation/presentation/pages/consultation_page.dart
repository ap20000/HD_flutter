import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../injection_container.dart';
import '../bloc/consultation_bloc.dart';
import '../bloc/consultation_event.dart';
import '../bloc/consultation_state.dart';
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

class ConsultationPage extends StatefulWidget {
  final String consultationId;
  final String currentUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final bool isDoctor;
  final Map<String, dynamic>? initialPrescription;

  const ConsultationPage({
    super.key,
    required this.consultationId,
    required this.currentUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.isDoctor = false,
    this.initialPrescription,
  });

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final TextEditingController _messageController = TextEditingController();
  Offset _localVideoOffset = const Offset(220, 80);

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString();
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _initRenderers() async {
    try {
      print('ConsultationPage: Initializing video renderers...');
      await Future.wait([
        _localRenderer.initialize(),
        _remoteRenderer.initialize(),
      ]);
      _localRenderer.muted = true; // Mute local camera mic feedback
      _remoteRenderer.muted = false; // Ensure remote renderer plays audio
      print('ConsultationPage: Video renderers initialized.');
    } catch (e) {
      print('ConsultationPage: Error during video renderer init: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hardware initialization issue: $e')),
        );
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) =>
          sl<ConsultationBloc>()..add(JoinConsultation(widget.consultationId)),
      child: BlocConsumer<ConsultationBloc, ConsultationState>(
        listener: (context, state) {
          if (state.localStream != null) {
            _localRenderer.srcObject = state.localStream;
          } else {
            _localRenderer.srcObject = null;
          }
          
          if (state.remoteStream != null) {
            _remoteRenderer.srcObject = state.remoteStream;
          } else {
            _remoteRenderer.srcObject = null;
          }

          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return PopScope(
            onPopInvokedWithResult: (didPop, result) {
              if (didPop && state.isCallActive) {
                context.read<ConsultationBloc>().add(EndConsultationCall());
              }
            },
            child: Scaffold(
              resizeToAvoidBottomInset: !state.isCallActive,
              backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
              appBar: _buildAppBar(context, state),
              body: Stack(
                children: [
                  _buildAmbientBackground(isDark),
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

  Widget _buildAmbientBackground(bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(isDark ? 0.05 : 0.03),
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ConsultationState state,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : AppColors.textPrimary,
          size: 20,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE8F0FF),
                backgroundImage: _getAvatarBytes(widget.otherUserAvatar) != null
                    ? MemoryImage(_getAvatarBytes(widget.otherUserAvatar)!)
                    : null,
                child: _getAvatarBytes(widget.otherUserAvatar) == null
                    ? Icon(
                        Icons.person,
                        size: 20,
                        color: isDark ? AppColors.darkPrimary : const Color(0xFF004AC6),
                      )
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
                    border: Border.all(
                      color: isDark ? AppColors.darkSurface : Colors.white, 
                      width: 2,
                    ),
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
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  state.isCallActive 
                      ? (state.callDuration > 0 ? _formatDuration(state.callDuration) : 'In Call') 
                      : 'Active Session',
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
        if (widget.isDoctor || widget.initialPrescription != null)
          _AnimatedInteractiveButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PrescriptionPage(
                    patientName: widget.isDoctor
                        ? widget.otherUserName
                        : 'Samyog',
                    isDoctor: widget.isDoctor,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: isDark ? AppColors.darkPrimary : const Color(0xFF004AC6),
                size: 20,
              ),
            ),
          ),
        _AnimatedInteractiveButton(
          onTap: () {
            context.read<ConsultationBloc>().add(
              const StartCall(isVideo: false),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.call_outlined,
              color: isDark ? AppColors.darkPrimary : const Color(0xFF004AC6),
              size: 20,
            ),
          ),
        ),
        _AnimatedInteractiveButton(
          onTap: () {
            context.read<ConsultationBloc>().add(
              const StartCall(isVideo: true),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.videocam_outlined,
              color: isDark ? AppColors.darkPrimary : const Color(0xFF004AC6),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildChatView(BuildContext context, ConsultationState state) {
    final List<Map<String, dynamic>> mockMessages = [
      {
        'senderId': 'doctor',
        'text':
            "Good morning. I've reviewed your previous logs. How have you been feeling since we adjusted your medication last week?",
        'type': 'text',
      },
      {
        'senderId': widget.currentUserId,
        'text':
            "I'm feeling much better, but I did notice a slight palpitation yesterday evening while resting.",
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
        'text':
            "Understood. That's a helpful detail. Based on the report you shared, I'll update your prescription to better manage those fluctuations.",
        'type': 'text',
      },
    ];

    final List<Map<String, dynamic>> realMessages = state.messages
        .map(
          (m) => {'senderId': m['senderId'], 'text': m['text'], 'type': 'text'},
        )
        .toList();

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

              Widget bubbleWidget;
              if (isFile) {
                bubbleWidget = _buildFileBubble(
                  msg['text'] ?? 'Document.pdf',
                  msg['fileSize'] ?? '0 KB • Document',
                  isMe,
                );
              } else {
                bubbleWidget = _buildMessageBubble(msg['text'] ?? '', isMe);
              }

              return _AnimatedChatBubble(
                isMe: isMe,
                child: bubbleWidget,
              );
            },
          ),
        ),
        _buildMessageInput(context),
      ],
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final meColor = isDark ? AppColors.darkPrimary : const Color(0xFF004AC6);
    final otherColor = isDark ? AppColors.darkSurface : Colors.white;
    final otherTextColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 15,
              backgroundColor: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE8F0FF),
              backgroundImage: _getAvatarBytes(widget.otherUserAvatar) != null
                  ? MemoryImage(_getAvatarBytes(widget.otherUserAvatar)!)
                  : null,
              child: _getAvatarBytes(widget.otherUserAvatar) == null
                  ? Icon(
                      Icons.person,
                      size: 14,
                      color: isDark ? AppColors.darkPrimary : const Color(0xFF004AC6),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: isMe ? meColor : otherColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              border: isMe
                  ? null
                  : Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEEF2F6), 
                      width: 1.5,
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: isMe ? Colors.white : otherTextColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileBubble(String fileName, String fileSize, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otherColor = isDark ? AppColors.darkSurface : Colors.white;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 15,
              backgroundColor: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE8F0FF),
              backgroundImage: _getAvatarBytes(widget.otherUserAvatar) != null
                  ? MemoryImage(_getAvatarBytes(widget.otherUserAvatar)!)
                  : null,
              child: _getAvatarBytes(widget.otherUserAvatar) == null
                  ? Icon(
                      Icons.person,
                      size: 14,
                      color: isDark ? AppColors.darkPrimary : const Color(0xFF004AC6),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 20,
              color: isMe 
                  ? (isDark ? AppColors.darkPrimary.withOpacity(0.2) : const Color(0xFF004AC6).withOpacity(0.1)) 
                  : otherColor,
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEEF2F6), 
                width: 1.5,
              ),
              onTap: () {
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening $fileName...'), behavior: SnackBarBehavior.floating),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEEF2F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Color(0xFFEF4444),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
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
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          _AnimatedInteractiveButton(
            scaleFactor: 0.85,
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attachments coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEEF2F6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.add_rounded,
                color: isDark ? AppColors.darkPrimary : const Color(0xFF004AC6),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEEF2F6), 
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: AppTypography.fontFamily,
                ),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8), 
                    fontSize: 14,
                    fontFamily: AppTypography.fontFamily,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _AnimatedInteractiveButton(
            scaleFactor: 0.85,
            onTap: () {
              if (_messageController.text.isNotEmpty) {
                context.read<ConsultationBloc>().add(
                  SendChatMessage(
                    _messageController.text,
                    widget.currentUserId,
                  ),
                );
                _messageController.clear();
              }
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPrimary : const Color(0xFF004AC6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppColors.darkPrimary : const Color(0xFF004AC6)).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallOverlay(BuildContext context, ConsultationState state) {
    if (!state.isVideoCall) {
      return _buildAudioCallOverlay(context, state);
    }
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          if (state.remoteStream != null)
            RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF004AC6)),
            ),

          Positioned(
            left: _localVideoOffset.dx,
            top: _localVideoOffset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;
                  double newX = _localVideoOffset.dx + details.delta.dx;
                  double newY = _localVideoOffset.dy + details.delta.dy;
                  
                  // Constrain position inside screen bounds with margins
                  newX = newX.clamp(10.0, screenWidth - 120.0);
                  newY = newY.clamp(30.0, screenHeight - 220.0);
                  
                  _localVideoOffset = Offset(newX, newY);
                });
              },
              child: Container(
                width: 110,
                height: 165,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 2),
                  boxShadow: const [
                    BoxShadow(blurRadius: 15, color: Colors.black38),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
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
                if (state.callDuration > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(state.callDuration),
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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

  Widget _buildAudioCallOverlay(BuildContext context, ConsultationState state) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          _PulsingCallAvatar(
            child: CircleAvatar(
              radius: 54,
              backgroundColor: const Color(0xFFE8F0FF),
              backgroundImage: _getAvatarBytes(widget.otherUserAvatar) != null
                  ? MemoryImage(_getAvatarBytes(widget.otherUserAvatar)!)
                  : null,
              child: _getAvatarBytes(widget.otherUserAvatar) == null
                  ? const Icon(Icons.person, size: 54, color: Color(0xFF004AC6))
                  : null,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            widget.otherUserName,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.remoteStream != null 
                ? (state.callDuration > 0 ? _formatDuration(state.callDuration) : 'Connected')
                : 'Calling...',
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CallControlButton(
                icon: state.isMuted ? Icons.mic_off : Icons.mic,
                onPressed: () =>
                    context.read<ConsultationBloc>().add(ToggleMute()),
                color: state.isMuted ? const Color(0xFFEF4444) : Colors.white24,
              ),
              const SizedBox(width: 32),
              _CallControlButton(
                icon: Icons.call_end,
                onPressed: () =>
                    context.read<ConsultationBloc>().add(EndConsultationCall()),
                color: const Color(0xFFEF4444),
                isLarge: true,
              ),
            ],
          ),
          const SizedBox(height: 64),
          if (state.remoteStream != null)
            SizedBox(
              width: 1,
              height: 1,
              child: Opacity(
                opacity: 0.01,
                child: RTCVideoView(
                  _remoteRenderer,
                  mirror: false,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCallControls(BuildContext context, ConsultationState state) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallControlButton(
                  icon: state.isMuted ? Icons.mic_off : Icons.mic,
                  onPressed: () =>
                      context.read<ConsultationBloc>().add(ToggleMute()),
                  color: state.isMuted ? const Color(0xFFEF4444) : Colors.white24,
                ),
                _CallControlButton(
                  icon: Icons.call_end,
                  onPressed: () =>
                      context.read<ConsultationBloc>().add(EndConsultationCall()),
                  color: const Color(0xFFEF4444),
                  isLarge: true,
                ),
                _CallControlButton(
                  icon: state.isCameraOn ? Icons.videocam : Icons.videocam_off,
                  onPressed: () =>
                      context.read<ConsultationBloc>().add(ToggleCamera()),
                  color: state.isCameraOn ? Colors.white24 : const Color(0xFFEF4444),
                ),
                _CallControlButton(
                  icon: Icons.flip_camera_ios_outlined,
                  onPressed: () =>
                      context.read<ConsultationBloc>().add(SwitchCamera()),
                  color: Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingCallOverlay(
    BuildContext context,
    ConsultationState state,
  ) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PulsingCallAvatar(
              child: CircleAvatar(
                radius: 54,
                backgroundColor: const Color(0xFFE8F0FF),
                backgroundImage: _getAvatarBytes(widget.otherUserAvatar) != null
                    ? MemoryImage(_getAvatarBytes(widget.otherUserAvatar)!)
                    : null,
                child: _getAvatarBytes(widget.otherUserAvatar) == null
                    ? const Icon(Icons.person, size: 54, color: Color(0xFF004AC6))
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              state.isVideoCall ? 'Incoming Video Call' : 'Incoming Audio Call',
              style: const TextStyle(
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
                _AnimatedInteractiveButton(
                  scaleFactor: 0.85,
                  onTap: () {
                    context.read<ConsultationBloc>().add(RejectCall());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                _AnimatedInteractiveButton(
                  scaleFactor: 0.85,
                  onTap: () {
                    context.read<ConsultationBloc>().add(AcceptCall());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call,
                      color: Colors.white,
                      size: 28,
                    ),
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

  const _CallControlButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimatedInteractiveButton(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 18 : 12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isLarge ? 28 : 22,
        ),
      ),
    );
  }
}

// ── Staggered Chat Bubble Entry Animation ─────────────────────────────────────

class _AnimatedChatBubble extends StatefulWidget {
  final Widget child;
  final bool isMe;

  const _AnimatedChatBubble({required this.child, required this.isMe});

  @override
  State<_AnimatedChatBubble> createState() => _AnimatedChatBubbleState();
}

class _AnimatedChatBubbleState extends State<_AnimatedChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isMe ? 0.15 : -0.15, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

// ── Interactive Spring Button Interaction ────────────────────────────────────

class _AnimatedInteractiveButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;

  const _AnimatedInteractiveButton({
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.92,
  });

  @override
  State<_AnimatedInteractiveButton> createState() => _AnimatedInteractiveButtonState();
}

class _AnimatedInteractiveButtonState extends State<_AnimatedInteractiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

// ── Pulsing Halo Call Waves Animation ────────────────────────────────────────

class _PulsingCallAvatar extends StatefulWidget {
  final Widget child;
  const _PulsingCallAvatar({required this.child});

  @override
  State<_PulsingCallAvatar> createState() => _PulsingCallAvatarState();
}

class _PulsingCallAvatarState extends State<_PulsingCallAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _ripple1;
  late Animation<double> _ripple2;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _ripple1 = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _ripple2 = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.06), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.06, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: (1.0 - (_controller.value - 0.3) / 0.7).clamp(0.0, 1.0) * 0.12,
              child: Transform.scale(
                scale: _ripple2.value,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF004AC6),
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: (1.0 - _controller.value / 0.7).clamp(0.0, 1.0) * 0.20,
              child: Transform.scale(
                scale: _ripple1.value,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF004AC6),
                  ),
                ),
              ),
            ),
            ScaleTransition(
              scale: _scale,
              child: widget.child,
            ),
          ],
        );
      },
    );
  }
}
