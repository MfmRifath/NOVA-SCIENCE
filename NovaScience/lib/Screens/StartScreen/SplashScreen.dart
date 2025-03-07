import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nova_science/Screens/StartScreen/HomePage.dart';
import 'package:lottie/lottie.dart';
import 'onboardingScreen.dart';
import 'homeScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Keeping the same color palette
  static const Color darkGreen = Color(0xFF11261f);
  static const Color darkYellow = Color(0xFF123755);
  static const Color maroon = Color(0xFF722626);

  // Multiple animation controllers for more sophisticated transitions
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;

  // Animations
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    // Text animation controller
    _textController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    // Progress indicator controller
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    );

    // Logo fade-in and scale animation
    _fadeInAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Interval(0.1, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    // Sequentially start animations
    _logoController.forward().then((_) {
      _textController.forward();
      _progressController.forward();
    });

    // Navigate after animations complete
    Timer(Duration(seconds: 5), _navigateToNextScreen);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() {
    User? user = FirebaseAuth.instance.currentUser;
    Widget nextScreen = user != null ? HomePage() : OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkGreen, darkYellow.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top space with accent design
              Container(
                height: screenSize.height * 0.15,
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: Container(
                    width: 80,
                    height: 5,
                    decoration: BoxDecoration(
                      color: maroon.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              // Main content area
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background design elements
                    Positioned(
                      left: -50,
                      top: screenSize.height * 0.2,
                      child: Opacity(
                        opacity: 0.05,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Main content
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated logo
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeInAnimation.value,
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  padding: EdgeInsets.all(30),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: darkGreen.withOpacity(0.4),
                                  ),
                                  child: Hero(
                                    tag: 'logo',
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      width: 160,
                                      height: 160,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 50),

                        // Organization name
                        AnimatedBuilder(
                          animation: _textController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _textController.value,
                              child: Transform.translate(
                                offset: Offset(0, _slideAnimation.value),
                                child: Text(
                                  'NOVA LEARN',
                                  style: GoogleFonts.roboto(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 4,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 20),

                        // Tagline
                        AnimatedBuilder(
                          animation: _textController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _textController.value * 0.9,
                              child: Transform.translate(
                                offset: Offset(0, _slideAnimation.value * 1.2),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: maroon.withOpacity(0.5), width: 1),
                                    ),
                                  ),
                                  child: Text(
                                    'Empowering Education, Inspiring Innovation',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 1.2,
                                      color: Colors.white.withOpacity(0.9),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom progress indicator
              Container(
                height: screenSize.height * 0.15,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated progress bar
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 50),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _progressController.value,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(maroon),
                              minHeight: 3,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 15),

                    // Copyright or version text
                    Text(
                      '© NOVA LEARN 2025',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}