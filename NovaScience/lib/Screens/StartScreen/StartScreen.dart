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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            // Path to your background image
            fit: BoxFit
                .cover, // Fill the entire screen while maintaining aspect ratio
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 40.0),

                // Centered Animated main image with fade-in effect
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeInOut,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        // Rounded corners for the image
                        child: Image.asset(
                          'assets/images/$img.png',
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: MediaQuery.of(context).size.width * 0.6,
                          fit: BoxFit.cover, // Cover for the image
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30.0),

                // Centered Container for heading and description with shadow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25.0, vertical: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      // Semi-transparent background
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          // Slightly darker shadow
                          spreadRadius: 3,
                          blurRadius: 15,
                          offset: const Offset(0, 5), // Shadow offset
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Heading text
                        Text(
                          heading,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 26.0, // Increased font size for heading
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15.0),

                        // Description text with line height for readability
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.normal,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 150.0,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
