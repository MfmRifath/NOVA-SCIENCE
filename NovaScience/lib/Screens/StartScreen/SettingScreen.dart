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
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuint,
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
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          'Settings',
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: accentColor,
            height: 2.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ListView(
                children: [
                  _buildSectionHeader('Account'),
                  _buildSettingsTile(
                    icon: Icons.account_circle_outlined,
                    title: 'Account Settings',
                    subtitle: 'Manage your account information',
                    onTap: () => _navigateToAccountSettings(),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsTile(
                    icon: Icons.password_outlined,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () => _navigateToChangePassword(),
                  ),
                  _buildDivider(),
                  _buildSectionHeader('Preferences'),
                  _buildSettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage notification settings',
                    onTap: () => _navigateToNotifications(),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsTile(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'Select your preferred language',
                    onTap: () => _showLanguageDialog(),
                  ),
                  _buildDivider(),
                  _buildSectionHeader('Security'),
                  _buildSettingsTile(
                    icon: Icons.security_outlined,
                    title: 'Privacy & Security',
                    subtitle: 'Adjust security settings',
                    onTap: () => _navigateToPrivacySettings(),
                  ),
                  _buildDivider(),
                  _buildSectionHeader('Support'),
                  _buildSettingsTile(
                    icon: Icons.help_outline_outlined,
                    title: 'Help & Support',
                    subtitle: 'Get help and send feedback',
                    onTap: () => _navigateToHelpSupport(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 12.0, left: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
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

  // Helper method to build each setting item with better UI
  Widget _buildSettingsTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: greenColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: yellowColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: yellowColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textDarkColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: textDarkColor.withOpacity(0.6),
          ),
        )
            : null,
        trailing: Icon(Icons.arrow_forward_ios, color: yellowColor, size: 16),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        visualDensity: VisualDensity.comfortable,
      ),
    );
  }

  // Custom divider
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Divider(
        color: accentColor.withOpacity(0.3),
        thickness: 1,
      ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Column(
          children: [
            Icon(
              Icons.language_outlined,
              color: yellowColor,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              'Select Language',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: greenColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('English'),
              Divider(height: 1, color: accentColor.withOpacity(0.3)),
              _buildLanguageOption('Spanish'),
              Divider(height: 1, color: accentColor.withOpacity(0.3)),
              _buildLanguageOption('French'),
            ],
          ),
        ),
        contentPadding: EdgeInsets.zero,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(
        language,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: textDarkColor,
        ),
      ),
      trailing: language == 'English'
          ? Icon(Icons.check_circle, color: accentColor, size: 20)
          : null,
      onTap: () {
        Navigator.of(context).pop();
        // Update language preference here
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
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

/// Placeholder for Change Password Screen
class ChangePasswordScreen extends StatelessWidget {
  // Custom color palette
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color accentColor = const Color(0xFFe9c46a);
  final Color textLightColor = const Color(0xFFF9FAFB);
  final Color surfaceColor = const Color(0xFFF7F7F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          'Change Password',
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: accentColor,
            height: 2.0,
          ),
        ),
        iconTheme: IconThemeData(color: textLightColor),
      ),
      body: Center(
        child: Text(
          'Change Password Screen',
          style: GoogleFonts.poppins(
            color: yellowColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Placeholder for Notifications Settings Screen
class NotificationsSettingsScreen extends StatelessWidget {
  // Custom color palette
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color accentColor = const Color(0xFFe9c46a);
  final Color textLightColor = const Color(0xFFF9FAFB);
  final Color surfaceColor = const Color(0xFFF7F7F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: accentColor,
            height: 2.0,
          ),
        ),
        iconTheme: IconThemeData(color: textLightColor),
      ),
      body: Center(
        child: Text(
          'Notifications Settings Screen',
          style: GoogleFonts.poppins(
            color: yellowColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Placeholder for Privacy Settings Screen
class PrivacySettingsScreen extends StatelessWidget {
  // Custom color palette
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color accentColor = const Color(0xFFe9c46a);
  final Color textLightColor = const Color(0xFFF9FAFB);
  final Color surfaceColor = const Color(0xFFF7F7F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          'Privacy & Security',
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: accentColor,
            height: 2.0,
          ),
        ),
        iconTheme: IconThemeData(color: textLightColor),
      ),
      body: Center(
        child: Text(
          'Privacy & Security Screen',
          style: GoogleFonts.poppins(
            color: yellowColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Placeholder for Help & Support Screen
class HelpSupportScreen extends StatelessWidget {
  // Custom color palette
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color accentColor = const Color(0xFFe9c46a);
  final Color textLightColor = const Color(0xFFF9FAFB);
  final Color surfaceColor = const Color(0xFFF7F7F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          'Help & Support',
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: accentColor,
            height: 2.0,
          ),
        ),
        iconTheme: IconThemeData(color: textLightColor),
      ),
      body: Center(
        child: Text(
          'Help & Support Screen',
          style: GoogleFonts.poppins(
            color: yellowColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}