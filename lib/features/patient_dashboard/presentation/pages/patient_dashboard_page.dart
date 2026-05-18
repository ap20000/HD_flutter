import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamro_doctor_mobile/features/consultation_room/presentation/pages/consultation_room_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../../../injection_container.dart';
import '../bloc/patient_dashboard_bloc.dart';
import '../bloc/patient_dashboard_event.dart';
import '../bloc/patient_dashboard_state.dart';

class PatientDashboardPage extends StatelessWidget {
  final User user;

  const PatientDashboardPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<PatientDashboardBloc>()..add(LoadDashboardData()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<PatientDashboardBloc, PatientDashboardState>(
          builder: (context, state) {
            if (state is PatientDashboardLoading) {
              return const _LoadingView();
            } else if (state is PatientDashboardError) {
              return _ErrorView(message: state.message);
            } else if (state is PatientDashboardLoaded) {
              return _DashboardBody(user: user, state: state);
            }
            return const SizedBox();
          },
        ),
        floatingActionButton: _PrimaryActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _ModernBottomNav(),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final User user;
  final PatientDashboardLoaded state;

  const _DashboardBody({required this.user, required this.state});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<PatientDashboardBloc>().add(LoadDashboardData()),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _SliverHeader(userName: user.name),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                const _SearchField(),
                const SizedBox(height: 24),
                _HealthSummaryCard(bmi: state.latestRecord?.bmi ?? 0),
                const SizedBox(height: 32),
                const SectionHeader(title: 'Quick Services'),
                const SizedBox(height: 16),
                const _QuickServicesGrid(),
                const SizedBox(height: 32),
                if (state.consultations.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Active Consultations',
                    actionText: 'History',
                    onAction: () {},
                  ),
                  const SizedBox(height: 16),
                  _ConsultationsScroll(consultations: state.consultations),
                  const SizedBox(height: 32),
                ],
                SectionHeader(
                  title: 'Top Specialists',
                  actionText: 'View All',
                  onAction: () {},
                ),
                const SizedBox(height: 16),
                _DoctorsScroll(doctors: state.doctors),
                const SizedBox(height: 32),
                const SectionHeader(title: 'Health Insights'),
                const SizedBox(height: 16),
                ...state.articles.map(
                  (article) => _ArticleCard(article: article),
                ),
                const SizedBox(height: 120), // Padding for FAB and Nav
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverHeader extends StatelessWidget {
  final String userName;
  const _SliverHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: AppColors.background,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good Morning,', style: AppTypography.bodyLarge),
                  Text(
                    '${userName.split(' ')[0]} 👋',
                    style: AppTypography.display,
                  ),
                ],
              ),
              const Spacer(),
              _ActionIconButton(icon: Icons.notifications_none_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthSummaryCard extends StatelessWidget {
  final double bmi;
  const _HealthSummaryCard({required this.bmi});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.appointmentCard,
      padding: const EdgeInsets.all(24),
      border: Border.all(color: Colors.transparent),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusBadge(
                  text: 'Health Summary',
                  color: Colors.white,
                  isSolid: false,
                ),
                const SizedBox(height: 16),
                Text(
                  bmi > 0
                      ? 'Your BMI is ${bmi.toStringAsFixed(1)}'
                      : 'Complete your health profile',
                  style: AppTypography.h2.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  bmi > 0
                      ? 'You are in the ${_getBmiCategory(bmi)} range.'
                      : 'Calculate your health score now.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _HealthProgressCircle(value: bmi / 40),
        ],
      ),
    );
  }

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}

class _HealthProgressCircle extends StatelessWidget {
  final double value;
  const _HealthProgressCircle({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      width: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const Icon(Icons.favorite, color: Colors.white, size: 30),
        ],
      ),
    );
  }
}

class _QuickServicesGrid extends StatelessWidget {
  const _QuickServicesGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ServiceItem(
          icon: Icons.calendar_today_outlined,
          label: 'Bookings',
          color: AppColors.appointmentCard,
        ),
        _ServiceItem(
          icon: Icons.receipt_long_outlined,
          label: 'Reports',
          color: AppColors.reportCard,
        ),
        _ServiceItem(
          icon: Icons.medical_services_outlined,
          label: 'Pharmacy',
          color: AppColors.pharmacyCard,
        ),
        _ServiceItem(
          icon: Icons.bloodtype_outlined,
          label: 'Blood',
          color: AppColors.error,
        ),
      ],
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ServiceItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 24,
          color: color.withOpacity(0.08),
          border: Border.all(color: Colors.transparent),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(label, style: AppTypography.labelLarge),
      ],
    );
  }
}

class _DoctorsScroll extends StatelessWidget {
  final List doctors;
  const _DoctorsScroll({required this.doctors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          return Container(
            width: 170,
            margin: const EdgeInsets.only(right: 16),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: AppColors.primarySoft,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: VerifiedBadge(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    doctor.name,
                    style: AppTypography.titleMedium,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialty,
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  _RatingBadge(rating: doctor.rating),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<PatientDashboardBloc>().add(RequestConsultation(doctor.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Consultation request sent!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Request', style: TextStyle(fontSize: 12)),
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

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
          const SizedBox(width: 4),
          Text(
            rating.toString(),
            style: AppTypography.labelMedium.copyWith(color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final dynamic article;
  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.article_outlined,
                color: AppColors.textTertiary,
                size: 40,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge(text: 'Health Tip', color: AppColors.secondary),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    style: AppTypography.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '5 min read • By ${article.author}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 16,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search doctors, services...',
          hintStyle: AppTypography.bodyMedium,
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
          suffixIcon: const Icon(Icons.tune_rounded, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  const _ActionIconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      borderRadius: 12,
      child: Icon(icon, color: AppColors.textPrimary, size: 24),
    );
  }
}

class _ConsultationsScroll extends StatelessWidget {
  final List consultations;
  const _ConsultationsScroll({required this.consultations});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: consultations.length,
        itemBuilder: (context, index) {
          final item = consultations[index];
          return Container(
            width: 260,
            margin: const EdgeInsets.only(right: 16),
            child: AppCard(
              color: AppColors.primarySoft,
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConsultationRoomPage(
                      consultationId: item.id,
                      currentUserId:
                          (context
                                  .findAncestorWidgetOfExactType<
                                    PatientDashboardPage
                                  >())
                              ?.user
                              .id ??
                          '',
                      otherUserName: item.doctorName,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.white,
                    child: Icon(Icons.videocam, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.doctorName, style: AppTypography.titleMedium),
                        Text(
                          'Status: ${item.status}',
                          style: AppTypography.bodySmall,
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

class _ModernBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavIcon(icon: Icons.home_filled, label: 'Home', isSelected: true),
            _NavIcon(icon: Icons.calendar_today_outlined, label: 'Schedule'),
            const SizedBox(width: 40), // Space for FAB
            _NavIcon(icon: Icons.chat_bubble_outline, label: 'Chat'),
            _NavIcon(icon: Icons.person_outline, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _NavIcon({
    required this.icon,
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textTertiary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {},
      backgroundColor: AppColors.primary,
      elevation: 4,
      child: const Icon(Icons.add, size: 30, color: Colors.white),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
      ),
    );
  }
}
