import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Stitch Design System
  static const Color primary = Color(0xFF004AC6); // Soft Navy
  static const Color primarySoft = Color(0xFFDBE1FF);
  
  static const Color secondary = Color(0xFF006C49); // Health Emerald/Green
  static const Color secondarySoft = Color(0xFF6CF8BB);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFEA580C);
  static const Color error = Color(0xFFBA1A1A);
  static const Color info = Color(0xFF2D9CDB);

  // Neutral Palette - Pearl & Navy
  static const Color background = Color(0xFFFAF8FF);
  static const Color white = Colors.white;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF131B2E);
  static const Color textSecondary = Color(0xFF434655);
  static const Color textTertiary = Color(0xFF737686);
  
  static const Color border = Color(0xFFC3C6D7);
  static const Color divider = Color(0xFFEAEDFF);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color black = Color(0xFF121212);

  // Specialized BMI & Status Colors
  static const Color bmiUnderweight = Color(0xFFF59E0B);
  static const Color bmiHealthy = Color(0xFF10B981);
  static const Color bmiOverweight = Color(0xFFEA580C);
  static const Color bmiObese = Color(0xFFDC2626);
  static const Color surfacePearl = Color(0xFFF8FAFC);
  static const Color statusOnline = Color(0xFF10B981);

  // Fallbacks
  static const Color appointmentCard = Color(0xFF004AC6);
  static const Color reportCard = Color(0xFF7B61FF);
  static const Color pharmacyCard = Color(0xFFFF9F43);
}
