import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nova_science/Screens/AddCourseScreen.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../Service/AuthService.dart';
import '../../Service/CourseProvider.dart';
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
  bool isAdmin = false; // Admin flag

  @override
  void initState() {
    super.initState();
    _checkAdminStatus(); // Check if the user is an admin
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false).fetchCourses();
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

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        isAdmin = userDoc.data()?['role'] == 'Admin'; // Check the role field

        // Update pages and titles dynamically based on admin role

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
    _refreshController.refreshCompleted();
  }

  Future<List<QueryDocumentSnapshot<Object?>>> _getFilteredCourses(Future<List<QueryDocumentSnapshot<Object?>>?>? futureCourses) async {
    final courses = await futureCourses?.then((value) => value ?? <QueryDocumentSnapshot<Object?>>[]) ?? <QueryDocumentSnapshot<Object?>>[];
    if (_searchQuery.isEmpty) {
      return courses;
    } else {
      return courses.where((course) {
        final data = course.data() as Map<String, dynamic>?;
        final title = data?['courseTitle']?.toString().toLowerCase() ?? '';
        final description = data?['description']?.toString().toLowerCase() ?? '';
        return title.contains(_searchQuery) || description.contains(_searchQuery);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final isLoading = courseProvider.isLoading;
    final hasError = courseProvider.hasError;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Welcome RN",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
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
          : null, // Show only if the user is an admin
      body: Stack(
        children: [
          _buildBackground(),
          SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            enablePullDown: true,
            header: WaterDropHeader(
              complete: Icon(Icons.check, color: Colors.green),
              failed: Icon(Icons.error, color: Colors.red),
            ),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _buildSearchBar(),
                        SizedBox(height: 30),
                        _buildSectionTitle("Free Watching"),
                        SizedBox(height: 15),
                        _buildCoursesGrid(isLoading, hasError, courseProvider.getFreeCourses()),
                        SizedBox(height: 30),
                        _buildSectionTitle("Premium Courses"),
                        SizedBox(height: 15),
                        _buildCoursesGrid(isLoading, hasError, courseProvider.getPremiumCourses()),
                        SizedBox(height: 30),
                        _buildSectionTitle("My Courses"),
                        SizedBox(height: 15),
                        _buildMyCoursesSection(courseProvider, context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        hintText: 'Search courses...',
        prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
        contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 4),
        Container(
          width: 50,
          height: 3,
          color: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildCoursesGrid(bool isLoading, bool hasError, Future<List<QueryDocumentSnapshot<Object?>>?>? futureCourses) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (hasError) {
      return Center(
        child: Text("Failed to load courses.", style: TextStyle(color: Colors.red)),
      );
    } else {
      return FutureBuilder<List<QueryDocumentSnapshot<Object?>>>(
        future: _getFilteredCourses(futureCourses),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Failed to load courses.", style: TextStyle(color: Colors.red)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("No courses found.", style: TextStyle(color: Colors.white)),
            );
          }
          return _buildCoursesGridView(snapshot.data!, context);
        },
      );
    }
  }



  Widget _buildCoursesGridView(List<QueryDocumentSnapshot<Object?>> courses, BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false); // Get AuthService

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final course = courses[index];
        final data = course.data() as Map<String, dynamic>?;

        if (data == null) {
          return Container();
        }

        final courseTitle = data['courseTitle'] ?? 'Untitled Course';
        final instructor = data['instructor'] ?? 'No instructor specified.';
        final time = data['duration'] ?? 'Duration not specified';
        final imageUrl = data['imageUrl'] ?? 'assets/images/default_image.jpg';
        final rating = data['averageRating'] != null ? double.parse(data['averageRating'].toString()) : 0.0;
        final subject = data['subject'] ?? 'Subject not specified';

        return FutureBuilder<int>(
          future: authService.getEnrollmentCount(course.id), // Fetch enrollment count
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator()); // Loading indicator
            }
            final enrolledCount = snapshot.data ?? 0; // Default to 0 if null

            return CourseCard(
              courseTitle: courseTitle,
              time: time,
              instructor: instructor,
              imageUrl: imageUrl,
              id: course.id,
              rating: rating,
              enrolledCount: enrolledCount,
              subject: subject,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/courseScreen',
                  arguments: course.id,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMyCoursesSection(CourseProvider courseProvider, BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? currentUserId = user?.uid;

    if (currentUserId == null) {
      return Center(
        child: Text(
          "Please log in to view your courses.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>?>(
      future: courseProvider.getEnrolledCourses(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Failed to load your courses.", style: TextStyle(color: Colors.red)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "You have not enrolled in any courses.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        return _buildCoursesGridView(snapshot.data!, context);
      },
    );
  }
}