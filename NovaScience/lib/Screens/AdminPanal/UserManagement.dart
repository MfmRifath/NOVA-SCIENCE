import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../Modals/User.dart'; // Your user model
import '../../Service/AuthService.dart'; // Your AuthService class

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AuthService _authService = AuthService(); // Instantiate AuthService
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<CustomUser> users = [];
  bool _isLoading = true;

  // Custom color palette
  final Color greenColor = const Color(0xFF11261f); // Dark green - primary
  final Color yellowColor = const Color(0xFF123755); // Navy blue - secondary
  final Color maroonColor = const Color(0xFF722626); // Maroon - error
  final Color accentColor = const Color(0xFFe9c46a); // Gold accent
  final Color surfaceColor = const Color(0xFFF7F7F2); // Light cream background
  final Color textDarkColor = const Color(0xFF1F2937); // Dark text
  final Color textLightColor = const Color(0xFFF9FAFB); // Light text

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch initial user data
  }

  // Fetch users method
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      users = await _authService.fetchAllUsers(); // Fetch all users from AuthService
      setState(() {
        _isLoading = false;
      }); // Refresh UI with the fetched users
    } catch (e) {
      // Handle error (e.g., show a message)
      print("Error fetching users: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Delete user method
  void _deleteUser(String email) async {
    try {
      // Find the user to delete from the local list
      CustomUser? userToDelete = users.firstWhere((user) => user.email == email);
      String? imageUrl = userToDelete.profileImageUrl;

      // Log the image URL for debugging
      print("Attempting to delete user with email: $email and image URL: $imageUrl");

      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Re-authenticate the user if necessary
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: 'user_password', // Replace with the actual user's password
        );

        await user.reauthenticateWithCredential(credential); // Re-authenticate the user
        await user.delete(); // Delete the user from Firebase Authentication

        print("User deleted successfully from Firebase Authentication!");

        // Delete the user document from Firestore
        await FirebaseFirestore.instance.collection('users').doc(userToDelete.id).delete(); // Assuming you have a user ID in CustomUser
        print("User document deleted successfully from Firestore!");

        // Check if the image URL is valid before deleting
        if (imageUrl != null && !imageUrl.startsWith('https://via.placeholder.com')) {
          // Proceed to delete the image from Firebase Storage
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
          print("Image deleted successfully from storage.");
        } else {
          print("No valid image URL found for user, or it's a placeholder URL. Skipping deletion.");
        }

        // Remove the user from the local list
        int index = users.indexOf(userToDelete);
        if (index >= 0) {
          users.removeAt(index); // Remove from the local list
          _listKey.currentState?.removeItem(index, (context, animation) {
            return _buildUserTile(userToDelete, animation, index);
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'User deleted successfully!',
            style: GoogleFonts.poppins(color: textLightColor),
          ),
          backgroundColor: greenColor,
          behavior: SnackBarBehavior.floating,
        ));

        setState(() {}); // Update UI
      } else {
        print("No user is currently signed in.");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'No user is currently signed in.',
            style: GoogleFonts.poppins(color: textLightColor),
          ),
          backgroundColor: maroonColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      // Handle errors
      print("Error deleting user: $e"); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Failed to delete user: $e',
          style: GoogleFonts.poppins(color: textLightColor),
        ),
        backgroundColor: maroonColor,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // Edit user method
  void _editUser(BuildContext context, CustomUser user) async {
    CustomUser? updatedUser = await _showUserDialog(user: user);

    if (updatedUser != null) {
      try {
        // Call AuthService to update the user in Firestore
        await _authService.updateUserByEmail(
          email: user.email!,
          updatedData: {
            'name': updatedUser.name ?? '',
            'role': updatedUser.role ?? '',
            'profileImageUrl': updatedUser.profileImageUrl ?? "https://via.placeholder.com/150",
          },
        );

        // Update UI to reflect changes
        int index = users.indexOf(user);
        users[index] = updatedUser;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'User updated successfully!',
            style: GoogleFonts.poppins(color: textLightColor),
          ),
          backgroundColor: greenColor,
          behavior: SnackBarBehavior.floating,
        ));
      } catch (e) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Failed to update user: $e',
            style: GoogleFonts.poppins(color: textLightColor),
          ),
          backgroundColor: maroonColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // Build user list in UI
  @override
  Widget build(BuildContext context) {
    final loggedInUsers = users.where((user) => user.isLoggedIn ?? false).toList();
    final otherUsers = users.where((user) => user.isLoggedIn == false).toList();

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          'User Management',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textLightColor,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: greenColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: textLightColor),
            onPressed: _fetchUsers,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2.0),
          child: Container(
            color: accentColor,
            height: 2.0,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: accentColor,
        ),
      )
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Currently Logged-in Users'),
            _buildUserList(loggedInUsers),
            const SizedBox(height: 20),
            Divider(
              color: accentColor.withOpacity(0.3),
              thickness: 1,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('All Other Users'),
            _buildUserList(otherUsers),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Show the user dialog and wait for a result (e.g., a newly created user)
          final newUser = await _showUserDialog();

          // If the dialog returns a non-null user, add it to your users list
          if (newUser != null) {
            setState(() {
              users.add(newUser);
            });
          }
        },
        tooltip: 'Add User',
        backgroundColor: greenColor,
        elevation: 2,
        child: Icon(Icons.add, color: textLightColor),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 14,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: greenColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<CustomUser> userList) {
    if (userList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 48,
              color: yellowColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No users in this category',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: yellowColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Users will appear here when available',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: textDarkColor.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: userList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = userList[index];

        // A simple fade-in animation for each tile
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: child,
              ),
            );
          },
          // This calls your existing user tile builder
          child: _buildUserTile(
            user,
            const AlwaysStoppedAnimation(1.0),
            index,
          ),
        );
      },
    );
  }

  Widget _buildUserTile(CustomUser user, Animation<double> animation, int index) {
    final bool isLoggedIn = user.isLoggedIn ?? false;

    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: greenColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Optional: show user details
              },
              splashColor: accentColor.withOpacity(0.1),
              highlightColor: accentColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Status indicator dot for logged-in users
                    if (isLoggedIn)
                      Container(
                        width: 8,
                        height: 56,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                    // Profile image
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: surfaceColor,
                      backgroundImage: user.profileImageUrl != null
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child: user.profileImageUrl == null
                          ? Icon(Icons.person_outline, size: 28, color: yellowColor)
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // User details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name ?? 'No Name',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: greenColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email ?? 'No Email',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: textDarkColor.withOpacity(0.7),
                            ),
                          ),
                          if (user.role != null && user.role!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: yellowColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: yellowColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                user.role!,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: yellowColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Edit button
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: yellowColor,
                            size: 20,
                          ),
                          onPressed: () => _editUser(context, user),
                          tooltip: 'Edit',
                          visualDensity: VisualDensity.compact,
                        ),
                        // Delete button
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: maroonColor,
                            size: 20,
                          ),
                          onPressed: () => _showDeleteConfirmation(context, user),
                          tooltip: 'Delete',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(BuildContext context, CustomUser user) async {
    final bool result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: maroonColor,
              size: 40,
            ),
            SizedBox(height: 16),
            Text(
              'Confirm Deletion',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: greenColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${user.name ?? 'this user'}? This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: textDarkColor,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: yellowColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonColor,
              foregroundColor: textLightColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'DELETE',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (result && user.email != null) {
      _deleteUser(user.email!);
    }
  }

  Future<CustomUser?> _showUserDialog({CustomUser? user}) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // Controllers
    final TextEditingController nameController =
    TextEditingController(text: user?.name ?? '');
    final TextEditingController emailController =
    TextEditingController(text: user?.email ?? '');
    final TextEditingController roleController =
    TextEditingController(text: user?.role ?? '');
    final TextEditingController phoneNumberController =
    TextEditingController(text: user?.phoneNumber ?? '');
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    // Local variables
    File? newProfileImage; // We'll pick this file & pass to AuthService
    bool isUploadingImage = false; // For showing a loading spinner while picking

    // We can still show a placeholder image or the user's current image
    String? previewImageUrl = user?.profileImageUrl ?? 'https://via.placeholder.com/150';

    // Key for optional form validation
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    return showDialog<CustomUser>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
      return StatefulBuilder(
          builder: (context, setState) {
        // --- Helper: Pick an image locally (no Firebase upload here) ---
        Future<void> pickImage() async {
          final picker = ImagePicker();
          final picked = await picker.pickImage(source: ImageSource.gallery);
          if (picked == null) return;
          setState(() => isUploadingImage = true);

          try {
            newProfileImage = File(picked.path);
            // Update the preview to show the newly picked local image
            previewImageUrl = null; // We'll show from local file now
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error picking image: $e',
                  style: GoogleFonts.poppins(color: textLightColor),
                ),
                backgroundColor: maroonColor,
              ),
            );
          } finally {
            setState(() => isUploadingImage = false);
          }
        }

        // --- Dialog UI ---
        return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              children: [
                Icon(
                  user == null ? Icons.person_add_outlined : Icons.person_outlined,
                  color: yellowColor,
                  size: 40,
                ),
                SizedBox(height: 16),
                Text(
                  user == null ? 'Add New User' : 'Edit User',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: greenColor,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ========== Avatar & Change Image Button ==========
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: surfaceColor,
                            backgroundImage: previewImageUrl != null
                                ? NetworkImage(previewImageUrl!)
                                : (newProfileImage != null
                                ? FileImage(newProfileImage!)
                                : null),
                            child: (previewImageUrl == null && newProfileImage == null)
                                ? Icon(Icons.person_outline, size: 48, color: yellowColor)
                                : null,
                          ),
                        ),
                        if (isUploadingImage)
                          Container(
                            width: 100,
                            height: 100,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(textLightColor),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: isUploadingImage ? null : pickImage,
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        size: 18,
                      ),
                      label: Text(
                        'Change Profile Image',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: yellowColor,
                        side: BorderSide(color: yellowColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const Divider(height: 32),

                    // ========== Form Fields ==========
                    _buildFormField(
                      controller: nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        // Basic email validation
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: roleController,
                      label: 'Role',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: phoneNumberController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (user == null && (value == null || value.isEmpty)) {
                          return 'Please enter a password';
                        }
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: confirmPasswordController,
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (passwordController.text.isNotEmpty &&
                            value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            actions: [
            // ========== Cancel Button ==========
            TextButton(
            onPressed: () => Navigator.of(context).pop(),
    child: Text(
    'CANCEL',
    style: GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: yellowColor,
    ),
    ),
    ),

    // ========== Save Button ==========
    ElevatedButton(
    onPressed: () async {
    // Validate form
    if (_formKey.currentState!.validate()) {
    // Basic password check
    if (passwordController.text != confirmPasswordController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content: Text(
    'Passwords do not match',
    style: GoogleFonts.poppins(color: textLightColor),
    ),
    backgroundColor: maroonColor,
    ),
    );
    return;
    }

    try {
    if (user == null) {
    // --- Create a NEW user via AuthService ---
    await authService.addUser(
    name: nameController.text.trim(),
    email: emailController.text.trim(),
    password: passwordController.text,
    role: roleController.text.trim().isEmpty
    ? 'User'
        : roleController.text.trim(),
    phoneNumber: phoneNumberController.text.trim().isEmpty
    ? null
        : phoneNumberController.text.trim(),
    profileImage: newProfileImage,
    );
    } else {
    // --- UPDATE existing user's Firestore data by Email ---
    await authService.updateUserByEmail(
    email: user.email ?? '', // old email
    updatedData: {
    'name': nameController.text.trim(),
    'email': emailController.text.trim(),
    'role': roleController.text.trim().isEmpty
    ? user.role
        : roleController.text.trim(),
    'phoneNumber': phoneNumberController.text.trim(),
    },
    );

    // If we picked a new image, call updateUser to upload & override
    if (newProfileImage != null) {
    await authService.updateUser(
    updatedData: {},
    newProfileImage: newProfileImage,
    );
    }
    }

    // Return updated/new CustomUser to the caller
    Navigator.of(context).pop(
    CustomUser(
    name: nameController.text,
    email: emailController.text,
    role: roleController.text,
    phoneNumber: phoneNumberController.text,
    profileImageUrl: previewImageUrl,
    ),
    );
    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Error: $e',
        style: GoogleFonts.poppins(color: textLightColor),
      ),
      backgroundColor: maroonColor,
      behavior: SnackBarBehavior.floating,
    ),
    );
    }
    }
    },
      style: ElevatedButton.styleFrom(
        backgroundColor: greenColor,
        foregroundColor: textLightColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        'SAVE',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
            ],
        );
          },
      );
        },
    );
  }

  // Helper method to build form fields with consistent styling
  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: textDarkColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: yellowColor,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: yellowColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: maroonColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: maroonColor, width: 1.5),
        ),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      validator: validator,
    );
  }
}