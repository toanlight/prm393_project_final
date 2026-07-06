import 'package:flutter/material.dart';

class AppDesignTokens {
  // Brand Colors (Vibrant, Harmanious HSL-like palettes)
  static const Color primary = Color(0xFF6366F1);      // Indigo / Deep Violet
  static const Color primaryDark = Color(0xFF4F46E5);  // Darker Indigo
  static const Color secondary = Color(0xFF06B6D4);    // Cyan / Ocean Blue
  static const Color accent = Color(0xFFEC4899);       // Pink / Accent Rose

  // Semantic Colors
  static const Color success = Color(0xFF10B981);      // Vibrant Emerald Green
  static const Color warning = Color(0xFFF59E0B);      // Amber Orange
  static const Color error = Color(0xFFEF4444);        // Bright Coral Red
  static const Color info = Color(0xFF3B82F6);         // Bright Blue

  // Light Mode Colors (Sleek Slate/Zinc)
  static const Color lightBackground = Color(0xFFF8FAFC); // Zinc 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF1F5F9); // Zinc 100
  static const Color lightTextPrimary = Color(0xFF0F172A); // Zinc 900
  static const Color lightTextSecondary = Color(0xFF475569); // Zinc 600
  static const Color lightBorder = Color(0xFFE2E8F0); // Zinc 200

  // Dark Mode Colors (Premium Obsidian & Slate Blue)
  static const Color darkBackground = Color(0xFF090D16);  // Obsidian Blue-Black
  static const Color darkSurface = Color(0xFF0F172A);     // Slate 900
  static const Color darkSurfaceCard = Color(0xFF1E293B); // Slate 800
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Zinc 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkBorder = Color(0xFF334155); // Slate 700

  // Gradients (Premium, glowing)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF090D16), Color(0xFF0B1528)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radius2Xl = 32.0;

  // Spacing (Logical Paddings/Margins)
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2Xl = 48.0;

  // Shadows
  static List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> darkShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 5,
      offset: const Offset(0, 2),
    ),
  ];

  // Glassmorphic properties
  static Color glassBgLight = Colors.white.withOpacity(0.7);
  static Color glassBorderLight = Colors.white.withOpacity(0.4);
  static Color glassBgDark = const Color(0xFF0F172A).withOpacity(0.7);
  static Color glassBorderDark = const Color(0xFF334155).withOpacity(0.3);
}
