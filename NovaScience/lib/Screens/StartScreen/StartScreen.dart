import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Startscreen extends StatelessWidget {
  const Startscreen({
    Key? key,
    required this.heading,
    required this.description,
    required this.img,
  }) : super(key: key);

  final String img;
  final String heading;
  final String description;

  // Function to navigate to the next screen with a custom page transition animation

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        child: Stack(
          children: [
            // Background Image with Gradient Overlay for better text contrast
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.4), // Darkens the image
                    BlendMode.darken,
                  ),
                ),
              ),
            ),

            // Main Content Area
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 50.0),

                    // Centered Animated main image with fade-in and scale effect
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOut,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15.0),
                            child: Image.asset(
                              'assets/images/$img.png',
                              width: MediaQuery.of(context).size.width * 0.6,
                              height: MediaQuery.of(context).size.width * 0.6,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40.0),

                    // Centered Container for heading and description with better readability
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25.0, vertical: 20.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 3,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Heading Text with Custom Styling
                            Text(
                              heading,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  fontSize: 26.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20.0),

                            // Description Text with Line Height for Better Readability
                            Text(
                              description,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black87,
                                  height: 1.5, // Increased line height for readability
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 150.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


