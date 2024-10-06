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
  String? _name;
  String? _email;
  String? _password;
  String? _phoneNumber;
  String? _location;
  String? _bio;
  File? _profileImage;
  final AuthService authService = AuthService();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
  }

  // Function to pick profile image from the gallery
  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Function to upload the image to Firebase Storage and get the URL
  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;

    try {
      // Upload the image
      TaskSnapshot uploadTask = await _storage
          .ref('profile_images/$userId')
          .putFile(_profileImage!);

      // Get the download URL of the uploaded image
      String downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Sign up function
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save(); // This line saves the form fields

    if (_name == null || _email == null || _password == null) {
      // Show a message or handle the error as needed
      print('Please fill in all the required fields.');
      return;
    }

    // Proceed with sign-up
    await authService.signUpWithEmail(
      name: _name!,
      email: _email!,
      password: _password!,
      phoneNumber: _phoneNumber,
      location: _location,
      bio: _bio,
    );
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
        title: Text('Sign Up'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'), // Add your background image here
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5), // Background color opacity
              BlendMode.dstATop,
            ),
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Container(
                padding: EdgeInsets.all(20), // Padding for the content background
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8), // Content background color with opacity
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              // Add Logo at the top
                              Image.asset(
                                'assets/images/logo.png', // Make sure to add the logo image to your assets
                                height: 100,
                                width: 100,
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person, color: Colors.black),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onSaved: (value) => _name = value,
                          validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email, color: Colors.black),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (value) => _email = value,
                          validator: (value) => value!.isEmpty ? 'Enter your email' : null,
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock, color: Colors.black),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          obscureText: true,
                          onSaved: (value) => _password = value,
                          validator: (value) => value!.isEmpty ? 'Enter your password' : null,
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone, color: Colors.black),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onSaved: (value) => _phoneNumber = value,
                          validator: (value) => value!.isEmpty ? 'Enter your phone number' : null,
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Location',
                            prefixIcon: Icon(Icons.location_on, color: Colors.black),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onSaved: (value) => _location = value,
                          validator: (value) => value!.isEmpty ? 'Enter your location' : null,
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Bio',
                            prefixIcon: Icon(Icons.info, color: Colors.black),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onSaved: (value) => _bio = value,
                          validator: (value) => value!.isEmpty ? 'Enter your bio' : null,
                        ),
                        SizedBox(height: 15),
                        // Improved Pick Image button
                        InkWell(
                          onTap: _pickProfileImage,
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Colors.blue.withOpacity(0.3), // Splash effect when tapped
                          child: Container(
                            width: double.infinity, // Full width button
                            padding: EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [Colors.purpleAccent, Colors.blueAccent], // Gradient color
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, color: Colors.white, size: 24), // Custom icon
                                SizedBox(width: 10),
                                Text(
                                  'Pick Profile Image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        Center(
                          child: _profileImage != null
                              ? ClipOval(
                            child: Image.file(
                              _profileImage!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                              : Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey,
                            ),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 30),
                          ),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
