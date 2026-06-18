import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../../../features/auth/presentation/pages/profile_page.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/dashboard_data.dart';
import '../bloc/patient_dashboard_bloc.dart';
import '../bloc/patient_dashboard_event.dart';
import '../bloc/patient_dashboard_state.dart';
import '../widgets/premium_bottom_nav.dart';

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
          body: SafeArea(child: _buildBody()),
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
        return _EmptyFeaturePage(
          title: 'Consultations',
          icon: Icons.assignment_outlined,
          description:
              'Start a consultation with any of our specialists to discuss your health concerns.',
          isDark: Theme.of(context).brightness == Brightness.dark,
        );
      case 2:
        return _EmptyFeaturePage(
          title: 'Health Articles',
          icon: Icons.article_outlined,
          description:
              'Read expert-written articles about health, wellness, and medical topics.',
          isDark: Theme.of(context).brightness == Brightness.dark,
        );
      case 3:
        return ProfilePage(user: widget.user);
      default:
        return const SizedBox();
    }
  }
}

// ── Dashboard body ────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
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

  static const _healthServices = [
    'Book Doctor',
    'Lab Tests',
    'Health Packages',
    'Pharmacy',
  ];

  static const _storyTitles = [
    'Vaccination tips',
    'Diabetes care',
    'Healthy eating',
  ];

  int get _unreadNotifications => state.consultations
      .where((c) => c.status == 'pending' || c.status == 'active')
      .length;

  List<String> get _upcomingAppointments => state.consultations
      .where((c) => c.status == 'active' || c.status == 'pending')
      .map((c) => '${c.doctorName} – ${c.doctorSpecialty}')
      .toList();

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
    if (state.doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No doctors available right now')),
      );
      return;
    }
    final doctor = state.doctors.first;
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
  }

  void _onAppointmentTap(BuildContext context) {
    HapticFeedback.lightImpact();
    onConsultationsTab();
  }

  void _onArticleTap(BuildContext context, Article article) {
    HapticFeedback.lightImpact();
    onArticlesTab();
  }

  void _onStoryTap(BuildContext context, String story) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening: $story')));
  }

  void _onNotificationsTap(BuildContext context) {
    HapticFeedback.lightImpact();
    onConsultationsTab();
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
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            title: Text(
              'Hamro Doctor',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => _onNotificationsTap(context),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.notifications_outlined, color: textPrimary),
                    if (_unreadNotifications > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: AppColors.error,
                          child: Text(
                            '$_unreadNotifications',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Notifications',
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeHeader(
                  context,
                  user.name,
                  textPrimary,
                  textSecondary,
                ),
                const SizedBox(height: 12),
                _SearchBar(isDark: isDark, onTap: () => _onSearchTap(context)),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: 'Health Services',
                  textColor: textPrimary,
                  onSeeAll: () {},
                ),
                const SizedBox(height: 8),
                _ServicesCarousel(
                  isDark: isDark,
                  services: _healthServices,
                  onTap: (s) => _onServiceTap(context, s),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ConsultationCard(
                        onTap: () => _onConsultNow(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AppointmentPreview(
                        isDark: isDark,
                        appointments: _upcomingAppointments,
                        onTap: () => _onAppointmentTap(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (state.latestRecord != null) ...[
                  _SectionTitle(
                    title: 'Health Summary',
                    textColor: textPrimary,
                    onSeeAll: () {},
                  ),
                  const SizedBox(height: 8),
                  _BmiSummaryCard(
                    isDark: isDark,
                    bmi: state.latestRecord!.bmi,
                    weight: state.latestRecord!.weight,
                    height: state.latestRecord!.height,
                  ),
                  const SizedBox(height: 18),
                ],
                _SectionTitle(
                  title: 'Health Packages',
                  textColor: textPrimary,
                  onSeeAll: () {},
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _PackageCard(
                        isDark: isDark,
                        title: 'Package ${index + 1}',
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                if (state.doctors.isNotEmpty) ...[
                  _SectionTitle(
                    title: 'Top Specialists',
                    textColor: textPrimary,
                    onSeeAll: () => _onConsultNow(context),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.doctors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final doctor = state.doctors[index];
                        return _SpecialistCard(
                          isDark: isDark,
                          name: doctor.name,
                          specialty: doctor.specialty,
                          onTap: () {
                            context.read<PatientDashboardBloc>().add(
                              RequestConsultation(doctor.id),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                _SectionTitle(
                  title: 'Stories',
                  textColor: textPrimary,
                  onSeeAll: () {},
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _storyTitles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _StoryAvatar(
                        text: _storyTitles[index],
                        onTap: () => _onStoryTap(context, _storyTitles[index]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: 'Recent Articles',
                  textColor: textPrimary,
                  onSeeAll: onArticlesTab,
                ),
                const SizedBox(height: 8),
                if (state.articles.isEmpty)
                  _EmptyArticlesPlaceholder(isDark: isDark)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.articles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final article = state.articles[idx];
                      return _ArticleCard(
                        isDark: isDark,
                        title: article.title,
                        author: article.author,
                        onTap: () => _onArticleTap(context, article),
                      );
                    },
                  ),
                const SizedBox(height: 24),
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
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.secondary.withOpacity(0.1),
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: AppTypography.bodyMedium.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                userName,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onProfileTap,
          icon: Icon(Icons.person_outline, color: textPrimary),
          tooltip: 'Profile',
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
      label: 'Search doctors, hospitals, services',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_outlined,
                color: isDark ? AppColors.textOnDarkSecondary : Colors.black54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search doctors, hospitals, services',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : Colors.black54,
                  ),
                ),
              ),
              Icon(
                Icons.filter_list,
                color: isDark ? AppColors.textOnDarkSecondary : Colors.black54,
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
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: textColor,
            fontFamily: AppTypography.fontFamily,
          ),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('See all')),
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
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final s = services[index];
          return GestureDetector(
            onTap: () => onTap(s),
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(
                      Icons.medical_services,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    s,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.textPrimary,
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

class _ConsultationCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ConsultationCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Start online consultation',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF2E6FFF)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Online Consultation',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chat or video call with certified doctors',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed: onTap,
                  child: const Text(
                    'Consult Now',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
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

class _AppointmentPreview extends StatelessWidget {
  final bool isDark;
  final List<String> appointments;
  final VoidCallback onTap;

  const _AppointmentPreview({
    required this.isDark,
    required this.appointments,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointments',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: appointments.isEmpty
                ? Text(
                    'No upcoming appointments',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : Colors.black54,
                    ),
                  )
                : Text(
                    appointments.first,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton(onPressed: onTap, child: const Text('View all')),
          ),
        ],
      ),
    );
  }
}

class _BmiSummaryCard extends StatelessWidget {
  final bool isDark;
  final double bmi;
  final double weight;
  final double height;

  const _BmiSummaryCard({
    required this.isDark,
    required this.bmi,
    required this.weight,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monitor_heart_outlined,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMI ${bmi.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${weight.toStringAsFixed(1)} kg • ${height.toStringAsFixed(0)} cm',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
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

class _PackageCard extends StatelessWidget {
  final bool isDark;
  final String title;

  const _PackageCard({required this.isDark, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Includes consultation + tests',
            style: TextStyle(
              color: isDark ? AppColors.textOnDarkSecondary : Colors.black54,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          ElevatedButton(onPressed: () {}, child: const Text('View')),
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
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'D',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              specialty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _StoryAvatar({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.image, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String author;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.isDark,
    required this.title,
    required this.author,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: isDark ? AppColors.textOnDarkSecondary : Colors.black26,
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
