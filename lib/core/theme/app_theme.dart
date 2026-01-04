import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF131722); // TradingView dark bg
  static const Color surface = Color(0xFF1E222D);
  static const Color primary = Color(0xFF2962FF);
  
  static const Color bullish = Color(0xFF089981); // Strong Green
  static const Color bearish = Color(0xFFF23645); // Strong Red
  static const Color neutral = Color(0xFF787B86);
  
  static const Color textPrimary = Color(0xFFD1D4DC);
  static const Color textSecondary = Color(0xFF787B86);
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
        background: AppColors.background,
        error: AppColors.bearish,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      ),
      dividerColor: const Color(0xFF2A2E39),
    );
  }
}
