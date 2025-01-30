import 'package:animate_do/animate_do.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      body: Stack(
        children: [
          // Parallax Background
          Positioned.fill(
            child: FadeIn(
              duration: Duration(seconds: 1),
              child: Image.asset(
                'assets/images/background.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                  Colors.black.withOpacity(0.8)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main Content
          isLoading
              ? Center(child: Pulse(child: CircularProgressIndicator(color: Colors.blue)))
              : SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 50),

                // Profile Header
                ElasticIn(
                  duration: Duration(milliseconds: 800),
                  child: Column(
                    children: [
                      _buildProfileImage(),
                      SizedBox(height: 20),
                      _buildProfileDetails(),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // Action Buttons
                FadeInLeft(
                  duration: Duration(milliseconds: 600),
                  child: _buildActionButtons(context),
                ),

                SizedBox(height: 40),

                // Profile Info Cards
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 40 : 20),
                  child: ZoomIn(
                    child: _buildProfileInfoCards(),
                  ),
                ),

                SizedBox(height: 40),

                // Delete Account Button
                FadeInUp(
                  duration: Duration(milliseconds: 800),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: _buildDeleteButton(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return BounceInDown(
      duration: Duration(milliseconds: 800),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 5,
            )
          ],
        ),
        child: CircleAvatar(
          radius: 70,
          backgroundImage: NetworkImage(userData?["profileImageUrl"] ?? "https://via.placeholder.com/150"),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetails() {
    return Column(
      children: [
        FadeInDown(
          child: Text(
            userData?['name'] ?? 'John Doe',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),
        ),
        SizedBox(height: 10),
        FadeInUp(
          child: Text(
            userData?['bio'] ?? 'Flutter Enthusiast',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProfileButton(
          icon: Icons.edit,
          label: "Edit",
          color: Colors.amber,
          onTap: () => Navigator.pushNamed(context, '/editProfile'),
        ),
        SizedBox(width: 20),
        _buildProfileButton(
          icon: Icons.logout,
          label: "Sign Out",
          color: Colors.redAccent,
          onTap: _signOut,
        ),
      ],
    );
  }

  Widget _buildProfileButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ElasticIn(
      duration: Duration(milliseconds: 500),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 25),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoCards() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildInfoCard(Icons.email, "Email", userData?['email'] ?? "johndoe@example.com"),
          _buildDivider(),
          _buildInfoCard(Icons.phone, "Phone", userData?['phoneNumber'] ?? "+123 456 7890"),
          _buildDivider(),
          _buildInfoCard(Icons.location_on, "Location", userData?['location'] ?? "San Francisco, CA"),
          _buildDivider(),
          _buildInfoCard(
            Icons.cake,
            "Birthday",
            userData?['birthday'] != null && userData?['birthday'] is Timestamp
                ? _formatTimestamp(userData!['birthday'])
                : "January 1, 1990",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String info) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        info,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      minVerticalPadding: 0,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.1),
      height: 1,
      indent: 20,
      endIndent: 20,
    );
  }

  Widget _buildDeleteButton() {
    return Tooltip(
      message: "Permanently delete your account",
      child: TextButton.icon(
        icon: Icon(Icons.delete_forever, color: Colors.red.shade300),
        label: Text(
          "Delete Account",
          style: TextStyle(
            color: Colors.red.shade300,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () => _confirmDeleteAccount(context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.red.withOpacity(0.1),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Delete Account", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("This action will:", style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 10),
            _buildDeleteConsequence(Icons.delete, "Permanently remove all your data"),
            _buildDeleteConsequence(Icons.block, "Disable all associated services"),
            _buildDeleteConsequence(Icons.warning, "Cannot be undone"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: Text("Confirm Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteConsequence(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.red.shade300),
          SizedBox(width: 10),
          Text(text, style: TextStyle(color: Colors.red.shade300)),
        ],
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