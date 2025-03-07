import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../Modals/User.dart';
import '../../Service/AuthService.dart';

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
  bool _isLoading = true;
  bool _isUpdating = false;
  CustomUser? currentUser;
  String? _originalName; // Store original name to check for changes

  // Updated color palette
  final Color greenColor = const Color(0xFF11261f); // Dark green - primary
  final Color yellowColor = const Color(0xFF123755); // Navy blue - secondary
  final Color maroonColor = const Color(0xFF722626); // Maroon - error
  final Color accentColor = const Color(0xFFe9c46a); // Gold accent
  final Color surfaceColor = const Color(0xFFF7F4E9); // Light cream background
  final Color textDarkColor = const Color(0xFF1F2937); // Dark text
  final Color textLightColor = const Color(0xFFF9FAFB); // Light text
  final Color dividerColor = const Color(0xFFE5E7EB); // Divider color

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  // Load user data and update the text controllers.
  Future<void> _loadUserData() async {
    try {
      AuthService authService = Provider.of<AuthService>(context, listen: false);
      CustomUser? fetchedUser = await authService.getCurrentUser();

      if (fetchedUser != null && mounted) {
        setState(() {
          currentUser = fetchedUser;
          _nameController.text = currentUser!.name ?? '';
          _originalName = currentUser!.name; // Store original name
          _phoneController.text = currentUser!.phoneNumber ?? '';
          _locationController.text = currentUser!.location ?? '';
          _bioController.text = currentUser!.bio ?? '';
          _birthday = currentUser!.birthday;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorSnackbar('Failed to load user data.');
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackbar('Error loading user data: $e');
      }
    }
  }

  // Pick a new profile image from the gallery.
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image to reduce size
        maxWidth: 800,
      );
      if (image != null && mounted) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error picking image: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: textLightColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: maroonColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: greenColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true;
      });

      try {
        AuthService authService = Provider.of<AuthService>(context, listen: false);
        CustomUser? user = currentUser;

        if (user == null) {
          setState(() {
            _isUpdating = false;
          });
          _showErrorSnackbar('No user data found.');
          return;
        }

        // Create the updated data map
        Map<String, dynamic> updatedData = {
          'name': _nameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'location': _locationController.text.trim(),
          'bio': _bioController.text.trim(),
        };

        // Only add birthday to the update if it's set
        if (_birthday != null) {
          updatedData['birthday'] = Timestamp.fromDate(_birthday!);
        }

        print('About to update with data: $updatedData');
        await authService.updateUser(
          updatedData: updatedData,
          newProfileImage: _profileImage,
        );
        print('Update completed');

        if (!mounted) return;

        setState(() {
          _isUpdating = false;
        });

        _showSuccessSnackbar('Profile updated successfully!');

        // Delay navigation briefly to allow the SnackBar to display.
        Future.delayed(Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate success
          }
        });
      } catch (e) {
        print('Error updating profile: $e');
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
          _showErrorSnackbar('Failed to update profile: $e');
        }
      }
    }
  }

  // Allow user to select a birthday using the date picker.
  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: yellowColor,
              onPrimary: textLightColor,
              surface: Colors.white,
              onSurface: textDarkColor,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _birthday = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loader until the user data is fetched.
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(
          child: CircularProgressIndicator(
            color: accentColor,
          ),
        ),
      );
    }

    // Wrap with GestureDetector to dismiss keyboard on tap outside.
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: surfaceColor,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  _buildProfileHeader(),
                  SizedBox(height: 24),
                  _buildProfileForm(),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Custom AppBar with official design
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Edit Profile',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: textLightColor,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      backgroundColor: greenColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: textLightColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(4.0),
        child: Container(
          color: accentColor.withOpacity(0.4),
          height: 1.0,
        ),
      ),
    );
  }

  // Profile header with image and name
  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: greenColor.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Profile Photo',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: greenColor,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 20),
          _buildProfileImageSection(),
        ],
      ),
    );
  }

  // Profile image section with a circular image and camera icon overlay
  Widget _buildProfileImageSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Profile image
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: greenColor.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Hero(
            tag: 'profile-image-${currentUser?.id}',
            child: ClipOval(
              child: _profileImage != null
                  ? Image.file(
                _profileImage!,
                fit: BoxFit.cover,
                width: 140,
                height: 140,
              )
                  : currentUser?.profileImageUrl != null
                  ? Image.network(
                currentUser!.profileImageUrl!,
                fit: BoxFit.cover,
                width: 140,
                height: 140,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 140,
                    height: 140,
                    color: yellowColor.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: accentColor,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 140,
                    height: 140,
                    color: yellowColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person_rounded,
                      size: 80,
                      color: yellowColor.withOpacity(0.4),
                    ),
                  );
                },
              )
                  : Container(
                width: 140,
                height: 140,
                color: yellowColor.withOpacity(0.1),
                child: Icon(
                  Icons.person_rounded,
                  size: 80,
                  color: yellowColor.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ),

        // Edit button overlay
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: greenColor.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                FeatherIcons.camera,
                color: greenColor,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Form container for profile information
  Widget _buildProfileForm() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: greenColor.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FeatherIcons.user, size: 18, color: yellowColor),
                SizedBox(width: 10),
                Text(
                  'Personal Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: greenColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(color: dividerColor, thickness: 1),
            SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: FeatherIcons.user,
              hintText: 'Enter your full name',
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: FeatherIcons.phone,
              hintText: 'Enter your phone number',
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              icon: FeatherIcons.mapPin,
              hintText: 'Enter your location',
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _bioController,
              label: 'Bio',
              icon: FeatherIcons.edit3,
              hintText: 'Tell us about yourself',
              maxLines: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Birthday',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: greenColor,
              ),
            ),
            SizedBox(height: 8),
            _buildBirthdayPicker(),
            SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // Redesigned text field widget with official style
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: greenColor,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: true,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: textDarkColor,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: yellowColor, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accentColor, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: maroonColor),
            ),
            filled: true,
            fillColor: surfaceColor,
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            hintStyle: GoogleFonts.poppins(
              color: textDarkColor.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Redesigned birthday picker field with formatted date
  Widget _buildBirthdayPicker() {
    return InkWell(
      onTap: _selectBirthday,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _birthday != null ? accentColor : dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              FeatherIcons.calendar,
              size: 18,
              color: yellowColor,
            ),
            SizedBox(width: 16),
            Text(
              _birthday != null
                  ? DateFormat('MMMM d, yyyy').format(_birthday!)
                  : "Select your birthday",
              style: GoogleFonts.poppins(
                color: _birthday != null
                    ? textDarkColor
                    : textDarkColor.withOpacity(0.4),
                fontSize: 15,
              ),
            ),
            Spacer(),
            Icon(
              Icons.arrow_drop_down,
              color: yellowColor,
            ),
          ],
        ),
      ),
    );
  }

  // Redesigned save button with loading state
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isUpdating ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: greenColor,
          disabledBackgroundColor: greenColor.withOpacity(0.4),
          foregroundColor: textLightColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isUpdating
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: accentColor,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'SAVING CHANGES...',
              style: GoogleFonts.poppins(
                color: textLightColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FeatherIcons.save, size: 18),
            SizedBox(width: 12),
            Text(
              'SAVE PROFILE',
              style: GoogleFonts.poppins(
                color: textLightColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}