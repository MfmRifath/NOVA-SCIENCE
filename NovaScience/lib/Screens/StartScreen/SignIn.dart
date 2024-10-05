import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideInAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideInAnimation = Tween<Offset>(
      begin: Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
        centerTitle: true,
        backgroundColor: Colors.teal, // App bar color
        elevation: 0, // Removes the shadow under the app bar
      ),
      extendBodyBehindAppBar: true, // Extends the body to go under the app bar
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'), // Add your background image here
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Dark Color Overlay with Opacity
          Container(
            color: Colors.black.withOpacity(0.7), // Dark overlay color
          ),

          // Main Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: SlideTransition(
                position: _slideInAnimation,
                child: Container(
                  // Background color for the content area
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // White background with slight transparency
                    borderRadius: BorderRadius.circular(12.0), // Rounded corners
                  ),
                  padding: const EdgeInsets.all(20.0), // Padding inside the content container
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 40.0), // Space between app bar and logo

                      // Add an image at the top
                      Center(
                        child: Image.asset(
                          'assets/images/logo.png', // Your logo or image file here
                          width: 150, // Set the desired width
                          height: 150, // Set the desired height
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 24.0), // Space between image and form

                      // Email Field
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.black), // Change label text color to black
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                          ),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: Colors.black), // Change text color to black
                      ),
                      SizedBox(height: 16.0),

                      // Password Field
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.black), // Change label text color to black
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                          ),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                        ),
                        obscureText: true,
                        style: TextStyle(color: Colors.black), // Change text color to black
                      ),
                      SizedBox(height: 8.0),

                      // Forgot Password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Forgot password logic
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.blue), // Change text color to teal
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),

                      // Sign In Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/homeScreen');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          backgroundColor: Colors.blueAccent, // Change to teal
                          elevation: 5,
                        ),
                        child: Text(
                          'SIGN IN',
                          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold,color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 16.0),

                      // Divider
                      Row(
                        children: <Widget>[
                          Expanded(child: Divider(thickness: 1.5, color: Colors.blue)),
                          Text(" Or Sign In With ", style: TextStyle(color: Colors.blue)),
                          Expanded(child: Divider(thickness: 1.5, color: Colors.blue)),
                        ],
                      ),
                      SizedBox(height: 16.0),

                      // Social Media Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // Sign in with Facebook logic
                            },
                            icon: Icon(Icons.facebook,color: Colors.white,),
                            label: Text('Facebook'
                            ,style: TextStyle(
                                color: Colors.white,
                              ),),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[900], // Darker blue for Facebook
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                          SizedBox(width: 16.0),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Sign in with Google logic
                            },
                            icon: Icon(FontAwesomeIcons.google,color: Colors.white,),
                            label: Text('Google', style: TextStyle(color: Colors.white),),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Orange for Google
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),

                      // Sign Up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don’t have an Account? ", style: TextStyle(color: Colors.blue)),
                          TextButton(
                            onPressed: () {
                              // Sign Up logic
                            },
                            child: Text(
                              'Sign Up Here',
                              style: TextStyle(color: Colors.blueAccent), // Match with the sign-in button
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
