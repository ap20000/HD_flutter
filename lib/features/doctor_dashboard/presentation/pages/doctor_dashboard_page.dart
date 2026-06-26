import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:hamro_doctor_mobile/features/consultation_room/presentation/pages/consultation_room_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../../../features/auth/presentation/pages/profile_page.dart';
import '../../../../injection_container.dart';
import '../../../../core/constants/constants.dart';
import 'package:hamro_doctor_mobile/features/patient_dashboard/domain/entities/story.dart';
import 'package:hamro_doctor_mobile/features/patient_dashboard/presentation/pages/story_viewer_page.dart';
import 'package:hamro_doctor_mobile/features/patient_dashboard/presentation/widgets/story_avatar.dart';
import 'package:hamro_doctor_mobile/features/patient_dashboard/presentation/pages/add_story_page.dart';
import '../bloc/doctor_dashboard_bloc.dart';
import 'package:hamro_doctor_mobile/features/patient_dashboard/presentation/pages/posts_page.dart';

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
        backgroundColor: const Color(
          0xFFF8FAFC,
        ), // Pearl White / Light Gray backdrop
        body: SafeArea(child: _buildBody()),
        bottomNavigationBar: _PremiumDoctorBottomNav(
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
        return BlocBuilder<DoctorDashboardBloc, DoctorDashboardState>(
          builder: (context, state) {
            if (state is DoctorDashboardLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            } else if (state is DoctorDashboardError) {
              return _ErrorView(message: state.message);
            } else if (state is DoctorDashboardLoaded) {
              return _ActiveConsultationsTab(user: widget.user, state: state);
            }
            return const SizedBox();
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

class _DoctorDashboardBody extends StatefulWidget {
  final User user;
  final DoctorDashboardLoaded state;

  const _DoctorDashboardBody({required this.user, required this.state});

  @override
  State<_DoctorDashboardBody> createState() => _DoctorDashboardBodyState();
}

class _DoctorDashboardBodyState extends State<_DoctorDashboardBody> {
  List<GroupedStories> _groupedStories = [];
  bool _isLoadingStories = true;

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
      debugPrint('Error fetching stories on doctor dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoadingStories = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.state.consultations
        .where((c) => c.status == 'pending')
        .length;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DoctorDashboardBloc>().add(LoadDoctorDashboardData());
        await _fetchStories();
      },
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _SliverDoctorHeader(
            user: widget.user,
            isOnline: widget.state.isOnline,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 12),
                // Horizontal scrollable stories tray for doctors
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
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddStoryPage(user: widget.user),
                                    ),
                                  );
                                  if (result == true) {
                                    _fetchStories();
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Consultation requests are only available for patient accounts.',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                _DoctorOnlineStatusCard(isOnline: widget.state.isOnline),
                const SizedBox(height: 24),
                _PerformanceStats(
                  stats: widget.state.stats,
                  pendingCount: pendingCount,
                ),
                const SizedBox(height: 28),
                _PendingRequestsSection(
                  consultations: widget.state.consultations,
                ),
                const SizedBox(height: 28),
                const _OpdScheduleSection(),
                const SizedBox(height: 28),
                _WorkplaceSection(workplaces: widget.state.workplaces),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverDoctorHeader extends StatelessWidget {
  final User user;
  final bool isOnline;

  const _SliverDoctorHeader({required this.user, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Doctor Avatar with Online Status indicator dot
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primarySoft,
                    backgroundImage: _getAvatarBytes(user.avatar) != null
                        ? MemoryImage(_getAvatarBytes(user.avatar)!)
                        : null,
                    child: _getAvatarBytes(user.avatar) == null
                        ? const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 24,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    height: 11,
                    width: 11,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.success
                          : AppColors.textTertiary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Name Greeting
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome Back,',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Dr. ${user.name.split(' ')[0]} 🩺',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF004AC6), // Brand Navy
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Notification Bell
            Container(
              height: 44,
              width: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2F6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1E293B),
                  size: 22,
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorOnlineStatusCard extends StatelessWidget {
  final bool isOnline;

  const _DoctorOnlineStatusCard({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isOnline ? AppColors.success : AppColors.textTertiary)
                  .withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.visibility : Icons.visibility_off,
              color: isOnline ? AppColors.success : AppColors.textTertiary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isOnline ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline
                      ? 'You are visible to patients'
                      : 'You are currently hidden',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isOnline,
            activeColor: AppColors.success,
            onChanged: (val) {
              context.read<DoctorDashboardBloc>().add(ToggleOnlineStatus(val));
            },
          ),
        ],
      ),
    );
  }
}

class _PerformanceStats extends StatelessWidget {
  final dynamic stats;
  final int pendingCount;

  const _PerformanceStats({required this.stats, required this.pendingCount});

  @override
  Widget build(BuildContext context) {
    final consultationCount = stats.noOfConsultations ?? 0;

    return Row(
      children: [
        // Today's Consultations
        Expanded(
          child: _StatCard(
            label: 'Consults',
            value: '$consultationCount',
            color: const Color(0xFF004AC6),
          ),
        ),
        const SizedBox(width: 12),
        // Pending Requests
        Expanded(
          child: _StatCard(
            label: 'Pending',
            value: '$pendingCount',
            color: const Color(0xFFEA580C),
          ),
        ),
        const SizedBox(width: 12),
        // Clinical Experience
        Expanded(
          child: const _StatCard(
            label: 'Experience',
            value: '8 Yrs',
            color: Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      color: Colors.white,
      border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PendingRequestsSection extends StatelessWidget {
  final List consultations;

  const _PendingRequestsSection({required this.consultations});

  @override
  Widget build(BuildContext context) {
    final pendingConsults = consultations
        .where((c) => c.status == 'pending')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pending Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        if (pendingConsults.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            borderRadius: 24,
            border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
            child: Center(
              child: Column(
                children: const [
                  Icon(
                    Icons.event_note_outlined,
                    color: Color(0xFF94A3B8),
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No pending requests found',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...pendingConsults.map(
            (cons) => _PendingRequestCard(consultation: cons),
          ),
      ],
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  final dynamic consultation;

  const _PendingRequestCard({required this.consultation});

  @override
  Widget build(BuildContext context) {
    // Check if we are active or pending
    final bool isPending = consultation.status == 'pending';
    final bool isActive = consultation.status == 'active';

    // Mock patient details if not provided
    final String ageGender = '24 Years • Female';
    final String problem = 'Persistent Cough & Fatigue for 3 days';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(18),
        borderRadius: 24,
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
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
                      otherUserAvatar: consultation.patientAvatar,
                      isDoctor: true,
                    ),
                  ),
                );
              }
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFE8F0FF),
                  child: Icon(Icons.person, color: Color(0xFF004AC6), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consultation.patientName ?? 'New Patient',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ageGender,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF004AC6),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Problem:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              problem,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<DoctorDashboardBloc>().add(
                            RespondToRequest(consultation.id, 'cancelled'),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<DoctorDashboardBloc>().add(
                            RespondToRequest(consultation.id, 'active'),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpdScheduleSection extends StatelessWidget {
  const _OpdScheduleSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OPD Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 24,
          border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF004AC6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '4:00 PM - 8:00 PM',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Next Session at Hamro Clinic',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkplaceSection extends StatelessWidget {
  final List workplaces;

  const _WorkplaceSection({required this.workplaces});

  @override
  Widget build(BuildContext context) {
    final String name = workplaces.isNotEmpty
        ? workplaces[0].name
        : 'Hamro Clinic';
    final String address = workplaces.isNotEmpty
        ? workplaces[0].address
        : 'Kathmandu, Nepal';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Workplace',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Add New',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004AC6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 24,
          border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF004AC6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumDoctorBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _PremiumDoctorBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_filled, 'Home'),
          _buildNavItem(
            1,
            Icons.assignment_turned_in_outlined,
            'Consultations',
          ),
          _buildNavItem(2, Icons.feed_outlined, 'Posts'),
          _buildNavItem(3, Icons.person_outline_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = selectedIndex == index;

    if (isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF004AC6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
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
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
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

class _ActiveConsultationsTab extends StatelessWidget {
  final User user;
  final DoctorDashboardLoaded state;

  const _ActiveConsultationsTab({required this.user, required this.state});

  String _formatMessageTime(String? timestampStr) {
    if (timestampStr == null || timestampStr.isEmpty) return '';
    try {
      final date = DateTime.parse(timestampStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) {
        final hour = date.hour > 12
            ? date.hour - 12
            : (date.hour == 0 ? 12 : date.hour);
        final minute = date.minute.toString().padLeft(2, '0');
        final period = date.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $period';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        switch (date.weekday) {
          case 1:
            return 'Mon';
          case 2:
            return 'Tue';
          case 3:
            return 'Wed';
          case 4:
            return 'Thu';
          case 5:
            return 'Fri';
          case 6:
            return 'Sat';
          default:
            return 'Sun';
        }
      } else {
        return '${date.month}/${date.day}';
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeConsults = state.consultations
        .where((c) => c.status == 'active')
        .toList();

    final List<Widget> activeWidgets = [];
    if (activeConsults.isEmpty) {
      activeWidgets.add(
        _LiveConsultationCard(
          name: 'Samyog',
          recentMessage:
              "I'm feeling much better, but I did notice a slight palpitation...",
          timeText: '10:30 AM',
          typeIcon: Icons.chat_bubble_outline_rounded,
          badgeColor: const Color(0xFF004AC6),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConsultationRoomPage(
                  consultationId: 'samyog_text_session',
                  currentUserId: user.id,
                  otherUserName: 'Samyog',
                  isDoctor: true,
                ),
              ),
            );
          },
        ),
      );
      activeWidgets.add(const SizedBox(height: 12));
      activeWidgets.add(
        _LiveConsultationCard(
          name: 'Aditi',
          recentMessage: 'Active Video Call Session',
          timeText: 'Yesterday',
          typeIcon: Icons.videocam_outlined,
          badgeColor: const Color(0xFF10B981),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConsultationRoomPage(
                  consultationId: 'aditi_video_session',
                  currentUserId: user.id,
                  otherUserName: 'Aditi',
                  isDoctor: true,
                ),
              ),
            );
          },
        ),
      );
    } else {
      for (final consult in activeConsults) {
        final lastMsg = consult.messages.isNotEmpty
            ? consult.messages.last['text'] as String
            : 'Consultation started. Tap to chat.';

        final timeText = consult.messages.isNotEmpty
            ? _formatMessageTime(consult.messages.last['timestamp'] as String?)
            : _formatMessageTime(consult.createdAt);

        final isVideo = consult.id.contains('video');
        final typeIcon = isVideo
            ? Icons.videocam_outlined
            : Icons.chat_bubble_outline_rounded;
        final badgeColor = isVideo
            ? const Color(0xFF10B981)
            : const Color(0xFF004AC6);

        activeWidgets.add(
          _LiveConsultationCard(
            name: consult.patientName ?? 'Patient',
            patientAvatar: consult.patientAvatar,
            recentMessage: lastMsg,
            timeText: timeText,
            typeIcon: typeIcon,
            badgeColor: badgeColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConsultationRoomPage(
                    consultationId: consult.id,
                    currentUserId: user.id,
                    otherUserName: consult.patientName ?? 'Patient',
                    otherUserAvatar: consult.patientAvatar,
                    isDoctor: true,
                    initialPrescription: consult.prescription,
                  ),
                ),
              ).then((_) {
                if (context.mounted) {
                  context.read<DoctorDashboardBloc>().add(
                    LoadDoctorDashboardData(),
                  );
                }
              });
            },
          ),
        );
        activeWidgets.add(const SizedBox(height: 12));
      }
      if (activeWidgets.isNotEmpty) {
        activeWidgets.removeLast();
      }
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<DoctorDashboardBloc>().add(LoadDoctorDashboardData()),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const _SliverConsultationsHeader(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF004AC6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Live Now',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...activeWidgets,
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverConsultationsHeader extends StatelessWidget {
  const _SliverConsultationsHeader();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          children: [
            const Text(
              'Active Consultations',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 22,
                color: Color(0xFF004AC6),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              height: 44,
              width: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2F6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF1E293B),
                  size: 22,
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveConsultationCard extends StatelessWidget {
  final String name;
  final String? patientAvatar;
  final String recentMessage;
  final String timeText;
  final IconData typeIcon;
  final Color badgeColor;
  final VoidCallback onTap;

  const _LiveConsultationCard({
    required this.name,
    this.patientAvatar,
    required this.recentMessage,
    required this.timeText,
    required this.typeIcon,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarBytes = _getAvatarBytes(patientAvatar);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 18,
      color: Colors.white,
      border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with badge
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: badgeColor.withOpacity(0.08),
                backgroundImage: avatarBytes != null
                    ? MemoryImage(avatarBytes)
                    : null,
                child: avatarBytes == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'P',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(typeIcon, color: Colors.white, size: 11),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          // Name and Message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeText,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  recentMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
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
