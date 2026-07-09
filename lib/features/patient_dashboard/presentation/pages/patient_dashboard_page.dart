import 'dart:convert';
import 'dart:math' as math;
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
import 'third_pole_ai_page.dart';
import 'story_viewer_page.dart';
import 'posts_page.dart';
import 'add_story_page.dart';
import '../widgets/story_avatar.dart';
import '../widgets/bmi_health_card.dart';
import '../widgets/dashboard_search_bar.dart';
import '../widgets/services_carousel.dart';
import '../widgets/consultation_banner_card.dart';
import '../widgets/specialist_card.dart';
import '../widgets/article_card.dart';
import '../widgets/upcoming_appointment_section.dart';

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

// ── Main Page ────────────────────────────────────────────────────────────────

class PatientDashboardPage extends StatefulWidget {
  final User user;

  const PatientDashboardPage({super.key, required this.user});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  int _selectedIndex = 0;

  void _showAIChatBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBackground
                : AppColors.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: ThirdPoleAIChatPage(user: widget.user),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
                final requested = state.consultations
                    .where((c) => c.status == 'pending')
                    .toList();
                if (requested.isNotEmpty && _selectedIndex != 1) {
                  // Optional: Auto switch
                }
              }
            },
            child: SafeArea(child: _buildBody()),
          ),
          floatingActionButton: _selectedIndex == 0
              ? _FloatingAIChatWidget(
                  user: widget.user,
                  showChatCallback: _showAIChatBottomSheet,
                )
              : null,
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
                onProfileTap: () => setState(() => _selectedIndex = 3),
                onArticlesTab: () => setState(() => _selectedIndex = 2),
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
        return PostsPage(user: widget.user);
      case 3:
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

  List<Consultation> get _upcomingAppointments => widget.state.consultations
      .where((c) => c.status == 'active' || c.status == 'pending')
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

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _AnimatedEntry(
                  index: 0,
                  child: _buildWelcomeHeader(
                    context,
                    widget.user.name,
                    textPrimary,
                    textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _AnimatedEntry(
                  index: 1,
                  child: DashboardSearchBar(onTap: () => _onSearchTap(context)),
                ),
                const SizedBox(height: 20),
                _AnimatedEntry(
                  index: 2,
                  child: SizedBox(
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
                                            borderRadius: BorderRadius.circular(20),
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
                ),
                const SizedBox(height: 20),
                _AnimatedEntry(
                  index: 3,
                  child: BmiHealthCard(
                    bmi: widget.state.latestRecord?.bmi ?? 22.86,
                    weight: widget.state.latestRecord?.weight ?? 70.0,
                    height: widget.state.latestRecord?.height ?? 1.75,
                  ),
                ),
                const SizedBox(height: 24),
                _AnimatedEntry(
                  index: 4,
                  child: ConsultationBannerCard(onTap: () => _onConsultNow(context)),
                ),
                const SizedBox(height: 24),
                _AnimatedEntry(
                  index: 5,
                  child: _buildAIChatCard(context, isDark, textPrimary, textSecondary),
                ),
                const SizedBox(height: 24),
                _AnimatedEntry(
                  index: 6,
                  child: _SectionTitle(
                    title: 'Our Services',
                    textColor: textPrimary,
                    onSeeAll: () {},
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedEntry(
                  index: 7,
                  child: ServicesCarousel(
                    services: _healthServices,
                    onTap: (s) => _onServiceTap(context, s),
                  ),
                ),
                const SizedBox(height: 24),
                _AnimatedEntry(
                  index: 8,
                  child: UpcomingAppointmentSection(
                    consultation: _upcomingAppointments.isNotEmpty
                        ? _upcomingAppointments.first
                        : null,
                    onTap: () => _onAppointmentTap(context),
                  ),
                ),
                const SizedBox(height: 24),
                _AnimatedEntry(
                  index: 9,
                  child: _SectionTitle(
                    title: 'Top Specialists',
                    textColor: textPrimary,
                    onSeeAll: () => _onConsultNow(context),
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedEntry(
                  index: 10,
                  child: SizedBox(
                    height: 195,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.state.doctors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final doctor = widget.state.doctors[index];
                        return SpecialistCard(
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
                ),
                const SizedBox(height: 24),
                _AnimatedEntry(
                  index: 11,
                  child: _SectionTitle(
                    title: 'Health Articles',
                    textColor: textPrimary,
                    onSeeAll: widget.onArticlesTab,
                  ),
                ),
                const SizedBox(height: 12),
                _AnimatedEntry(
                  index: 12,
                  child: widget.state.articles.isEmpty
                      ? _EmptyArticlesPlaceholder(isDark: isDark)
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.state.articles.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final article = widget.state.articles[idx];
                            return ArticleCard(
                              article: article,
                              onTap: () => _onArticleTap(context, article),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAIChatBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBackground
                : AppColors.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: ThirdPoleAIChatPage(user: widget.user),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAIChatCard(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.darkSurface,
                ]
              : [
                  AppColors.primary.withOpacity(0.08),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.05 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.mediumImpact();
            _showAIChatBottomSheet(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: AppColors.primary,
                    size: 32,
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
                            'ThirdPole AI Assistant',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bmiHealthy.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: AppColors.bmiHealthy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Describe symptoms, find matching doctors, and ask health questions.',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.white54 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(
    BuildContext context,
    String userName,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarBytes = _getAvatarBytes(widget.user.avatar);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THIRDPOLE HEALTH',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withOpacity(0.06) : AppColors.primarySoft.withOpacity(0.4),
              ),
              child: Center(
                child: IconButton(
                  onPressed: () => _onNotificationsTap(context),
                  padding: EdgeInsets.zero,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_none_outlined,
                        color: textPrimary,
                        size: 24,
                      ),
                      if (_unreadNotifications > 0)
                        Positioned(
                          right: 1,
                          top: 1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: 'Notifications',
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onProfileTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primarySoft,
                      backgroundImage: avatarBytes != null ? MemoryImage(avatarBytes) : null,
                      child: avatarBytes == null
                          ? const Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 22,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkBackground : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Home section widgets ──────────────────────────────────────────────────────

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

// ── Consultations Page ────────────────────────────────────────────────────────

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
            fontWeight: FontWeight.w900,
            color: isDark ? AppColors.white : AppColors.textPrimary,
            fontFamily: AppTypography.fontFamily,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          _buildAmbientGlows(isDark),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.25 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontFamily: AppTypography.fontFamily,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search consultations...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : Colors.black38,
                        fontSize: 13,
                        fontFamily: AppTypography.fontFamily,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.dividerDark : const Color(0xFFEEF2F6),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final consultation = filtered[index];
                          return _AnimatedEntry(
                            index: index,
                            child: _FullConsultationCard(
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
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientGlows(bool isDark) {
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.secondary;
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(isDark ? 0.06 : 0.03),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withOpacity(isDark ? 0.05 : 0.02),
            ),
          ),
        ),
      ],
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEEF2F6)),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(isDark ? 0.45 : 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontFamily: AppTypography.fontFamily,
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
              fontFamily: AppTypography.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullConsultationCard extends StatefulWidget {
  final bool isDark;
  final Consultation consultation;
  final VoidCallback onTap;

  const _FullConsultationCard({
    required this.isDark,
    required this.consultation,
    required this.onTap,
  });

  @override
  State<_FullConsultationCard> createState() => _FullConsultationCardState();
}

class _FullConsultationCardState extends State<_FullConsultationCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
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
    final isDark = widget.isDark;
    final statusColor = widget.consultation.status == 'active'
        ? const Color(0xFF10B981) // emerald green
        : (widget.consultation.status == 'pending' ? const Color(0xFFF59E0B) : Colors.grey);

    final bool isAccepted = widget.consultation.status == 'active';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Opacity(
        opacity: isAccepted ? 1.0 : 0.9,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: !isAccepted
                  ? statusColor.withOpacity(0.3)
                  : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEEF2F6)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: GestureDetector(
              onTapDown: isAccepted ? (_) => _controller.forward() : null,
              onTapUp: isAccepted ? (_) {
                _controller.reverse();
                widget.onTap();
              } : null,
              onTapCancel: isAccepted ? () => _controller.reverse() : null,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isAccepted
                                  ? [const Color(0xFF004AC6), const Color(0xFF10B981)]
                                  : [const Color(0xFFF59E0B), Colors.grey.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                            child: Text(
                              widget.consultation.doctorName.isNotEmpty ? widget.consultation.doctorName[0].toUpperCase() : 'D',
                              style: TextStyle(
                                color: isAccepted ? const Color(0xFF004AC6) : const Color(0xFFF59E0B),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: AppTypography.fontFamily,
                              ),
                            ),
                          ),
                        ),
                        if (!isAccepted)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                size: 10,
                                color: Colors.white,
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
                            widget.consultation.doctorName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                              fontFamily: AppTypography.fontFamily,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.consultation.doctorSpecialty,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontFamily: AppTypography.fontFamily,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isAccepted) ...[
                                  const _PulsingStatusDot(color: Color(0xFF10B981)),
                                  const SizedBox(width: 6),
                                ] else ...[
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 10,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  isAccepted ? 'ONGOING SESSION' : 'WAITING FOR APPROVAL',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: statusColor,
                                    letterSpacing: 0.5,
                                    fontFamily: AppTypography.fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAccepted)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.primary.withOpacity(0.15) : const Color(0xFFE8F0FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: isDark ? AppColors.darkPrimary : const Color(0xFF004AC6),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: Color(0xFFD97706),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pulse Status Indicator Dot ───────────────────────────────────────────────

class _PulsingStatusDot extends StatefulWidget {
  final Color color;
  const _PulsingStatusDot({required this.color});

  @override
  State<_PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<_PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
        ),
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  final Widget child;
  final int index;

  const _AnimatedEntry({required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _FloatingAIChatWidget extends StatefulWidget {
  final User user;
  final Function(BuildContext) showChatCallback;

  const _FloatingAIChatWidget({
    required this.user,
    required this.showChatCallback,
  });

  @override
  State<_FloatingAIChatWidget> createState() => _FloatingAIChatWidgetState();
}

class _FloatingAIChatWidgetState extends State<_FloatingAIChatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller.addListener(() {
      if (_controller.value >= 0.5 && !_isFlipped) {
        setState(() {
          _isFlipped = true;
        });
      } else if (_controller.value < 0.5 && _isFlipped) {
        setState(() {
          _isFlipped = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerFlip() {
    if (_controller.isAnimating) return;
    HapticFeedback.mediumImpact();
    _controller.forward().then((_) {
      widget.showChatCallback(context);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _controller.reset();
          setState(() {
            _isFlipped = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double angle = _controller.value * math.pi;

        final frontButton = Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                AppColors.primary,
                Color(0xFF2E7D32),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            color: Colors.white,
            size: 28,
          ),
        );

        final backButton = Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2E7D32),
                Colors.orange,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.chat_bubble_rounded,
            color: Colors.white,
            size: 28,
          ),
        );

        return GestureDetector(
          onTap: _triggerFlip,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002) // perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: !_isFlipped
                ? frontButton
                : Transform(
                    transform: Matrix4.rotationY(math.pi),
                    alignment: Alignment.center,
                    child: backButton,
                  ),
          ),
        );
      },
    );
  }
}

