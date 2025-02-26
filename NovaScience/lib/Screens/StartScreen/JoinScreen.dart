import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JoinScreen extends StatelessWidget {
  const JoinScreen({Key? key}) : super(key: key);

  // Color palette
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color maroonColor = const Color(0xFF722626);
  final Color accentColor = const Color(0xFFe9c46a);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              greenColor,
              yellowColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Subtle background design elements
            _buildBackgroundElements(screenWidth, screenHeight),

            // Main content
            SafeArea(
              child: Column(
                children: <Widget>[
                  // Header section with logo
                  _buildHeaderSection(screenWidth),

                  // Welcome content
                  _buildWelcomeContent(),

                  // Buttons section
                  _buildButtonSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundElements(double screenWidth, double screenHeight) {
    return Stack(
      children: [
        // Top right accent
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            width: screenWidth * 0.4,
            height: 10,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
            ),
          ),
        ),

        // Bottom left accent
        Positioned(
          left: 0,
          bottom: screenHeight * 0.15,
          child: Container(
            width: 10,
            height: screenHeight * 0.25,
            decoration: BoxDecoration(
              color: maroonColor.withOpacity(0.3),
            ),
          ),
        ),

        // Subtle grid pattern overlay
        Positioned.fill(
          child: Opacity(
            opacity: 0.05,
            child: Image.asset(
              'assets/images/grid_pattern.png',
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Hero(
            tag: 'logo',
            child: Image.asset(
              'assets/images/logo.png',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 16),

          // Organization name
          Text(
            'NOVA SCIENCE',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeContent() {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section indicator
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),

            // Welcome heading
            Text(
              'Welcome',
              style: GoogleFonts.roboto(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 8),

            // Institution name
            Text(
              'NOVA LEARN',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: accentColor,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 24),

            // Description
            Text(
              'Access premium educational resources and cutting-edge learning solutions designed to enhance your academic excellence.',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.8),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          // Main registration button
          _buildPrimaryButton(
            label: 'CREATE ACCOUNT',
            onPressed: () => Navigator.pushNamed(context, '/signUp'),
          ),
          SizedBox(height: 16),

          // Secondary sign in button
          _buildSecondaryButton(
            label: 'SIGN IN',
            onPressed: () => Navigator.pushNamed(context, '/signIn'),
          ),

          SizedBox(height: 32),

          // Copyright notice
          Text(
            '© 2025 NOVA LEARN. All Rights Reserved.',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: maroonColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}