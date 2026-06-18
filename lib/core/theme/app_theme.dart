import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.surfacePearl, // Premium background
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor:
          AppColors.surfacePearl, // Use premium light backdrop
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.darkPrimary,
      secondary: AppColors.darkAccent,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onPrimary: AppColors.textOnDarkPrimary,
      onSecondary: AppColors.textOnDarkPrimary,
      onSurface: AppColors.textOnDarkPrimary,
      onError: AppColors.textOnDarkPrimary,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.dividerDark,
      textTheme: TextTheme(
        displayLarge: AppTypography.display.copyWith(
          color: AppColors.textOnDarkPrimary,
        ),
        headlineLarge: AppTypography.h1.copyWith(
          color: AppColors.textOnDarkPrimary,
        ),
        headlineMedium: AppTypography.h2.copyWith(
          color: AppColors.textOnDarkPrimary,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.textOnDarkPrimary,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.textOnDarkPrimary,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.textOnDarkSecondary,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.textOnDarkSecondary,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.textOnDarkSecondary,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.textOnDarkPrimary,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.textOnDarkSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.textOnDarkPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: BorderSide(color: AppColors.darkPrimary, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: AppColors.textOnDarkPrimary,
      ),
    );
  }
}
