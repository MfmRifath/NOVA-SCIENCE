import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../Service/AuthService.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _authService.currentUser;
    if (user != null) {
      userData = await _authService.getUserData(user.uid);
    }
    setState(() {
      isLoading = false;
    });
  }
  Future<void> _deleteAccount() async {
    try {
      User? user = _authService.currentUser;
      if (user == null) return;

      // Show progress indicator while deleting
      setState(() => isLoading = true);

      // Delete user data from Firestore
      await _authService.deleteUser();

      // Delete user from Firebase Authentication
      await user.delete();

      // Redirect to login page
      Navigator.of(context).pushReplacementNamed('/join');

      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Your account has been deleted successfully.")),
      );
    } catch (e) {
      print("Error deleting account: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete account. Please try again.")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Stack(
        children: [
          _buildBackground(),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                _buildProfileImage(),
                const SizedBox(height: 20),
                _buildProfileDetails(),
                const SizedBox(height: 30),
                _buildActionButtons(context),
                const SizedBox(height: 30),
                _buildProfileInfoList(),
                const SizedBox(height: 30),
                _buildProfileButton(
                  icon: Icons.delete_forever,
                  label: "Delete Account",
                  color: Colors.red,
                  onTap: () => _confirmDeleteAccount(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.jpg'), // Correct the path
          fit: BoxFit.cover, // Ensures the image covers the entire background
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.9), // Semi-transparent overlay
              Colors.blue.shade400.withOpacity(0.7),
              Colors.purple.shade300.withOpacity(0.7),
            ],
          ),
        ),
      ),
    );
  }
  // Profile Image Widget
  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: () {
        // Implement profile picture change functionality
      },
      child: CircleAvatar(
        radius: 70,
        backgroundImage: NetworkImage(userData?["profileImageUrl"] ?? "https://via.placeholder.com/150"),
        backgroundColor: Colors.grey.shade300,
      ),
    );
  }

  // Profile Details Widget
  Widget _buildProfileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          userData?['name'] ?? 'John Doe',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          userData?['bio'] ?? 'Flutter Enthusiast',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          userData?['description'] ?? 'I build modern apps with clean designs!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  // Action Buttons (Edit and Logout)
  // Action Buttons (Edit, Logout, and Delete Account)
  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Edit Profile Button
          _buildProfileButton(
            icon: Icons.edit,
            label: "Edit Profile",
            color: Colors.yellowAccent,
            onTap: () {
              Navigator.pushNamed(context, '/editProfile');
            },
          ),
          // Sign Out Button
          _buildProfileButton(
            icon: Icons.logout,
            label: "Sign Out",
            color: Colors.redAccent,
            onTap: _signOut,
          ),
          // Delete Account Button

        ],
      ),
    );
  }
  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismiss
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Delete Account"),
          content: Text("Are you sure you want to permanently delete your account? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(), // Close dialog
              child: Text("Cancel", style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog before deletion
                _deleteAccount();
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  Widget _buildProfileButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), // Slight transparent background
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Profile Info List
  Widget _buildProfileInfoList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileInfoItem(Icons.email, "Email", userData?['email'] ?? "johndoe@example.com"),
          const Divider(color: Colors.white54),
          _buildProfileInfoItem(Icons.phone, "Phone", userData?['phoneNumber'] ?? "+123 456 7890"),
          const Divider(color: Colors.white54),
          _buildProfileInfoItem(Icons.location_on, "Location", userData?['location'] ?? "San Francisco, CA"),
          const Divider(color: Colors.white54),
          _buildProfileInfoItem(
            Icons.cake,
            "Birthday",
            userData?['birthday'] != null && userData?['birthday'] is Timestamp
                ? _formatTimestamp(userData!['birthday'])
                : "January 1, 1990",
          ),
          const Divider(color: Colors.white54),
        ],
      ),
    );
  }
  String _formatTimestamp(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    return "${date.day}-${date.month}-${date.year}"; // Format as DD-MM-YYYY
  }

  // Profile Info Item
  Widget _buildProfileInfoItem(IconData icon, String title, String info) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
      subtitle: Text(
        info,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white60,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
    );
  }

  // Sign Out Functionality
  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.of(context).pushReplacementNamed('/join');
  }
}