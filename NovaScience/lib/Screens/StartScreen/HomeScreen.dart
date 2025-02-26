import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:nova_science/Screens/AddCourseScreen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Service/AdvertisementProvider.dart';
import '../../Service/AuthService.dart';
import '../../Service/CourseProvider.dart';
import '../AdvertisementCarousel.dart';
import 'CourseCard.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Color palette
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color maroonColor = const Color(0xFF722626);
  final Color accentColor = const Color(0xFFe9c46a);

  // Secondary colors
  final Color backgroundColor = const Color(0xFFF5F5F5);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF333333);
  final Color textSecondaryColor = const Color(0xFF666666);

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  bool isAdmin = false;
  bool _isRefreshing = false;
  AuthService authService = AuthService();
  String _selectedMedium = "All";
  final List<String> _mediumOptions = ["All", "Tamil", "English", "Sinhala"];

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _searchController.addListener(_onSearchChanged);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _slideController.forward();
      Provider.of<CourseProvider>(context, listen: false).fetchCourses();
      Provider.of<AdvertisementProvider>(context, listen: false).fetchAdvertisements();
    });

    String userId = authService.currentUser!.uid;
    authService.checkAndUnenrollExpiredCourses(userId);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim().toLowerCase();
      if (query != _searchQuery) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  Future<List<QueryDocumentSnapshot<Object?>>> _getFilteredCourses(
      Future<List<QueryDocumentSnapshot<Object?>>?>? futureCourses) async {
    final courses = await futureCourses
        ?.then((value) => value ?? <QueryDocumentSnapshot<Object?>>[])
        ?? <QueryDocumentSnapshot<Object?>>[];

    // Filter approved courses
    final approvedCourses = courses.where((course) {
      final data = course.data() as Map<String, dynamic>?;
      return data?['isApproved'] == true;
    }).toList();

    // Filter by search query
    List<QueryDocumentSnapshot<Object?>> filtered = _searchQuery.isEmpty
        ? approvedCourses
        : approvedCourses.where((course) {
      final data = course.data() as Map<String, dynamic>?;
      final title = data?['courseTitle']?.toString().toLowerCase() ?? '';
      final instructor = data?['instructor']?.toString().toLowerCase() ?? '';
      final subject = data?['subject']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery) ||
          instructor.contains(_searchQuery) ||
          subject.contains(_searchQuery);
    }).toList();

    // Filter by medium if not "All"
    if (_selectedMedium != "All") {
      filtered = filtered.where((course) {
        final data = course.data() as Map<String, dynamic>?;
        final medium = data?['medium']?.toString().trim() ?? '';
        if (medium.isEmpty) return false;
        return medium.toLowerCase() == _selectedMedium.toLowerCase();
      }).toList();
    }
    return filtered;
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        isAdmin = userDoc.data()?['role'] == 'Admin';
      });
    } else {
      setState(() {
        isAdmin = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await Provider.of<CourseProvider>(context, listen: false).fetchCourses();
    await Provider.of<AdvertisementProvider>(context, listen: false).fetchAdvertisements();

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final advertisementProvider = Provider.of<AdvertisementProvider>(context);
    final isLoading = courseProvider.isLoading;
    final hasError = courseProvider.hasError;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddCourseScreen()),
          );
        },
        backgroundColor: maroonColor,
        child: Icon(Icons.add, color: Colors.white),
      )
          : null,
      body: LiquidPullToRefresh(
        onRefresh: _onRefresh,
        color: yellowColor,
        backgroundColor: Colors.white,
        height: 100,
        animSpeedFactor: 2,
        showChildOpacityTransition: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid parameters
            double width = constraints.maxWidth;
            int gridCount;
            double horizontalPadding;
            double cardAspectRatio;

            if (width > 1200) {
              gridCount = 5;
              horizontalPadding = 24.0;
              cardAspectRatio = 0.8;
            } else if (width > 900) {
              gridCount = 4;
              horizontalPadding = 20.0;
              cardAspectRatio = 0.8;
            } else if (width > 600) {
              gridCount = 3;
              horizontalPadding = 16.0;
              cardAspectRatio = 0.8;
            } else {
              gridCount = 2;
              horizontalPadding = 16.0;
              cardAspectRatio = 0.8;
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeroSection(),
                      SizedBox(height: 24),
                      _buildFilterRow(),
                      SizedBox(height: 24),
                      _buildAdvertisementSection(advertisementProvider),
                      _buildCourseSections(
                        courseProvider,
                        gridCount,
                        cardAspectRatio,
                      ),
                      SizedBox(height: 80), // Add space at the bottom
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: greenColor,
      elevation: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 32,
            width: 32,
          ),
          SizedBox(width: 12),
          Text(
            'NOVA SCIENCE',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.account_circle_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [greenColor, yellowColor],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Nova Science',
            style: GoogleFonts.roboto(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Access premium educational resources designed to enhance your academic excellence',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: greenColor,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'EXPLORE COURSES',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                hintStyle: GoogleFonts.roboto(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: yellowColor),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMedium,
              icon: Icon(Icons.arrow_drop_down, color: yellowColor),
              style: GoogleFonts.roboto(
                color: textPrimaryColor,
                fontSize: 14,
              ),
              items: _mediumOptions.map((String medium) {
                return DropdownMenuItem<String>(
                  value: medium,
                  child: Text(medium),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMedium = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvertisementSection(AdvertisementProvider advertisementProvider) {
    if (advertisementProvider.isLoading) {
      return Container(
        height: 160,
        margin: EdgeInsets.only(bottom: 24),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    if (advertisementProvider.advertisements.isEmpty) return SizedBox();

    return Container(
      height: 160,
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AdvertisementCarousel(
          advertisements: advertisementProvider.advertisements,
        ),
      ),
    );
  }

  Widget _buildCourseSections(
      CourseProvider courseProvider,
      int gridCount,
      double aspectRatio
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("My Learning", Icons.book_outlined),
        _buildMyCoursesSection(courseProvider, gridCount, aspectRatio),
        _buildSectionHeader("Premium Courses", Icons.workspace_premium_outlined),
        _buildCoursesGrid(courseProvider.getPremiumCourses(), gridCount, aspectRatio),
        _buildSectionHeader("Free Courses", Icons.play_circle_outline),
        _buildCoursesGrid(courseProvider.getFreeCourses(), gridCount, aspectRatio),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Icon(icon, color: maroonColor, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: greenColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesGrid(
      Future<List<QueryDocumentSnapshot<Object?>>?>? futureCourses,
      int gridCount,
      double aspectRatio
      ) {
    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>>(
      future: _getFilteredCourses(futureCourses),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid(gridCount);
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState("No courses found");
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            return _buildCourseItem(snapshot.data![index]);
          },
        );
      },
    );
  }

  Widget _buildCourseItem(QueryDocumentSnapshot<Object?> course) {
    final data = course.data() as Map<String, dynamic>;
    final authService = Provider.of<AuthService>(context, listen: false);

    return FutureBuilder<int>(
      future: authService.getEnrollmentCount(course.id),
      builder: (context, snapshot) {
        return CourseCard(
          courseTitle: data['courseTitle'] ?? 'New Course',
          time: data['duration'] ?? 'Self-paced',
          instructor: data['instructor'] ?? 'Expert Instructor',
          imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/150',
          subject: data['subject'] ?? 'General',
          id: course.id,
          rating: (data['averageRating']?.toDouble()) ?? 0.0,
          enrolledCount: snapshot.data,
          onTap: () => Navigator.pushNamed(
            context,
            '/courseScreen',
            arguments: course.id,
          ),
        );
      },
    );
  }

  Widget _buildShimmerGrid(int gridCount) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: gridCount * 2,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      height: 160,
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 32, color: yellowColor),
          SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCoursesSection(
      CourseProvider courseProvider,
      int gridCount,
      double aspectRatio
      ) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>?>(
      future: user != null ? courseProvider.getEnrolledCourses(user.uid) : null,
      builder: (context, snapshot) {
        if (user == null) {
          return _buildEmptyState("Sign in to view your courses");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid(gridCount);
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState("You haven't enrolled in any courses yet");
        }

        return _buildCoursesGrid(Future.value(snapshot.data), gridCount, aspectRatio);
      },
    );
  }
}