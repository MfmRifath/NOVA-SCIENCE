import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nova_science/Service/AuthService.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Modals/User.dart';

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
  bool _isLoading = true;
  bool _isUpdating = false;
  CustomUser? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    AuthService authService = Provider.of<AuthService>(context, listen: false);
    CustomUser? fetchedUser = await authService.getCurrentUser();

    if (fetchedUser != null) {
      setState(() {
        currentUser = fetchedUser;
        _nameController.text = currentUser!.name ?? '';
        _phoneController.text = currentUser!.phoneNumber ?? '';
        _locationController.text = currentUser!.location ?? '';
        _bioController.text = currentUser!.bio ?? '';
        _birthday = currentUser!.birthday?.toDate();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load user data.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
      });

      AuthService authService = Provider.of<AuthService>(context, listen: false);
      CustomUser? user = currentUser;

      if (user == null) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No user data found.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'bio': _bioController.text.trim(),
        'birthday': _birthday != null ? Timestamp.fromDate(_birthday!) : null,
      };

      try {
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

        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: LoadingSpinner()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfileImageSection(),
              SizedBox(height: 32),
              _buildFormFields(),
              SizedBox(height: 24),
              _buildBirthdayPicker(),
              SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          )),
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.grey.shade700),
      centerTitle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 4,
              )
            ],
          ),
          child: ClipOval(
            child: _profileImage != null
                ? Image.file(_profileImage!, fit: BoxFit.cover)
                : Image.network(
              currentUser!.profileImageUrl ?? 'https://via.placeholder.com/150',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return LoadingSpinner();
              },
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Icon(
                FeatherIcons.camera,
                color: Colors.blue.shade600,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: FeatherIcons.user,
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: FeatherIcons.phone,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: _locationController,
          label: 'Location',
          icon: FeatherIcons.mapPin,
        ),
        SizedBox(height: 20),
        _buildTextField(
          controller: _bioController,
          label: 'Bio',
          icon: FeatherIcons.edit3,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.grey.shade800),
      decoration: InputDecoration(
        prefixIcon: Container(
          width: 50,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: Colors.blue.shade600),
        ),
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        floatingLabelStyle: TextStyle(color: Colors.blue.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) => value == null || value.trim().isEmpty
          ? 'This field is required'
          : null,
    );
  }

  Widget _buildBirthdayPicker() {
    return GestureDetector(
      onTap: _selectBirthday,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(FeatherIcons.calendar, size: 20, color: Colors.blue.shade600),
            SizedBox(width: 16),
            Text(
              _birthday != null
                  ? "${_birthday!.toLocal()}".split(' ')[0]
                  : "Select your birthday",
              style: TextStyle(
                color: _birthday != null
                    ? Colors.grey.shade800
                    : Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          padding: EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: _isUpdating
            ? SizedBox.shrink()
            : Icon(FeatherIcons.save, size: 20, color: Colors.white),
        label: _isUpdating
            ? LoadingSpinner(color: Colors.white)
            : Text(
          'SAVE CHANGES',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class LoadingSpinner extends StatelessWidget {
  final Color? color;

  const LoadingSpinner({this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator.adaptive(
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Colors.blue.shade600,
        ),
      ),
    );
  }
}