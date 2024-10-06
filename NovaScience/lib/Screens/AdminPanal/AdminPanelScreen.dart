import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Dashboard Overview
              Card(
                color: Colors.blue[50],
                child: ListTile(
                  leading: Icon(Icons.dashboard, color: Colors.blue),
                  title: Text('Dashboard Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text('View key metrics and activity logs.'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(context, '/dashboardOverview');
                  },
                ),
              ),

              SizedBox(height: 10),

              // User Management Section
              Card(
                color: Colors.green[50],
                child: ListTile(
                  leading: Icon(Icons.people, color: Colors.green),
                  title: Text('User Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text('Manage users, roles, and permissions.'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(context, '/userManagement');
                  },
                ),
              ),

              SizedBox(height: 10),

              // Course Management Section
              Card(
                color: Colors.orange[50],
                child: ListTile(
                  leading: Icon(Icons.book, color: Colors.orange),
                  title: Text('Course Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text('Add, update, or remove courses.'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(context, '/courseManagement');
                  },
                ),
              ),

              SizedBox(height: 10),

              // Reports and Analytics
              Card(
                color: Colors.red[50],
                child: ListTile(
                  leading: Icon(Icons.analytics, color: Colors.red),
                  title: Text('Reports & Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text('View reports and analytics.'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(context, '/reports');
                  },
                ),
              ),

              SizedBox(height: 10),

              // Settings Section
              Card(
                color: Colors.purple[50],
                child: ListTile(
                  leading: Icon(Icons.settings, color: Colors.purple),
                  title: Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text('Configure system settings.'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushNamed(context, '/systemSettings');
                  },
                ),
              ),

              SizedBox(height: 20),

              // Logout Button
              ElevatedButton.icon(
                onPressed: () {
                  // Handle logout action
                },
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
