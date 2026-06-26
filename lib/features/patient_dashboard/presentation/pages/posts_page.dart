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
import '../../domain/entities/dashboard_data.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
            Tab(text: 'Discussion'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ArticlesTab(user: widget.user),
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
                    builder: (context) => ArticleDetailPage(article: article, user: widget.user),
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


// ── 3. DISCUSSION TAB ────────────────────────────────────────────────────────

class _DiscussionTab extends StatefulWidget {
  final User user;
  const _DiscussionTab({required this.user});

  @override
  State<_DiscussionTab> createState() => _DiscussionTabState();
}

class _DiscussionTabState extends State<_DiscussionTab> {
  List<dynamic> _questions = [];
  List<dynamic> _articleComments = [];
  List<ArticleCommentGroup> _groupedArticleComments = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _replyController = TextEditingController();
  String? _replyingToId;
  String? _replyingToCommentId;
  int _activeSubTab = 0; // 0 = Public Forum, 1 = Article Comments

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Fetch forum questions
      final questionsResponse = await sl<Dio>().get('${ApiConstants.baseUrl}/api/v1/forum/questions');
      
      // 2. Fetch article comments if the logged-in user is a doctor
      if (widget.user.role == 'doctor') {
        final commentsResponse = await sl<Dio>().get('${ApiConstants.baseUrl}/api/v1/doctor/article-comments');
        if (commentsResponse.data != null && commentsResponse.data['success'] == true) {
          _articleComments = commentsResponse.data['comments'] ?? [];
        } else {
          _articleComments = [];
        }
        _groupAndNestComments();
      }

      if (questionsResponse.data != null && questionsResponse.data['success'] == true) {
        if (mounted) {
          setState(() {
            _questions = questionsResponse.data['questions'] ?? [];
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
        _fetchData();
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

  Future<void> _postArticleCommentReply(String articleId, String parentCommentId) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await sl<Dio>().post(
        '${ApiConstants.baseUrl}/api/v1/articles/$articleId/comments',
        data: {
          'text': text,
          'parentCommentId': parentCommentId,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        _replyController.clear();
        setState(() {
          _replyingToCommentId = null;
        });
        _fetchData();
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
                          _fetchData();
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


  void _groupAndNestComments() {
    if (_articleComments.isEmpty) {
      setState(() {
        _groupedArticleComments = [];
      });
      return;
    }

    // 1. Group raw comments by article ID
    final Map<String, List<Map<String, dynamic>>> commentsByArticle = {};
    final Map<String, Map<String, dynamic>> articlesById = {};

    for (var commentRaw in _articleComments) {
      if (commentRaw == null) continue;
      final comment = Map<String, dynamic>.from(commentRaw);
      final article = comment['article'];
      if (article == null) continue;
      
      final articleId = article['_id'] ?? article['id'] ?? 'unknown';
      articlesById[articleId] = Map<String, dynamic>.from(article);
      
      if (!commentsByArticle.containsKey(articleId)) {
        commentsByArticle[articleId] = [];
      }
      commentsByArticle[articleId]!.add(comment);
    }

    final List<ArticleCommentGroup> groups = [];

    // Helper to parse date
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.fromMillisecondsSinceEpoch(0);
      try {
        return DateTime.parse(date.toString());
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    // 2. Process each article group
    commentsByArticle.forEach((articleId, commentsList) {
      final article = articlesById[articleId]!;

      // Sort all comments in this group chronologically (oldest first)
      commentsList.sort((a, b) => parseDate(a['createdAt']).compareTo(parseDate(b['createdAt'])));

      // Map to quickly find nodes
      final Map<String, CommentNode> nodeMap = {};
      for (var comment in commentsList) {
        final cid = comment['_id'] ?? comment['id'] ?? '';
        if (cid.isNotEmpty) {
          nodeMap[cid] = CommentNode(comment: comment, children: []);
        }
      }

      // Build tree
      final List<CommentNode> roots = [];
      for (var comment in commentsList) {
        final cid = comment['_id'] ?? comment['id'] ?? '';
        if (cid.isEmpty) continue;
        final node = nodeMap[cid]!;

        // Determine parent ID
        String? parentId;
        final parentVal = comment['parentComment'];
        if (parentVal is String) {
          parentId = parentVal;
        } else if (parentVal is Map) {
          parentId = parentVal['_id'] ?? parentVal['id'];
        }

        if (parentId == null || !nodeMap.containsKey(parentId)) {
          // It is a root comment
          roots.add(node);
        } else {
          // It is a reply, add to parent's children
          nodeMap[parentId]!.children.add(node);
        }
      }

      // Flatten tree
      final List<FlattenedComment> flattenedList = [];
      void flattenTree(CommentNode node, int depth) {
        flattenedList.add(FlattenedComment(comment: node.comment, depth: depth));
        for (var child in node.children) {
          flattenTree(child, depth + 1);
        }
      }

      for (var root in roots) {
        flattenTree(root, 0);
      }

      groups.add(ArticleCommentGroup(article: article, comments: flattenedList));
    });

    setState(() {
      _groupedArticleComments = groups;
    });
  }

  Widget _buildArticleCommentGroup(ArticleCommentGroup group, bool isDark) {
    final articleTitle = group.article['title'] ?? 'Article';
    final category = group.article['category'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: isDark ? AppColors.dividerDark : const Color(0xFFEEF2F6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article Header Card
          InkWell(
            onTap: () {
              final articleData = Map<String, dynamic>.from(group.article)
                ..['author'] = {'name': widget.user.name};
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailPage(article: articleData, user: widget.user),
                ),
              );
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.04),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.article_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (category != null)
                          Text(
                            category.toString().toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          articleTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
          
          // Comments inside this article
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: group.comments.map((flatComment) {
                return _buildRedditCommentCard(flatComment, isDark);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedditCommentCard(FlattenedComment flatComment, bool isDark) {
    final comment = flatComment.comment;
    final author = comment['author'];
    final authorName = author?['name'] ?? 'Anonymous Patient';
    final authorRole = author?['role'] ?? 'patient';
    final dateStr = comment['createdAt'] != null
        ? DateTime.parse(comment['createdAt']).toLocal().toString().split(' ')[0]
        : '';
    final depth = flatComment.depth.clamp(0, 4);
    final isReplying = _replyingToCommentId == comment['_id'];

    final articleVal = comment['article'];
    String articleId = '';
    if (articleVal is Map) {
      articleId = articleVal['_id'] ?? articleVal['id'] ?? '';
    } else if (articleVal is String) {
      articleId = articleVal;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ancestor thread lines
            for (int i = 0; i < depth; i++)
              Container(
                width: 1.5,
                margin: EdgeInsets.only(
                  left: i == 0 ? 0.0 : 8.0,
                  right: i == depth - 1 ? 12.0 : 0.0,
                  top: 4,
                  bottom: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            // Comment Content Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? (depth == 0 ? AppColors.darkSurface.withOpacity(0.5) : AppColors.darkSurface.withOpacity(0.2)) 
                      : (depth == 0 ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.dividerDark : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFE8F0FF),
                          child: Text(
                            authorName.isNotEmpty ? authorName[0].toUpperCase() : 'P',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  authorName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: authorRole == 'doctor'
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  authorRole.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                    color: authorRole == 'doctor' ? AppColors.success : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white60 : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comment['text'] ?? '',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Spacer(),
                        if (articleId.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                if (isReplying) {
                                  _replyingToCommentId = null;
                                  _replyController.clear();
                                } else {
                                  _replyingToCommentId = comment['_id'];
                                  _replyController.clear();
                                }
                              });
                            },
                            icon: Icon(
                              isReplying ? Icons.close_rounded : Icons.reply_rounded, 
                              size: 14, 
                              color: AppColors.primary,
                            ),
                            label: Text(
                              isReplying ? 'Cancel' : 'Reply',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                    if (isReplying) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Write a reply...',
                                hintStyle: const TextStyle(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: isDark ? AppColors.dividerDark : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _postArticleCommentReply(articleId, comment['_id']),
                            icon: const Icon(Icons.send_rounded, size: 18, color: AppColors.primary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeSubTab = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeSubTab == 0 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _activeSubTab == 0
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Public Forum',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _activeSubTab == 0 ? Colors.white : (isDark ? Colors.white60 : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeSubTab = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeSubTab == 1 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _activeSubTab == 1
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Article Comments',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _activeSubTab == 1 ? Colors.white : (isDark ? Colors.white60 : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    Widget tabContent;
    if (widget.user.role == 'doctor' && _activeSubTab == 1) {
      tabContent = _groupedArticleComments.isEmpty
          ? Center(
              child: Text(
                'No article comments yet.',
                style: TextStyle(color: isDark ? Colors.white60 : AppColors.textTertiary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _groupedArticleComments.length,
              itemBuilder: (context, index) {
                final group = _groupedArticleComments[index];
                return _buildArticleCommentGroup(group, isDark);
              },
            );
    } else {
      tabContent = _questions.isEmpty
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
                final authorName = isAnonymous ? 'Anonymous Patient' : (post['user']?['name'] ?? 'User');
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
            );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          if (widget.user.role == 'doctor') _buildSubTabs(isDark),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              color: AppColors.primary,
              child: tabContent,
            ),
          ),
        ],
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

class CommentNode {
  final Map<String, dynamic> comment;
  final List<CommentNode> children;

  CommentNode({required this.comment, required this.children});
}

class FlattenedComment {
  final Map<String, dynamic> comment;
  final int depth;

  FlattenedComment({required this.comment, required this.depth});
}

class ArticleCommentGroup {
  final Map<String, dynamic> article;
  final List<FlattenedComment> comments;

  ArticleCommentGroup({required this.article, required this.comments});
}

// ── 4. ARTICLE DETAIL PAGE ───────────────────────────────────────────────────

class ArticleDetailPage extends StatefulWidget {
  final dynamic article;
  final User user;

  const ArticleDetailPage({super.key, required this.article, required this.user});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  List<dynamic> _rawComments = [];
  List<FlattenedComment> _nestedComments = [];
  bool _isLoadingComments = true;
  bool _isSubmitting = false;
  String? _replyingToCommentId;

  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCommentsInitial();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _fetchCommentsInitial() async {
    setState(() {
      _isLoadingComments = true;
    });
    await _fetchComments();
    if (mounted) {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _fetchComments() async {
    final articleId = widget.article['_id'] ?? widget.article['id'] ?? '';
    if (articleId.isEmpty) return;

    try {
      final response = await sl<Dio>().get('${ApiConstants.baseUrl}/api/v1/articles/$articleId/comments');
      if (response.data != null && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _rawComments = response.data['comments'] ?? [];
          });
          _nestComments();
        }
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    }
  }

  void _nestComments() {
    if (_rawComments.isEmpty) {
      setState(() {
        _nestedComments = [];
      });
      return;
    }

    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.fromMillisecondsSinceEpoch(0);
      try {
        return DateTime.parse(date.toString());
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    final commentsList = List<Map<String, dynamic>>.from(
      _rawComments.map((c) => Map<String, dynamic>.from(c)),
    );

    commentsList.sort((a, b) => parseDate(a['createdAt']).compareTo(parseDate(b['createdAt'])));

    final Map<String, CommentNode> nodeMap = {};
    for (var comment in commentsList) {
      final cid = comment['_id'] ?? comment['id'] ?? '';
      if (cid.isNotEmpty) {
        nodeMap[cid] = CommentNode(comment: comment, children: []);
      }
    }

    final List<CommentNode> roots = [];
    for (var comment in commentsList) {
      final cid = comment['_id'] ?? comment['id'] ?? '';
      if (cid.isEmpty) continue;
      final node = nodeMap[cid]!;

      String? parentId;
      final parentVal = comment['parentComment'];
      if (parentVal is String) {
        parentId = parentVal;
      } else if (parentVal is Map) {
        parentId = parentVal['_id'] ?? parentVal['id'];
      }

      if (parentId == null || !nodeMap.containsKey(parentId)) {
        roots.add(node);
      } else {
        nodeMap[parentId]!.children.add(node);
      }
    }

    final List<FlattenedComment> flattenedList = [];
    void flattenTree(CommentNode node, int depth) {
      flattenedList.add(FlattenedComment(comment: node.comment, depth: depth));
      for (var child in node.children) {
        flattenTree(child, depth + 1);
      }
    }

    for (var root in roots) {
      flattenTree(root, 0);
    }

    setState(() {
      _nestedComments = flattenedList;
    });
  }

  Future<void> _postComment({String? parentCommentId}) async {
    final articleId = widget.article['_id'] ?? widget.article['id'] ?? '';
    if (articleId.isEmpty) return;

    final controller = parentCommentId == null ? _commentController : _replyController;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await sl<Dio>().post(
        '${ApiConstants.baseUrl}/api/v1/articles/$articleId/comments',
        data: {
          'text': text,
          'parentCommentId': parentCommentId,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        controller.clear();
        if (parentCommentId != null) {
          _replyingToCommentId = null;
        }
        await _fetchComments();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to post comment')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _stripHtml(String htmlString) {
    final regExp = RegExp(r'<[^>]*>|&[^;]+;', multiLine: true, caseSensitive: false);
    return htmlString.replaceAll(regExp, ' ').trim();
  }

  Widget _buildCommentCard(FlattenedComment flatComment, bool isDark) {
    final comment = flatComment.comment;
    final author = comment['author'];
    final authorName = author?['name'] ?? 'Anonymous User';
    final authorRole = author?['role'] ?? 'patient';
    final dateStr = comment['createdAt'] != null
        ? DateTime.parse(comment['createdAt']).toLocal().toString().split(' ')[0]
        : '';
    final depth = flatComment.depth.clamp(0, 4);
    final isReplying = _replyingToCommentId == comment['_id'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < depth; i++)
              Container(
                width: 1.5,
                margin: EdgeInsets.only(
                  left: i == 0 ? 0.0 : 8.0,
                  right: i == depth - 1 ? 12.0 : 0.0,
                  top: 4,
                  bottom: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark 
                      ? (depth == 0 ? AppColors.darkSurface.withOpacity(0.5) : AppColors.darkSurface.withOpacity(0.2)) 
                      : (depth == 0 ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.dividerDark : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFE8F0FF),
                          child: Text(
                            authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  authorName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: authorRole == 'doctor'
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  authorRole.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                    color: authorRole == 'doctor' ? AppColors.success : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white60 : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comment['text'] ?? '',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              if (isReplying) {
                                _replyingToCommentId = null;
                                _replyController.clear();
                              } else {
                                _replyingToCommentId = comment['_id'];
                                _replyController.clear();
                              }
                            });
                          },
                          icon: Icon(
                            isReplying ? Icons.close_rounded : Icons.reply_rounded, 
                            size: 14, 
                            color: AppColors.primary,
                          ),
                          label: Text(
                            isReplying ? 'Cancel' : 'Reply',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    if (isReplying) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Write a reply...',
                                hintStyle: const TextStyle(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: isDark ? AppColors.dividerDark : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                )
                              : IconButton(
                                  onPressed: () => _postComment(parentCommentId: comment['_id']),
                                  icon: const Icon(Icons.send_rounded, size: 18, color: AppColors.primary),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authorName = widget.article['author']?['name'] ?? 'Admin';
    final thumbnail = widget.article['featureImage'];
    final dateStr = widget.article['createdAt'] != null
        ? DateTime.parse(widget.article['createdAt']).toLocal().toString().split(' ')[0]
        : '';
    final plainContent = _stripHtml(widget.article['content'] ?? '');

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
                  if (widget.article['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.article['category'].toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    widget.article['title'] ?? '',
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
                  const Divider(height: 40),

                  // Comment box header
                  Text(
                    'Comments (${_rawComments.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Root comment input box
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFE8F0FF),
                        child: Text(
                          widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Share your thoughts on this article...',
                            hintStyle: const TextStyle(fontSize: 12.5),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            isDense: true,
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
                      ),
                      const SizedBox(width: 12),
                      _isSubmitting && _replyingToCommentId == null
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : IconButton(
                              onPressed: () => _postComment(),
                              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                            ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Comments list
                  if (_isLoadingComments)
                    const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  else if (_nestedComments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No comments yet. Be the first to share your thoughts!',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _nestedComments.map((flatComment) {
                        return _buildCommentCard(flatComment, isDark);
                      }).toList(),
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
