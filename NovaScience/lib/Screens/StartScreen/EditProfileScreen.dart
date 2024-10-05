import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Make sure 'intl' package is installed

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();

  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.purple.shade100],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),

                    // Profile Picture with animation
                    _buildProfileImage(),

                    SizedBox(height: 40),

                    // Name TextField
                    _buildTextField(
                      controller: nameController,
                      label: "Full Name",
                      hintText: "Enter your full name",
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Email TextField
                    _buildTextField(
                      controller: emailController,
                      label: "Email Address",
                      hintText: "Enter your email",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Phone TextField
                    _buildTextField(
                      controller: phoneController,
                      label: "Phone Number",
                      hintText: "Enter your phone number",
                      icon: Icons.phone_android,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20),

                    // Location TextField
                    _buildTextField(
                      controller: locationController,
                      label: "Location",
                      hintText: "Enter your location",
                      icon: Icons.location_on_outlined,
                    ),

                    SizedBox(height: 20),

                    // Birthday TextField (With Date Picker)
                    _buildTextField(
                      controller: birthDateController,
                      label: "Birthday",
                      hintText: "Select your birthday",
                      icon: Icons.cake_outlined,
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode()); // Dismiss keyboard
                        _selectDate(context);
                      },
                      readOnly: true,
                    ),

                    SizedBox(height: 20),

                    // Bio TextField
                    _buildTextField(
                      controller: bioController,
                      label: "Bio",
                      hintText: "Tell us about yourself",
                      icon: Icons.info_outline,
                      maxLines: 3,
                    ),

                    SizedBox(height: 30),

                    // Save and Cancel Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Profile image with option to change
  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: () {
        // Logic to change the profile picture
      },
      child: Center(
        child: Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage("https://via.placeholder.com/150"),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TextField builder function
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.purple),
        labelText: label,
        labelStyle: TextStyle(color: Colors.purple),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  // Action buttons (Save and Cancel)
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profile updated!')),
              );
            }
          },
          child: Text('Save Changes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 5,
          ),
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: BorderSide(color: Colors.blueAccent),
          ),
        ),
      ],
    );
  }

  // Method to select date for the birthday
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }
}
