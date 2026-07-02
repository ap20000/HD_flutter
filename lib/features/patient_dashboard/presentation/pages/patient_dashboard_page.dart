import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../../../features/auth/presentation/pages/profile_page.dart';
import '../../../../injection_container.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/story.dart';
import '../bloc/patient_dashboard_bloc.dart';
import '../bloc/patient_dashboard_event.dart';
import '../bloc/patient_dashboard_state.dart';
import '../widgets/premium_bottom_nav.dart';
import '../../../consultation/presentation/pages/consultation_page.dart';
import 'book_appointment_page.dart';
import 'third_pole_ai_page.dart';
import 'story_viewer_page.dart';
import 'posts_page.dart';
import 'add_story_page.dart';
import '../widgets/story_avatar.dart';

// ── Main Page ────────────────────────────────────────────────────────────────

class PatientDashboardPage extends StatefulWidget {
  final User user;

  const PatientDashboardPage({super.key, required this.user});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: BlocProvider(
        create: (context) =>
            sl<PatientDashboardBloc>()..add(LoadDashboardData()),
        child: Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : const Color(0xFFF8FAFC),
          body: BlocListener<PatientDashboardBloc, PatientDashboardState>(
            listener: (context, state) {
              if (state is PatientDashboardLoaded) {
                // Check if any consultation was just requested and we're notified
                final requested = state.consultations
                    .where((c) => c.status == 'pending')
                    .toList();
                if (requested.isNotEmpty && _selectedIndex != 1) {
                  // Optional: Automatically switch to consultations tab
                  // setState(() => _selectedIndex = 1);
                }
              }
            },
            child: SafeArea(child: _buildBody()),
          ),
          bottomNavigationBar: PremiumBottomNav(
            selectedIndex: _selectedIndex,
            onTap: (index) {
              HapticFeedback.lightImpact();
              setState(() => _selectedIndex = index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return BlocBuilder<PatientDashboardBloc, PatientDashboardState>(
          builder: (context, state) {
            if (state is PatientDashboardLoading) {
              return const _LoadingView();
            } else if (state is PatientDashboardError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<PatientDashboardBloc>().add(
                  LoadDashboardData(),
                ),
              );
            } else if (state is PatientDashboardLoaded) {
              return _DashboardBody(
                user: widget.user,
                state: state,
                onProfileTap: () => setState(() => _selectedIndex = 4),
                onArticlesTab: () => setState(() => _selectedIndex = 3),
                onConsultationsTab: () => setState(() => _selectedIndex = 1),
              );
            }
            return const SizedBox();
          },
        );
      case 1:
        return BlocBuilder<PatientDashboardBloc, PatientDashboardState>(
          builder: (context, state) {
            if (state is PatientDashboardLoading) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Scaffold(
                backgroundColor: isDark
                    ? AppColors.darkBackground
                    : const Color(0xFFF8FAFC),
                appBar: AppBar(
                  title: Text(
                    'Consultations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                ),
                body: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            return _ConsultationsPage(
              isDark: Theme.of(context).brightness == Brightness.dark,
              consultations: state is PatientDashboardLoaded
                  ? state.consultations
                  : [],
              currentUserId: widget.user.id,
            );
          },
        );
      case 2:
        return ThirdPoleAIChatPage(user: widget.user);
      case 3:
        return PostsPage(user: widget.user);
      case 4:
        return ProfilePage(user: widget.user);
      default:
        return const SizedBox();
    }
  }
}

// ── Dashboard body ────────────────────────────────────────────────────────────

class _DashboardBody extends StatefulWidget {
  final User user;
  final PatientDashboardLoaded state;
  final VoidCallback onProfileTap;
  final VoidCallback onArticlesTab;
  final VoidCallback onConsultationsTab;

  const _DashboardBody({
    required this.user,
    required this.state,
    required this.onProfileTap,
    required this.onArticlesTab,
    required this.onConsultationsTab,
  });

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  List<GroupedStories> _groupedStories = [];
  bool _isLoadingStories = true;

  static const _healthServices = [
    'Book Doctor',
    'Lab Tests',
    'Health Packages',
    'Pharmacy',
  ];

  int get _unreadNotifications => widget.state.consultations
      .where((c) => c.status == 'pending' || c.status == 'active')
      .length;

  List<String> get _upcomingAppointments => widget.state.consultations
      .where((c) => c.status == 'active' || c.status == 'pending')
      .map((c) => '${c.doctorName} – ${c.doctorSpecialty}')
      .toList();

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingStories = true;
    });

    try {
      final response = await sl<Dio>().get(ApiConstants.stories);
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
            grouped.add(
              GroupedStories(
                authorId: entry.key,
                authorName: firstStory.authorName,
                authorAvatar: firstStory.authorAvatar,
                authorSpecialty: firstStory.authorSpecialty,
                stories: authorStories,
              ),
            );
          }
        }

        if (mounted) {
          setState(() {
            _groupedStories = grouped;
            _isLoadingStories = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingStories = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching stories: $e');
      if (mounted) {
        setState(() {
          _isLoadingStories = false;
        });
      }
    }
  }

  void _onSearchTap(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Search coming soon')));
  }

  void _onServiceTap(BuildContext context, String service) {
    HapticFeedback.lightImpact();
    if (service == 'Book Doctor') {
      _onConsultNow(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$service coming soon')));
    }
  }

  void _onConsultNow(BuildContext context) {
    HapticFeedback.lightImpact();
    if (widget.state.doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No doctors available right now')),
      );
      return;
    }
    final doctor = widget.state.doctors.first;
    context.read<PatientDashboardBloc>().add(RequestConsultation(doctor.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Starting consultation request with Dr. ${doctor.name}...',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
    widget.onConsultationsTab();
  }

  void _onAppointmentTap(BuildContext context) {
    HapticFeedback.lightImpact();
    widget.onConsultationsTab();
  }

  void _onArticleTap(BuildContext context, Article article) {
    HapticFeedback.lightImpact();
    widget.onArticlesTab();
  }

  void _onNotificationsTap(BuildContext context) {
    HapticFeedback.lightImpact();
    widget.onConsultationsTab();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.white : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.textOnDarkSecondary
        : AppColors.textSecondary;

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        context.read<PatientDashboardBloc>().add(LoadDashboardData());
        await _fetchStories();
      },
      color: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
            elevation: 0,
            pinned: true,
            leadingWidth: 42,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 20),
              ),
            ),
            title: Text(
              'Hamro Doctor',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _onNotificationsTap(context),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      color: textPrimary,
                      size: 26,
                    ),
                    if (_unreadNotifications > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: AppColors.error,
                        ),
                      ),
                  ],
                ),
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeHeader(
                  context,
                  widget.user.name,
                  textPrimary,
                  textSecondary,
                ),
                const SizedBox(height: 16),
                _SearchBar(isDark: isDark, onTap: () => _onSearchTap(context)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 100,
                  child: _isLoadingStories
                      ? ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 5,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            return const StoryShimmer();
                          },
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _groupedStories.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return StoryAvatar(
                                text: 'Your Story',
                                avatarUrl: widget.user.avatar,
                                isYourStory: true,
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  if (widget.user.role == 'patient') {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        backgroundColor: isDark
                                            ? AppColors.darkSurface
                                            : Colors.white,
                                        title: Row(
                                          children: [
                                            const Icon(
                                              Icons.info_outline,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Health Stories',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        content: Text(
                                          'Only verified medical specialists can post health stories. Feel free to browse active stories from our doctors!',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : AppColors.textSecondary,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text(
                                              'Got it',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    final result = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddStoryPage(user: widget.user),
                                      ),
                                    );
                                    if (result == true) {
                                      _fetchStories();
                                    }
                                  }
                                },
                              );
                            }

                            final grouped = _groupedStories[index - 1];
                            final doctorLastName = grouped.authorName
                                .split(" ")
                                .last;
                            return StoryAvatar(
                              text: 'Dr. $doctorLastName',
                              avatarUrl: grouped.authorAvatar,
                              hasStories: true,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StoryViewerPage(
                                      groupedStoriesList: _groupedStories,
                                      initialAuthorIndex: index - 1,
                                      onConsultNow: (doctorId) {
                                        // Start consultation request with this doctor
                                        context
                                            .read<PatientDashboardBloc>()
                                            .add(RequestConsultation(doctorId));
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Starting consultation request with Dr. ${grouped.authorName}...',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              16,
                                            ),
                                          ),
                                        );
                                        widget.onConsultationsTab();
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
                _ConsultationCard(onTap: () => _onConsultNow(context)),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Our Services',
                  textColor: textPrimary,
                  onSeeAll: () {},
                ),
                const SizedBox(height: 12),
                _ServicesCarousel(
                  isDark: isDark,
                  services: _healthServices,
                  onTap: (s) => _onServiceTap(context, s),
                ),
                const SizedBox(height: 24),
                _UpcomingAppointmentCard(
                  isDark: isDark,
                  appointment: _upcomingAppointments.isNotEmpty
                      ? _upcomingAppointments.first
                      : null,
                  onTap: () => _onAppointmentTap(context),
                ),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Top Specialists',
                  textColor: textPrimary,
                  onSeeAll: () => _onConsultNow(context),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 195,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.state.doctors.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final doctor = widget.state.doctors[index];
                      return _SpecialistCard(
                        isDark: isDark,
                        name: doctor.name,
                        specialty: doctor.specialty,
                        onTap: () {
                          context.read<PatientDashboardBloc>().add(
                            RequestConsultation(doctor.id),
                          );
                          widget.onConsultationsTab();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Health Articles',
                  textColor: textPrimary,
                  onSeeAll: widget.onArticlesTab,
                ),
                const SizedBox(height: 12),
                if (widget.state.articles.isEmpty)
                  _EmptyArticlesPlaceholder(isDark: isDark)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.state.articles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final article = widget.state.articles[idx];
                      return _ArticleCard(
                        isDark: isDark,
                        article: article,
                        onTap: () => _onArticleTap(context, article),
                      );
                    },
                  ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(
    BuildContext context,
    String userName,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Namaste, ${userName.split(" ").first}!',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Text('👋', style: TextStyle(fontSize: 22)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'How can we help you today?',
          style: AppTypography.bodyMedium.copyWith(
            color: textSecondary,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

// ── Home section widgets ──────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _SearchBar({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Search doctors, hospitals, or services...',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: isDark ? AppColors.textOnDarkSecondary : Colors.black45,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search doctors, hospitals, or services...',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : Colors.black45,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color textColor;
  final VoidCallback onSeeAll;

  const _SectionTitle({
    required this.title,
    required this.textColor,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: textColor,
            fontFamily: AppTypography.fontFamily,
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: Row(
            children: [
              const Text(
                'View All',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServicesCarousel extends StatelessWidget {
  final bool isDark;
  final List<String> services;
  final void Function(String) onTap;

  const _ServicesCarousel({
    required this.isDark,
    required this.services,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> serviceDetails = [
      {
        'name': 'General',
        'icon': Icons.medical_services_outlined,
        'color': const Color(0xFFE3F2FD),
        'iconColor': const Color(0xFF1976D2),
      },
      {
        'name': 'Cardiology',
        'icon': Icons.favorite_outline,
        'color': const Color(0xFFFFEBEE),
        'iconColor': const Color(0xFFD32F2F),
      },
      {
        'name': 'Genetics',
        'icon': Icons.biotech_outlined,
        'color': const Color(0xFFF3E5F5),
        'iconColor': const Color(0xFF7B1FA2),
      },
      {
        'name': 'Diagnostic',
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFFE8F5E9),
        'iconColor': const Color(0xFF388E3C),
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: serviceDetails.map((service) {
        return GestureDetector(
          onTap: () => onTap(service['name']),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : service['color'],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  service['icon'],
                  color: isDark ? Colors.white : service['iconColor'],
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                service['name'],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ConsultationCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Consult with a Doctor',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD).withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2196F3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Live Consultation',
                          style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Consult with a\nDoctor',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connect instantly with\nverified specialists available\n24/7.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Consult Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                top: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Image.network(
                    'https://img.freepik.com/free-photo/smiling-female-doctor-white-coat-standing-with-clipboard-hand_231208-12965.jpg?t=st=1718712000~exp=1718715600~hmac=1234567890abcdef', // Mock image
                    fit: BoxFit.cover,
                    width: 150,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 150,
                      color: Colors.grey.withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingAppointmentCard extends StatelessWidget {
  final bool isDark;
  final String? appointment;
  final VoidCallback onTap;

  const _UpcomingAppointmentCard({
    required this.isDark,
    required this.appointment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming Appointment',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appointment ?? 'No upcoming appointments',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, size: 18, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final bool isDark;
  final int index;

  const _PackageCard({required this.isDark, required this.index});

  @override
  Widget build(BuildContext context) {
    final displayTitle = index == 0
        ? 'Full Body Checkup'
        : 'Heart Health Package';
    final displayPrice = index == 0 ? '4,500' : '3,200';
    final displayOldPrice = index == 0 ? '6,000' : null;
    final count = index == 0 ? 64 : 12;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    index == 0 ? Icons.person : Icons.favorite,
                    size: 60,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$count Tests Included',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Rs. $displayPrice',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                    if (displayOldPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Rs. $displayOldPrice',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.black26,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'Book Package',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
}

class _SpecialistCard extends StatelessWidget {
  final bool isDark;
  final String name;
  final String specialty;
  final VoidCallback onTap;

  const _SpecialistCard({
    required this.isDark,
    required this.name,
    required this.specialty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'D',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              specialty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Consult Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final bool isDark;
  final Article article;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.isDark,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.withOpacity(0.1),
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Heart Care',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time,
                          size: 10,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '5 min read',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? AppColors.white : AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 12,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Trending',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.bookmark_border,
                          size: 18,
                          color: Colors.black45,
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
    );
  }
}

class _EmptyArticlesPlaceholder extends StatelessWidget {
  final bool isDark;

  const _EmptyArticlesPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.border,
        ),
      ),
      child: Text(
        'No articles available yet',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark
              ? AppColors.textOnDarkSecondary
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Loading view ──────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onRetry();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty feature page ────────────────────────────────────────────────────────

class _EmptyFeaturePage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final bool isDark;

  const _EmptyFeaturePage({
    required this.title,
    required this.icon,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.surfacePearl,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 28),
              Text(
                '$title Coming Soon',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notification_important_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We\'re working hard to bring this feature to you.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
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
}

class _ConsultationsPage extends StatefulWidget {
  final bool isDark;
  final List<Consultation> consultations;
  final String currentUserId;

  const _ConsultationsPage({
    required this.isDark,
    required this.consultations,
    required this.currentUserId,
  });

  @override
  State<_ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<_ConsultationsPage> {
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'active', 'pending'

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    // Filter list based on search query and filter selection
    final filtered = widget.consultations.where((c) {
      final matchesSearch =
          c.doctorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.doctorSpecialty.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _filterType == 'all' ||
          (_filterType == 'active' && c.status == 'active') ||
          (_filterType == 'pending' && c.status == 'pending');
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Consultations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search consultations...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('active', 'Ongoing'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pending'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // List or Empty State
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final consultation = filtered[index];
                      return _FullConsultationCard(
                        isDark: isDark,
                        consultation: consultation,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConsultationPage(
                                consultationId: consultation.id,
                                currentUserId: widget.currentUserId,
                                otherUserName: consultation.doctorName,
                                isDoctor: false,
                                initialPrescription: consultation.prescription,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isSelected = _filterType == type;
    final isDark = widget.isDark;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _filterType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.withOpacity(isDark ? 0.08 : 0.2),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: widget.isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No consultations found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullConsultationCard extends StatelessWidget {
  final bool isDark;
  final Consultation consultation;
  final VoidCallback onTap;

  const _FullConsultationCard({
    required this.isDark,
    required this.consultation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = consultation.status == 'active'
        ? Colors.green
        : (consultation.status == 'pending' ? Colors.orange : Colors.grey);

    final bool isAccepted = consultation.status == 'active';

    return Opacity(
      opacity: isAccepted ? 1.0 : 0.8,
      child: InkWell(
        onTap: isAccepted ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: !isAccepted
                ? Border.all(color: statusColor.withOpacity(0.3), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      consultation.doctorName[0],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (!isAccepted)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.hourglass_empty,
                            size: 16,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consultation.doctorName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      consultation.doctorSpecialty,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAccepted ? 'ONGOING SESSION' : 'WAITING FOR APPROVAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isAccepted)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                )
              else
                const Icon(Icons.lock_outline, size: 18, color: Colors.orange),
            ],
          ),
        ),
      ),
    );
  }
}
