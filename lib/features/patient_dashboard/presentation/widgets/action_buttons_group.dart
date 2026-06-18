import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../bloc/patient_dashboard_bloc.dart';
import '../bloc/patient_dashboard_event.dart';

class ActionButtonsGroup extends StatefulWidget {
  final List doctors;

  const ActionButtonsGroup({super.key, required this.doctors});

  @override
  State<ActionButtonsGroup> createState() => _ActionButtonsGroupState();
}

class _ActionButtonsGroupState extends State<ActionButtonsGroup> {
  double _primaryScale = 1.0;
  final List<double> _secondaryScales = [1.0, 1.0];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasNoDoctors = widget.doctors.isEmpty;

    return Column(
      children: [
        // Primary CTA: Consult Now
        GestureDetector(
          onTapDown: hasNoDoctors
              ? null
              : (_) => setState(() => _primaryScale = 0.97),
          onTapUp: hasNoDoctors
              ? null
              : (_) => setState(() => _primaryScale = 1.0),
          onTapCancel: hasNoDoctors
              ? null
              : () => setState(() => _primaryScale = 1.0),
          onTap: hasNoDoctors
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  if (widget.doctors.isNotEmpty) {
                    context.read<PatientDashboardBloc>().add(
                      RequestConsultation(widget.doctors[0].id),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Starting consultation request with Dr. ${widget.doctors[0].name}...',
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      ),
                    );
                  }
                },
          child: AnimatedScale(
            scale: _primaryScale,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasNoDoctors
                      ? [
                          AppColors.primary.withOpacity(0.4),
                          AppColors.primary.withOpacity(0.3),
                        ]
                      : [AppColors.primary, const Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: hasNoDoctors
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_call_rounded,
                    color: hasNoDoctors
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasNoDoctors ? 'No doctors available' : 'Consult Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: hasNoDoctors
                          ? Colors.white.withOpacity(0.6)
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Secondary buttons
        Row(
          children: [
            _SecondaryButton(
              index: 0,
              icon: Icons.calendar_month_rounded,
              label: 'Appointments',
              scale: _secondaryScales[0],
              isDark: isDark,
              onTapDown: () => setState(() => _secondaryScales[0] = 0.97),
              onTapUp: () => setState(() => _secondaryScales[0] = 1.0),
              onTap: () {
                HapticFeedback.lightImpact();
                // Navigate to appointments
              },
            ),
            const SizedBox(width: 12),
            _SecondaryButton(
              index: 1,
              icon: Icons.article_rounded,
              label: 'Records',
              scale: _secondaryScales[1],
              isDark: isDark,
              onTapDown: () => setState(() => _secondaryScales[1] = 0.97),
              onTapUp: () => setState(() => _secondaryScales[1] = 1.0),
              onTap: () {
                HapticFeedback.lightImpact();
                // Navigate to records
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final double scale;
  final bool isDark;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.index,
    required this.icon,
    required this.label,
    required this.scale,
    required this.isDark,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) => onTapUp(),
        onTapCancel: onTapUp,
        onTap: onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : AppColors.border.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isDark
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withOpacity(0.9)
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
