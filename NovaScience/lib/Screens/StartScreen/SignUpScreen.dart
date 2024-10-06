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

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _email;
  String? _password;
  String? _phoneNumber;
  String? _location;
  Timestamp? _birthday;
  String? _bio;
  File? _profileImage;
final AuthService authService = AuthService();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  final ImagePicker _picker = ImagePicker();

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
      birthday: _birthday,
      bio: _bio,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Name'),
                  onSaved: (value) => _name = value,
                  validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (value) => _email = value,
                  validator: (value) => value!.isEmpty ? 'Enter your email' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  onSaved: (value) => _password = value,
                  validator: (value) => value!.isEmpty ? 'Enter your password' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  onSaved: (value) => _phoneNumber = value,
                  validator: (value) => value!.isEmpty ? 'Enter your phone number' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Location'),
                  onSaved: (value) => _location = value,
                  validator: (value) => value!.isEmpty ? 'Enter your location' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Bio'),
                  onSaved: (value) => _bio = value,
                  validator: (value) => value!.isEmpty ? 'Enter your bio' : null,
                ),
                // Birthday input can be a date picker
                ElevatedButton(
                  onPressed: _pickProfileImage,
                  child: Text('Pick Profile Image'),
                ),
                _profileImage != null
                    ? Image.file(_profileImage!, height: 100, width: 100, fit: BoxFit.cover)
                    : Container(height: 100, width: 100, color: Colors.grey),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signUp,
                  child: Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
