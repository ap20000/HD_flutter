import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../features/auth/domain/entities/user.dart';
import '../../../../features/auth/presentation/pages/profile_page.dart';
import '../../../../injection_container.dart';
import '../bloc/patient_dashboard_bloc.dart';
import '../bloc/patient_dashboard_event.dart';
import '../bloc/patient_dashboard_state.dart';

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
    return BlocProvider(
      create: (context) => sl<PatientDashboardBloc>()..add(LoadDashboardData()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // Ultra premium light backdrop
        body: SafeArea(
          child: _buildBody(),
        ),
        bottomNavigationBar: _PremiumBottomNav(
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
        return BlocBuilder<PatientDashboardBloc, PatientDashboardState>(
          builder: (context, state) {
            if (state is PatientDashboardLoading) {
              return const _LoadingView();
            } else if (state is PatientDashboardError) {
              return _ErrorView(message: state.message);
            } else if (state is PatientDashboardLoaded) {
              return _DashboardBody(user: widget.user, state: state);
            }
            return const SizedBox();
          },
        );
      case 1:
        return const _PatientPlaceholderPage(
          title: 'Consultations',
          icon: Icons.assignment_outlined,
        );
      case 2:
        return const _PatientPlaceholderPage(
          title: 'Articles',
          icon: Icons.article_outlined,
        );
      case 3:
        return ProfilePage(user: widget.user);
      default:
        return const SizedBox();
    }
  }
}

class _DashboardBody extends StatelessWidget {
  final User user;
  final PatientDashboardLoaded state;

  const _DashboardBody({required this.user, required this.state});

  @override
  Widget build(BuildContext context) {
    final double userBmi = state.latestRecord?.bmi ?? 28.57; // Fallback to mockup value for rendering
    final double userWeight = state.latestRecord?.weight ?? 66.0;
    final double userHeight = state.latestRecord?.height ?? 152.0;

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
                const SizedBox(height: 16),
                _BmiHealthCard(
                  bmi: userBmi,
                  weight: userWeight,
                  height: userHeight,
                ),
                const SizedBox(height: 24),
                _ActionButtonsGroup(doctors: state.doctors),
                const SizedBox(height: 28),
                _SpecialistsSection(doctors: state.doctors),
                const SizedBox(height: 28),
                const _UpcomingAppointmentSection(),
                const SizedBox(height: 40),
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
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=150'), // Professional avatar placeholder
                backgroundColor: AppColors.primarySoft,
              ),
            ),
            const SizedBox(width: 12),
            // Welcome Greeting
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Good morning,',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8), // Soft slate grey
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${userName.split(' ')[0]} 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF1E56FB), // Premium brand blue
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
                color: Color(0xFFEEF2F6), // Soft grey/lavender background
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

class _BmiHealthCard extends StatelessWidget {
  final double bmi;
  final double weight;
  final double height;

  const _BmiHealthCard({
    required this.bmi,
    required this.weight,
    required this.height,
  });

