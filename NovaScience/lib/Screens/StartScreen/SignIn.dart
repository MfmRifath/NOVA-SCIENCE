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
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Sign In', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
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
          // Main Content
          Center(
            child: FadeIn(
              duration: Duration(milliseconds: 600),
              child: SlideInUp(
                duration: Duration(milliseconds: 800),
                child: Container(
                  width: isLargeScreen ? screenWidth * 0.5 : screenWidth * 0.9,
                  padding: EdgeInsets.all(isLargeScreen ? 30 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 2)],
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
                            width: isLargeScreen ? 150 : 100,
                            height: isLargeScreen ? 150 : 100,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildTextField("Email", _emailController, Icons.email, false, isLargeScreen),
                      SizedBox(height: 16),
                      _buildTextField("Password", _passwordController, Icons.lock, true, isLargeScreen),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text('Forgot Password?', style: TextStyle(color: Colors.teal)),
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildSignInButton(isLargeScreen),
                      SizedBox(height: 20),
                      _buildSocialLoginButtons(isLargeScreen),
                      SizedBox(height: 20),
                      _buildSignUpOption(),
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
  Widget _buildSignUpOption() {
    return FadeInUp(
      duration: Duration(milliseconds: 800),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Don’t have an Account? ", style: TextStyle(fontSize: 16)),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/signUpScreen'),
            child: Text("Sign Up", style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool isPassword, bool isLargeScreen) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        prefixIcon: Icon(icon, color: Colors.teal),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, color: Colors.teal),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        )
            : null,
      ),
    );
  }

  Widget _buildSignInButton(bool isLargeScreen) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _signInWithEmail,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 18 : 16),
        backgroundColor: Colors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('SIGN IN', style: TextStyle(fontSize: isLargeScreen ? 20 : 18, color: Colors.white)),
    );
  }

  Widget _buildSocialLoginButtons(bool isLargeScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: Icon(FontAwesomeIcons.google, color: Colors.red, size: isLargeScreen ? 30 : 24), onPressed: _signInWithGoogle),
      ],
    );
  }
}