import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'onboardingScreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _duration = Duration(milliseconds: 1500);
  final _delay = Duration(milliseconds: 300);

  void _navigateToOnboarding() {
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

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 5), _navigateToOnboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Parallax Background
          Positioned.fill(
            child: FadeIn(
              duration: _duration,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/background.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.6),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with combined animations
                ElasticInLeft(
                  delay: _delay,
                  duration: _duration,
                   // Add scale here instead of ScaleIn
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

                // Text animation
                FadeInDown(
                  delay: _delay * 2,
                  from: 30,
                  child: Text(
                    'Lighting the Way of Science',
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

                // Loading indicator with pulse effect
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