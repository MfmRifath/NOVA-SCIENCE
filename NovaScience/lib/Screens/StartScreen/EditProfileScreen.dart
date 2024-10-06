import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nova_science/Service/AuthService.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore for Timestamp

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  DateTime? _birthday;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    // Load user data here
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    AuthService authService = Provider.of<AuthService>(context, listen: false);
    var userData = await authService.getCurrentUserData();

    if (userData != null) {
      _nameController.text = userData['name'] ?? '';
      _phoneController.text = userData['phoneNumber'] ?? '';
      _locationController.text = userData['location'] ?? '';
      _bioController.text = userData['bio'] ?? '';
      _birthday = userData['birthday']?.toDate();
      // Set the existing profile image if it exists
      if (userData['profileImageUrl'] != null) {
        // You can load the image URL to display it directly or keep it as a File object
        _profileImage = null; // Placeholder; you could load it using a network image in a different widget
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      AuthService authService = Provider.of<AuthService>(context, listen: false);
      // Ensure to pass the email of the user as required by the AuthService
      String email = (await authService.getCurrentUserEmail()) ?? ''; // Get the user's email

      await authService.updateUser(
        updatedData: {
          'name': _nameController.text,
          'email': email, // Use the email fetched from AuthService
          'phoneNumber': _phoneController.text,
          'location': _locationController.text,
          'bio': _bioController.text,
          'birthday': _birthday != null ? Timestamp.fromDate(_birthday!) : null,
        },
        newProfileImage: _profileImage,
      );

      Navigator.pop(context); // Go back to the previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updateProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : NetworkImage('https://via.placeholder.com/150'), // Placeholder for existing image
                    child: _profileImage == null
                        ? Icon(Icons.camera_alt, size: 50)
                        : null,
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                ),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(labelText: 'Location'),
                ),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(labelText: 'Bio'),
                  maxLines: 3,
                ),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _birthday ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != _birthday) {
                      setState(() {
                        _birthday = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 15.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _birthday != null
                              ? "${_birthday!.toLocal()}".split(' ')[0]
                              : "Select your birthday",
                        ),
                        Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
