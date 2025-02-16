// widgets/advertisement_carousel.dart
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../Service/AuthService.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _signInWithEmail() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Create an instance of AuthService
      AuthService authService = AuthService();

      // Store FCM Token via AuthService
      await authService.storeFCMToken();

      await _updateLoginStatus(userCredential.user!, true);

      Navigator.pushReplacementNamed(context, '/homeScreen');
    } catch (e) {
      _showSnackBar('Failed to sign in: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Create an instance of AuthService
      AuthService authService = AuthService();

      // Store FCM Token via AuthService
      await authService.storeFCMToken();

      await _updateLoginStatus(userCredential.user!, true);

      Navigator.pushReplacementNamed(context, '/homeScreen');
    } catch (e) {
      _showSnackBar('Google Sign-In failed: ${e.toString()}');
    }
  }

  Future<void> _updateLoginStatus(User user, bool isLoggedIn) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'name': user.displayName,
      'profilePic': user.photoURL,
      'isLoggedIn': isLoggedIn,
    }, SetOptions(merge: true));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen size for responsive design
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true, // Ensure the body resizes when the keyboard appears
      appBar: AppBar(
        title: Text('Sign In', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        // Dismiss keyboard when tapping outside
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Background Image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            // Main Content with Scroll
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 40.0 : 20.0, vertical: 20.0),
                  child: FadeIn(
                    duration: Duration(milliseconds: 600),
                    child: SlideInUp(
                      duration: Duration(milliseconds: 800),
                      child: Container(
                        width: isLargeScreen ? screenWidth * 0.5 : double.infinity,
                        padding: EdgeInsets.all(isLargeScreen ? 30 : 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 2)
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo with Animation
                            BounceInDown(
                              duration: Duration(milliseconds: 800),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: isLargeScreen ? 170 : 120,
                                  height: isLargeScreen ? 170 : 120,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            // Email Text Field
                            _buildTextField("Email", _emailController, Icons.email, false, isLargeScreen),
                            SizedBox(height: 16),
                            // Password Text Field
                            _buildTextField("Password", _passwordController, Icons.lock, true, isLargeScreen),
                            SizedBox(height: 8),
                            // Forgot Password Button
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // Implement Forgot Password functionality
                                  Navigator.pushNamed(context, '/forgotPassword');
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(color:Color(0xFF722626)),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            // Sign In Button
                            _buildSignInButton(isLargeScreen),
                            SizedBox(height: 20),
                            // Social Login Buttons
                           // _buildSocialLoginButtons(isLargeScreen),
                            SizedBox(height: 20),
                            // Sign Up Option
                            _buildSignUpOption(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a TextField with specified parameters
  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon,
      bool isPassword,
      bool isLargeScreen) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
      textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        prefixIcon: Icon(icon, color: Color(0xFF722626)),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, color: Color(0xFF722626)),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        )
            : null,
      ),
    );
  }

  // Builds the Sign In button
  Widget _buildSignInButton(bool isLargeScreen) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _signInWithEmail,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 18 : 16),
        backgroundColor:Color(0xFF722626),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: _isLoading
          ? SizedBox(
        height: 24.0,
        width: 24.0,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      )
          : Text(
        'SIGN IN',
        style: TextStyle(fontSize: isLargeScreen ? 20 : 18, color: Colors.white),
      ),
    );
  }

  // Builds social login buttons
  Widget _buildSocialLoginButtons(bool isLargeScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google Sign-In Button
        IconButton(
          icon: FaIcon(FontAwesomeIcons.google, color: Colors.red, size: isLargeScreen ? 30 : 24),
          onPressed: _isLoading ? null : _signInWithGoogle,
          tooltip: 'Sign in with Google',
        ),
        // Add more social buttons here if needed (e.g., Facebook)
      ],
    );
  }

  // Builds the Sign Up option
  Widget _buildSignUpOption() {
    return FadeInUp(
      duration: Duration(milliseconds: 800),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Don’t have an Account? ", style: TextStyle(fontSize: 16)),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/signUp'),
            child: Text(
              "Sign Up",
              style: TextStyle(color: Color(0xFF722626), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}