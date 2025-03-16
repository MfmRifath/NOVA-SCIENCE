// Create a separate theme file: lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF11261F); // Dark green
  static const Color secondaryColor = Color(0xFF123755); // Navy blue
  static const Color accentColor = Color(0xFFe9c46a); // Gold
  static const Color tertiaryColor = Color(0xFF722626); // Maroon

  // Supporting colors
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light gray
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F); // Red
  static const Color successColor = Color(0xFF388E3C); // Green
  static const Color warningColor = Color(0xFFF57C00); // Orange
  static const Color infoColor = Color(0xFF1976D2); // Blue

  // Text colors
  static const Color textPrimaryColor = Color(0xFF212121); // Nearly black
  static const Color textSecondaryColor = Color(0xFF757575); // Medium gray
  static const Color textTertiaryColor = Color(0xFF9E9E9E); // Light gray
  static const Color textOnPrimaryColor = Colors.white;

  // Elevation and shadows
  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  // Typography
  static TextTheme get textTheme => GoogleFonts.robotoTextTheme().copyWith(
    displayLarge: GoogleFonts.roboto(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: textPrimaryColor,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.roboto(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: textPrimaryColor,
      letterSpacing: -0.25,
    ),
    displaySmall: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: textPrimaryColor,
    ),
    headlineMedium: GoogleFonts.roboto(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: textPrimaryColor,
    ),
    titleLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: textPrimaryColor,
      letterSpacing: 0.5,
    ),
    titleMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textPrimaryColor,
      letterSpacing: 0.15,
    ),
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: textPrimaryColor,
      letterSpacing: 0.15,
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: textPrimaryColor,
      letterSpacing: 0.25,
    ),
    bodySmall: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: textSecondaryColor,
      letterSpacing: 0.4,
    ),
    labelLarge: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textPrimaryColor,
      letterSpacing: 0.1,
    ),
  );

  // Create theme data
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      error: errorColor,
      background: backgroundColor,
      surface: surfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onBackground: textPrimaryColor,
      onSurface: textPrimaryColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textTheme: textTheme,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: tertiaryColor,
      unselectedItemColor: textTertiaryColor,
      selectedLabelStyle: textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: textTheme.bodySmall,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: textTertiaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: textTertiaryColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor),
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: textTertiaryColor,
      ),
    ),
  );
}