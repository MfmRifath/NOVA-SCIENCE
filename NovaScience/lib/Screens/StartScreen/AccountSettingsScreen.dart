import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountSettingsScreen extends StatefulWidget {
  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: currentUser?.displayName ?? '');
    _emailController = TextEditingController(text: currentUser?.email ?? '');
  }

  /// Update user information
  Future<void> _updateAccountInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = this.currentUser;
      if (currentUser != null) {
        // Update display name if it has changed
        if (_nameController.text != currentUser.displayName) {
          await currentUser?.updateDisplayName(_nameController.text);
        }

        // Update email if it has changed
        if (_emailController.text != currentUser.email) {
          await currentUser?.updateEmail(_emailController.text);
        }

        // Refresh the user data
        await currentUser.reload();
        FirebaseAuth.instance.currentUser;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account information updated successfully')),
        );
      } else {
        throw FirebaseAuthException(code: 'no-user', message: 'No user logged in.');
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to update account')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Reset user's password
  Future<void> _resetPassword() async {
    if (currentUser?.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: currentUser!.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to ${currentUser!.email}')),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Failed to send password reset email')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No email address available for this user.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account Settings',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView(
          children: [
            _buildSectionHeader('Personal Information'),
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'Enter your name',
            ),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'Enter your email',
              enabled: false,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateAccountInfo,
              child: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 30),
            _buildSectionHeader('Security'),
            ElevatedButton.icon(
              onPressed: _resetPassword,
              icon: Icon(Icons.lock_reset),
              label: Text('Reset Password'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  // Helper method for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}