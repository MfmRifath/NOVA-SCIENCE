// HomeScreen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:nova_science/Screens/AddCourseScreen.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';

import '../../Service/AdvertisementProvider.dart';
import '../../Service/AuthService.dart';
import '../../Service/CourseProvider.dart';
import '../AdvertisementCarousel.dart';

import 'CourseCard.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false).fetchCourses();
      Provider.of<AdvertisementProvider>(context, listen: false).fetchAdvertisements();
    });
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

  Future<List<QueryDocumentSnapshot<Object?>>> _getFilteredCourses(Future<List<QueryDocumentSnapshot<Object?>>?>? futureCourses) async {
    final courses = await futureCourses?.then((value) => value ?? <QueryDocumentSnapshot<Object?>>[]) ?? <QueryDocumentSnapshot<Object?>>[];
    if (_searchQuery.isEmpty) {
      return courses;
    } else {
      return courses.where((course) {
        final data = course.data() as Map<String, dynamic>?;
        final title = data?['courseTitle']?.toString().toLowerCase() ?? '';
        final instructor = data?['instructor']?.toString().toLowerCase() ?? '';
        final subject = data?['subject']?.toString().toLowerCase() ?? '';
        return title.contains(_searchQuery) || instructor.contains(_searchQuery) || subject.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        isAdmin = userDoc.data()?['role'] == 'Admin';
        print("Admin Status: $isAdmin"); // Debug Statement
      });
    } else {
      setState(() {
        isAdmin = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Provider.of<CourseProvider>(context, listen: false).fetchCourses();
    await Provider.of<AdvertisementProvider>(context, listen: false).fetchAdvertisements();
    _refreshController.refreshCompleted();
    print("Data Refreshed"); // Debug Statement
  }


  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final advertisementProvider = Provider.of<AdvertisementProvider>(context);
    final isLoading = courseProvider.isLoading;
    final hasError = courseProvider.hasError;

    print("HomeScreen Build: isLoading=$isLoading, hasError=$hasError"); // Debug Statement

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddCourseScreen()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        tooltip: 'Add Course',
      )
          : null,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: LiquidPullToRefresh(
              onRefresh: _onRefresh,
              color: Colors.blueAccent,
              height: 150,
              backgroundColor: Colors.white.withOpacity(0.9),
              animSpeedFactor: 2,
              showChildOpacityTransition: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Determine breakpoints
                  double width = constraints.maxWidth;
                  int gridCount;
                  double padding = 16.0;
                  double sectionTitleFontSize = 22;
                  double cardAspectRatio = 0.7;  // Reduced from 0.75

                  if (width > 1200) {
                    gridCount = 6;  // Increased number of columns
                    padding = 20.0;
                    sectionTitleFontSize = 24;
                    cardAspectRatio = 0.65;  // More narrow aspect ratio
                  } else if (width > 1000) {
                    gridCount = 5;
                    padding = 18.0;
                    sectionTitleFontSize = 22;
                    cardAspectRatio = 0.65;
                  } else if (width > 800) {
                    gridCount = 4;
                    padding = 16.0;
                    sectionTitleFontSize = 20;
                    cardAspectRatio = 0.65;
                  } else if (width > 600) {
                    gridCount = 3;
                    padding = 14.0;
                    sectionTitleFontSize = 18;
                    cardAspectRatio = 0.7;
                  } else {
                    gridCount = 2;
                    padding = 12.0;
                    sectionTitleFontSize = 16;
                    cardAspectRatio = 0.75;
                  }
                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildSearchBar(),
                            SizedBox(height: 30),
                            _buildAdvertisementSection(advertisementProvider),
                            _buildCourseSections(courseProvider, gridCount, cardAspectRatio, sectionTitleFontSize),
                          ]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSections(CourseProvider courseProvider, int gridCount, double aspectRatio, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Free Courses", Icons.video_library, fontSize),
        _buildCoursesGrid(courseProvider.getFreeCourses(), gridCount, aspectRatio),
        _buildSectionHeader("Premium Courses", Icons.workspace_premium, fontSize),
        _buildCoursesGrid(courseProvider.getPremiumCourses(), gridCount, aspectRatio),
        _buildSectionHeader("My Learning", Icons.school, fontSize),
        _buildMyCoursesSection(courseProvider, gridCount, aspectRatio),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: fontSize + 4),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search courses...',
          prefixIcon: Icon(Icons.search_rounded, color: Colors.blueAccent),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear_rounded),
            onPressed: () => _searchController.clear(),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesGrid(
      Future<List<QueryDocumentSnapshot<Object?>>?>? futureCourses,
      int gridCount,
      double aspectRatio,
      ) {
    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>>(
      future: _getFilteredCourses(futureCourses),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid(gridCount);
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(Icons.error_outline, "No courses found");
        }

        return AnimationLimiter(
          child: GridView.builder(
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
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 500),
                columnCount: gridCount,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: _buildCourseItem(snapshot.data![index]),
                  ),
                ),
              );
            },
          ),
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
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      height: 200,
      margin: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.white.withOpacity(0.6)),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Update advertisement section
  Widget _buildAdvertisementSection(AdvertisementProvider advertisementProvider) {
    if (advertisementProvider.isLoading) {
      return Container(
        height: 180,
        margin: EdgeInsets.only(bottom: 30),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    if (advertisementProvider.advertisements.isEmpty) return SizedBox();

    return Container(
      height: 180,
      margin: EdgeInsets.only(bottom: 30),
      child: AdvertisementCarousel(advertisements: advertisementProvider.advertisements),
    );
  }

  // Update My Courses section
  Widget _buildMyCoursesSection(CourseProvider courseProvider, int gridCount, double aspectRatio) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>?>(
      future: user != null ? courseProvider.getEnrolledCourses(user.uid) : null,
      builder: (context, snapshot) {
        if (user == null) {
          return _buildEmptyState(
            Icons.login_rounded,
            "Sign in to view your courses",
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid(gridCount);
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            Icons.menu_book_rounded,
            "Start your learning journey!\nExplore our courses",
          );
        }

        return _buildCoursesGrid(Future.value(snapshot.data), gridCount, aspectRatio);
      },
    );
  }
  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade800,
            Colors.blue.shade400,
            Colors.purple.shade300,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}