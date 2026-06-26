import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../injection_container.dart';
import '../../../../core/constants/constants.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../domain/entities/story.dart';
import '../../domain/entities/dashboard_data.dart';
import 'story_viewer_page.dart';

class PostsPage extends StatefulWidget {
  final User user;

  const PostsPage({super.key, required this.user});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Posts & Community',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white60 : AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Articles'),
            Tab(text: 'Stories'),
            Tab(text: 'Discussion'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ArticlesTab(user: widget.user),
          _StoriesTab(user: widget.user),
          _DiscussionTab(user: widget.user),
        ],
      ),
    );
  }
}

// ── 1. ARTICLES TAB ──────────────────────────────────────────────────────────

class _ArticlesTab extends StatefulWidget {
  final User user;
  const _ArticlesTab({required this.user});

  @override
  State<_ArticlesTab> createState() => _ArticlesTabState();
}

class _ArticlesTabState extends State<_ArticlesTab> {
  List<dynamic> _articles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await sl<Dio>().get('${ApiConstants.baseUrl}${ApiConstants.getArticles}');
      if (response.data != null && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _articles = response.data['articles'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Failed to load articles';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error fetching articles: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchArticles,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_articles.isEmpty) {
      return Center(
        child: Text(
          'No articles published yet.',
          style: TextStyle(color: isDark ? Colors.white60 : AppColors.textTertiary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchArticles,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          final authorName = article['author']?['name'] ?? 'Admin';
          final thumbnail = article['featureImage'];
          final dateStr = article['createdAt'] != null
              ? DateTime.parse(article['createdAt']).toLocal().toString().split(' ')[0]
              : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              border: Border.all(color: isDark ? AppColors.dividerDark : const Color(0xFFEEF2F6), width: 1.5),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleDetailPage(article: article),
                  ),
                );
              },
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: _buildArticleImage(thumbnail),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (article['category'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              article['category'].toString().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          article['title'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'By $authorName',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : AppColors.textTertiary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : AppColors.textTertiary,
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
          );
        },
      ),
    );
  }
}

// ── 2. STORIES TAB ───────────────────────────────────────────────────────────

class _StoriesTab extends StatefulWidget {
  final User user;
  const _StoriesTab({required this.user});

  @override
  State<_StoriesTab> createState() => _StoriesTabState();
}

class _StoriesTabState extends State<_StoriesTab> {
  List<GroupedStories> _groupedStories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await sl<Dio>().get('${ApiConstants.baseUrl}${ApiConstants.stories}');
      if (response.data != null && response.data['success'] == true) {
        final List storiesJson = response.data['stories'] ?? [];
        final stories = storiesJson.map((e) => Story.fromJson(e)).toList();

        // Group stories by author
        final Map<String, List<Story>> authorGroups = {};
        for (var story in stories) {
          authorGroups.putIfAbsent(story.authorId, () => []).add(story);
        }

        final List<GroupedStories> grouped = [];
        for (var entry in authorGroups.entries) {
          final authorStories = entry.value;
          if (authorStories.isNotEmpty) {
            final firstStory = authorStories.first;
            grouped.add(GroupedStories(
              authorId: entry.key,
              authorName: firstStory.authorName,
              authorAvatar: firstStory.authorAvatar,
              authorSpecialty: firstStory.authorSpecialty,
              stories: authorStories,
            ));
          }
        }

        if (mounted) {
          setState(() {
            _groupedStories = grouped;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching stories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return RefreshIndicator(
      onRefresh: _fetchStories,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
          childAspectRatio: 0.8,
        ),
        itemCount: _groupedStories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildYourStoryButton(isDark);
          }

          final grouped = _groupedStories[index - 1];
          final doctorLastName = grouped.authorName.split(" ").last;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryViewerPage(
                    groupedStoriesList: _groupedStories,
                    initialAuthorIndex: index - 1,
                    onConsultNow: (doctorId) {
                      // Trigger consultation request flow or print info
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Consultation request initiated with Dr. ${grouped.authorName}'),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFD946EF), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primarySoft,
                      backgroundImage: _getAvatarBytes(grouped.authorAvatar) != null
                          ? MemoryImage(_getAvatarBytes(grouped.authorAvatar)!)
                          : null,
                      child: _getAvatarBytes(grouped.authorAvatar) == null
                          ? const Icon(Icons.person, color: AppColors.primary, size: 28)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dr. $doctorLastName',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  grouped.authorSpecialty ?? 'Specialist',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white60 : AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildYourStoryButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (widget.user.role == 'patient') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              title: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Health Stories',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Only verified medical specialists can post health stories. Feel free to browse active stories from our doctors!',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story creation is coming soon on mobile.')),
          );
        }
      },
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 33,
                backgroundColor: AppColors.primarySoft,
                backgroundImage: _getAvatarBytes(widget.user.avatar) != null
                    ? MemoryImage(_getAvatarBytes(widget.user.avatar)!)
                    : null,
                child: _getAvatarBytes(widget.user.avatar) == null
                    ? const Icon(Icons.person, color: AppColors.primary, size: 28)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your Story',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── 3. DISCUSSION TAB ────────────────────────────────────────────────────────

class _DiscussionTab extends StatefulWidget {
  final User user;
  const _DiscussionTab({required this.user});

