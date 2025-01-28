import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'AccountSettingsScreen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
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
                  onTap: () => _navigateToAccountSettings(),
                ),
                _buildSettingsTile(
                  icon: Icons.password,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () => _navigateToChangePassword(),
                ),
                Divider(),
                _buildSectionHeader('Preferences'),
                _buildSettingsTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage notification settings',
                  onTap: () => _navigateToNotifications(),
                ),
                _buildSettingsTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'Select your preferred language',
                  onTap: () => _showLanguageDialog(),
                ),
                Divider(),
                _buildSectionHeader('Security'),
                _buildSettingsTile(
                  icon: Icons.security,
                  title: 'Privacy & Security',
                  subtitle: 'Adjust security settings',
                  onTap: () => _navigateToPrivacySettings(),
                ),
                Divider(),
                _buildSectionHeader('Support'),
                _buildSettingsTile(
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help and send feedback',
                  onTap: () => _navigateToHelpSupport(),
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

  /// Navigate to Account Settings
  void _navigateToAccountSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AccountSettingsScreen()),
    );
  }

  /// Navigate to Change Password Screen
  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
    );
  }

  /// Navigate to Notifications Screen
  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationsSettingsScreen()),
    );
  }

  /// Show Language Selection Dialog
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('English'),
              onTap: () {
                Navigator.of(context).pop();
                // Update language preference here
              },
            ),
            ListTile(
              title: Text('Spanish'),
              onTap: () {
                Navigator.of(context).pop();
                // Update language preference here
              },
            ),
            ListTile(
              title: Text('French'),
              onTap: () {
                Navigator.of(context).pop();
                // Update language preference here
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to Privacy & Security Screen
  void _navigateToPrivacySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrivacySettingsScreen()),
    );
  }

  /// Navigate to Help & Support Screen
  void _navigateToHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HelpSupportScreen()),
    );
  }
}

/// Placeholder for Account Settings Screen


/// Placeholder for Change Password Screen
class ChangePasswordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Change Password')),
      body: Center(child: Text('Change Password Screen')),
    );
  }
}

/// Placeholder for Notifications Settings Screen
class NotificationsSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications Settings')),
      body: Center(child: Text('Notifications Settings Screen')),
    );
  }
}

/// Placeholder for Privacy Settings Screen
class PrivacySettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Privacy & Security')),
      body: Center(child: Text('Privacy & Security Screen')),
    );
  }
}

/// Placeholder for Help & Support Screen
class HelpSupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Help & Support')),
      body: Center(child: Text('Help & Support Screen')),
    );
  }
}