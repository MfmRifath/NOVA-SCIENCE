import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // For custom fonts

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward(); // Start the animation when the screen loads
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: true, // Center the app bar title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ListView(
              children: [
                _buildSectionHeader('Account'),
                _buildSettingsTile(
                  icon: Icons.account_circle,
                  title: 'Account Settings',
                  subtitle: 'Manage your account information',
                  onTap: () {
                    // Handle Account Settings Tap
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.password,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () {
                    // Handle Change Password Tap
                  },
                ),
                Divider(),
                _buildSectionHeader('Preferences'),
                _buildSettingsTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage notification settings',
                  onTap: () {
                    // Handle Notifications Tap
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'Select your preferred language',
                  onTap: () {
                    // Handle Language Selection Tap
                  },
                ),
                Divider(),
                _buildSectionHeader('Security'),
                _buildSettingsTile(
                  icon: Icons.security,
                  title: 'Privacy & Security',
                  subtitle: 'Adjust security settings',
                  onTap: () {
                    // Handle Privacy & Security Tap
                  },
                ),
                Divider(),
                _buildSectionHeader('Support'),
                _buildSettingsTile(
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help and send feedback',
                  onTap: () {
                    // Handle Help & Support Tap
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create section headers
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

  // Helper method to build each setting item with better UI
  Widget _buildSettingsTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, size: 28, color: Colors.blue),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      )
          : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: Theme.of(context).cardColor,
      hoverColor: Colors.blue.shade50,
    );
  }
}