  @override
  State<_DiscussionTab> createState() => _DiscussionTabState();
}

class _DiscussionTabState extends State<_DiscussionTab> {
  List<dynamic> _questions = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _replyController = TextEditingController();
  String? _replyingToId;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await sl<Dio>().get('${ApiConstants.baseUrl}/api/v1/forum/questions');
      if (response.data != null && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _questions = response.data['questions'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Failed to load forum questions';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error loading forum: $e';
        });
      }
    }
  }

  Future<void> _postReply(String questionId) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await sl<Dio>().post(
        '${ApiConstants.baseUrl}/api/v1/forum/questions/$questionId/answer',
        data: {'content': text},
      );

      if (response.data != null && response.data['success'] == true) {
        _replyController.clear();
        setState(() {
          _replyingToId = null;
        });
        _fetchQuestions();
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit reply')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error replying: $e')),
        );
      }
    }
  }

  void _showAddQuestionDialog(BuildContext context, bool isDark) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    bool isAnonymous = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Start a Discussion',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Topic Title',
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : AppColors.textTertiary),
                      hintText: 'e.g., How to maintain a healthy sleep cycle?',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDark ? AppColors.dividerDark : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Details',
                      labelStyle: TextStyle(color: isDark ? Colors.white60 : AppColors.textTertiary),
                      hintText: 'Explain the details of your question/discussion topic...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDark ? AppColors.dividerDark : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isAnonymous,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setModalState(() {
                            isAnonymous = val ?? false;
                          });
                        },
                      ),
                      Text(
                        'Post anonymously',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final details = contentController.text.trim();
                        if (title.isEmpty || details.isEmpty) return;

                        Navigator.pop(context);
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          await sl<Dio>().post(
                            '${ApiConstants.baseUrl}/api/v1/forum/questions',
                            data: {
                              'title': title,
                              'content': details,
                              'isAnonymous': isAnonymous,
                            },
                          );
                          _fetchQuestions();
                        } catch (e) {
                          setState(() {
                            _isLoading = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error posting discussion: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Start Discussion',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchQuestions,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _fetchQuestions,
        color: AppColors.primary,
        child: _questions.isEmpty
            ? Center(
                child: Text(
                  'No discussions yet.',
                  style: TextStyle(color: isDark ? Colors.white60 : AppColors.textTertiary),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final post = _questions[index];
                  final isAnonymous = post['isAnonymous'] ?? false;
                  final authorName = isAnonymous
                      ? 'Anonymous Patient'
                      : (post['user']?['name'] ?? 'User');
                  final dateStr = post['createdAt'] != null
                      ? DateTime.parse(post['createdAt']).toLocal().toString().split(' ')[0]
                      : '';
                  final answers = post['answers'] as List? ?? [];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: AppCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(18),
                      border: Border.all(color: isDark ? AppColors.dividerDark : const Color(0xFFEEF2F6), width: 1.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Author
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFE8F0FF),
                                child: Text(
                                  isAnonymous ? 'A' : (authorName.toString().isNotEmpty ? authorName[0].toUpperCase() : 'U'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authorName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${answers.length} ${answers.length == 1 ? 'REPLY' : 'REPLIES'}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            post['title'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            post['content'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Answers list (doctor replies)
                          if (answers.isNotEmpty) ...[
                            const Divider(height: 24),
                            ...answers.map((answer) {
                              final doctorName = answer['doctor']?['name'] ?? 'Specialist';
                              final specialty = answer['doctor']?['doctorDetails']?['speciality'] ?? 'Expert Advice';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface.withOpacity(0.5) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? AppColors.dividerDark : const Color(0xFFEEF2F6)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.verified_user_rounded, color: AppColors.secondary, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          doctorName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '($specialty)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.white60 : AppColors.textTertiary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      answer['content'] ?? '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],

                          // Doctor Inline Reply Form
                          if (widget.user.role == 'doctor') ...[
                            const SizedBox(height: 12),
                            if (_replyingToId == post['_id']) ...[
                              TextField(
                                controller: _replyController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Provide your professional insight...',
                                  hintStyle: const TextStyle(fontSize: 13),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: isDark ? AppColors.dividerDark : Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: AppColors.primary),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _postReply(post['_id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Post Reply', style: TextStyle(color: Colors.white)),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _replyingToId = null;
                                        _replyController.clear();
                                      });
                                    },
                                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                  ),
                                ],
                              ),
                            ] else ...[
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _replyingToId = post['_id'];
                                    _replyController.clear();
                                  });
                                },
                                icon: const Icon(Icons.reply_rounded, size: 16, color: AppColors.primary),
                                label: const Text(
                                  'Reply to discussion',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: widget.user.role == 'patient'
          ? FloatingActionButton(
              onPressed: () => _showAddQuestionDialog(context, isDark),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ── Helper functions/classes ───────────────────────────────────────────────

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

Widget _buildArticleImage(String? imagePath, {double? width, double? height}) {
  if (imagePath == null || imagePath.isEmpty) {
    return Container(
      color: AppColors.primarySoft.withOpacity(0.5),
      child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 36),
    );
  }
  if (imagePath.startsWith('data:image')) {
    try {
      final cleaned = imagePath.split(',').last;
      final bytes = base64Decode(cleaned);
      return Image.memory(bytes, width: width, height: height, fit: BoxFit.cover);
    } catch (e) {
      return Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image));
    }
  }
  final fullUrl = imagePath.startsWith('http') ? imagePath : '${ApiConstants.baseUrl}$imagePath';
  return Image.network(
    fullUrl,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
    ),
  );
}

// ── 4. ARTICLE DETAIL PAGE ───────────────────────────────────────────────────

class ArticleDetailPage extends StatelessWidget {
  final dynamic article;
  const ArticleDetailPage({super.key, required this.article});

  String _stripHtml(String htmlString) {
    final regExp = RegExp(r'<[^>]*>|&[^;]+;', multiLine: true, caseSensitive: false);
    return htmlString.replaceAll(regExp, ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authorName = article['author']?['name'] ?? 'Admin';
    final thumbnail = article['featureImage'];
    final dateStr = article['createdAt'] != null
        ? DateTime.parse(article['createdAt']).toLocal().toString().split(' ')[0]
        : '';
    final plainContent = _stripHtml(article['content'] ?? '');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Read Article', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image header
            if (thumbnail != null)
              SizedBox(
                width: double.infinity,
                height: 220,
                child: _buildArticleImage(thumbnail),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article['category'].toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    article['title'] ?? '',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'By $authorName',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 40),
                  Text(
                    plainContent,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: isDark ? Colors.white70 : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
