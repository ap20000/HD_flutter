import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../injection_container.dart';
import '../bloc/consultation_room_bloc.dart';

class ConsultationRoomPage extends StatefulWidget {
  final String consultationId;
  final String currentUserId;
  final String otherUserName;

  const ConsultationRoomPage({
    super.key,
    required this.consultationId,
    required this.currentUserId,
    required this.otherUserName,
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
              backgroundColor: AppColors.background,
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
      backgroundColor: AppColors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const CircleAvatar(radius: 18, backgroundColor: AppColors.primarySoft, child: Icon(Icons.person, size: 20, color: AppColors.primary)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.otherUserName, style: AppTypography.titleMedium),
              Text(state.isCallActive ? 'In Video Call' : 'Online', style: AppTypography.labelMedium.copyWith(color: AppColors.secondary)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined, color: AppColors.primary),
          onPressed: () => context.read<ConsultationRoomBloc>().add(const StartCall(isVideo: false)),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: AppColors.primary),
          onPressed: () => context.read<ConsultationRoomBloc>().add(const StartCall(isVideo: true)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildChatView(BuildContext context, ConsultationRoomState state) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            reverse: true,
            itemCount: state.messages.length,
            itemBuilder: (context, index) {
              final msg = state.messages[state.messages.length - 1 - index];
              final isMe = msg['senderId'] == widget.currentUserId;
              return _MessageBubble(text: msg['text'] ?? '', isMe: isMe);
            },
          ),
        ),
        _buildMessageInput(context),
      ],
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(color: AppColors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(
        children: [
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              borderRadius: 30,
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(hintText: 'Type a message...', border: InputBorder.none),
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
            child: const CircleAvatar(radius: 24, backgroundColor: AppColors.primary, child: Icon(Icons.send, color: Colors.white, size: 20)),
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
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          
          Positioned(
            right: 20,
            top: 40,
            child: Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24, width: 2), boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black45)]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
              ),
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
            color: state.isMuted ? Colors.red : Colors.white24,
          ),
          const SizedBox(width: 20),
          _CallControlButton(
            icon: Icons.call_end,
            onPressed: () => context.read<ConsultationRoomBloc>().add(EndConsultationCall()),
            color: Colors.red,
            isLarge: true,
          ),
          const SizedBox(width: 20),
          _CallControlButton(
            icon: state.isCameraOn ? Icons.videocam : Icons.videocam_off,
            onPressed: () => context.read<ConsultationRoomBloc>().add(ToggleCamera()),
            color: state.isCameraOn ? Colors.white24 : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingCallOverlay(BuildContext context, ConsultationRoomState state) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primarySoft,
              child: Icon(Icons.person, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Incoming Video Call',
              style: AppTypography.h2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              widget.otherUserName,
              style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'decline_call',
                  onPressed: () => context.read<ConsultationRoomBloc>().add(RejectCall()),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: 'accept_call',
                  onPressed: () => context.read<ConsultationRoomBloc>().add(AcceptCall()),
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.videocam, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  const _MessageBubble({required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [if (!isMe) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Text(text, style: AppTypography.bodyMedium.copyWith(color: isMe ? Colors.white : AppColors.textPrimary)),
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
        height: isLarge ? 64 : 50,
        width: isLarge ? 64 : 50,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: isLarge ? 30 : 24),
      ),
    );
  }
}
