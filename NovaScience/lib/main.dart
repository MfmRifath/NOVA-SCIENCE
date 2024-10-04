import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nova_science/Screens/StartScreen/JoinScreen.dart';
import 'package:nova_science/Screens/StartScreen/onboardingScreen.dart';

void main() => runApp(const NovaScience());

class NovaScience extends StatelessWidget {
  const NovaScience({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hide the debug banner
      title: 'Nova Science',
      home: SplashScreen(),
      routes: {
        '/Join': (context) => JoinScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _logoAnimation;
  double _opacity = 0.0; // For fade-in animation

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2), // Duration for the slide animation
    );

    // Create slide animation from top to bottom
    _logoAnimation = Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start animations
    _controller.forward();

    // Start the fade-in for the text after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // Delay for 3 seconds, then navigate to the onboarding screen
    Timer(Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => Onboardingscreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Opacity
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'), // Your background image
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black54, // Semi-transparent black overlay
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Sliding logo animation
                SlideTransition(
                  position: _logoAnimation,
                  child: Image.asset('assets/images/logo.png', width: 200, height: 200),
                ),
                SizedBox(height: 20),

                // Fade-in text animation
                AnimatedOpacity(
                  opacity: _opacity,
                  duration: Duration(seconds: 2),
                  child: Text(
                    'Lighting the Way of Science',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Changed to white for contrast
                      fontFamily: 'Roboto', // Customize font here
                    ),
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
