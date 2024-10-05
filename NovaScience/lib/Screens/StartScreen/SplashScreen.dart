import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'onboardingScreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _logoSlideAnimation;
  late Animation<double> _logoScaleAnimation;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    // Create sliding animation from top to bottom
    _logoSlideAnimation =
        Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0)).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );

    // Create scale animation for logo growth effect
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Start animations
    _controller.forward();

    // Start the fade-in for the text after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // Delay for 4 seconds, then navigate to the onboarding screen
    Timer(Duration(seconds: 4), () {
      _navigateToOnboarding();
    });
  }

  // Custom page transition for onboarding screen
  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 800),
      pageBuilder: (context, animation, secondaryAnimation) {
        return OnboardingScreen();
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade transition with slight zoom
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend content behind status bar
      body: Stack(
        children: [
          // Blurred Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4), // Darkens the background
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Slide and scale animation for logo
                SlideTransition(
                  position: _logoSlideAnimation,
                  child: ScaleTransition(
                    scale: _logoScaleAnimation,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 150,
                      height: 150, // Slightly smaller logo for minimalism
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Fade-in text animation with modern font and color
                AnimatedOpacity(
                  opacity: _opacity,
                  duration: Duration(seconds: 2),
                  child: Text(
                    'Lighting the Way of Science',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // High contrast for readability
                      fontFamily: 'Lora', // More elegant font style
                      letterSpacing: 1.2, // Better spacing
                    ),
                    textAlign: TextAlign.center, // Center-aligned text
                  ),
                ),
                SizedBox(height: 30),

                // Circular Progress Indicator
                CircularProgressIndicator(
                  color: Colors.white, // Consistent color theme
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
