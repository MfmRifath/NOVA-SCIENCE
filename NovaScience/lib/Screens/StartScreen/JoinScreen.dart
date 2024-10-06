import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JoinScreen extends StatelessWidget {
  const JoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade100, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            image: DecorationImage(
              image: AssetImage('assets/images/background.jpg'), // Optional background image
              fit: BoxFit.cover,
              opacity: 0.1, // Adjust opacity as needed
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                SizedBox(height: 40.0), // Top spacing

                // Logo image with Hero animation
                Hero(
                  tag: 'logo',
                  child: AnimatedContainer(
                    duration: Duration(seconds: 1),
                    curve: Curves.easeInOut,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: screenWidth * 0.6, // Responsive logo size
                      height: screenWidth * 0.6,
                    ),
                  ),
                ),

                SizedBox(height: 30.0), // Spacing after the logo

                // Description text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Join NOVA SCIENCE to Begin Your Journey!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 28.0, // Increased for emphasis
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0), // Spacing between title and content
                      Text(
                        'Start your learning journey with NOVA SCIENCE, where A/L Science and O/L Maths and Science come to life. Our expert-driven courses and resources are designed to help you succeed. Join now and unlock your full potential!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 16.0, // Increased font size for readability
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                            height: 1.5, // Line height for readability
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40.0), // Spacing before buttons

                // Row of buttons for Sign In and Sign Up
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signIn');
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 5,
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login), // Icon for Sign In
                              SizedBox(width: 8), // Space between icon and text
                              Text(
                                'Sign In',
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    fontSize: 18.0, // Slightly larger font
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 10), // Space between buttons
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signUp');
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 15.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 5,
                            backgroundColor: Colors.green, // Button color
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add), // Icon for Sign Up
                              SizedBox(width: 8), // Space between icon and text
                              Text(
                                'Sign Up',
                                style: GoogleFonts.poppins(
                                  textStyle: const TextStyle(
                                    fontSize: 18.0, // Slightly larger font
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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

                SizedBox(height: 30.0), // Final bottom spacing

                // Optional Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    '© 2024 NOVA SCIENCE. All Rights Reserved.',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
