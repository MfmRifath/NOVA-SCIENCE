import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final RefreshController _refreshController =
  RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  bool isAdmin = false;
  AuthService authService = AuthService();
  String _selectedMedium = "All";
  final List<String> _mediumOptions = ["All", "Tamil", "English", "Sinhala"];

  // Custom Colors – adjust these to match your branding.
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color maroonColor = const Color(0xFF722626);

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false).fetchCourses();
      Provider.of<AdvertisementProvider>(context, listen: false)
          .fetchAdvertisements();
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

    // Filter approved courses.
    final approvedCourses = courses.where((course) {
      final data = course.data() as Map<String, dynamic>?;
      return data?['isApproved'] == true;
    }).toList();

    // Debug logging.
    approvedCourses.forEach((course) {
      final data = course.data() as Map<String, dynamic>?;
      print("Approved course: ${data?['courseTitle']} - Medium: ${data?['medium']}");
    });

    // Filter by search query.
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

    // Filter by medium if not "All".
    if (_selectedMedium != "All") {
      filtered = filtered.where((course) {
        final data = course.data() as Map<String, dynamic>?;
        final medium = data?['medium']?.toString().trim() ?? '';
        print("Filtering course: ${data?['courseTitle']} - Medium: $medium against $_selectedMedium");
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
        print("Admin Status: $isAdmin");
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
    await Provider.of<AdvertisementProvider>(context, listen: false)
        .fetchAdvertisements();
    _refreshController.refreshCompleted();
    print("Data Refreshed");
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final advertisementProvider =
    Provider.of<AdvertisementProvider>(context);
    final isLoading = courseProvider.isLoading;
    final hasError = courseProvider.hasError;

    print("HomeScreen Build: isLoading=$isLoading, hasError=$hasError");

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddCourseScreen()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: maroonColor,
        tooltip: 'Add Course',
      )
          : null,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: LiquidPullToRefresh(
              onRefresh: _onRefresh,
              color: yellowColor,
              height: 150,
              backgroundColor: Colors.white.withOpacity(0.9),
              animSpeedFactor: 2,
              showChildOpacityTransition: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive grid parameters based on available width.
                  double width = constraints.maxWidth;
                  int gridCount;
                  double padding;
                  double sectionTitleFontSize;
                  double cardAspectRatio;

                  if (width > 1200) {
                    gridCount = 6;
                    padding = 20.0;
                    sectionTitleFontSize = 24;
                    cardAspectRatio = 0.65;
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
                      SliverAppBar(
                        backgroundColor: yellowColor,
                        expandedHeight: 180,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          centerTitle: true,
                          title: Text("Welcome Back!"),
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [greenColor, yellowColor, maroonColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                              // Center a logo above the title.
                              Align(
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 30.0),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    height: 80,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildFilterRow(),
                            SizedBox(height: 30),
                            _buildAdvertisementSection(advertisementProvider),
                            _buildCourseSections(courseProvider, gridCount,
                                cardAspectRatio, sectionTitleFontSize),
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

  Widget _buildCourseSections(CourseProvider courseProvider, int gridCount,
      double aspectRatio, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("My Learning", Icons.school, fontSize),
        _buildMyCoursesSection(courseProvider, gridCount, aspectRatio),
        _buildSectionHeader("Premium Courses", Icons.workspace_premium, fontSize),
        _buildCoursesGrid(courseProvider.getPremiumCourses(), gridCount, aspectRatio),
        _buildSectionHeader("Free Courses", Icons.video_library, fontSize),
        _buildCoursesGrid(courseProvider.getFreeCourses(), gridCount, aspectRatio),
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search courses...',
          prefixIcon: Icon(Icons.search_rounded, color: yellowColor),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear_rounded),
            onPressed: () => _searchController.clear(),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildSearchBar()),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMedium,
                items: _mediumOptions.map((medium) {
                  return DropdownMenuItem<String>(
                    value: medium,
                    child: Text(medium),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMedium = value;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesGrid(
      Future<List<QueryDocumentSnapshot<Object?>>?>? futureCourses,
      int gridCount,
      double aspectRatio) {
    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>>(
      future: _getFilteredCourses(futureCourses),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid(gridCount);
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(Icons.error_outline, "No courses found");
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            return FadeInUp(
              delay: Duration(milliseconds: index * 100),
              duration: Duration(milliseconds: 500),
              child: _buildCourseItem(snapshot.data![index]),
            );
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

  // Advertisement Section.
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
      child: AdvertisementCarousel(
          advertisements: advertisementProvider.advertisements),
    );
  }

  // My Courses Section.
  Widget _buildMyCoursesSection(
      CourseProvider courseProvider, int gridCount, double aspectRatio) {
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
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
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
            greenColor,
            yellowColor,
            maroonColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}