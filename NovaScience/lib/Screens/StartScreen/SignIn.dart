import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Service/AuthService.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Color palette
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color maroonColor = const Color(0xFF722626);
  final Color accentColor = const Color(0xFFe9c46a);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

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
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

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
    } finally {
      setState(() => _isLoading = false);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: maroonColor,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLargeScreen = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Header background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenSize.height * 0.3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [greenColor, yellowColor],
                  ),
                ),
                child: Stack(
                  children: [
                    // Subtle pattern overlay
                    Opacity(
                      opacity: 0.05,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/grid_pattern.png'),
                            repeat: ImageRepeat.repeat,
                          ),
                        ),
                      ),
                    ),
                    // Accent line
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: screenSize.width * 0.3,
                        height: 6,
                        color: accentColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                child: SizedBox(
                  height: screenSize.height - MediaQuery.of(context).padding.top,
                  child: Column(
                    children: [
                      // Header with logo and title
                      _buildHeader(isLargeScreen),

                      // Sign in form
                      Expanded(
                        child: _buildSignInForm(isLargeScreen),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLargeScreen) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        bottom: 40,
        left: 24,
        right: 24,
      ),
      child: Column(
        children: [
          // Logo and company name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 40,
                height: 40,
              ),
              SizedBox(width: 16),
              Text(
                'NOVA SCIENCE',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignInForm(bool isLargeScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Form container
            Container(
              width: isLargeScreen ? 460 : double.infinity,
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form title
                  Text(
                    'Sign In',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: greenColor,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Form description
                  Text(
                    'Enter your credentials to access your account',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 32),

                  // Email field
                  _buildInputField(
                    'Email',
                    _emailController,
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),

                  // Password field
                  _buildInputField(
                    'Password',
                    _passwordController,
                    Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/forgotPassword'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: yellowColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Sign in button
                  _buildPrimaryButton(
                    'SIGN IN',
                    _signInWithEmail,
                  ),
                  SizedBox(height: 24),

                  // Or divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Google sign in button
                  _buildSocialButton(
                    'SIGN IN WITH GOOGLE',
                    FontAwesomeIcons.google,
                    _signInWithGoogle,
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Sign up option
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signUp'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Register',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: maroonColor,
                    ),
                  ),
                ),
              ],
            ),

            // Footer
            Padding(
              padding: EdgeInsets.only(top: 24, bottom: 16),
              child: Text(
                '© 2025 NOVA SCIENCE. All Rights Reserved.',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool isPassword = false,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: greenColor,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscureText : false,
          keyboardType: keyboardType,
          style: GoogleFonts.roboto(
            fontSize: 15,
            color: Colors.grey.shade800,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: maroonColor, width: 1),
            ),
            prefixIcon: Icon(icon, color: yellowColor, size: 20),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: yellowColor,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            )
                : null,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: maroonColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: yellowColor,
          side: BorderSide(color: Colors.grey.shade300, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        icon: FaIcon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}