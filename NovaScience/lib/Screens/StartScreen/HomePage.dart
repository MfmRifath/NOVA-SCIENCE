import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../AdminPanal/AdminPanelScreen.dart';
import 'HomeScreen.dart';
import 'ProfileScreen.dart';
import 'SettingScreen.dart';
import 'TeacherScreen.dart'; // Import the new TeacherScreen

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  bool isAdmin = false;
  bool isTeacher = false; // New variable to track if the user is a teacher

  final List<Widget> _commonPages = [
    HomeScreen(), // Home
    ProfileScreen(), // Profile
    SettingsScreen(), // Settings
  ];

  final List<String> _commonTitles = [
    'Home',
    'Profile',
    'Settings',
  ];

  List<Widget> _pages = [];
  List<String> _titles = [];

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // Check both admin and teacher roles
  }

  /// Check if the current user has the admin or teacher role
  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        isAdmin = userDoc.data()?['role'] == 'Admin'; // Check the role field for Admin
        isTeacher = userDoc.data()?['role'] == 'Teacher'; // Check the role field for Teacher

        // Update pages and titles dynamically based on roles
        _pages = List.from(_commonPages);
        _titles = List.from(_commonTitles);

        if (isAdmin) {
          _pages.add(AdminPanelScreen()); // Add Admin Panel
          _titles.add('Admin Panel');
        }

        if (isTeacher) {
          _pages.add(TeacherScreen()); // Add Teacher Screen
          _titles.add('Teacher Section');
        }
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles.isNotEmpty ? _titles[_selectedIndex] : '',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications, size: 28, color: Colors.white),
                Positioned(
                  right: 0,
                  top: 0,
                  child: _buildNotificationBadge(),
                ),
              ],
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          SizedBox(width: 10),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 14,
            unselectedFontSize: 12,
            iconSize: 26,
            items: _buildBottomNavigationBarItems(),
          ),
        ),
      ),
    );
  }

  /// Build BottomNavigationBar items dynamically based on roles
  List<BottomNavigationBarItem> _buildBottomNavigationBarItems() {
    final List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    if (isAdmin) {
      items.add(
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    if (isTeacher) {
      items.add(
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined), // Use a school icon for teachers
          activeIcon: Icon(Icons.school),
          label: 'Teacher',
        ),
      );
    }

    return items;
  }

  Widget _buildNotificationBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Container();
        return Container(
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Text(
            snapshot.data!.docs.length.toString(),
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}