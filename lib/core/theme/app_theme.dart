import 'package:flutter/material.dart';

class AppColors {
  // =========================
  // Background System
  // =========================
  static const Color background = Color(0xFF0E1116);
  // Carbon black (ultra premium)

  static const Color surface = Color(0xFF161B22);
  // Cards, sheets, bottom bars

  static const Color surfaceRaised = Color(0xFF1E2633);
  // Elevated UI (pattern cards)

  static const Color divider = Color(0xFF2A3240);

  // =========================
  // Brand & Primary Actions
  // =========================
  static const Color primary = Color(0xFF00E0A4);
  // Emerald green (brand identity)

  static const Color primarySoft = Color(0xFF7CF5D0);
  // Hover, focus, charts

  static const Color accent = Color(0xFFE6B566);
  // Gold accent (premium, rewards, CTA)

  // =========================
  // Market Direction Colors
  // =========================
  static const Color bullish = Color(0xFF00C896);
  // Profit green

  static const Color bearish = Color(0xFFE5533D);
  // Muted red (less aggressive)

  static const Color neutral = Color(0xFF9AA4B2);
  // Sideways market

  // =========================
  // Text Hierarchy
  // =========================
  static const Color textPrimary = Color(0xFFE6EDF3);
  // Headings

  static const Color textSecondary = Color(0xFFB1BAC4);
  // Subtext

  static const Color textMuted = Color(0xFF7D8590);
  // Hints, disabled

  // =========================
  // Status & Feedback
  // =========================
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF4C430);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF95A5A6);
  // =========================
  // Light Theme Colors
  // =========================
  static const Color backgroundLight = Color(0xFFF6F8FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF24292F);
  static const Color textSecondaryLight = Color(0xFF57606A);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface,
      primaryColor: AppColors.primary,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.bullish,
        surface: AppColors.surface,
        error: AppColors.bearish,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
        titleLarge: TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      ),
      dividerColor: const Color(0xFF2A2E39),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: AppColors.backgroundLight,
      cardColor: AppColors.surfaceLight,
      primaryColor: AppColors.primary,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.bullish,
        surface: AppColors.surfaceLight,
        error: AppColors.bearish,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textPrimaryLight),
        bodySmall: TextStyle(color: AppColors.textSecondaryLight),
        titleLarge: TextStyle(
            color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold),
      ),
      dividerColor: const Color(0xFFD0D7DE),
    );
  }
}
