import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:nova_science/Service/AuthService.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _name, _email, _password, _phoneNumber, _location, _bio;
  File? _profileImage;
  final AuthService authService = AuthService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoading = false;

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
        SnackBar(content: Text('Error uploading image')),
      );
      return null;
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // Call the sign-up method in AuthService.
      // Ensure that signUpWithEmail either signs the user in automatically or returns a non-null value on success.
      await authService.signUpWithEmail(
        name: _name!,
        email: _email!,
        password: _password!,
        phoneNumber: _phoneNumber,
        location: _location,
        bio: _bio,
      );

      // After a successful sign-up, navigate to the login screen.
      // If you want the user to be automatically logged in, change '/login' to the route of your home screen.
      Navigator.of(context).pushReplacementNamed('/signIn');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign Up Failed: $error')),
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

  // Input decoration builder for consistency across text fields
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      hintText: 'Enter your $label',
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(_getIcon(label), color: Colors.deepOrangeAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  IconData _getIcon(String label) {
    switch (label.toLowerCase()) {
      case 'name':
        return Icons.person;
      case 'email':
        return Icons.email;
      case 'password':
        return Icons.lock;
      case 'phone number':
        return Icons.phone;
      case 'location':
        return Icons.location_on;
      case 'bio':
        return Icons.info;
      default:
        return Icons.text_fields;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent AppBar to allow background to shine through
      appBar: AppBar(
        title: Text('Sign Up', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background: image with a gradient overlay
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
              ),
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Form content with fade-in animation
          FadeTransition(
            opacity: _animation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile Image Picker Section
                        GestureDetector(
                          onTap: _pickProfileImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                                child: _profileImage == null
                                    ? Icon(Icons.camera_alt, size: 40, color: Colors.grey.shade800)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrangeAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.edit, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                        _buildTextField('Name'),
                        SizedBox(height: 16),
                        _buildTextField('Email', keyboardType: TextInputType.emailAddress),
                        SizedBox(height: 16),
                        _buildTextField('Password', obscureText: true),
                        SizedBox(height: 16),
                        _buildTextField('Phone Number', keyboardType: TextInputType.phone),
                        SizedBox(height: 16),
                        _buildTextField('Location'),
                        SizedBox(height: 16),
                        _buildTextField('Bio', maxLines: 3),
                        SizedBox(height: 24),
                        _buildSignUpButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Loader overlay: shows a semi-transparent overlay with a loader when _isLoading is true.
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: _inputDecoration(label),
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
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrangeAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        child: Text(
          'Sign Up',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}