import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamro_doctor_mobile/features/consultation_room/presentation/pages/consultation_room_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../../../features/auth/presentation/pages/profile_page.dart';
import '../../../../injection_container.dart';
import '../bloc/doctor_dashboard_bloc.dart';

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


class DoctorDashboardPage extends StatefulWidget {
  final User user;

  const DoctorDashboardPage({super.key, required this.user});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<DoctorDashboardBloc>()..add(LoadDoctorDashboardData()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _buildBody(),
        bottomNavigationBar: _DoctorBottomNav(
          selectedIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return BlocBuilder<DoctorDashboardBloc, DoctorDashboardState>(
          builder: (context, state) {
            if (state is DoctorDashboardLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            } else if (state is DoctorDashboardError) {
              return _ErrorView(message: state.message);
            } else if (state is DoctorDashboardLoaded) {
              return _DoctorDashboardBody(user: widget.user, state: state);
            }
            return const SizedBox();
          },
        );
      case 1:
        return const _DoctorPlaceholderPage(
          title: 'Schedule',
          icon: Icons.calendar_month_rounded,
        );
      case 2:
        return const _DoctorPlaceholderPage(
          title: 'Messages',
          icon: Icons.message_rounded,
        );
      case 3:
        return ProfilePage(user: widget.user);
      default:
        return const SizedBox();
    }
  }
}

class _DoctorDashboardBody extends StatelessWidget {
  final User user;
  final DoctorDashboardLoaded state;

