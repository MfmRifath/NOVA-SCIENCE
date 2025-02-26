import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:nova_science/Service/AuthService.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  // Color palette
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color maroonColor = const Color(0xFF722626);
  final Color accentColor = const Color(0xFFe9c46a);

  final _formKey = GlobalKey<FormState>();
  String? _name, _email, _password, _phoneNumber, _location, _bio;
  File? _profileImage;
  final AuthService authService = AuthService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;
    try {
      TaskSnapshot uploadTask = await _storage.ref('profile_images/$userId').putFile(_profileImage!);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image'),
          backgroundColor: maroonColor,
        ),
      );
      return null;
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      await authService.signUpWithEmail(
        name: _name!,
        email: _email!,
        password: _password!,
        phoneNumber: _phoneNumber,
        location: _location,
        bio: _bio,
      );

      Navigator.of(context).pushReplacementNamed('/signIn');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign Up Failed: $error'),
          backgroundColor: maroonColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Input decoration builder for form fields
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.roboto(
        color: yellowColor.withOpacity(0.8),
        fontWeight: FontWeight.w500,
      ),
      hintText: 'Enter your $label',
      hintStyle: GoogleFonts.roboto(
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      prefixIcon: Icon(icon, color: yellowColor),
      suffixIcon: label.toLowerCase() == 'password'
          ? IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility : Icons.visibility_off,
          color: yellowColor,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      )
          : null,
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: maroonColor, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  IconData _getIcon(String label) {
    switch (label.toLowerCase()) {
      case 'name':
        return Icons.person_outline;
      case 'email':
        return Icons.email_outlined;
      case 'password':
        return Icons.lock_outline;
      case 'phone number':
        return Icons.phone_outlined;
      case 'location':
        return Icons.location_on_outlined;
      case 'bio':
        return Icons.description_outlined;
      default:
        return Icons.text_fields;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Account Registration',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: greenColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Header background
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: greenColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),

          // Form content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: FadeTransition(
                opacity: _animation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company branding
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              width: 32,
                              height: 32,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'NOVA SCIENCE',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Form card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Form title
                            Text(
                              'Create Your Account',
                              style: GoogleFonts.roboto(
                                color: greenColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                            SizedBox(height: 8),

                            // Subtitle
                            Text(
                              'Please fill in your information to register',
                              style: GoogleFonts.roboto(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 24),

                            // Profile Image Section
                            Center(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: _pickProfileImage,
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 50,
                                          backgroundColor: Colors.grey.shade200,
                                          backgroundImage: _profileImage != null
                                              ? FileImage(_profileImage!)
                                              : null,
                                          child: _profileImage == null
                                              ? Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.grey.shade400,
                                          )
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: accentColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.camera_alt,
                                              size: 18,
                                              color: greenColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Profile Picture',
                                    style: GoogleFonts.roboto(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),

                            // Section divider
                            Divider(color: Colors.grey.shade300),
                            SizedBox(height: 24),

                            // Form fields
                            _buildTextField('Name'),
                            SizedBox(height: 16),
                            _buildTextField('Email', keyboardType: TextInputType.emailAddress),
                            SizedBox(height: 16),
                            _buildTextField('Password', obscureText: _obscurePassword),
                            SizedBox(height: 16),
                            _buildTextField('Phone Number', keyboardType: TextInputType.phone),
                            SizedBox(height: 16),
                            _buildTextField('Location'),
                            SizedBox(height: 16),
                            _buildTextField('Bio', maxLines: 3),
                            SizedBox(height: 24),

                            // Terms and conditions
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size:
                                  16,
                                  color: yellowColor,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'By signing up, you agree to our Terms of Service and Privacy Policy',
                                    style: GoogleFonts.roboto(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),

                            // Submit button
                            _buildSignUpButton(),
                            SizedBox(height: 16),

                            // Sign in link
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pushReplacementNamed('/signIn'),
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.roboto(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(text: 'Already have an account? '),
                                      TextSpan(
                                        text: 'Sign In',
                                        style: TextStyle(
                                          color: yellowColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
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
    );
  }

  Widget _buildTextField(String label,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            color: greenColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          keyboardType: keyboardType,
          obscureText: label.toLowerCase() == 'password' ? _obscurePassword : obscureText,
          maxLines: maxLines,
          style: GoogleFonts.roboto(
            color: Colors.grey.shade800,
            fontSize: 15,
          ),
          decoration: _inputDecoration(label, _getIcon(label)),
          onSaved: (val) {
            switch (label.toLowerCase()) {
              case 'name':
                _name = val;
                break;
              case 'email':
                _email = val;
                break;
              case 'password':
                _password = val;
                break;
              case 'phone number':
                _phoneNumber = val;
                break;
              case 'location':
                _location = val;
                break;
              case 'bio':
                _bio = val;
                break;
            }
          },
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter your $label';
            }
            if (label.toLowerCase() == 'email' && !RegExp(r'\S+@\S+\.\S+').hasMatch(val)) {
              return 'Please enter a valid email address';
            }
            if (label.toLowerCase() == 'password' && val.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: maroonColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Text(
          'REGISTER ACCOUNT',
          style: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}