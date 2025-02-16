import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nova_science/Screens/StartScreen/HomePage.dart';
import 'onboardingScreen.dart';
import 'homeScreen.dart'; // Ensure you have a HomeScreen widget

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Durations and delays for animations
  final _duration = Duration(milliseconds: 1500);
  final _delay = Duration(milliseconds: 300);

  // This function checks if the user is signed in.
  // If yes, navigate to HomeScreen; if not, navigate to OnboardingScreen.
  void _navigateToNextScreen() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is signed in, navigate to HomeScreen.
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 1200),
          pageBuilder: (_, __, ___) => HomePage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0.0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.fastOutSlowIn,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    } else {
      // No user is signed in, navigate to OnboardingScreen.
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 1200),
          pageBuilder: (_, __, ___) => OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0.0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.fastOutSlowIn,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // After 5 seconds, check user status and navigate accordingly.
    Timer(Duration(seconds: 5), _navigateToNextScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background with fade animation.
          Positioned.fill(
            child: FadeIn(
              duration: _duration,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF11261F), // Dark teal
                      Color(0xFF123755), // Deep blue
                      Color(0xFF722626), // Maroon
                    ],
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animation.
                ElasticInLeft(
                  delay: _delay,
                  duration: _duration,
                  child: SlideInUp(
                    delay: _delay,
                    from: 100,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                ),

                SizedBox(height: 40),

                // Animated tagline.
                FadeInDown(
                  delay: _delay * 2,
                  from: 30,
                  child: Text(
                    'A New Way of Learning.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      fontFamily: 'PlayfairDisplay',
                      letterSpacing: 1.8,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(2, 2),
                        )
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 50),

                // Loading indicator with pulse effect.
                Pulse(
                  infinite: true,
                  child: SpinKitFadingFour(
                    color: Colors.white,
                    size: 40,
                    duration: Duration(milliseconds: 1500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}