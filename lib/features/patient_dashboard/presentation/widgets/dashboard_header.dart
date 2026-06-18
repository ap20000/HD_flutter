import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;

  const DashboardHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName = userName.split(' ').first;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with status indicator
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: const NetworkImage(
                      'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=150',
                    ),
                    backgroundColor: AppColors.primarySoft,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
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
            const SizedBox(width: 12),
            // Greeting
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Good morning',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$firstName 👋',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.white : AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Notification bell with badge
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                // Handle notifications
              },
              child: Stack(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.07)
                          : AppColors.primarySoft.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                  // Notification badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
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