  const _DoctorDashboardBody({required this.user, required this.state});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<DoctorDashboardBloc>().add(LoadDoctorDashboardData()),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _DoctorHeader(user: user, isOnline: state.isOnline),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),
                _PerformanceStats(stats: state.stats),
                const SizedBox(height: 32),
                SectionHeader(
                  title: 'Today\'s Consultations',
                  actionText: 'Queue',
                  onAction: () {},
                ),
                const SizedBox(height: 16),
                _PatientQueue(consultations: state.consultations),
                const SizedBox(height: 32),
                SectionHeader(
                  title: 'My Workplaces',
                  actionText: 'Add New',
                  onAction: () {},
                ),
                const SizedBox(height: 16),
                _WorkplacesList(workplaces: state.workplaces),
                const SizedBox(height: 32),
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 16),
                const _QuickActionsGrid(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorHeader extends StatelessWidget {
  final User user;
  final bool isOnline;

  const _DoctorHeader({required this.user, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      backgroundColor: AppColors.background,
      elevation: 0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primarySoft,
                    backgroundImage: _getAvatarBytes(user.avatar) != null
                        ? MemoryImage(_getAvatarBytes(user.avatar)!)
                        : null,
                    child: _getAvatarBytes(user.avatar) == null
                        ? const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 35,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 14,
                      width: 14,
                      decoration: BoxDecoration(
                        color: isOnline ? AppColors.secondary : AppColors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${user.name.split(' ')[0]}',
                    style: AppTypography.h2,
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(
                    text: isOnline ? 'Online' : 'Offline',
                    color: isOnline
                        ? AppColors.secondary
                        : AppColors.textTertiary,
                  ),
                ],
              ),
              const Spacer(),
              _StatusToggle(isOnline: isOnline),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final bool isOnline;
  const _StatusToggle({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: isOnline,
      activeColor: AppColors.secondary,
      onChanged: (val) {
        context.read<DoctorDashboardBloc>().add(ToggleOnlineStatus(val));
      },
    );
  }
}

class _PerformanceStats extends StatelessWidget {
  final dynamic stats;
  const _PerformanceStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Earnings',
            value: 'Rs. ${stats.netEarnings.toInt()}',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Consults',
            value: '${stats.noOfConsultations}',
            icon: Icons.people_outline,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      color: color.withOpacity(0.05),
      border: Border.all(color: color.withOpacity(0.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(value, style: AppTypography.h2),
          Text(label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

class _PatientQueue extends StatelessWidget {
  final List consultations;
  const _PatientQueue({required this.consultations});

  @override
  Widget build(BuildContext context) {
    if (consultations.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_note_outlined,
                color: AppColors.textTertiary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No consultations scheduled',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: consultations
          .map((cons) => _PatientCard(consultation: cons))
          .toList(),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final dynamic consultation;
  const _PatientCard({required this.consultation});

  @override
  Widget build(BuildContext context) {
    final bool isPending = consultation.status == 'pending';
    final bool isActive = consultation.status == 'active';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        onTap: isActive
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConsultationRoomPage(
                      consultationId: consultation.id,
                      currentUserId:
                          (context
                                  .findAncestorWidgetOfExactType<
                                    DoctorDashboardPage
                                  >())
                              ?.user
                              .id ??
                          '',
                      otherUserName: consultation.patientName ?? 'Patient',
                    ),
                  ),
                );
              }
            : null,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isPending ? AppColors.reportCard.withOpacity(0.2) : AppColors.divider,
              child: Icon(
                isPending ? Icons.notification_important_rounded : Icons.person,
                color: isPending ? AppColors.reportCard : AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    consultation.patientName ?? 'New Patient',
                    style: AppTypography.titleMedium,
                  ),
                  Text(
                    isPending ? 'Wants to consult' : 'Active Session',
                    style: AppTypography.bodySmall.copyWith(
                      color: isPending ? AppColors.reportCard : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isPending) ...[
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                onPressed: () {
                  context.read<DoctorDashboardBloc>().add(
                    RespondToRequest(consultation.id, 'active'),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                onPressed: () {
                  context.read<DoctorDashboardBloc>().add(
                    RespondToRequest(consultation.id, 'cancelled'),
                  );
                },
              ),
            ] else ...[
              StatusBadge(
                text: consultation.status.toUpperCase(),
                color: isActive ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkplacesList extends StatelessWidget {
  final List workplaces;
  const _WorkplacesList({required this.workplaces});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: workplaces.isEmpty ? 1 : workplaces.length,
        itemBuilder: (context, index) {
          if (workplaces.isEmpty) {
            return AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: const Center(child: Text('No workplaces added yet')),
            );
          }
          final wp = workplaces[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    wp.name,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(wp.address, style: AppTypography.bodySmall, maxLines: 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionItem(
          icon: Icons.edit_note_rounded,
          label: 'Article',
          color: AppColors.reportCard,
        ),
        _ActionItem(
          icon: Icons.add_a_photo_outlined,
          label: 'Story',
          color: AppColors.secondary,
        ),
        _ActionItem(
          icon: Icons.history_rounded,
          label: 'History',
          color: AppColors.primary,
        ),
        _ActionItem(
          icon: Icons.settings_outlined,
          label: 'Settings',
          color: AppColors.textTertiary,
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActionItem({
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
          borderRadius: 20,
          color: color.withOpacity(0.1),
          border: Border.all(color: Colors.transparent),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 10),
        Text(label, style: AppTypography.labelLarge),
      ],
    );
  }
}

class _DoctorBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _DoctorBottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavIcon(
            icon: Icons.dashboard_rounded, 
            isSelected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavIcon(
            icon: Icons.calendar_month_rounded, 
            isSelected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavIcon(
            icon: Icons.message_rounded, 
            isSelected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavIcon(
            icon: Icons.person_rounded, 
            isSelected: selectedIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon, 
    required this.onTap, 
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Icon(
          icon,
          color: isSelected ? AppColors.white : AppColors.grey,
          size: 28,
        ),
      ),
    );
  }
}

class _DoctorPlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _DoctorPlaceholderPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                '$title Coming Soon',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We are building this premium module to bring world-class healthcare tools directly to your screen.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(message, style: AppTypography.bodyLarge),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.read<DoctorDashboardBloc>().add(
              LoadDoctorDashboardData(),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
