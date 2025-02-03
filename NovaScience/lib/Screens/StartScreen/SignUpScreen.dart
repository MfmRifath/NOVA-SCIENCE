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
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image')));
      return null;
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    await authService.signUpWithEmail(
      name: _name!,
      email: _email!,
      password: _password!,
      phoneNumber: _phoneNumber,
      location: _location,
      bio: _bio,
    );
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up'), backgroundColor: Colors.blueAccent),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.dstATop),
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _animation,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(child: Image.asset('assets/images/logo.png', height: 100, width: 100)),
                            SizedBox(height: 20),
                            _buildTextField('Name', Icons.person, (val) => _name = val),
                            _buildTextField('Password', Icons.lock, (val) => _password = val, keyboardType: TextInputType.text, obscureText: true),
                            _buildTextField('Password', Icons.lock, (val) => _password = val, obscureText: true),
                            _buildTextField('Phone Number', Icons.phone, (val) => _phoneNumber = val),
                            _buildTextField('Location', Icons.location_on, (val) => _location = val),
                            _buildTextField('Bio', Icons.info, (val) => _bio = val),
                            SizedBox(height: 15),
                            _buildImagePicker(),
                            SizedBox(height: 20),
                            _isLoading
                                ? Center(child: CircularProgressIndicator())
                                : _buildSignUpButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, Function(String?) onSave, {TextInputType keyboardType = TextInputType.text, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.black),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        onSaved: onSave,
        validator: (value) => value!.isEmpty ? 'Enter your $label' : null,
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        InkWell(
          onTap: _pickProfileImage,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: [Colors.purpleAccent, Colors.blueAccent]),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.image, color: Colors.white), SizedBox(width: 10), Text('Pick Profile Image', style: TextStyle(color: Colors.white))],
            ),
          ),
        ),
        SizedBox(height: 15),
        _profileImage != null
            ? ClipOval(child: Image.file(_profileImage!, height: 100, width: 100, fit: BoxFit.cover))
            : CircleAvatar(radius: 50, backgroundColor: Colors.grey, child: Icon(Icons.camera_alt, color: Colors.white)),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _signUp,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: EdgeInsets.symmetric(vertical: 15)),
      child: Text('Sign Up', style: TextStyle(fontSize: 18)),
    );
  }
}
