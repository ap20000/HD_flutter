import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_widgets.dart';

class UpcomingAppointmentSection extends StatefulWidget {
  const UpcomingAppointmentSection({super.key});

  @override
  State<UpcomingAppointmentSection> createState() =>
      _UpcomingAppointmentSectionState();
}

class _UpcomingAppointmentSectionState
    extends State<UpcomingAppointmentSection> {
  double _scale = 1.0;
  // TODO: Replace with actual appointment data from bloc/provider
  bool hasUpcomingAppointment = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Appointment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        hasUpcomingAppointment
            ? GestureDetector(
                onTapDown: (_) => setState(() => _scale = 0.97),
                onTapUp: (_) => setState(() => _scale = 1.0),
                onTapCancel: () => setState(() => _scale = 1.0),
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to appointment details
                },
                child: AnimatedScale(
                  scale: _scale,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutBack,
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: 20,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : AppColors.divider,
                      width: 1,
                    ),
                    child: Row(
                      children: [
                        // Date badge
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.15),
                                AppColors.primary.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'OCT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary.withOpacity(0.7),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '12',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Physical Checkup',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: isDark
                                        ? AppColors.textOnDarkSecondary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '10:30 AM',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.textOnDarkSecondary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 13,
                                    color: isDark
                                        ? AppColors.textOnDarkSecondary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Hamro Clinic',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.textOnDarkSecondary
                                            : AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: isDark
                              ? Colors.white.withOpacity(0.3)
                              : AppColors.textTertiary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.grey.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 40,
                      color: isDark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.12),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No upcoming appointments',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Book an appointment with a doctor to get started',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}
