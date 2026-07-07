import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Border radius
  static const double radiusSm  = 8;
  static const double radiusMd  = 10;
  static const double radiusLg  = 14;
  static const double radiusXl  = 16;
  static const double radius2xl = 20;

  // Spacing
  static const double sp4  = 4;
  static const double sp8  = 8;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;

  // Card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(radiusXl),
    border: Border.all(color: AppColors.border, width: 1),
  );

  // Subtle shadow cho card nổi
  static BoxDecoration get cardElevated => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(radiusXl),
    border: Border.all(color: AppColors.border, width: 1),
    boxShadow: const [
      BoxShadow(
        color: Color(0x080F172A),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
    );
  }
}
