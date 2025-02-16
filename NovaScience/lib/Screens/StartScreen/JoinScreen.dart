import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class JoinScreen extends StatelessWidget {
  const JoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Animated background elements
              Positioned(
                right: -screenWidth * 0.2,
                top: -screenHeight * 0.1,
                child: FadeInLeft(
                  from: 200,
                  duration: const Duration(seconds: 2),
                  child: Container(
                    width: screenWidth * 0.6,
                    height: screenWidth * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
              ),

              // Main content
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Top section: Logo with animation
                  Expanded(
                    flex: 4,
                    child: ZoomIn(
                      duration: const Duration(milliseconds: 800),
                      child: Center(
                        child: Hero(
                          tag: 'logo',
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: screenWidth * 0.6,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Middle section: Text content
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeInDown(
                            from: 60,
                            duration: const Duration(milliseconds: 600),
                            child: Text(
                              'Welcome to NOVA LEARN!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 28.0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff722626),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          FadeInUp(
                            from: 40,
                            delay: const Duration(milliseconds: 200),
                            duration: const Duration(milliseconds: 800),
                            child: Text(
                              'Begin your journey with NOVA LEARN and unlock your full potential! Explore A/L Science, O/L Maths, and more with expertly crafted courses.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff11261f),
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom section: Buttons
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32.0, vertical: 24.0),
                      child: Column(
                        children: [
                          FadeInRight(
                            delay: const Duration(milliseconds: 400),
                            duration: const Duration(milliseconds: 600),
                            child: _AnimatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/signIn'),
                              label: 'Sign In',
                              icon: Icons.login_rounded,
                              color: Colors.white,
                              textColor: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          FadeInLeft(
                            delay: const Duration(milliseconds: 600),
                            duration: const Duration(milliseconds: 600),
                            child: _AnimatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/signUp'),
                              label: 'Create Account',
                              icon: Icons.person_add_alt_1_rounded,
                              color: Colors.amber.shade400,
                              textColor: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          ElasticIn(
                            delay: const Duration(milliseconds: 1000),
                            child: FadeInUp(
                              child: Text(
                                '© 2024 NOVA LEARN. All Rights Reserved.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.0,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;

  const _AnimatedButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Bounce(
      infinite: true,
      duration: const Duration(seconds: 2),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 4,
          shadowColor: Colors.black26,
          animationDuration: const Duration(milliseconds: 200),
        ),
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}