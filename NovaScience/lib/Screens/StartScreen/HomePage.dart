
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:nova_science/Service/NotificationBadge.dart';
import '../../GroupChat/DiscussionScreen.dart';
import '../AdminPanal/AdminPanelScreen.dart';
import 'AppTheme.dart';

import 'HomeScreen.dart';
import 'ProfileScreen.dart';
import 'ResourceScreen.dart';
import 'SettingScreen.dart';
import 'TeacherScreen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  bool isAdmin = false;
  bool isTeacher = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late AnimationController _fadeController;

  // Animation values
  late Animation<double> _fadeAnimation;

  final List<Widget> _commonPages = [];
  final List<String> _commonTitles = [
    'Dashboard',
    'Profile',
    'Resources',
    'Discussion', // Added Discussion tab
    'Settings',
  ];

  List<Widget> _pages = [];
  List<String> _titles = [];

  // Page icons (using outline variants)
  final List<IconData> _commonIcons = [
    Icons.dashboard_outlined,
    Icons.person_outline,
    Icons.folder_outlined,
    Icons.forum_outlined, // Added Discussion icon
    Icons.settings_outlined,
  ];

  List<IconData> _icons = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Initialize common pages
    _commonPages.addAll([
      HomeScreen(),
      ProfileScreen(),
      ResourceScreen(),
      DiscussionScreen(), // Added Discussion screen
      SettingsScreen(),
    ]);

    _checkUserRole();

    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _checkUserRole() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          isAdmin = userDoc.data()?['role'] == 'Admin';
          isTeacher = userDoc.data()?['role'] == 'Teacher';

          // Update pages and titles based on roles
          _pages = List.from(_commonPages);
          _titles = List.from(_commonTitles);
          _icons = List.from(_commonIcons);

          if (isAdmin) {
            _pages.add(AdminPanelScreen());
            _titles.add('Administration');
            _icons.add(Icons.admin_panel_settings_outlined);
          }

          if (isTeacher) {
            _pages.add(TeacherScreen());
            _titles.add('Teaching');
            _icons.add(Icons.school_outlined);
          }

          _isLoading = false;
        });

        // Start fade animation after data is loaded
        _fadeController.forward();
      } else {
        setState(() {
          _pages = List.from(_commonPages);
          _titles = List.from(_commonTitles);
          _icons = List.from(_commonIcons);
          _isLoading = false;
        });

        // Start fade animation after data is loaded
        _fadeController.forward();
      }
    } catch (e) {
      print('Error checking user role: $e');
      setState(() {
        _pages = List.from(_commonPages);
        _titles = List.from(_commonTitles);
        _icons = List.from(_commonIcons);
        _isLoading = false;
      });

      // Start fade animation after data is loaded
      _fadeController.forward();
    }
  }

  void _onItemTapped(int index) {
    _animationController.reset();
    _animationController.forward();

    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutQuint,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildContent(),
        ),
      ),
    );
  }
  Widget _buildContent() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: _pages,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/images/logo.png',
                height: 100,
                width: 100,
              ),
            ),
            SizedBox(height: 40),
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 32),
            AnimatedBuilder(
              animation: _animationController..repeat(reverse: true),
              builder: (context, child) {
                return Opacity(
                  opacity: 0.6 + (_animationController.value * 0.4),
                  child: Text(
                    'Loading',
                    style: AppTheme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      toolbarHeight: 64,
      centerTitle: false,
      title: Row(
        children: [
          Hero(
            tag: 'app_logo',
            child: Image.asset(
              'assets/images/logo.png',
              height: 36,
              width: 36,
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOVA LEARN',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _titles[_selectedIndex],
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _buildSearchButton(),
        NotificationBadge(child: _buildNotificationButton()),
        SizedBox(width: 8),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor.withOpacity(0.95),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          showSearch(
            context: context,
            delegate: CustomSearchDelegate(),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.search_rounded,
            size: 24,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                Navigator.pushNamed(context, '/notifications');
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _buildNotificationBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Container();

        int count = snapshot.data!.docs.length;
        return Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.tertiaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          constraints: BoxConstraints(
            minWidth: 16,
            minHeight: 16,
          ),
          child: Text(
            count > 9 ? '9+' : count.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: AppTheme.lightShadow,
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60, // Fixed, conservative height
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_icons.length, (index) {
              bool isSelected = _selectedIndex == index;
              return Expanded(
                child: _buildNavItem(index, isSelected),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isSelected) {
    // Using a simpler layout structure to avoid overflow issues
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: isSelected
              ? Border(
            top: BorderSide(
              color: AppTheme.tertiaryColor,
              width: 2.0,
            ),
          )
              : null,
        ),
        padding: EdgeInsets.only(top: isSelected ? 0 : 2), // Compensate for border height
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _icons[index],
              color: isSelected
                  ? AppTheme.tertiaryColor
                  : AppTheme.textTertiaryColor,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              _getTabTitle(index),
              style: TextStyle(
                color: isSelected
                    ? AppTheme.tertiaryColor
                    : AppTheme.textTertiaryColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getTabTitle(int index) {
    if (index < _titles.length) {
      return _titles[index];
    }
    return '';
  }
}

// Updated search delegate to use the new theme
class CustomSearchDelegate extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return AppTheme.lightTheme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppTheme.primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      scaffoldBackgroundColor: AppTheme.surfaceColor,
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      AnimatedOpacity(
        opacity: query.isNotEmpty ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        child: IconButton(
          icon: Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            query = '';
          },
          tooltip: 'Clear',
        ),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, '');
      },
      tooltip: 'Back',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: AppTheme.textTertiaryColor.withOpacity(0.5),
            ),
            SizedBox(height: 24),
            Text(
              'Search for courses, topics, or instructors',
              style: AppTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('courses')
          .where('courseTitle', isGreaterThanOrEqualTo: query)
          .where('courseTitle', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tertiaryColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_outlined,
                  size: 64,
                  color: AppTheme.textTertiaryColor.withOpacity(0.5),
                ),
                SizedBox(height: 24),
                Text(
                  'No courses found for "$query"',
                  style: AppTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          padding: EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/courseScreen',
                    arguments: doc.id,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['imageUrl'] ?? 'https://via.placeholder.com/60',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              child: Icon(
                                Icons.book_outlined,
                                color: AppTheme.primaryColor,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['courseTitle'] ?? 'Unknown Course',
                              style: AppTheme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              data['instructor'] ?? 'Unknown Instructor',
                              style: AppTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 14,
                                  color: AppTheme.textTertiaryColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${data['students'] ?? 0} students',
                                  style: AppTheme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textTertiaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.secondaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}