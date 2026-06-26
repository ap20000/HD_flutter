import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class StoryAvatar extends StatelessWidget {
  final String text;
  final String? avatarUrl;
  final bool isYourStory;
  final bool hasStories;
  final VoidCallback onTap;

  const StoryAvatar({
    super.key,
    required this.text,
    this.avatarUrl,
    this.isYourStory = false,
    this.hasStories = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatarChild;
    if (isYourStory) {
      final absoluteUrl = avatarUrl != null && avatarUrl!.isNotEmpty
          ? (avatarUrl!.startsWith('http')
              ? avatarUrl!
              : '${ApiConstants.baseUrl}$avatarUrl')
          : null;

      avatarChild = Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            backgroundImage: absoluteUrl != null ? NetworkImage(absoluteUrl) : null,
            child: absoluteUrl == null
                ? Icon(
                    Icons.person,
                    color: isDark ? Colors.white60 : Colors.black45,
                    size: 28,
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      );
    } else {
      final absoluteUrl = avatarUrl != null && avatarUrl!.isNotEmpty
          ? (avatarUrl!.startsWith('http')
              ? avatarUrl!
              : '${ApiConstants.baseUrl}$avatarUrl')
          : null;

      avatarChild = CircleAvatar(
        radius: 28,
        backgroundColor: Colors.grey.withOpacity(0.1),
        backgroundImage: absoluteUrl != null ? NetworkImage(absoluteUrl) : null,
        child: absoluteUrl == null
            ? Icon(
                Icons.person,
                color: isDark ? Colors.white60 : Colors.black45,
                size: 28,
              )
            : null,
      );
    }

    Widget borderWrapper;
    if (isYourStory) {
      borderWrapper = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: avatarChild,
      );
    } else if (hasStories) {
      borderWrapper = Container(
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Colors.purple,
              Colors.pink,
              Colors.orange,
              Colors.yellow,
              Colors.purple
            ],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
            shape: BoxShape.circle,
          ),
          child: avatarChild,
        ),
      );
    } else {
      borderWrapper = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: avatarChild,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            borderWrapper,
            const SizedBox(height: 8),
            Text(
              text,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontFamily: AppTypography.fontFamily,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class StoryShimmer extends StatelessWidget {
  const StoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 48,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
