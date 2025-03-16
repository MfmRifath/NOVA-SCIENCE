// lib/theme/nova_design_system.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NovaDesignSystem {
  // Color System
  static const Color primaryColor = Color(0xFF11261F);      // Dark green
  static const Color secondaryColor = Color(0xFF123755);    // Navy blue
  static const Color accentColor = Color(0xFFe9c46a);       // Gold
  static const Color tertiaryColor = Color(0xFF722626);     // Maroon

  // Neutral Colors
  static const Color neutral100 = Color(0xFFF5F5F5);  // Background
  static const Color neutral200 = Color(0xFFEEEEEE);  // Light gray for cards
  static const Color neutral300 = Color(0xFFE0E0E0);  // Borders
  static const Color neutral400 = Color(0xFFBDBDBD);  // Disabled state
  static const Color neutral500 = Color(0xFF9E9E9E);  // Placeholder text
  static const Color neutral600 = Color(0xFF757575);  // Secondary text
  static const Color neutral700 = Color(0xFF616161);  // Tertiary text
  static const Color neutral800 = Color(0xFF424242);  // Body text
  static const Color neutral900 = Color(0xFF212121);  // Headlines

  // Status Colors
  static const Color success = Color(0xFF388E3C);  // Green
  static const Color warning = Color(0xFFF57C00);  // Orange
  static const Color error = Color(0xFFD32F2F);    // Red
  static const Color info = Color(0xFF1976D2);     // Blue

  // Spacing System
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;

  // Border Radii
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusCircular = 999.0;

  // Typography
  static TextTheme get textTheme => GoogleFonts.poppinsTextTheme().copyWith(
    // Headlines
    displayLarge: GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: neutral900,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: neutral900,
      letterSpacing: -0.25,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: neutral900,
    ),

    // Subheadings
    headlineMedium: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: neutral900,
      letterSpacing: 0.15,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: neutral900,
    ),

    // Title
    titleLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: neutral800,
      letterSpacing: 0.15,
    ),

    // Body
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: neutral800,
      letterSpacing: 0.15,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: neutral800,
      letterSpacing: 0.25,
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: neutral600,
      letterSpacing: 0.4,
    ),

    // Label
    labelLarge: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: neutral800,
      letterSpacing: 0.1,
    ),
    labelSmall: GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: neutral600,
      letterSpacing: 0.5,
    ),
  );

  // Elevation/Shadow System
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 6,
      offset: Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
  ];

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    elevation: 2,
    textStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    elevation: 2,
    textStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle accentButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: tertiaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    elevation: 2,
    textStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle outlineButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: BorderSide(color: primaryColor, width: 1.5),
    padding: EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    textStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: EdgeInsets.symmetric(horizontal: spacing8, vertical: spacing4),
    textStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: neutral600,
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: neutral500,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: neutral300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: neutral300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: error),
      ),
    );
  }

  // Card Styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: shadowSmall,
  );

  static BoxDecoration cardDecorationHighlight = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: shadowMedium,
    border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
  );
}