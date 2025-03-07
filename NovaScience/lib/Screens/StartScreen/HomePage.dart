import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../AdminPanal/AdminPanelScreen.dart';
import 'HomeScreen.dart';
import 'ProfileScreen.dart';
import 'SettingScreen.dart';
import 'TeacherScreen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // Color palette
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color maroonColor = const Color(0xFF722626);
  final Color accentColor = const Color(0xFFe9c46a);

  // Secondary colors
  final Color backgroundColor = const Color(0xFFF5F5F5);
  final Color surfaceColor = Colors.white;
  final Color errorColor = const Color(0xFFD32F2F);

  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  bool isAdmin = false;
  bool isTeacher = false;
  bool _isLoading = true;
  late AnimationController _animationController;

  final List<Widget> _commonPages = [];
  final List<String> _commonTitles = [
    'Dashboard',
    'Profile',
    'Settings',
  ];

  List<Widget> _pages = [];
  List<String> _titles = [];

  // Page icons (using outline variants for a more professional look)
  final List<IconData> _commonIcons = [
    Icons.dashboard_outlined,
    Icons.person_outline,
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

    // Initialize common pages
    _commonPages.addAll([
      HomeScreen(),
      ProfileScreen(),
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
      } else {
        setState(() {
          _pages = List.from(_commonPages);
          _titles = List.from(_commonTitles);
          _icons = List.from(_commonIcons);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking user role: $e');
      setState(() {
        _pages = List.from(_commonPages);
        _titles = List.from(_commonTitles);
        _icons = List.from(_commonIcons);
        _isLoading = false;
      });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: greenColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 80,
              width: 80,
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: greenColor,
      elevation: 0,
      toolbarHeight: 64,
      centerTitle: false,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 32,
            width: 32,
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOVA LEARN',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _titles[_selectedIndex],
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _buildSearchButton(),
        _buildNotificationButton(),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchButton() {
    return IconButton(
      icon: Icon(
        Icons.search_outlined,
        size: 24,
        color: Colors.white,
      ),
      onPressed: () {
        // Open search functionality
        showSearch(
          context: context,
          delegate: CustomSearchDelegate(
            greenColor: greenColor,
            yellowColor: yellowColor,
            maroonColor: maroonColor,
            accentColor: accentColor,
          ),
        );
      },
      tooltip: 'Search',
    );
  }

  Widget _buildNotificationButton() {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              size: 24,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            tooltip: 'Notifications',
          ),
          Positioned(
            top: 10,
            right: 10,
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
            color: maroonColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: greenColor,
              width: 1.5,
            ),
          ),
          constraints: BoxConstraints(
            minWidth: 16,
            minHeight: 16,
          ),
          child: Text(
            count > 9 ? '9+' : count.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
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
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icons.length, (index) {
              bool isSelected = _selectedIndex == index;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onItemTapped(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _icons[index],
                          color: isSelected ? maroonColor : Colors.grey.shade600,
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          _getTabTitle(index),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                            color: isSelected ? maroonColor : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0: return 'Dashboard';
      case 1: return 'Profile';
      case 2: return 'Settings';
      case 3:
        if (isAdmin) return 'Admin';
        if (isTeacher) return 'Teaching';
        return '';
      default: return '';
    }
  }
}

// Custom search delegate
class CustomSearchDelegate extends SearchDelegate<String> {
  final Color greenColor;
  final Color yellowColor;
  final Color maroonColor;
  final Color accentColor;

  CustomSearchDelegate({
    required this.greenColor,
    required this.yellowColor,
    required this.maroonColor,
    required this.accentColor,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: Colors.white),
        onPressed: () {
          query = '';
        },
        tooltip: 'Clear',
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
              valueColor: AlwaysStoppedAnimation<Color>(maroonColor),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_outlined, size: 48, color: Colors.grey.shade400),
                SizedBox(height: 16),
                Text(
                  'No results found',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.grey.shade600,
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
              margin: EdgeInsets.only(bottom: 8),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    data['imageUrl'] ?? 'https://via.placeholder.com/50',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                      );
                    },
                  ),
                ),
                title: Text(
                  data['courseTitle'] ?? 'Unknown Course',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500,
                    color: greenColor,
                  ),
                ),
                subtitle: Text(
                  data['instructor'] ?? 'Unknown Instructor',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward,
                  size: 16,
                  color: yellowColor,
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/courseScreen',
                    arguments: doc.id,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey.shade300),
            SizedBox(height: 16),
            Text(
              'Search for courses',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return buildResults(context);
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: greenColor,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: GoogleFonts.roboto(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.roboto(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
      scaffoldBackgroundColor: Colors.white,
    );
  }
}