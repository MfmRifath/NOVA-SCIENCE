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
              colors: [Colors.blueAccent.shade100, Colors.lightBlue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            image: DecorationImage(
              image: const AssetImage('assets/images/background.jpg'),
              fit: BoxFit.cover,
              opacity: 0.2, // Ensure the text is always visible
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Top section: Logo
              Expanded(
                flex: 4,
                child: Center(
                  child: Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: screenWidth * 0.6,
                      height: screenWidth * 0.6,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Middle section: Text content
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome to NOVA SCIENCE!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Text(
                        'Begin your journey with NOVA SCIENCE and unlock your full potential! Explore A/L Science, O/L Maths, and so much more with expertly crafted courses designed just for you.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 16.0,
                            color: Colors.black87,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signIn');
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 55),
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 5,
                        ),
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: Text(
                          'Sign In',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signUp');
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 55),
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 5,
                        ),
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        label: Text(
                          'Sign Up',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // Footer
                      Text(
                        '© 2024 NOVA SCIENCE. All Rights Reserved.',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}