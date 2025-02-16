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

  // Define color constants for a consistent look
  final Color primaryColor = Colors.blueAccent; // Used for edit actions and accent elements
  final Color dangerColor = Colors.redAccent;     // Used for sign out and delete actions
  final Color infoCardColor = Colors.black.withOpacity(0.6); // Background for info cards

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

      setState(() => isLoading = true);

      // Delete user data from Firestore and Authentication
      await _authService.deleteUser();
      await user.delete();

      // Redirect to join/login page
      Navigator.of(context).pushReplacementNamed('/join');

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

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.of(context).pushReplacementNamed('/join');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image with FadeIn animation
          Positioned.fill(
            child: FadeIn(
              duration: Duration(seconds: 1),
              child: Image.asset(
                'assets/images/background.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Gradient Overlay for improved contrast
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main Content: either a loader or the scrollable profile content
          isLoading
              ? Center(
            child: Pulse(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          )
              : SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 60),

                // Profile Header Section with animated appearance
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

                // Action Buttons: Edit & Sign Out
                FadeInLeft(
                  duration: Duration(milliseconds: 600),
                  child: _buildActionButtons(context),
                ),

                SizedBox(height: 40),

                // Profile Information Cards
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
      child: GestureDetector(
        onTap: () {
          // Implement profile image editing functionality here, if desired.
        },
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
          child: ClipOval(
            child: Container(
              width: 140,
              height: 140,
              // Check if the profileImageUrl exists; if not, use the local asset.
              child: userData?["profileImageUrl"] != null
                  ? Image.network(
                userData!["profileImageUrl"],
                fit: BoxFit.cover,
                // If the network image fails, use a local placeholder.
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                  );
                },
              )
                  : Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              ),
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
              fontSize: 28,
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
              fontSize: 16,
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
          color: primaryColor,
          onTap: () => Navigator.pushNamed(context, '/editProfile'),
        ),
        SizedBox(width: 20),
        _buildProfileButton(
          icon: Icons.logout,
          label: "Sign Out",
          color: dangerColor,
          onTap: _signOut,
        ),
      ],
    );
  }

  Widget _buildProfileButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: infoCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
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
      color: Colors.white.withOpacity(0.2),
      height: 1,
      indent: 20,
      endIndent: 20,
    );
  }

  Widget _buildDeleteButton() {
    return Tooltip(
      message: "Permanently delete your account",
      child: TextButton.icon(
        icon: Icon(Icons.delete_forever, color: dangerColor.withOpacity(0.9)),
        label: Text(
          "Delete Account",
          style: TextStyle(
            color: dangerColor.withOpacity(0.9),
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () => _confirmDeleteAccount(context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: dangerColor.withOpacity(0.1),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: dangerColor),
            SizedBox(width: 10),
            Text("Delete Account", style: TextStyle(color: dangerColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("This action will:", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white70)),
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
            style: ElevatedButton.styleFrom(backgroundColor: dangerColor),
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
          Icon(icon, size: 18, color: dangerColor.withOpacity(0.9)),
          SizedBox(width: 10),
          Text(text, style: TextStyle(color: dangerColor.withOpacity(0.9))),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    return "${date.day}-${date.month}-${date.year}";
  }
}