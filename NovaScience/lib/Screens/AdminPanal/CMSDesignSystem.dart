import 'package:flutter/material.dart';

/// Design system for the Course Management System
/// This class defines all design tokens: colors, typography, spacing, etc.
class CMSDesignSystem {
  // Color Palette
  static const Color primaryGreen = Color(0xFF11261F);
  static const Color primaryBlue = Color(0xFF123755);
  static const Color accentMaroon = Color(0xFF722626);

  // Extended palette - lighter and darker variants
  static const Color lightGreen = Color(0xFF1E3F33);
  static const Color darkGreen = Color(0xFF0A1915);
  static const Color lightBlue = Color(0xFF1D517D);
  static const Color darkBlue = Color(0xFF0A243B);
  static const Color lightMaroon = Color(0xFF8F3F3F);
  static const Color darkMaroon = Color(0xFF5A1E1E);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color disabledBackground = Color(0xFFF5F5F5);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFF5F5F5);
  static const Color textOnAccent = Color(0xFFF5F5F5);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // Course status-specific colors
  static const Color freeCourseColor = lightGreen;
  static const Color premiumCourseColor = primaryBlue;
  static const Color pendingCourseColor = accentMaroon;

  // Spacing
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // Border radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusCircular = 100.0;

  // Elevation
  static const List<BoxShadow> shadowLow = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowHigh = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 3),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowXHigh = [
    BoxShadow(
      color: Color(0x29000000),
      offset: Offset(0, 6),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // Animation durations
  static const Duration durationShort = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationLong = Duration(milliseconds: 500);
}

/// Theme data for the Course Management System
/// This class provides the theme data used throughout the app
class CMSTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: CMSDesignSystem.primaryGreen,
        secondary: CMSDesignSystem.primaryBlue,
        tertiary: CMSDesignSystem.accentMaroon,
        surface: CMSDesignSystem.cardBackground,
        background: CMSDesignSystem.background,
        error: CMSDesignSystem.error,
        onPrimary: CMSDesignSystem.textOnPrimary,
        onSecondary: CMSDesignSystem.textOnPrimary,
        onSurface: CMSDesignSystem.textPrimary,
        onBackground: CMSDesignSystem.textPrimary,
        onError: CMSDesignSystem.textOnPrimary,
        brightness: Brightness.light,
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: CMSDesignSystem.textPrimary,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: CMSDesignSystem.textPrimary,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: CMSDesignSystem.textPrimary,
          height: 1.3,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: CMSDesignSystem.textPrimary,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: CMSDesignSystem.textPrimary,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CMSDesignSystem.textPrimary,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: CMSDesignSystem.textPrimary,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: CMSDesignSystem.textPrimary,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: CMSDesignSystem.textSecondary,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: CMSDesignSystem.textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: CMSDesignSystem.textPrimary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: CMSDesignSystem.textSecondary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: CMSDesignSystem.textPrimary,
          height: 1.2,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: CMSDesignSystem.textPrimary,
          height: 1.2,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: CMSDesignSystem.textSecondary,
          height: 1.2,
          letterSpacing: 0.5,
        ),
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: CMSDesignSystem.primaryGreen,
        foregroundColor: CMSDesignSystem.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: CMSDesignSystem.white,
        ),
        iconTheme: IconThemeData(
          color: CMSDesignSystem.white,
        ),
      ),

      // Card theme
      cardTheme: CardTheme(
        color: CMSDesignSystem.cardBackground,
        elevation: 0,
        margin: EdgeInsets.all(CMSDesignSystem.spacing8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CMSDesignSystem.radiusLarge),
          side: BorderSide(color: CMSDesignSystem.divider, width: 1),
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: CMSDesignSystem.divider,
        thickness: 1,
        space: CMSDesignSystem.spacing32,
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CMSDesignSystem.primaryGreen,
          foregroundColor: CMSDesignSystem.white,
          padding: EdgeInsets.symmetric(
            horizontal: CMSDesignSystem.spacing24,
            vertical: CMSDesignSystem.spacing16,
          ),
          elevation: 0,
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CMSDesignSystem.primaryGreen,
          padding: EdgeInsets.symmetric(
            horizontal: CMSDesignSystem.spacing24,
            vertical: CMSDesignSystem.spacing16,
          ),
          side: BorderSide(color: CMSDesignSystem.primaryGreen, width: 1.5),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CMSDesignSystem.primaryGreen,
          padding: EdgeInsets.symmetric(
            horizontal: CMSDesignSystem.spacing16,
            vertical: CMSDesignSystem.spacing8,
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CMSDesignSystem.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: CMSDesignSystem.spacing20,
          vertical: CMSDesignSystem.spacing16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
          borderSide: BorderSide(
            color: CMSDesignSystem.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
          borderSide: BorderSide(
            color: CMSDesignSystem.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
          borderSide: BorderSide(
            color: CMSDesignSystem.primaryGreen,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
          borderSide: BorderSide(
            color: CMSDesignSystem.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CMSDesignSystem.radiusMedium),
          borderSide: BorderSide(
            color: CMSDesignSystem.error,
            width: 2,
          ),
        ),
        hintStyle: TextStyle(
          color: CMSDesignSystem.textSecondary.withOpacity(0.6),
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: CMSDesignSystem.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: CMSDesignSystem.primaryGreen,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: TextStyle(
          color: CMSDesignSystem.error,
          fontSize: 12,
        ),
      ),

      // Tab bar theme
      tabBarTheme: TabBarTheme(
        labelColor: CMSDesignSystem.white,
        unselectedLabelColor: CMSDesignSystem.white.withOpacity(0.7),
        indicatorColor: CMSDesignSystem.primaryBlue,
        labelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: CMSDesignSystem.primaryBlue,
        foregroundColor: CMSDesignSystem.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CMSDesignSystem.radiusCircular),
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: CMSDesignSystem.background,
        disabledColor: CMSDesignSystem.disabledBackground,
        selectedColor: CMSDesignSystem.primaryGreen.withOpacity(0.2),
        secondarySelectedColor: CMSDesignSystem.primaryGreen,
        padding: EdgeInsets.symmetric(horizontal: CMSDesignSystem.spacing8, vertical: CMSDesignSystem.spacing4),
        labelStyle: TextStyle(
          color: CMSDesignSystem.textPrimary,
          fontSize: 14,
        ),
        secondaryLabelStyle: TextStyle(
          color: CMSDesignSystem.white,
          fontSize: 14,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CMSDesignSystem.radiusCircular),
          side: BorderSide(
            color: CMSDesignSystem.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),

      // Scaffold background color
      scaffoldBackgroundColor: CMSDesignSystem.background,
    );
  }
}