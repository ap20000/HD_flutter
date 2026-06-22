import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/constants.dart';
import '../../../../injection_container.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../bloc/patient_dashboard_bloc.dart';
import '../bloc/patient_dashboard_event.dart';

class ChatMessage {
  final String sender; // 'user' or 'bot'
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'] ?? 'bot',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class ParsedDoctor {
  final String name;
  final String specialty;
  final String experience;
  final bool isOnline;
  final String doctorId;

  ParsedDoctor({
    required this.name,
    required this.specialty,
    required this.experience,
    required this.isOnline,
    required this.doctorId,
  });
}

class ThirdPoleAIChatPage extends StatefulWidget {
  final User user;

  const ThirdPoleAIChatPage({super.key, required this.user});

  @override
  State<ThirdPoleAIChatPage> createState() => _ThirdPoleAIChatPageState();
}

class _ThirdPoleAIChatPageState extends State<ThirdPoleAIChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingHistory = true;
  bool _isChatLoading = false;
  bool _showSpecialtyChips = false;

  final List<String> _specialties = [
    'Cardiologist',
    'Dermatologist',
    'Neurologist',
    'Dentist',
    'Pediatrician',
    'Orthopedic',
    'Gynecologist',
    'General Physician'
  ];

  @override
  void initState() {
    super.initState();
    _fetchChatHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchChatHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });
    try {
      final response = await sl<Dio>().get(ApiConstants.chatbotHistory);
      if (response.data['success'] == true) {
        final List historyList = response.data['messages'] ?? [];
        setState(() {
          _messages.clear();
          _messages.addAll(historyList.map((m) => ChatMessage.fromJson(m)));
        });
      }
    } catch (e) {
      debugPrint('Error fetching chatbot history: $e');
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isChatLoading) return;

    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(ChatMessage(
        sender: 'user',
        text: text,
        timestamp: DateTime.now(),
      ));
      _isChatLoading = true;
      _showSpecialtyChips = false;
    });
    _inputController.clear();
    _scrollToBottom();

    // Check special local commands
    if (text == '/doctors') {
      setState(() {
        _messages.add(ChatMessage(
          sender: 'bot',
          text: '🩺 Choose a specialty below to find available doctors:',
          timestamp: DateTime.now(),
        ));
        _showSpecialtyChips = true;
        _isChatLoading = false;
      });
      _scrollToBottom();
      return;
    } else if (text == '/symptoms') {
      setState(() {
        _messages.add(ChatMessage(
          sender: 'bot',
          text:
              'Please describe your symptoms directly (e.g. \'fever and cough\', \'nerve pain\', \'skin rash\'). I will suggest the correct specialist field immediately.',
          timestamp: DateTime.now(),
        ));
        _isChatLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      final response = await sl<Dio>().post(
        ApiConstants.chatbotChat,
        data: {'message': text},
      );

      if (response.data['success'] == true) {
        final List serverMessages = response.data['messages'] ?? [];
        setState(() {
          _messages.clear();
          _messages.addAll(serverMessages.map((m) => ChatMessage.fromJson(m)));
        });
      } else {
        final reply = response.data['reply'] ?? 'Sorry, I encountered an error.';
        setState(() {
          _messages.add(ChatMessage(
            sender: 'bot',
            text: reply,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      debugPrint('Chatbot API request failed: $e');
      setState(() {
        _messages.add(ChatMessage(
          sender: 'bot',
          text:
              'Unable to connect to the assistant server. Please check your network and try again.',
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isChatLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _fetchDoctorsAndSave(String specialty) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _messages.add(ChatMessage(
        sender: 'user',
        text: '🔍 Find Doctors in $specialty',
        timestamp: DateTime.now(),
      ));
      _isChatLoading = true;
      _showSpecialtyChips = false;
    });
    _scrollToBottom();

    try {
      final response = await sl<Dio>().get(
        '${ApiConstants.getDoctors}?speciality=$specialty',
      );

      String botReplyText = '';
      if (response.data['success'] == true) {
        final List doctors = response.data['doctors'] ?? [];
        if (doctors.isEmpty) {
          botReplyText =
              'I couldn\'t find any matching ${specialty}s currently available on the platform.';
        } else {
          botReplyText =
              'Here are the matching specialists I found on the platform:\n\n';
          for (final doc in doctors) {
            final docDetails = doc['doctorDetails'] ?? {};
            final experience = docDetails['experience'] ?? 0;
            final isOnline = docDetails['isOnline'] == true;
            final docId = doc['_id'] ?? '';

            botReplyText += '- **Dr. ${doc['name']}** ($specialty)\n';
            botReplyText += '  Experience: $experience years\n';
            botReplyText += '  Status: ${isOnline ? '🟢 Online' : '⚪ Offline'}\n';
            botReplyText += '  Doctor ID for booking: `$docId`\n\n';
          }
          botReplyText +=
              'To book a digital consultation, you can click the **Consult Now** button on their card or say: *"Request a consultation with Dr. <Doctor ID>"*.';
        }
      } else {
        botReplyText =
            'Error fetching doctors: ${response.data['error'] ?? 'Unknown error'}';
      }

      // Save to backend chatbot session history
      final saveResponse = await sl<Dio>().post(
        ApiConstants.chatbotSave,
        data: {
          'userMessage': '🔍 Find Doctors in $specialty',
          'botReply': botReplyText,
        },
      );

      if (saveResponse.data['success'] == true) {
        final List serverMessages = saveResponse.data['messages'] ?? [];
        setState(() {
          _messages.clear();
          _messages.addAll(serverMessages.map((m) => ChatMessage.fromJson(m)));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            sender: 'bot',
            text: botReplyText,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      debugPrint('Error fetching doctors directly: $e');
      setState(() {
        _messages.add(ChatMessage(
          sender: 'bot',
          text:
              'Error connecting to the server. Please check your network and try again.',
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isChatLoading = false;
      });
      _scrollToBottom();
    }
  }

  List<ParsedDoctor> _parseDoctorsFromText(String text) {
    final List<ParsedDoctor> list = [];
    if (!text.contains("Doctor ID for booking:")) return list;

    final parts = text.split("- **Dr. ");
    if (parts.length <= 1) return list;

    for (var i = 1; i < parts.length; i++) {
      try {
        final block = parts[i];
        final lines = block.split('\n');
        if (lines.isEmpty) continue;

        final nameAndSpec = lines[0];
        final name = nameAndSpec.split('**').first.trim();

        String specialty = 'Specialist';
        if (nameAndSpec.contains('(')) {
          specialty = nameAndSpec.split('(').last.replaceAll(')', '').trim();
        }

        String experience = 'N/A';
        for (final line in lines) {
          if (line.contains('Experience:')) {
            experience = line.replaceFirst('Experience:', '').trim();
            break;
          }
        }

        bool isOnline = false;
        for (final line in lines) {
          if (line.contains('Status:')) {
            isOnline =
                line.contains('🟢') || line.toLowerCase().contains('online');
            break;
          }
        }

        String doctorId = '';
        for (final line in lines) {
          if (line.contains('Doctor ID for booking:')) {
            final idPart = line.split('`');
            if (idPart.length >= 3) {
              doctorId = idPart[1].trim();
            } else {
              final match = RegExp(r'`([^`]+)`').firstMatch(line);
              if (match != null) {
                doctorId = match.group(1)!.trim();
              }
            }
            break;
          }
        }

        if (name.isNotEmpty && doctorId.isNotEmpty) {
          list.add(ParsedDoctor(
            name: name,
            specialty: specialty,
            experience: experience,
            isOnline: isOnline,
            doctorId: doctorId,
          ));
        }
      } catch (e) {
        debugPrint('Error parsing doctor block: $e');
      }
    }
    return list;
  }

  String _getCleanIntroText(String text) {
    if (!text.contains("Doctor ID for booking:")) return text;
    final index = text.indexOf("- **Dr. ");
    if (index != -1) {
      return text.substring(0, index).trim();
    }
    return text;
  }

  List<TextSpan> _parseMarkdownToSpans(
    String text,
    TextStyle defaultStyle,
    TextStyle boldStyle,
    TextStyle italicStyle,
  ) {
    final List<TextSpan> spans = [];
    final regExp = RegExp(r'\*\*(.*?)\*\*|\*(.*?)\*');
    int start = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: defaultStyle,
        ));
      }

      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: boldStyle,
        ));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: italicStyle,
        ));
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: defaultStyle,
      ));
    }

    return spans;
  }

  Widget _buildFormattedText(String text, bool isUser, bool isDark) {
    final defaultStyle = TextStyle(
      fontSize: 14,
      fontFamily: AppTypography.fontFamily,
      height: 1.4,
      color: isUser
          ? Colors.white
          : (isDark ? AppColors.textOnDarkSecondary : AppColors.textPrimary),
    );
    final boldStyle = defaultStyle.copyWith(
      fontWeight: FontWeight.bold,
      color: isUser
          ? Colors.white
          : (isDark ? AppColors.darkPrimary : AppColors.primary),
    );
    final italicStyle = defaultStyle.copyWith(
      fontStyle: FontStyle.italic,
    );

    final lines = text.split('\n');
    final List<Widget> children = [];

    for (final line in lines) {
      bool isHeader = false;
      String cleanLine = line;

      if (line.startsWith('### ') || line.startsWith('## ') || line.startsWith('# ')) {
        isHeader = true;
        cleanLine = line.replaceFirst(RegExp(r'^#{1,3}\s+'), '');
      }

      final spans = _parseMarkdownToSpans(
        cleanLine,
        isHeader
            ? boldStyle.copyWith(
                fontSize: 15,
                color: isUser ? Colors.white : AppColors.primary,
              )
            : defaultStyle,
        boldStyle,
        italicStyle,
      );

      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: RichText(
            text: TextSpan(children: spans),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.background;
    final textCol = isDark ? Colors.white : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Third Pole AI',
          style: TextStyle(
            color: textCol,
            fontWeight: FontWeight.bold,
            fontFamily: AppTypography.fontFamily,
            fontSize: 18,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Support Online Status Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface.withOpacity(0.5)
                  : AppColors.primary.withOpacity(0.04),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.dividerDark : AppColors.divider,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Receptionist',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.bmiHealthy,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Always Online',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.bmiHealthy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Message Stream / History
          Expanded(
            child: _isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _messages.isEmpty
                    ? _buildWelcomeCard(isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isChatLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isChatLoading) {
                            return _buildTypingIndicatorBubble(isDark);
                          }

                          final msg = _messages[index];
                          final isUser = msg.sender == 'user';

                          // Parse recommended doctors
                          final doctors = _parseDoctorsFromText(msg.text);
                          final cleanText = _getCleanIntroText(msg.text);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: isUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: isUser
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isUser) ...[
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.primarySoft,
                                        child: const Icon(
                                          Icons.smart_toy,
                                          color: AppColors.primary,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isUser
                                              ? AppColors.primary
                                              : (isDark
                                                  ? AppColors.darkSurface
                                                  : Colors.white),
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(16),
                                            topRight: const Radius.circular(16),
                                            bottomLeft: Radius.circular(
                                                isUser ? 16 : 0),
                                            bottomRight: Radius.circular(
                                                isUser ? 0 : 16),
                                          ),
                                          border: isUser
                                              ? null
                                              : Border.all(
                                                  color: isDark
                                                      ? Colors.white
                                                          .withOpacity(0.08)
                                                      : AppColors.divider,
                                                ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                  isDark ? 0.2 : 0.02),
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: _buildFormattedText(
                                            cleanText, isUser, isDark),
                                      ),
                                    ),
                                  ],
                                ),
                                if (doctors.isNotEmpty)
                                  Container(
                                    height: 145,
                                    margin: const EdgeInsets.only(
                                      left: 36,
                                      top: 8,
                                    ),
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: doctors.length,
                                      itemBuilder: (context, docIdx) {
                                        final doc = doctors[docIdx];
                                        return ParsedDoctorCard(
                                          doctor: doc,
                                          isDark: isDark,
                                          onConsultTap: () {
                                            context
                                                .read<PatientDashboardBloc>()
                                                .add(RequestConsultation(
                                                    doc.doctorId));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Starting consultation request with Dr. ${doc.name}...',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: 4,
                                    left: isUser ? 0 : 40,
                                    right: isUser ? 4 : 0,
                                  ),
                                  child: Text(
                                    _formatTime(msg.timestamp),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.grey.shade400,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Specialist Chips (Visible when '/doctors' command is local state)
          if (_showSpecialtyChips)
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surfacePearl,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.dividerDark : AppColors.divider,
                  ),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _specialties.length,
                itemBuilder: (context, idx) {
                  final spec = _specialties[idx];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      onPressed: () => _fetchDoctorsAndSave(spec),
                      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
                      label: Text(
                        spec,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  );
                },
              ),
            ),

          // Quick Action Suggestion Chips Row
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.dividerDark : AppColors.divider,
                ),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildQuickActionChip('🩺 Find Doctor', '/doctors', isDark),
                _buildQuickActionChip(
                    '🧠 Describe Symptoms', '/symptoms', isDark),
                _buildQuickActionChip('🏥 Hospitals', '/hospitals', isDark),
                _buildQuickActionChip(
                    '💬 My Consultations', '/my_consultations', isDark),
              ],
            ),
          ),

          // Input Text Box Area
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: 24, // extra padding for bottom safe area
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.surfacePearl,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? AppColors.dividerDark
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            textInputAction: TextInputAction.send,
                            onSubmitted: _sendMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: textCol,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type your health question...',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade400,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _sendMessage(_inputController.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(
      String label, String command, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => _sendMessage(command),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.surfacePearl,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.dividerDark : Colors.grey.shade100,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(bool isDark) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final textCol = isDark ? Colors.white : AppColors.textPrimary;
    final subTextCol = isDark ? Colors.white70 : AppColors.textSecondary;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : AppColors.divider,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Hi ${widget.user.name.split(' ').first}, 👋',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textCol,
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'I am your AI Receptionist. I can recommend specialists, find doctors, answer general health education queries, or help request a digital consultation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: subTextCol,
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Try asking: "Who is the best cardiologist?" or click one of the quick actions below to get started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicatorBubble(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primarySoft,
            child: const Icon(
              Icons.smart_toy,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : AppColors.divider,
              ),
            ),
            child: const TypingIndicator(),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class ParsedDoctorCard extends StatelessWidget {
  final ParsedDoctor doctor;
  final bool isDark;
  final VoidCallback onConsultTap;

  const ParsedDoctorCard({
    super.key,
    required this.doctor,
    required this.isDark,
    required this.onConsultTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final textCol = isDark ? Colors.white : AppColors.textPrimary;
    final subTextCol = isDark ? Colors.white70 : AppColors.textSecondary;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${doctor.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: textCol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      doctor.specialty,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exp: ${doctor.experience}',
                style: TextStyle(fontSize: 9, color: subTextCol),
              ),
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: doctor.isOnline ? AppColors.bmiHealthy : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    doctor.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: doctor.isOnline ? AppColors.bmiHealthy : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: onConsultTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
                elevation: 0,
              ),
              child: const Text(
                'Consult Now',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = isDark ? Colors.white54 : Colors.grey.shade400;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double delay = index * 0.2;
            double position = _controller.value - delay;
            if (position < 0) position += 1.0;
            final double value = math.sin(position * math.pi * 2);
            final double offset = -4.0 * (value > 0 ? value : 0);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              transform: Matrix4.translationValues(0.0, offset, 0.0),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
