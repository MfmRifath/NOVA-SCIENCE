import 'package:flutter/material.dart';

import 'HomeScreen.dart';
import 'ProfileScreen.dart';
import 'SettingScreen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of pages to display
  final List<Widget> _pages = [
    HomeScreen(),       // Index 0
    ProfileScreen(),    // Index 1
    SettingsScreen(),   // Index 2
    AdminPanelScreen(), // Index 3
  ];

  // This method will handle page navigation
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body is the selected page based on _selectedIndex
      body: _pages[_selectedIndex],

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Handle taps on navigation bar
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin Panel',
          ),
        ],
      ),
    );
  }
}






class AdminPanelScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
      ),
      body: Center(
        child: Text(
          'This is the Admin Panel Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
