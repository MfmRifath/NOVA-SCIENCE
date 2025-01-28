// EditProfileScreen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nova_science/Service/AuthService.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore for Timestamp
import '../../Modals/User.dart';


class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  DateTime? _birthday;
  File? _profileImage;
  bool _isLoading = true; // Indicates if user data is being loaded
  bool _isUpdating = false; // Indicates if profile is being updated

  // **Define currentUser as a member variable**
  CustomUser? currentUser;

  @override
  void initState() {
    super.initState();
    // Load user data when the screen initializes
    _loadUserData();
  }

  /// Loads the current user's data into the form fields
  Future<void> _loadUserData() async {
    AuthService authService = Provider.of<AuthService>(context, listen: false);
    CustomUser? fetchedUser = await authService.getCurrentUser();

    if (fetchedUser != null) {
      setState(() {
        currentUser = fetchedUser; // Assign to the member variable
        _nameController.text = currentUser!.name ?? '';
        _phoneController.text = currentUser!.phoneNumber ?? '';
        _locationController.text = currentUser!.location ?? '';
        _bioController.text = currentUser!.bio ?? '';
        _birthday = currentUser!.birthday?.toDate();
        // Note: Profile image is handled separately
      });
    } else {
      // Handle the case where user data is not available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load user data. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Opens the image picker to select a new profile image
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Updates the user's profile with the provided data
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
      });

      AuthService authService = Provider.of<AuthService>(context, listen: false);
      CustomUser? user = currentUser; // Use the member variable

      if (user == null) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No user data found. Please sign in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Prepare updated data
      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'bio': _bioController.text.trim(),
        'birthday': _birthday != null ? Timestamp.fromDate(_birthday!) : null,
      };

      try {
        // Update user data via AuthService
        await authService.updateUser(
          updatedData: updatedData,
          newProfileImage: _profileImage,
        );

        setState(() {
          _isUpdating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context); // Navigate back after successful update
      } catch (e) {
        setState(() {
          _isUpdating = false;
        });
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Opens the date picker to select the user's birthday
  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthday) {
      setState(() {
        _birthday = picked;
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while user data is being fetched
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Profile'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Ensure that currentUser is not null before building the UI
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Profile'),
        ),
        body: Center(
          child: Text('No user data available. Please sign in again.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          IconButton(
            icon: _isUpdating
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.0,
              ),
            )
                : Icon(Icons.save),
            onPressed: _isUpdating ? null : _updateProfile,
            tooltip: 'Save Profile',
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
                // Profile Image Section
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : NetworkImage(
                      currentUser!.profileImageUrl ??
                          'https://via.placeholder.com/150',
                    ) as ImageProvider,
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                SizedBox(height: 16),

                // Email Field (Read-only)
                TextFormField(
                  initialValue: currentUser!.email ?? '',
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
                SizedBox(height: 16),

                // Phone Number Field
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),

                // Location Field
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                // Bio Field
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),

                // Birthday Picker
                GestureDetector(
                  onTap: _selectBirthday,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
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
                          style: TextStyle(
                            fontSize: 16,
                            color: _birthday != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        Icon(Icons.calendar_today, color: Colors.grey[700]),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // Update Button (Alternative Placement)
                /*
                ElevatedButton(
                  onPressed: _isUpdating ? null : _updateProfile,
                  child: _isUpdating
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text('Update Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
                */
              ],
            ),
          ),
        ),
      ),
    );
  }
}