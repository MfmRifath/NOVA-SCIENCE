import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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
      String? imageUrl = userToDelete?.profileImageUrl;

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

  // Add user method
  void _addUser() async {
    CustomUser? newUser = await _showUserDialog();

    if (newUser != null) {
      try {
        // Log details for debugging
        print("Attempting to add user: ${newUser.email}");

        // Create the user in Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: newUser.email!,
          password: 'user123', // Replace with user-provided password
        );

        // Get the newly created user
        User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          // Store the user data in Firestore
          await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set({
            'name': newUser.name,
            'email': newUser.email,
            'role': newUser.role,
            'isLoggedin': false,
            'phoneNumber': newUser.phoneNumber,
            'profileImageUrl': newUser.profileImageUrl,
            'registeredDate': FieldValue.serverTimestamp(), // Store the registration date
          });

          // Update UI to reflect the new user added
          users.add(newUser); // Add the new user to the local list
          _listKey.currentState?.insertItem(users.length - 1); // Insert the item in AnimatedList
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('User added successfully!'),
          ));
          setState(() {});
        } else {
          print("Error: User creation failed.");
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('User creation failed.'),
          ));
        }
      } catch (e) {
        // Log the error for debugging
        print("Error while adding user: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add user: $e'),
        ));
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Currently Logged-in Users'),
            _buildUserList(users.where((user) => user.isLoggedin ?? false).toList()), // Show logged-in users
            const SizedBox(height: 20),
            _buildSectionTitle('All Users'),
            Expanded(
              child: _buildUserList(users.where((user) => user.isLoggedin == false).toList()), // Show logged-in users

            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        tooltip: 'Add User',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUserList(List<CustomUser> loggedInUsers) {
    if (loggedInUsers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No currently logged-in users.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: loggedInUsers.length,
      itemBuilder: (context, index) {
        final user = loggedInUsers[index];
        return _buildUserTile(user, const AlwaysStoppedAnimation(1.0), index);
      },
    );
  }

  Widget _buildUserTile(CustomUser user, Animation<double> animation, int index) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: user.profileImageUrl != null
              ? CircleAvatar(
            backgroundImage: NetworkImage(user.profileImageUrl!),
          )
              : const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text(user.name ?? 'No Name'),
          subtitle: Text(user.email ?? 'No Email'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editUser(context, user),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteUser(user.email!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<CustomUser?> _showUserDialog({CustomUser? user}) async {
    TextEditingController nameController = TextEditingController(text: user?.name ?? '');
    TextEditingController emailController = TextEditingController(text: user?.email ?? '');
    TextEditingController roleController = TextEditingController(text: user?.role ?? '');
    TextEditingController phoneNumberController = TextEditingController(text: user?.phoneNumber ?? '');

    String? profileImageUrl = user?.profileImageUrl ?? 'https://via.placeholder.com/150'; // Default image

    return await showDialog<CustomUser>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(user == null ? 'Add User' : 'Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              TextField(
                controller: phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
              ),
              const SizedBox(height: 16),
              profileImageUrl != null
                  ? CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(profileImageUrl!),
              )
                  : const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person),
              ),
              TextButton(
                onPressed: () async {
                  // Image picking logic
                  final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (pickedImage != null) {
                    File imageFile = File(pickedImage.path);
                    // Upload image to Firebase Storage and get URL
                    Reference storageReference = FirebaseStorage.instance.ref().child('profile_images/${DateTime.now().millisecondsSinceEpoch}');
                    UploadTask uploadTask = storageReference.putFile(imageFile);
                    TaskSnapshot taskSnapshot = await uploadTask;
                    profileImageUrl = await taskSnapshot.ref.getDownloadURL();
                    setState(() {});
                  }
                },
                child: const Text('Change Profile Image'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(
                  CustomUser(
                    name: nameController.text,
                    email: emailController.text,
                    role: roleController.text,
                    phoneNumber: phoneNumberController.text,
                    profileImageUrl: profileImageUrl,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
