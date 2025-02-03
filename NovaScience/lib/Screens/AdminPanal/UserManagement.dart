import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch initial user data
  }

  // Fetch users method
  Future<void> _fetchUsers() async {
    try {
      users = await _authService.fetchAllUsers(); // Fetch all users from AuthService
      setState(() {}); // Refresh UI with the fetched users
    } catch (e) {
      // Handle error (e.g., show a message)
      print("Error fetching users: $e");
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
          content: Text('User deleted successfully!'),
        ));

        setState(() {}); // Update UI
      } else {
        print("No user is currently signed in.");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No user is currently signed in.'),
        ));
      }
    } catch (e) {
      // Handle errors
      print("Error deleting user: $e"); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete user: $e'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User updated successfully!'),
        ));
      } catch (e) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update user: $e'),
        ));
      }
    }
  }

  // Build user list in UI
  @override
  Widget build(BuildContext context) {
    final loggedInUsers = users.where((user) => user.isLoggedin ?? false).toList();
    final otherUsers = users.where((user) => user.isLoggedin == false).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Currently Logged-in Users'),
            _buildUserList(loggedInUsers),
            const SizedBox(height: 20),
            const Divider(thickness: 1),
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
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      // If you'd like an extended FAB:
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _addUser,
      //   label: const Text('Add User'),
      //   icon: const Icon(Icons.add),
      //   backgroundColor: Colors.blueAccent,
      // ),
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: Colors.blueAccent, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              color: Colors.blueGrey.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(List<CustomUser> loggedInUsers) {
    if (loggedInUsers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No currently logged-in users.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Once users log in, they will appear here.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      // If this is inside another scrollable view, keep `shrinkWrap` and custom scroll physics:
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: loggedInUsers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final user = loggedInUsers[index];

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
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Optional: handle tile tap (e.g., show user details)
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? const Icon(Icons.person, size: 28, color: Colors.grey)
                  : null,
            ),
            title: Text(
              user.name ?? 'No Name',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              user.email ?? 'No Email',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editUser(context, user);
                } else if (value == 'delete') {
                  if (user.email != null) {
                    _deleteUser(user.email!);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete'),
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ),
        ),
      ),
    );
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

    // We can still show a placeholder image or the user’s current image
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
                    content: Text('Error picking image: $e'),
                    backgroundColor: Colors.red,
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
              title: Text(
                user == null ? 'Add User' : 'Edit User',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                          CircleAvatar(
                            radius: 45,
                            backgroundImage: previewImageUrl != null
                                ? NetworkImage(previewImageUrl!)
                                : (newProfileImage != null
                                ? FileImage(newProfileImage!)
                                : null),
                            child: (previewImageUrl == null && newProfileImage == null)
                                ? const Icon(Icons.person, size: 45)
                                : null,
                          ),
                          if (isUploadingImage)
                            Container(
                              width: 90,
                              height: 90,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.black38,
                                shape: BoxShape.circle,
                              ),
                              child: const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: isUploadingImage ? null : pickImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Change Profile Image'),
                      ),
                      const Divider(height: 24),

                      // ========== Name ==========
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ========== Email ==========
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // ========== Role ==========
                      TextFormField(
                        controller: roleController,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ========== Phone Number ==========
                      TextFormField(
                        controller: phoneNumberController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // ========== Password ==========
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ========== Confirm Password ==========
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              actions: [
                // ========== Cancel Button ==========
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),

                // ========== Save Button ==========
                ElevatedButton(
                  onPressed: () async {
                    // Basic password check
                    if (passwordController.text !=
                        confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Passwords do not match'),
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

                        // For changing password of a user who is NOT the currently logged-in user,
                        // you typically need Admin privileges and must use custom logic (e.g., Admin SDK).
                        // If the edited user is the current user, you can do something like:
                        //   await FirebaseAuth.instance.currentUser?.updatePassword(passwordController.text);
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
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
