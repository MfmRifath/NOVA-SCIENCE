import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController and Fade Animation
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward(); // Start the animation
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the controller
    super.dispose();
  }

  Widget _buildAdminCard({
    required Color cardColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardColor,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(icon, color: cardColor, size: 28),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 20),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A gradient background gives a modern look.
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: ListView(
                children: [
                  Text(
                    'Admin Panel',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 20),
                  _buildAdminCard(
                    cardColor: Colors.blue[50]!,
                    icon: Icons.dashboard,
                    title: 'Dashboard Overview',
                    subtitle: 'View key metrics and activity logs.',
                    onTap: () {
                      Navigator.pushNamed(context, '/dashboardOverview');
                    },
                  ),
                  _buildAdminCard(
                    cardColor: Colors.green[50]!,
                    icon: Icons.people,
                    title: 'User Management',
                    subtitle: 'Manage users, roles, and permissions.',
                    onTap: () {
                      Navigator.pushNamed(context, '/userManagement');
                    },
                  ),
                  _buildAdminCard(
                    cardColor: Colors.orange[50]!,
                    icon: Icons.book,
                    title: 'Course Management',
                    subtitle: 'Add, update, or remove courses.',
                    onTap: () {
                      Navigator.pushNamed(context, '/courseManagement');
                    },
                  ),
                  _buildAdminCard(
                    cardColor: Colors.teal[50]!,
                    icon: Icons.school,
                    title: 'Enroll Users into Courses',
                    subtitle: 'Assign courses to users.',
                    onTap: () {
                      Navigator.pushNamed(context, '/enrollUsers');
                    },
                  ),
                  _buildAdminCard(
                    cardColor: Colors.red[50]!,
                    icon: Icons.analytics,
                    title: 'Reports & Analytics',
                    subtitle: 'View reports and analytics.',
                    onTap: () {
                      Navigator.pushNamed(context, '/reports');
                    },
                  ),
                  _buildAdminCard(
                    cardColor: Colors.purple[50]!,
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'Configure system settings.',
                    onTap: () {
                      Navigator.pushNamed(context, '/systemSettings');
                    },
                  ),
                  _buildAdminCard(
                    cardColor: Colors.purple[50]!,
                    icon: Icons.campaign,
                    title: 'Manage Advertisement',
                    subtitle: 'Add, edit, or delete advertisements.',
                    onTap: () {
                      Navigator.pushNamed(context, '/manageAdvertisements');
                    },
                  ),
                  _buildAdminCard(
                    cardColor: Colors.purple[50]!,
                    icon: Icons.payment,
                    title: 'All Teachers Payment Details',
                    subtitle: 'View all payment details.',
                    onTap: () {
                      Navigator.pushNamed(context, '/teachersPayment');
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle logout action here.
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}