  String _getBmiCategory(double val) {
    if (val < 18.5) return 'Underweight';
    if (val < 25) return 'Healthy';
    if (val < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBmiColor(double val) {
    if (val < 18.5) return const Color(0xFFF59E0B); // Amber
    if (val < 25) return const Color(0xFF10B981); // Emerald
    if (val < 30) return const Color(0xFFEA580C); // Orange
    return const Color(0xFFEF4444); // Red
  }

  @override
  Widget build(BuildContext context) {
    final String category = _getBmiCategory(bmi);
    final Color categoryColor = _getBmiColor(bmi);

    return AppCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Body Mass Index',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B), // Dark slate
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        bmi.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E56FB),
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: categoryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Document/Folder Icon Button
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFF1E56FB),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Multi-Segment Gauge Track
          LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              // Map BMI values 15 to 40 linearly to percentage
              final double clampedBmi = bmi.clamp(15.0, 40.0);
              final double pointerPercentage = (clampedBmi - 15.0) / 25.0; // 0.0 to 1.0
              final double pointerPosition = pointerPercentage * totalWidth;

              return Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      // Colored Segments Row
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 7,
                          width: totalWidth,
                          child: Row(
                            children: [
                              Expanded(flex: 35, child: Container(color: const Color(0xFFF59E0B))), // Amber
                              Expanded(flex: 64, child: Container(color: const Color(0xFF10B981))), // Emerald
                              Expanded(flex: 50, child: Container(color: const Color(0xFFEA580C))), // Orange
                              Expanded(flex: 101, child: Container(color: const Color(0xFFEF4444))), // Red
                            ],
                          ),
                        ),
                      ),
                      // Pointer capsule
                      Positioned(
                        left: pointerPosition - 2.5,
                        top: -5,
                        child: Container(
                          width: 5,
                          height: 17,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A), // Dark slate/black capsule pointer
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Metric Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('15', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                      Text('18.5', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                      Text('24.9', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                      Text('29.9', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                      Text('40', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          // View Health Plan Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                _showHealthPlanDialog(context, bmi);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E56FB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'View health plan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHealthPlanDialog(BuildContext context, double bmiVal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final category = _getBmiCategory(bmiVal);
        final color = _getBmiColor(bmiVal);
        
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$category Weight Plan',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your BMI: ${bmiVal.toStringAsFixed(2)} kg/m²',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Suggestions
              _buildSuggestionItem('Balanced Diet Plan', 'Prioritize whole grain carbs, lean proteins, and double portion of fiber.', color),
              _buildSuggestionItem('Cardio Activity', 'Engage in moderate-intensity activities for at least 150 minutes per week.', color),
              _buildSuggestionItem('Hydration Goal', 'Consume at least 2.5–3 liters of water spread evenly throughout the day.', color),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E56FB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Got it, thanks!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionItem(String title, String desc, Color bulletColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: bulletColor, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtonsGroup extends StatelessWidget {
  final List doctors;
  const _ActionButtonsGroup({required this.doctors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Consult Now Primary Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              if (doctors.isNotEmpty) {
                context.read<PatientDashboardBloc>().add(RequestConsultation(doctors[0].id));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Starting consultation request with Dr. ${doctors[0].name}...')),
                );
              }
            },
            icon: const Icon(Icons.video_call_rounded, color: Colors.white, size: 22),
            label: const Text(
              'Consult Now',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E56FB),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Secondary Buttons Row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF1E56FB), size: 18),
                  label: const Text(
                    'Book Appointment',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E56FB)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E56FB), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.article_outlined, color: Color(0xFF1E56FB), size: 18),
                  label: const Text(
                    'Health Records',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E56FB)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E56FB), width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SpecialistsSection extends StatelessWidget {
  final List doctors;
  const _SpecialistsSection({required this.doctors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Specialists',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'See all',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E56FB)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: doctors.isNotEmpty ? doctors.length : 2,
            itemBuilder: (context, index) {
              final String name = doctors.isNotEmpty ? doctors[index].name : (index == 0 ? 'Dr. Aradhana' : 'Dr. Rohan');
              final String specialty = doctors.isNotEmpty ? doctors[index].specialty : (index == 0 ? 'Cardiologist' : 'Pediatrician');
              final String avatarUrl = index == 0
                  ? 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150'
                  : 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150';

              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 14),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 24,
                  border: Border.all(color: const Color(0xFFEEF2F6), width: 1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(avatarUrl),
                            backgroundColor: AppColors.primarySoft,
                          ),
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        specialty,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UpcomingAppointmentSection extends StatelessWidget {
  const _UpcomingAppointmentSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Appointment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(14),
          borderRadius: 24,
          border: Border.all(color: const Color(0xFFEEF2F6), width: 1.5),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'OCT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E56FB)),
                    ),
                    Text(
                      '12',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E56FB), height: 1.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Physical Checkup',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '10:30 AM • Hamro Clinic',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _PremiumBottomNav({required this.selectedIndex, required this.onTap});

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
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_filled, 'Home'),
          _buildNavItem(1, Icons.assignment_turned_in_outlined, 'Consultations'),
          _buildNavItem(2, Icons.library_books_outlined, 'Articles'),
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
          color: const Color(0xFF1E56FB),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(message, style: AppTypography.bodyLarge),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.read<PatientDashboardBloc>().add(
              LoadDashboardData(),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _PatientPlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PatientPlaceholderPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
