import 'package:flutter/material.dart';

class SystemSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('System Settings'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSectionTitle('General Settings'),
            _buildListTile(
              title: 'Language',
              subtitle: 'Change the app language',
              icon: Icons.language,
              onTap: () {
                _showLanguageDialog(context);
              },
            ),
            _buildListTile(
              title: 'Storage',
              subtitle: 'Manage storage usage',
              icon: Icons.storage,
              onTap: () {
                _showStorageDialog(context);
              },
            ),
            Divider(),
            _buildSectionTitle('Notifications'),
            _buildSwitchTile(
              title: 'Enable Notifications',
              subtitle: 'Receive updates and reminders',
              value: true,
              onChanged: (value) {
                // Handle the switch change
              },
            ),
            _buildSwitchTile(
              title: 'Sound Notifications',
              subtitle: 'Enable sound for notifications',
              value: false,
              onChanged: (value) {
                // Handle the switch change
              },
            ),
            Divider(),
            _buildSectionTitle('Advanced Settings'),
            _buildListTile(
              title: 'Reset Settings',
              subtitle: 'Restore default settings',
              icon: Icons.restore,
              onTap: () {
                _showResetDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blueAccent,
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: Icon(Icons.arrow_forward_ios),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Language'),
          content: Text('Implement language selection functionality here.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showStorageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            title: Text('Storage Management'),
            content: Text('Implement storage management functionality here.'),
            actions: [
            TextButton(
            onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text('Close'),
            ),
      ],
    );
  },
  );
}

void _showResetDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Reset Settings'),
        content: Text('Are you sure you want to reset to default settings?'),
        actions: [
          TextButton(
            onPressed: () {
              // Handle reset logic here
              Navigator.of(context).pop();
            },
            child: Text('Yes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('No'),
          ),
        ],
      );
    },
  );
}
}
