import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hamro_doctor_mobile/core/theme/app_colors.dart';
import 'package:hamro_doctor_mobile/core/constants/constants.dart';
import '../../domain/entities/story.dart';

class StoryViewerPage extends StatefulWidget {
  final List<GroupedStories> groupedStoriesList;
  final int initialAuthorIndex;
  final Function(String doctorId)? onConsultNow;

  const StoryViewerPage({
    super.key,
    required this.groupedStoriesList,
    required this.initialAuthorIndex,
    this.onConsultNow,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with SingleTickerProviderStateMixin {
  late int _currentAuthorIndex;
  late int _currentStoryIndex;
  late AnimationController _animationController;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentAuthorIndex = widget.initialAuthorIndex;
    _currentStoryIndex = 0;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _nextStory();
          }
        });
      }
    });

    _startAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  void _nextStory() {
    final currentAuthorStories =
        widget.groupedStoriesList[_currentAuthorIndex].stories;
    if (_currentStoryIndex < currentAuthorStories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _startAnimation();
    } else {
      if (_currentAuthorIndex < widget.groupedStoriesList.length - 1) {
        setState(() {
          _currentAuthorIndex++;
          _currentStoryIndex = 0;
        });
        _startAnimation();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _prevStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _startAnimation();
    } else {
      if (_currentAuthorIndex > 0) {
        setState(() {
          _currentAuthorIndex--;
          _currentStoryIndex =
              widget.groupedStoriesList[_currentAuthorIndex].stories.length - 1;
        });
        _startAnimation();
      } else {
        _startAnimation(); // Restart current first story
      }
    }
  }

  void _pause() {
    if (!_isPaused) {
      _animationController.stop();
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _resume() {
    if (_isPaused) {
      _animationController.forward();
      setState(() {
        _isPaused = false;
      });
    }
  }

  Widget _buildStoryMedia(String? imageStr) {
    if (imageStr == null || imageStr.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }

    if (imageStr.startsWith('data:image')) {
      try {
        final base64Content = imageStr.split(',').last;
        final bytes = base64.decode(base64Content);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (e) {
        debugPrint('Error decoding base64 story image: $e');
      }
    }

    final url = imageStr.startsWith('http')
        ? imageStr
        : '${ApiConstants.baseUrl}$imageStr';

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[900],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white24, size: 64),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedAuthor = widget.groupedStoriesList[_currentAuthorIndex];
    final activeStory = groupedAuthor.stories[_currentStoryIndex];
    final screenWidth = MediaQuery.of(context).size.width;

    final avatarUrl = groupedAuthor.authorAvatar;
    final isAvatarNetwork = avatarUrl != null && avatarUrl.startsWith('http');
    final absoluteAvatarUrl = isAvatarNetwork
        ? avatarUrl
        : (avatarUrl != null ? '${ApiConstants.baseUrl}$avatarUrl' : null);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Dismissible(
          key: const Key('story-viewer-dismiss'),
          direction: DismissDirection.vertical,
          onDismissed: (_) {
            Navigator.of(context).pop();
          },
          child: GestureDetector(
            onLongPressDown: (_) => _pause(),
            onLongPressUp: () => _resume(),
            onLongPressCancel: () => _resume(),
            onTapDown: (details) {
              final tapPositionX = details.globalPosition.dx;
              if (tapPositionX < screenWidth / 3) {
                _prevStory();
              } else {
                _nextStory();
              }
            },
            child: Stack(
              children: [
                // Story Media Background
                Positioned.fill(
                  child: _buildStoryMedia(activeStory.image),
                ),

                // Bottom Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 250,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),

                // Top Gradient overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Header Overlay & Progress Indicators
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      // Segmented Progress Bars
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, _) {
                          return Row(
                            children: List.generate(
                              groupedAuthor.stories.length,
                              (index) {
                                double progress = 0.0;
                                if (index < _currentStoryIndex) {
                                  progress = 1.0;
                                } else if (index == _currentStoryIndex) {
                                  progress = _animationController.value;
                                }
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor:
                                            Colors.white.withOpacity(0.3),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                        minHeight: 3,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Author Info Header
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: ClipOval(
                              child: absoluteAvatarUrl != null
                                  ? Image.network(
                                      absoluteAvatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: AppColors.primary,
                                        child: Center(
                                          child: Text(
                                            groupedAuthor.authorName[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.primary,
                                      child: Center(
                                        child: Text(
                                          groupedAuthor.authorName[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  groupedAuthor.authorName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (groupedAuthor.authorSpecialty != null)
                                  Text(
                                    groupedAuthor.authorSpecialty!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom Content Overlay
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activeStory.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        activeStory.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activeStory.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CTA booking button
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                if (widget.onConsultNow != null) {
                                  widget.onConsultNow!(activeStory.authorId);
                                }
                              },
                              child: const Text(
                                'Consult Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
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
        ),
      ),
    );
  }
}
