import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Service/AuthService.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Color palette
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color maroonColor = const Color(0xFF722626);
  final Color accentColor = const Color(0xFFe9c46a);

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

      setState(() => isLoading = true);

      // Delete user data from Firestore and Authentication
      await _authService.deleteUser();
      await user.delete();

      // Redirect to join/login page
      Navigator.of(context).pushReplacementNamed('/join');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Your account has been deleted successfully."),
          backgroundColor: maroonColor,
        ),
      );
    } catch (e) {
      print("Error deleting account: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete account. Please try again."),
          backgroundColor: maroonColor,
        ),
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
    final screenSize = MediaQuery.of(context).size;
    final bool isLargeScreen = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
        ),
      )
          : Stack(
        children: [
          // Header background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [greenColor, yellowColor],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),

                  // Profile header with image and name
                  _buildProfileHeader(),

                  SizedBox(height: 30),

                  // Profile information sections
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Personal Information"),
                        SizedBox(height: 16),
                        _buildProfileInfoCard(),

                        SizedBox(height: 24),

                        // _buildSectionTitle("Account Settings"),
                        // SizedBox(height: 16),
                        // _buildAccountSettingsCard(),
                        //
                        // SizedBox(height: 40),

                        // Action buttons
                        _buildActionButtons(),

                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Profile image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: userData?["profileImageUrl"] != null
                  ? Image.network(
                userData!["profileImageUrl"],
                fit: BoxFit.cover,
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
          SizedBox(width: 20),

          // Name and title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData?['name'] ?? 'User Name',
                  style: GoogleFonts.roboto(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  userData?['email'] ?? 'user@example.com',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: greenColor,
      ),
    );
  }

  Widget _buildProfileInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person_outline,
            title: "Full Name",
            value: userData?['name'] ?? 'Not provided',
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.email_outlined,
            title: "Email",
            value: userData?['email'] ?? 'Not provided',
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            title: "Phone",
            value: userData?['phoneNumber'] ?? 'Not provided',
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            title: "Location",
            value: userData?['location'] ?? 'Not provided',
          ),
          if (userData?['birthday'] != null && userData?['birthday'] is Timestamp) ...[
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              title: "Birthday",
              value: _formatTimestamp(userData!['birthday']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingRow(
            icon: Icons.security_outlined,
            title: "Security Settings",
            onTap: () {
              // Navigate to security settings
            },
          ),
          _buildDivider(),
          _buildSettingRow(
            icon: Icons.notifications_outlined,
            title: "Notification Preferences",
            onTap: () {
              // Navigate to notification settings
            },
          ),
          _buildDivider(),
          _buildSettingRow(
            icon: Icons.language_outlined,
            title: "Language and Region",
            onTap: () {
              // Navigate to language settings
            },
          ),
          _buildDivider(),
          _buildSettingRow(
            icon: Icons.payment_outlined,
            title: "Payment Methods",
            onTap: () {
              // Navigate to payment settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: yellowColor,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: textColor(value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: yellowColor,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Color textColor(String value) {
    if (value == 'Not provided') {
      return Colors.grey.shade400;
    }
    return Colors.grey.shade800;
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/editProfile'),
          icon: Icon(Icons.edit_outlined, size: 18),
          label: Text('EDIT PROFILE'),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: greenColor,
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            textStyle: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: Icon(Icons.logout_outlined, size: 18),
          label: Text('SIGN OUT'),
          style: OutlinedButton.styleFrom(
            foregroundColor: maroonColor,
            side: BorderSide(color: maroonColor.withOpacity(0.5), width: 1),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            textStyle: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(height: 24),
        TextButton.icon(
          onPressed: () => _confirmDeleteAccount(context),
          icon: Icon(Icons.delete_outline, size: 18),
          label: Text('Delete Account'),
          style: TextButton.styleFrom(
            foregroundColor: maroonColor,
            padding: EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            textStyle: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Account",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: maroonColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to delete your account?",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "This action will permanently remove all your data and cannot be undone.",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.roboto(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: Text(
              "Delete",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    return "${date.day}-${date.month}-${date.year}";
  }
}