import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppDesignTokens.primary,
      scaffoldBackgroundColor: AppDesignTokens.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppDesignTokens.primary,
        onPrimary: Colors.white,
        secondary: AppDesignTokens.secondary,
        onSecondary: Colors.white,
        error: AppDesignTokens.error,
        onError: Colors.white,
        surface: AppDesignTokens.lightSurface,
        onSurface: AppDesignTokens.lightTextPrimary,
        surfaceContainerHighest: AppDesignTokens.lightSurfaceCard,
      ),
      cardTheme: CardThemeData(
        color: AppDesignTokens.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          side: const BorderSide(color: AppDesignTokens.lightBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppDesignTokens.lightTextPrimary),
        titleTextStyle: TextStyle(
          color: AppDesignTokens.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppDesignTokens.lightTextPrimary,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppDesignTokens.lightTextPrimary,
          letterSpacing: -0.8,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppDesignTokens.lightTextPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppDesignTokens.lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppDesignTokens.lightTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppDesignTokens.lightTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDesignTokens.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.spaceLg,
            vertical: AppDesignTokens.spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDesignTokens.lightSurfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: const BorderSide(color: AppDesignTokens.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: const BorderSide(color: AppDesignTokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: const BorderSide(color: AppDesignTokens.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spaceMd,
          vertical: AppDesignTokens.spaceMd,
        ),
        labelStyle: const TextStyle(color: AppDesignTokens.lightTextSecondary),
        hintStyle: const TextStyle(color: AppDesignTokens.lightTextSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppDesignTokens.primary,
      scaffoldBackgroundColor: AppDesignTokens.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppDesignTokens.primary,
        onPrimary: Colors.white,
        secondary: AppDesignTokens.secondary,
        onSecondary: Colors.white,
        error: AppDesignTokens.error,
        onError: Colors.white,
        surface: AppDesignTokens.darkSurface,
        onSurface: AppDesignTokens.darkTextPrimary,
        surfaceContainerHighest: AppDesignTokens.darkSurfaceCard,
      ),
      cardTheme: CardThemeData(
        color: AppDesignTokens.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          side: const BorderSide(color: AppDesignTokens.darkBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppDesignTokens.darkTextPrimary),
        titleTextStyle: TextStyle(
          color: AppDesignTokens.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppDesignTokens.darkTextPrimary,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppDesignTokens.darkTextPrimary,
          letterSpacing: -0.8,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppDesignTokens.darkTextPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppDesignTokens.darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppDesignTokens.darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppDesignTokens.darkTextSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDesignTokens.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.spaceLg,
            vertical: AppDesignTokens.spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDesignTokens.darkSurfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: const BorderSide(color: AppDesignTokens.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: const BorderSide(color: AppDesignTokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          borderSide: const BorderSide(color: AppDesignTokens.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spaceMd,
          vertical: AppDesignTokens.spaceMd,
        ),
        labelStyle: const TextStyle(color: AppDesignTokens.darkTextSecondary),
        hintStyle: const TextStyle(color: AppDesignTokens.darkTextSecondary),
      ),
    );
  }
}
