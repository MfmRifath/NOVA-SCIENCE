import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart';

// Custom color scheme matching your app
class AppColors {
  static const Color primaryGreen = Color(0xFF11261F);
  static const Color secondaryBlue = Color(0xFF123755);
  static const Color accentMaroon = Color(0xFF722626);
  static const Color accentYellow = Color(0xFFe9c46a);
  static const Color lightBackground = Color(0xFFF7F7F2);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF242424);
  static const Color textSecondary = Color(0xFF6C6C6C);
  static const Color textLight = Color(0xFFF9FAFB);
}

// Breakpoints for responsive design
class Breakpoints {
  static const double small = 600; // Phone
  static const double medium = 1200; // Tablet
  static const double large = 1920; // Desktop
}

// Extension method to create lists with separators
extension ListWithSeparatorExtension<T> on List<T> {
  List<Widget> separatedBy(Widget separator) {
    if (isEmpty) return [];
    if (length == 1) return [this[0] as Widget];

    return List.generate(length * 2 - 1, (index) {
      if (index.isEven) {
        return this[index ~/ 2] as Widget;
      }
      return separator;
    });
  }
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Filter states
  String _selectedTimeRange = 'Last 6 Months';
  String _selectedSubject = 'All Subjects';
  String _selectedMedium = 'All Mediums';
  bool _isLoading = true;
  bool _showFloatingStats = false;

  // Analytics data
  Map<String, dynamic> _dashboardStats = {};
  List<Course> _allCourses = [];
  Map<String, int> _usersByRole = {};
  Map<String, int> _coursesBySubject = {};
  Map<String, int> _coursesByMedium = {};
  Map<String, int> _userRegistrationsByMonth = {};
  Map<String, double> _revenueByMonth = {};
  Map<String, double> _feedbackByRating = {};
  List<Map<String, dynamic>> _topCourses = [];
  Map<String, int> _courseCompletionRates = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
    _fetchInitialData();
  }

  void _onScroll() {
    setState(() {
      _showFloatingStats = _scrollController.offset > 200;
    });
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _fetchAllCourses(), // Fetch all courses first
        _fetchDashboardStats(),
        _fetchUsersByRole(),
        _fetchUserRegistrationTrends(),
        _fetchRevenueTrends(),
        _fetchCoursesByCategory(),
        _fetchFeedbackAnalytics(),
        _fetchCourseCompletionRates(),
      ]);

      setState(() => _isLoading = false);
    } catch (error) {
      print('Error fetching analytics data: $error');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAllCourses() async {
    try {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      await courseProvider.fetchCourses();

      final coursesSnapshot = await FirebaseFirestore.instance.collection('courses').get();
      List<Course> courses = [];

      for (var doc in coursesSnapshot.docs) {
        final data = doc.data();
        courses.add(Course.fromMap(data, doc.id));
      }

      setState(() {
        _allCourses = courses;
      });

      // Calculate top courses after getting all courses
      _calculateTopCourses();

    } catch (e) {
      print('Error fetching all courses: $e');
    }
  }

  void _calculateTopCourses() {
    // Sort courses by enrollments or ratings
    List<Map<String, dynamic>> topCourses = [];

    for (var course in _allCourses) {
      int enrollmentCount = course.enrolledUserIds?.length ?? 0;
      double averageRating = course.averageRating ?? 0.0;

      topCourses.add({
        'id': course.id,
        'title': course.courseTitle ?? 'Untitled Course',
        'instructor': course.instructor ?? 'Unknown',
        'enrollments': enrollmentCount,
        'rating': averageRating,
        'price': course.price ?? 0.0,
        'revenue': enrollmentCount * (course.price ?? 0.0),
        'subject': course.subject ?? 'Unknown',
        'medium': course.medium ?? 'Unknown',
      });
    }

    // Sort by revenue (highest first)
    topCourses.sort((a, b) => b['revenue'].compareTo(a['revenue']));

    setState(() {
      _topCourses = topCourses;
    });
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

      // Get logged in users
      int activeUsers = await courseProvider.getNumberOfLoggedInUsers();
      int totalUsers = usersSnapshot.docs.length;

      // Course stats
      int totalCourses = _allCourses.length;
      int premiumCourses = _allCourses.where((course) => course.status == 'premium').length;
      int freeCourses = _allCourses.where((course) => course.status == 'free').length;

      // Calculate total enrollments and revenue
      int totalEnrollments = 0;
      double totalRevenue = 0.0;

      for (var course in _allCourses) {
        int enrollmentCount = course.enrolledUserIds?.length ?? 0;
        totalEnrollments += enrollmentCount;

        // Calculate revenue only for premium courses
        if (course.status?.toLowerCase() == 'premium') {
          totalRevenue += enrollmentCount * (course.price ?? 0.0);
        }
      }

      // Calculate average rating across all courses
      double totalRating = 0.0;
      int ratedCourses = 0;

      for (var course in _allCourses) {
        if (course.averageRating != null && course.averageRating! > 0) {
          totalRating += course.averageRating!;
          ratedCourses++;
        }
      }

      double averageRating = ratedCourses > 0 ? totalRating / ratedCourses : 0.0;

      setState(() {
        _dashboardStats = {
          'totalUsers': totalUsers,
          'activeUsers': activeUsers,
          'totalCourses': totalCourses,
          'premiumCourses': premiumCourses,
          'freeCourses': freeCourses,
          'totalEnrollments': totalEnrollments,
          'totalRevenue': totalRevenue,
          'averageRating': averageRating,
        };
      });
    } catch (e) {
      print('Error fetching dashboard stats: $e');
    }
  }

  Future<void> _fetchUsersByRole() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

      Map<String, int> roleCount = {
        'Admin': 0,
        'Teacher': 0,
        'User': 0,
        'Other': 0,
      };

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final role = userData['role'] as String? ?? 'User';

        if (roleCount.containsKey(role)) {
          roleCount[role] = roleCount[role]! + 1;
        } else {
          roleCount['Other'] = roleCount['Other']! + 1;
        }
      }

      setState(() {
        _usersByRole = roleCount;
      });
    } catch (e) {
      print('Error fetching users by role: $e');
    }
  }

  Future<void> _fetchCoursesByCategory() async {
    try {
      Map<String, int> subjectCount = {};
      Map<String, int> mediumCount = {};

      for (var course in _allCourses) {
        // Process subjects
        final subject = course.subject ?? 'Unknown';
        if (subjectCount.containsKey(subject)) {
          subjectCount[subject] = subjectCount[subject]! + 1;
        } else {
          subjectCount[subject] = 1;
        }

        // Process mediums
        final medium = course.medium ?? 'Unknown';
        if (mediumCount.containsKey(medium)) {
          mediumCount[medium] = mediumCount[medium]! + 1;
        } else {
          mediumCount[medium] = 1;
        }
      }

      setState(() {
        _coursesBySubject = subjectCount;
        _coursesByMedium = mediumCount;
      });
    } catch (e) {
      print('Error fetching courses by category: $e');
    }
  }

  Future<void> _fetchUserRegistrationTrends() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      Map<String, int> monthlyRegistrations = {};

      // Get number of months to show based on selected time range
      int monthsToShow = _getMonthsFromTimeRange();

      // Initialize all months with zero count
      for (int i = 0; i < monthsToShow; i++) {
        final date = DateTime.now().subtract(Duration(days: 30 * i));
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyRegistrations[monthKey] = 0;
      }

      // Count registrations per month
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        if (userData['registeredDate'] != null) {
          final registeredDate = (userData['registeredDate'] as Timestamp).toDate();

          // Only count if within time range
          if (registeredDate.isAfter(DateTime.now().subtract(Duration(days: 30 * monthsToShow)))) {
            final monthKey = '${registeredDate.year}-${registeredDate.month.toString().padLeft(2, '0')}';
            monthlyRegistrations.update(
              monthKey,
                  (value) => value + 1,
              ifAbsent: () => 1,
            );
          }
        }
      }

      setState(() {
        _userRegistrationsByMonth = Map.fromEntries(
            monthlyRegistrations.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key))
        );
      });
    } catch (e) {
      print('Error fetching user registration trends: $e');
    }
  }

  Future<void> _fetchRevenueTrends() async {
    try {
      Map<String, double> monthlyRevenue = {};

      // Get number of months to show based on selected time range
      int monthsToShow = _getMonthsFromTimeRange();

      // Initialize all months with zero count
      for (int i = 0; i < monthsToShow; i++) {
        final date = DateTime.now().subtract(Duration(days: 30 * i));
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyRevenue[monthKey] = 0.0;
      }

      // Go through all users
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final enrolledCourses = userData['enrolledCourses'] as List<dynamic>?;

        if (enrolledCourses != null) {
          for (var enrollment in enrolledCourses) {
            if (enrollment is Map<String, dynamic>) {
              final Timestamp? enrollmentDate = enrollment['enrollmentDate'];
              final String? courseId = enrollment['courseId'];

              if (enrollmentDate != null && courseId != null) {
                final enrollDate = enrollmentDate.toDate();

                // Only count if within time range
                if (enrollDate.isAfter(DateTime.now().subtract(Duration(days: 30 * monthsToShow)))) {
                  final monthKey = '${enrollDate.year}-${enrollDate.month.toString().padLeft(2, '0')}';

                  // Find the course and add its price to the revenue
                  final course = _allCourses.firstWhere(
                        (c) => c.id == courseId,
                    orElse: () => Course(),
                  );

                  if (course.price != null && course.status?.toLowerCase() == 'premium') {
                    monthlyRevenue.update(
                      monthKey,
                          (value) => value + course.price!,
                      ifAbsent: () => course.price!,
                    );
                  }
                }
              }
            }
          }
        }
      }

      setState(() {
        _revenueByMonth = Map.fromEntries(
            monthlyRevenue.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key))
        );
      });
    } catch (e) {
      print('Error fetching revenue trends: $e');
    }
  }

  Future<void> _fetchFeedbackAnalytics() async {
    try {
      Map<String, double> ratingDistribution = {
        '5 Stars': 0,
        '4 Stars': 0,
        '3 Stars': 0,
        '2 Stars': 0,
        '1 Star': 0,
      };

      int totalFeedbacks = 0;

      for (var course in _allCourses) {
        for (var feedback in course.feedbacks) {
          totalFeedbacks++;

          // Round rating to nearest integer
          int ratingInt = (feedback.rating ?? 0.0).round();

          switch (ratingInt) {
            case 5:
              ratingDistribution['5 Stars'] = ratingDistribution['5 Stars']! + 1;
              break;
            case 4:
              ratingDistribution['4 Stars'] = ratingDistribution['4 Stars']! + 1;
              break;
            case 3:
              ratingDistribution['3 Stars'] = ratingDistribution['3 Stars']! + 1;
              break;
            case 2:
              ratingDistribution['2 Stars'] = ratingDistribution['2 Stars']! + 1;
              break;
            case 1:
              ratingDistribution['1 Star'] = ratingDistribution['1 Star']! + 1;
              break;
          }
        }
      }

      // Convert counts to percentages
      if (totalFeedbacks > 0) {
        ratingDistribution.forEach((key, value) {
          ratingDistribution[key] = (value / totalFeedbacks) * 100;
        });
      }

      setState(() {
        _feedbackByRating = ratingDistribution;
      });
    } catch (e) {
      print('Error fetching feedback analytics: $e');
    }
  }

  Future<void> _fetchCourseCompletionRates() async {
    try {
      // In a real system, you'd get actual completion data
      // For now, we're simplifying with some assumptions

      Map<String, int> completionRates = {
        'Completed': 0,
        'In Progress': 0,
        'Not Started': 0,
      };

      int totalEnrollments = 0;
      int totalCompletions = 0;
      int totalInProgress = 0;

      for (var course in _allCourses) {
        int enrollments = course.enrolledUserIds?.length ?? 0;
        totalEnrollments += enrollments;

        // Assume 60% completion rate across platform (for demo)
        int completedUsers = (enrollments * 0.6).round();
        int inProgressUsers = (enrollments * 0.3).round();

        totalCompletions += completedUsers;
        totalInProgress += inProgressUsers;
      }

      int notStarted = totalEnrollments - totalCompletions - totalInProgress;

      completionRates['Completed'] = totalCompletions;
      completionRates['In Progress'] = totalInProgress;
      completionRates['Not Started'] = notStarted;

      setState(() {
        _courseCompletionRates = completionRates;
      });
    } catch (e) {
      print('Error fetching course completion rates: $e');
    }
  }

  int _getMonthsFromTimeRange() {
    switch (_selectedTimeRange) {
      case 'Last Month':
        return 1;
      case 'Last 3 Months':
        return 3;
      case 'Last 6 Months':
        return 6;
      case 'Last Year':
        return 12;
      default:
        return 6;
    }
  }

  String formatMonthKey(String monthKey) {
    try {
      final parts = monthKey.split('-');
      if (parts.length == 2) {
        final year = parts[0];
        final month = int.tryParse(parts[1]);
        if (month != null) {
          return '${DateFormat('MMM').format(DateTime(2023, month))} $year';
        }
      }
    } catch (e) {
      // Fall back to original format in case of any error
    }
    return monthKey;
  }

  double _calculateHealthScore() {
    // Calculate based on key metrics - this is a simplified example
    final userGrowthRate = 5.2; // Example percentage
    final courseCompletionRate = _dashboardStats['totalEnrollments'] != null && _dashboardStats['totalEnrollments'] > 0
        ? (_courseCompletionRates['Completed'] ?? 0) / _dashboardStats['totalEnrollments']! * 100
        : 0.0;
    final activeUserRate = _dashboardStats['totalUsers'] != null && _dashboardStats['totalUsers'] > 0
        ? (_dashboardStats['activeUsers'] ?? 0) / _dashboardStats['totalUsers']! * 100
        : 0.0;
    final averageRating = _dashboardStats['averageRating'] ?? 0.0;

    // Weight different factors
    double score = 0.0;
    score += userGrowthRate * 3;      // Weight: 30%
    score += courseCompletionRate * 0.2; // Weight: 20%
    score += activeUserRate * 0.3;    // Weight: 30%
    score += (averageRating / 5.0) * 20; // Weight: 20%

    return score;
  }

  Color _getHealthScoreColor() {
    final score = _calculateHealthScore();
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.deepOrange;
    return Colors.red;
  }

  String _getCourseCompletionInsight() {
    final total = _courseCompletionRates.values.fold(0, (a, b) => a + b);
    if (total == 0) return '';

    final completionPercent = (_courseCompletionRates['Completed'] ?? 0) / total * 100;

    if (completionPercent >= 70) {
      return 'excellent! Your course material seems to be engaging and well-structured.';
    } else if (completionPercent >= 50) {
      return 'good, but there may be room for improvement in course engagement.';
    } else if (completionPercent >= 30) {
      return 'below average. Consider reviewing your course content and structure to improve completion rates.';
    } else {
      return 'concerning. Urgent attention is needed to improve course completion rates.';
    }
  }

  String _calculateAvgContentPerSection(int totalContent) {
    int totalSections = 0;
    for (var course in _allCourses) {
      totalSections += course.sections.length;
    }

    if (totalSections > 0) {
      return (totalContent / totalSections).toStringAsFixed(1);
    }
    return '0';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < Breakpoints.small;
    final isMediumScreen = screenSize.width >= Breakpoints.small && screenSize.width < Breakpoints.medium;
    final isLargeScreen = screenSize.width >= Breakpoints.medium;

    // Determine orientation
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Education Analytics',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filter options',
            onPressed: () => _showFilterOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
            onPressed: _fetchInitialData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2.0),
          child: Container(
            color: AppColors.accentYellow,
            height: 2.0,
          ),
        ),
      ),
      floatingActionButton: _showFloatingStats
          ? FloatingActionButton.extended(
        onPressed: () {
          _scrollController.animateTo(0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut);
        },
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.arrow_upward),
        label: Text(
          'Dashboard',
          style: TextStyle(color: AppColors.textLight),
        ),
      )
          : null,
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.accentYellow),
            SizedBox(height: 16),
            Text('Loading analytics data...'),
          ],
        ),
      )
          : SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Dashboard header
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.7),
                      AppColors.lightBackground,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Education Platform Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Filter chips row - horizontal scrollable
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: _selectedTimeRange,
                            icon: Icons.date_range,
                            onTap: () => _showFilterOptions(context),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: _selectedSubject,
                            icon: Icons.book,
                            onTap: () => _showSubjectFilterDialog(context),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: _selectedMedium,
                            icon: Icons.language,
                            onTap: () => _showMediumFilterDialog(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Key stats - Responsive layout
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildResponsiveStatsGrid(
                        isSmallScreen: isSmallScreen,
                        isMediumScreen: isMediumScreen,
                        isPortrait: isPortrait,
                      ),
                    ),

                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryGreen,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primaryGreen,
                  indicatorWeight: 3,
                  isScrollable: true,
                  tabs: [
                    Tab(
                      text: 'Overview',
                      icon: Icon(Icons.dashboard),
                    ),
                    Tab(
                      text: 'User Analytics',
                      icon: Icon(Icons.people),
                    ),
                    Tab(
                      text: 'Course Analytics',
                      icon: Icon(Icons.school),
                    ),
                    Tab(
                      text: 'Revenue Analytics',
                      icon: Icon(Icons.trending_up),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              // Overview Tab with responsive layout
              _buildResponsiveOverviewTab(isSmallScreen, isMediumScreen),

              // User Analytics Tab with responsive layout
              _buildResponsiveUserAnalyticsTab(isSmallScreen, isMediumScreen),

              // Course Analytics Tab with responsive layout
              _buildResponsiveCourseAnalyticsTab(isSmallScreen, isMediumScreen),

              // Revenue Analytics Tab with responsive layout
              _buildResponsiveRevenueAnalyticsTab(isSmallScreen, isMediumScreen),
            ],
          ),
        ),
      ),
    );
  }

  // Responsive widget builders
  Widget _buildResponsiveStatsGrid({
    required bool isSmallScreen,
    required bool isMediumScreen,
    required bool isPortrait,
  }) {
    // For very small screens in portrait mode, stack the stats vertically
    if (isSmallScreen && isPortrait) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildStatCard(
                label: 'Total Users',
                value: _dashboardStats['totalUsers']?.toString() ?? '0',
                icon: Icons.people,
                iconColor: Colors.blue,
              )),
              SizedBox(width: 8),
              Expanded(child: _buildStatCard(
                label: 'Total Courses',
                value: _dashboardStats['totalCourses']?.toString() ?? '0',
                icon: Icons.school,
                iconColor: Colors.purple,
              )),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildStatCard(
                label: 'Revenue',
                value: '\$${NumberFormat("#,###").format(_dashboardStats['totalRevenue'] ?? 0)}',
                icon: Icons.attach_money,
                iconColor: Colors.green.shade700,
              )),
              SizedBox(width: 8),
              Expanded(child: _buildStatCard(
                label: 'Avg. Rating',
                value: (_dashboardStats['averageRating'] ?? 0.0).toStringAsFixed(1),
                icon: Icons.star,
                iconColor: Colors.amber,
              )),
            ],
          ),
          SizedBox(height: 12),
          // Second row with smaller stats cards
          _buildSecondaryStatsRow(isSmallScreen: true),
        ],
      );
    }
    // For larger screens or landscape, use a more horizontal layout
    else {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildStatCard(
                label: 'Total Users',
                value: _dashboardStats['totalUsers']?.toString() ?? '0',
                icon: Icons.people,
                iconColor: Colors.blue,
              )),
              SizedBox(width: 8),
              Expanded(child: _buildStatCard(
                label: 'Total Courses',
                value: _dashboardStats['totalCourses']?.toString() ?? '0',
                icon: Icons.school,
                iconColor: Colors.purple,
              )),
              SizedBox(width: 8),
              Expanded(child: _buildStatCard(
                label: 'Revenue',
                value: '\$${NumberFormat("#,###").format(_dashboardStats['totalRevenue'] ?? 0)}',
                icon: Icons.attach_money,
                iconColor: Colors.green.shade700,
              )),
              SizedBox(width: 8),
              Expanded(child: _buildStatCard(
                label: 'Avg. Rating',
                value: (_dashboardStats['averageRating'] ?? 0.0).toStringAsFixed(1),
                icon: Icons.star,
                iconColor: Colors.amber,
              )),
            ],
          ),
          SizedBox(height: 12),
          _buildSecondaryStatsRow(isSmallScreen: isSmallScreen),
        ],
      );
    }
  }

  Widget _buildSecondaryStatsRow({required bool isSmallScreen}) {
    if (isSmallScreen) {
      // For small screens, use a grid layout
      return GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: [
          _buildStatCard(
            label: 'Active Users',
            value: _dashboardStats['activeUsers']?.toString() ?? '0',
            icon: Icons.person,
            iconColor: Colors.teal,
            small: true,
          ),
          _buildStatCard(
            label: 'Premium',
            value: _dashboardStats['premiumCourses']?.toString() ?? '0',
            icon: Icons.workspace_premium,
            iconColor: Colors.orange,
            small: true,
          ),
          _buildStatCard(
            label: 'Free',
            value: _dashboardStats['freeCourses']?.toString() ?? '0',
            icon: Icons.card_giftcard,
            iconColor: Colors.red,
            small: true,
          ),
          _buildStatCard(
            label: 'Enrollments',
            value: NumberFormat.compact().format(_dashboardStats['totalEnrollments'] ?? 0),
            icon: Icons.how_to_reg,
            iconColor: Colors.indigo,
            small: true,
          ),
        ],
      );
    } else {
      // For larger screens, use a row
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildStatCard(
            label: 'Active Users',
            value: _dashboardStats['activeUsers']?.toString() ?? '0',
            icon: Icons.person,
            iconColor: Colors.teal,
            small: true,
          )),
          SizedBox(width: 8),
          Expanded(child: _buildStatCard(
            label: 'Premium',
            value: _dashboardStats['premiumCourses']?.toString() ?? '0',
            icon: Icons.workspace_premium,
            iconColor: Colors.orange,
            small: true,
          )),
          SizedBox(width: 8),
          Expanded(child: _buildStatCard(
            label: 'Free',
            value: _dashboardStats['freeCourses']?.toString() ?? '0',
            icon: Icons.card_giftcard,
            iconColor: Colors.red,
            small: true,
          )),
          SizedBox(width: 8),
          Expanded(child: _buildStatCard(
            label: 'Enrollments',
            value: NumberFormat.compact().format(_dashboardStats['totalEnrollments'] ?? 0),
            icon: Icons.how_to_reg,
            iconColor: Colors.indigo,
            small: true,
          )),
        ],
      );
    }
  }

  // Responsive tab builders
  Widget _buildResponsiveOverviewTab(bool isSmallScreen, bool isMediumScreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform Health Card
          _buildSectionTitle('Platform Health'),
          _buildPlatformHealthCard(),

          const SizedBox(height: 24),

          // User and Course Distribution - Responsive layout
          _buildSectionTitle('User & Course Distribution'),
          _buildResponsiveDistributionSection(isSmallScreen),

          const SizedBox(height: 24),

          // Top Courses Table
          _buildSectionTitle('Top Performing Courses'),
          _buildTopCoursesTable(),

          const SizedBox(height: 24),

          // Feedback Overview
          _buildSectionTitle('Feedback Overview'),
          _buildResponsiveFeedbackOverview(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildResponsiveUserAnalyticsTab(bool isSmallScreen, bool isMediumScreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Users by Role
          _buildSectionTitle('User Distribution by Role'),
          _buildUsersByRoleChart(),

          const SizedBox(height: 24),

          // User Registration Trends
          _buildSectionTitle('User Registration Trends'),
          _buildUserRegistrationTrendsChart(),

          const SizedBox(height: 24),

          // Active Users vs Total Users
          _buildSectionTitle('Active Users vs. Total Users'),
          _buildActiveUsersCard(),

          const SizedBox(height: 24),

          // User Metrics Table - Adaptive layout
          _buildSectionTitle('User Metrics'),
          _buildResponsiveMetricsTable(
            title: 'User Metrics',
            metrics: [
              {'label': 'Total Users', 'value': (_dashboardStats['totalUsers'] ?? 0).toString()},
              {'label': 'Active Users', 'value': (_dashboardStats['activeUsers'] ?? 0).toString()},
              {'label': 'Teachers', 'value': (_usersByRole['Teacher'] ?? 0).toString()},
              {'label': 'Administrators', 'value': (_usersByRole['Admin'] ?? 0).toString()},
              {'label': 'Students', 'value': (_usersByRole['User'] ?? 0).toString()},
              {'label': 'Average Daily Logins', 'value': '37'},
              {'label': 'User Retention Rate', 'value': '88%'},
            ],
            isSmallScreen: isSmallScreen,
          ),

          const SizedBox(height: 24),

          // User Engagement
          _buildSectionTitle('User Engagement by Medium'),
          _buildUserEngagementByMedium(),
        ],
      ),
    );
  }

  Widget _buildResponsiveCourseAnalyticsTab(bool isSmallScreen, bool isMediumScreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Courses by Category
          _buildSectionTitle('Courses by Category'),
          _buildResponsiveCoursesByCategorySection(isSmallScreen),

          const SizedBox(height: 24),

          // Top Courses
          _buildSectionTitle('Top Courses by Enrollment'),
          _buildTopCoursesChart(),

          const SizedBox(height: 24),

          // Course Completion Rate
          _buildSectionTitle('Course Completion Rates'),
          _buildCourseCompletionRateChart(),

          const SizedBox(height: 24),

          // Course Metrics - Adaptive layout
          _buildSectionTitle('Course Metrics'),
          _buildResponsiveCourseMetricsTable(isSmallScreen),

          const SizedBox(height: 24),

          // Content Analytics
          _buildSectionTitle('Content Analytics'),
          _buildResponsiveContentAnalyticsCard(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildResponsiveRevenueAnalyticsTab(bool isSmallScreen, bool isMediumScreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Trends
          _buildSectionTitle('Revenue Trends'),
          _buildRevenueTrendsChart(),

          const SizedBox(height: 24),

          // Revenue Breakdown
          _buildSectionTitle('Revenue by Course Category'),
          _buildResponsiveRevenueBreakdownSection(isSmallScreen),

          const SizedBox(height: 24),

          // Revenue Metrics
          _buildSectionTitle('Revenue Metrics'),
          _buildRevenueMetricsCard(),

          const SizedBox(height: 24),

          // Top Revenue Sources
          _buildSectionTitle('Top Revenue Sources'),
          _buildResponsiveTopRevenueSourcesTable(isSmallScreen),
        ],
      ),
    );
  }

  // Responsive component builders
  Widget _buildResponsiveDistributionSection(bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        children: [
          _buildDistributionCard(
            title: 'Users by Role',
            data: _usersByRole,
            icon: Icons.people,
            colors: [
              Colors.blueAccent,
              Colors.purpleAccent,
              Colors.teal,
              Colors.grey,
            ],
          ),
          SizedBox(height: 16),
          _buildDistributionCard(
            title: 'Courses by Subject',
            data: _coursesBySubject,
            icon: Icons.book,
            colors: [
              Colors.orange,
              Colors.green,
              Colors.redAccent,
              Colors.blueGrey,
              Colors.amber,
            ],
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildDistributionCard(
              title: 'Users by Role',
              data: _usersByRole,
              icon: Icons.people,
              colors: [
                Colors.blueAccent,
                Colors.purpleAccent,
                Colors.teal,
                Colors.grey,
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildDistributionCard(
              title: 'Courses by Subject',
              data: _coursesBySubject,
              icon: Icons.book,
              colors: [
                Colors.orange,
                Colors.green,
                Colors.redAccent,
                Colors.blueGrey,
                Colors.amber,
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildResponsiveFeedbackOverview(bool isSmallScreen) {
    // Create responsive layout for feedback overview
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Feedback Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            isSmallScreen
                ? Column(
              // Vertical layout for small screens
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRatingDistribution(),
                SizedBox(height: 20),
                _buildFeedbackMetrics(),
              ],
            )
                : Row(
              // Horizontal layout for larger screens
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildRatingDistribution()),
                SizedBox(width: 16),
                Expanded(child: _buildFeedbackMetrics()),
              ],
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildRatingDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating Distribution',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        _buildRatingBar('5 Stars', _feedbackByRating['5 Stars'] ?? 0, Colors.green),
        SizedBox(height: 8),
        _buildRatingBar('4 Stars', _feedbackByRating['4 Stars'] ?? 0, Colors.lightGreen),
        SizedBox(height: 8),
        _buildRatingBar('3 Stars', _feedbackByRating['3 Stars'] ?? 0, Colors.amber),
        SizedBox(height: 8),
        _buildRatingBar('2 Stars', _feedbackByRating['2 Stars'] ?? 0, Colors.orange),
        SizedBox(height: 8),
        _buildRatingBar('1 Star', _feedbackByRating['1 Star'] ?? 0, Colors.red),
      ],
    );
  }

  Widget _buildFeedbackMetrics() {
    // Calculate totals
    final totalFeedbacks = _feedbackByRating.values.fold<double>(0, (sum, value) => sum + value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feedback Metrics',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        _buildFeedbackMetric(
          label: 'Total Reviews',
          value: totalFeedbacks.toStringAsFixed(0),
          icon: Icons.rate_review,
          color: Colors.purple,
        ),
        SizedBox(height: 16),
        _buildFeedbackMetric(
          label: 'Average Rating',
          value: '${(_dashboardStats['averageRating'] ?? 0.0).toStringAsFixed(1)}/5.0',
          icon: Icons.star,
          color: Colors.amber,
        ),
        SizedBox(height: 16),
        _buildFeedbackMetric(
          label: 'Positive Feedback',
          value: '${((_feedbackByRating['5 Stars'] ?? 0) + (_feedbackByRating['4 Stars'] ?? 0)).toStringAsFixed(1)}%',
          icon: Icons.thumb_up,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildResponsiveCoursesByCategorySection(bool isSmallScreen) {
    // Create responsive layout for course categories
    if (isSmallScreen) {
      return Column(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.subject, color: AppColors.primaryGreen),
                      SizedBox(width: 8),
                      Text(
                        'Courses by Subject',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _coursesBySubject.isEmpty
                        ? Center(child: Text('No data available'))
                        : PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: _getCoursesByCategoryPieSections(_coursesBySubject),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language, color: AppColors.secondaryBlue),
                      SizedBox(width: 8),
                      Text(
                        'Courses by Medium',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryBlue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _coursesByMedium.isEmpty
                        ? Center(child: Text('No data available'))
                        : PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: _getCoursesByCategoryPieSections(_coursesByMedium, AppColors.secondaryBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.subject, color: AppColors.primaryGreen),
                        SizedBox(width: 8),
                        Text(
                          'Courses by Subject',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _coursesBySubject.isEmpty
                          ? Center(child: Text('No data available'))
                          : PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          sections: _getCoursesByCategoryPieSections(_coursesBySubject),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language, color: AppColors.secondaryBlue),
                        SizedBox(width: 8),
                        Text(
                          'Courses by Medium',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryBlue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _coursesByMedium.isEmpty
                          ? Center(child: Text('No data available'))
                          : PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                          sections: _getCoursesByCategoryPieSections(_coursesByMedium, AppColors.secondaryBlue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildResponsiveCourseMetricsTable(bool isSmallScreen) {
    final totalCourses = _dashboardStats['totalCourses'] ?? 0;
    final premiumCourses = _dashboardStats['premiumCourses'] ?? 0;
    final freeCourses = _dashboardStats['freeCourses'] ?? 0;
    final totalEnrollments = _dashboardStats['totalEnrollments'] ?? 0;

    // Calculate average enrollments per course
    final avgEnrollments = totalCourses > 0 ? totalEnrollments / totalCourses : 0;

    // Calculate average sections and videos per course
    double avgSections = 0;
    double avgVideos = 0;
    double avgPdfs = 0;

    if (_allCourses.isNotEmpty) {
      int totalSections = 0;
      int totalVideos = 0;
      int totalPdfs = 0;

      for (var course in _allCourses) {
        totalSections += course.sections.length;

        for (var section in course.sections) {
          totalVideos += section.videos.length;
          totalPdfs += section.pdfs.length;
        }
      }

      avgSections = totalSections / _allCourses.length;
      avgVideos = totalVideos / _allCourses.length;
      avgPdfs = totalPdfs / _allCourses.length;
    }

    // Build metrics data
    final metrics = [
      {'label': 'Total Courses', 'value': totalCourses.toString()},
      {'label': 'Premium Courses', 'value': premiumCourses.toString()},
      {'label': 'Free Courses', 'value': freeCourses.toString()},
      {'label': 'Total Enrollments', 'value': totalEnrollments.toString()},
      {'label': 'Avg. Enrollments/Course', 'value': avgEnrollments.toStringAsFixed(1)},
      {'label': 'Avg. Sections/Course', 'value': avgSections.toStringAsFixed(1)},
      {'label': 'Avg. Videos/Course', 'value': avgVideos.toStringAsFixed(1)},
      {'label': 'Avg. PDFs/Course', 'value': avgPdfs.toStringAsFixed(1)},
    ];

    return _buildResponsiveMetricsTable(
        title: 'Course Metrics',
        metrics: metrics,
        isSmallScreen: isSmallScreen
    );
  }

  // Update the function signature to accept dynamic values in the metrics map
  Widget _buildResponsiveMetricsTable({
    required String title,
    required List<Map<String, dynamic>> metrics,  // Changed from String to dynamic
    bool isSmallScreen = false,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),

            // For small screens, stack metrics into a single column
            if (isSmallScreen)
              Column(
                children: metrics.map((metric) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          metric['label'].toString(),  // Ensure we call toString()
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          metric['value'].toString(),  // Ensure we call toString()
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList().separatedBy(Divider()),
              )
            // For larger screens, create a two-column layout
            else if (metrics.length > 4)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      children: metrics.sublist(0, metrics.length ~/ 2).map((metric) {
                        return _buildMetricRow(
                            metric['label'].toString(),  // Ensure we call toString()
                            metric['value'].toString()   // Ensure we call toString()
                        );
                      }).toList().separatedBy(Divider()),
                    ),
                  ),
                  SizedBox(width: 24),
                  // Right column
                  Expanded(
                    child: Column(
                      children: metrics.sublist(metrics.length ~/ 2).map((metric) {
                        return _buildMetricRow(
                            metric['label'].toString(),  // Ensure we call toString()
                            metric['value'].toString()   // Ensure we call toString()
                        );
                      }).toList().separatedBy(Divider()),
                    ),
                  ),
                ],
              )
            // For fewer metrics or medium screens
            else
              Column(
                children: metrics.map((metric) {
                  return _buildMetricRow(
                      metric['label'].toString(),  // Ensure we call toString()
                      metric['value'].toString()   // Ensure we call toString()
                  );
                }).toList().separatedBy(Divider()),
              ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildResponsiveContentAnalyticsCard(bool isSmallScreen) {
    // Calculate content type statistics
    int totalVideos = 0;
    int totalPdfs = 0;

    for (var course in _allCourses) {
      for (var section in course.sections) {
        totalVideos += section.videos.length;
        totalPdfs += section.pdfs.length;
      }
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.content_paste, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Content Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Content type cards - responsive layout
            isSmallScreen
                ? Column(
              children: [
                _buildContentTypeCard(
                  title: 'Video Content',
                  count: totalVideos,
                  icon: Icons.videocam_outlined,
                  color: Colors.red.shade700,
                ),
                SizedBox(height: 16),
                _buildContentTypeCard(
                  title: 'PDF Resources',
                  count: totalPdfs,
                  icon: Icons.picture_as_pdf_outlined,
                  color: Colors.blue.shade700,
                ),
              ],
            )
                : Row(
              children: [
                Expanded(
                  child: _buildContentTypeCard(
                    title: 'Video Content',
                    count: totalVideos,
                    icon: Icons.videocam_outlined,
                    color: Colors.red.shade700,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildContentTypeCard(
                    title: 'PDF Resources',
                    count: totalPdfs,
                    icon: Icons.picture_as_pdf_outlined,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Content ratio pie chart
            if (totalVideos > 0 || totalPdfs > 0) ...[
              Text(
                'Content Type Ratio',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 16),

              // Responsive chart height
              SizedBox(
                height: isSmallScreen ? 180 : 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: isSmallScreen ? 30 : 40,
                    sections: [
                      PieChartSectionData(
                        value: totalVideos.toDouble(),
                        title: 'Videos',
                        color: Colors.red.shade700,
                        radius: isSmallScreen ? 70 : 80,
                        titleStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                      PieChartSectionData(
                        value: totalPdfs.toDouble(),
                        title: 'PDFs',
                        color: Colors.blue.shade700,
                        radius: isSmallScreen ? 70 : 80,
                        titleStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 20),

            // Content insights
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content Insights',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildContentInsightRow(
                    title: 'Video to PDF Ratio',
                    value: totalPdfs > 0 ? '${(totalVideos / totalPdfs).toStringAsFixed(1)}:1' : 'N/A',
                  ),
                  SizedBox(height: 8),
                  _buildContentInsightRow(
                    title: 'Avg. Videos per Section',
                    value: _calculateAvgContentPerSection(totalVideos),
                  ),
                  SizedBox(height: 8),
                  _buildContentInsightRow(
                    title: 'Avg. PDFs per Section',
                    value: _calculateAvgContentPerSection(totalPdfs),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildResponsiveRevenueBreakdownSection(bool isSmallScreen) {
    // Create revenue data by category
    Map<String, double> revenueBySubject = {};
    Map<String, double> revenueByMedium = {};

    // Calculate revenue by subject and medium
    for (var course in _allCourses) {
      if (course.price == null || course.status?.toLowerCase() != 'premium') continue;

      final subject = course.subject ?? 'Unknown';
      final medium = course.medium ?? 'Unknown';
      final enrollmentCount = course.enrolledUserIds?.length ?? 0;
      final revenue = course.price! * enrollmentCount;

      // Update subject revenue
      revenueBySubject.update(
        subject,
            (value) => value + revenue,
        ifAbsent: () => revenue,
      );

      // Update medium revenue
      revenueByMedium.update(
        medium,
            (value) => value + revenue,
        ifAbsent: () => revenue,
      );
    }

    // Responsive layout
    if (isSmallScreen) {
      return Column(
        children: [
          _buildRevenueBreakdownCard(
            title: 'Revenue by Subject',
            data: revenueBySubject,
            icon: Icons.subject,
            iconColor: Colors.green.shade700,
            chartColor: Colors.green,
          ),
          SizedBox(height: 16),
          _buildRevenueBreakdownCard(
            title: 'Revenue by Medium',
            data: revenueByMedium,
            icon: Icons.language,
            iconColor: Colors.blue,
            chartColor: Colors.blue,
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildRevenueBreakdownCard(
              title: 'Revenue by Subject',
              data: revenueBySubject,
              icon: Icons.subject,
              iconColor: Colors.green.shade700,
              chartColor: Colors.green,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildRevenueBreakdownCard(
              title: 'Revenue by Medium',
              data: revenueByMedium,
              icon: Icons.language,
              iconColor: Colors.blue,
              chartColor: Colors.blue,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildRevenueBreakdownCard({
    required String title,
    required Map<String, double> data,
    required IconData icon,
    required Color iconColor,
    required Color chartColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: data.isEmpty
                  ? Center(child: Text('No revenue data available'))
                  : PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: _getRevenueBreakdownPieSections(data, chartColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveTopRevenueSourcesTable(bool isSmallScreen) {
    if (_topCourses.isEmpty) {
      return _buildEmptyStateCard('No revenue data available');
    }

    // Sort by revenue
    final sortedCourses = List<Map<String, dynamic>>.from(_topCourses)
      ..sort((a, b) => b['revenue'].compareTo(a['revenue']));

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Top Revenue Sources',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // For small screens, simplify the table
            if (isSmallScreen)
              _buildCompactRevenueSourcesList(sortedCourses)
            else
              _buildFullRevenueSourcesTable(sortedCourses),

            // Add a total row
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Revenue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${sortedCourses.fold(0.0, (sum, course) => sum + course['revenue']).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildCompactRevenueSourcesList(List<Map<String, dynamic>> courses) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        final course = courses[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'By ${course['instructor']} • \$${course['price'].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Text(
                '\$${course['revenue'].toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullRevenueSourcesTable(List<Map<String, dynamic>> courses) {
    return Column(
      children: [
        // Table header
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'Course',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Instructor',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'Price',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'Revenue',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        Divider(height: 24),

        // Table rows
        for (var course in courses) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  course['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  course['instructor'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '\$${course['price'].toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '\$${course['revenue'].toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          Divider(height: 16),
        ],
      ],
    );
  }

  // Standard widget builders
  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accentYellow.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primaryGreen,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool small = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: small ? 8 : 12, horizontal: small ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: small ? 18 : 22),
          SizedBox(height: small ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          SizedBox(height: small ? 1 : 2),
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 10 : 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.accentYellow,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformHealthCard() {
    // Calculate health stats
    final userGrowthRate = 5.2; // Example percentage
    final courseCompletionRate = _dashboardStats['totalEnrollments'] != null && _dashboardStats['totalEnrollments'] > 0
        ? (_courseCompletionRates['Completed'] ?? 0) / _dashboardStats['totalEnrollments']! * 100
        : 0.0;
    final activeUserRate = _dashboardStats['totalUsers'] != null && _dashboardStats['totalUsers'] > 0
        ? (_dashboardStats['activeUsers'] ?? 0) / _dashboardStats['totalUsers']! * 100
        : 0.0;
    final averageRating = _dashboardStats['averageRating'] ?? 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Health Metrics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    label: 'User Growth',
                    value: '$userGrowthRate%',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildHealthMetric(
                    label: 'Course Completion',
                    value: '${courseCompletionRate.toStringAsFixed(1)}%',
                    icon: Icons.school,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    label: 'Active Users',
                    value: '${activeUserRate.toStringAsFixed(1)}%',
                    icon: Icons.people,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildHealthMetric(
                    label: 'Avg. Rating',
                    value: '${averageRating.toStringAsFixed(1)}/5.0',
                    icon: Icons.star,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Platform Health Score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getHealthScoreColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_calculateHealthScore().toStringAsFixed(0)}/100',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getHealthScoreColor(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Health score progress bar
            Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _calculateHealthScore() / 100,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getHealthScoreColor(),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildHealthMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistributionCard({
    required String title,
    required Map<String, int> data,
    required IconData icon,
    required List<Color> colors,
  }) {
    // Sort data by value (descending)
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate total for percentages
    final total = data.values.fold<int>(0, (sum, value) => sum + value);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                  sections: List.generate(
                    sortedEntries.length > 5 ? 5 : sortedEntries.length,
                        (index) {
                      final entry = sortedEntries[index];
                      final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;

                      return PieChartSectionData(
                        color: colors[index % colors.length],
                        value: entry.value.toDouble(),
                        title: entry.value > 0 ? '${percentage.toStringAsFixed(0)}%' : '',
                        radius: 55,
                        titleStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Legend
            for (int i = 0; i < sortedEntries.length && i < 5; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        sortedEntries[i].key,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${sortedEntries[i].value}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildTopCoursesTable() {
    if (_topCourses.isEmpty) {
      return _buildEmptyStateCard('No course data available');
    }

    // Take top 5 courses
    final topFive = _topCourses.take(5).toList();

    return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Text(
    'Top Performing Courses',
    style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryGreen,
    ),
    ),
    Text(
    'By Revenue',
    style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    ),
    ),
    ],
    ),

    SizedBox(height: 16),

    // Responsive table
    MediaQuery.of(context).size.width < 640
    ? ListView.separated(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    itemCount: topFive.length,
    separatorBuilder: (context, index) => Divider(),
    itemBuilder: (context, index) {
    final course = topFive[index];
    return ListTile(
    leading: Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
    color: AppColors.accentMaroon.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    ),
    child: Center(
    child: Text(
    '${index + 1}',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    color: AppColors.accentMaroon,
    ),
    ),
    ),
    ),
    title: Text(
    course['title'] as String,
    style: TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    ),
    subtitle: Row(
    children: [
    Text(
    '${course['enrollments']} students',
    style: TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    ),
    ),
    SizedBox(width: 8),
    Text(
    '\$${course['revenue'].toStringAsFixed(0)}',
    style: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.green.shade700,
    ),
    ),
    ],
    ),
    );
    },
    )
        : Column(
    children: [
    // Table header
    Row(
    children: [
    Expanded(
    flex: 3,
    child: Text(
    'Course',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 13,
    color: AppColors.textPrimary,
    ),
    ),
    ),
    Expanded(
    flex: 2,
    child: Text(
    'Instructor',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 13,
    color: AppColors.textPrimary,
    ),
    ),
    ),
    Expanded(
    flex: 1,
    child: Text(
    'Students',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 13,
    color: AppColors.textPrimary,
    ),
    textAlign: TextAlign.center,
    ),
    ),
    Expanded(
    flex: 1,
    child: Text(
    'Revenue',
    style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 13,
    color: AppColors.textPrimary,
    ),
    textAlign: TextAlign.center,
    ),
    ),
    ],
    ),

    Divider(height: 24),

    // Course rows
    for (var i = 0; i < topFive.length; i++) ...[
    Row(
    children: [
    Expanded(
    flex: 3,
    child: Row(
    children: [
    Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
    color: AppColors.primaryGreen.withOpacity(0.1),
    shape: BoxShape.circle,
    ),
    child: Center(
      child: Text(
        '${i + 1}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: AppColors.primaryGreen,
        ),
      ),
    ),
    ),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          topFive[i]['title'] as String,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
    ),
    ),
      Expanded(
        flex: 2,
        child: Text(
          topFive[i]['instructor'] as String,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Expanded(
        flex: 1,
        child: Text(
          '${topFive[i]['enrollments']}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      Expanded(
        flex: 1,
        child: Text(
          '\$${topFive[i]['revenue'].toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ],
    ),
      if (i < topFive.length - 1)
        Divider(height: 16),
    ],
    ],
    ),

      SizedBox(height: 8),

      // View all button
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () {
            // Navigate to full course list or change tab
            _tabController.animateTo(2); // Course Analytics tab
          },
          icon: Icon(
            Icons.visibility,
            size: 16,
            color: AppColors.secondaryBlue,
          ),
          label: Text(
            'View All Courses',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryBlue,
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ),
    ],
    ),
    ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildRatingBar(String label, double percentage, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsersByRoleChart() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: _usersByRole['Admin']?.toDouble() ?? 0,
                      title: 'Admin',
                      color: Colors.orangeAccent,
                      radius: 100,
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    PieChartSectionData(
                      value: _usersByRole['Teacher']?.toDouble() ?? 0,
                      title: 'Teacher',
                      color: Colors.lightBlueAccent,
                      radius: 100,
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    PieChartSectionData(
                      value: _usersByRole['User']?.toDouble() ?? 0,
                      title: 'User',
                      color: AppColors.primaryGreen,
                      radius: 100,
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    PieChartSectionData(
                      value: _usersByRole['Other']?.toDouble() ?? 0,
                      title: 'Other',
                      color: Colors.grey,
                      radius: 100,
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Admin', Colors.orangeAccent, _usersByRole['Admin'] ?? 0),
                SizedBox(width:5),
                _buildLegendItem('Teacher', Colors.lightBlueAccent, _usersByRole['Teacher'] ?? 0),
                SizedBox(width:5),
                _buildLegendItem('User', AppColors.primaryGreen, _usersByRole['User'] ?? 0),
                SizedBox(width:5),
                _buildLegendItem('Other', Colors.grey, _usersByRole['Other'] ?? 0),
              ],
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildUserRegistrationTrendsChart() {
    if (_userRegistrationsByMonth.isEmpty) {
      return _buildEmptyStateCard('No user registration data available');
    }

    final sortedKeys = _userRegistrationsByMonth.keys.toList()..sort();
    final values = sortedKeys.map((m) => _userRegistrationsByMonth[m]!.toDouble()).toList();
    final maxValue = values.isNotEmpty ? values.reduce(math.max) : 0;

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < sortedKeys.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i],
              color: AppColors.secondaryBlue,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${formatMonthKey(sortedKeys[group.x])}\n',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '${rod.toY.toInt()} users',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value >= 0 && value < sortedKeys.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                sortedKeys[value.toInt()].split('-')[1],
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  barGroups: barGroups,
                ),
              ),
            ),
            SizedBox(height: 16),
            // Data table
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: sortedKeys.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final month = sortedKeys[index];
                  final registrations = _userRegistrationsByMonth[month] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 16,
                              color: AppColors.secondaryBlue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              formatMonthKey(month),
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Text(
                          '$registrations users',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildActiveUsersCard() {
    final totalUsers = _dashboardStats['totalUsers'] ?? 0;
    final activeUsers = _dashboardStats['activeUsers'] ?? 0;
    final inactiveUsers = totalUsers - activeUsers;

    double activePercentage = totalUsers > 0 ? (activeUsers / totalUsers) * 100 : 0;

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Users',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$activeUsers of $totalUsers total users',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${activePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Active vs Inactive progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User Activity Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$totalUsers users',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: totalUsers > 0 ? activeUsers / totalUsers : 0,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildActivityLegendItem('Active Users', Colors.green, activeUsers),
                    SizedBox(width: 24),
                    _buildActivityLegendItem('Inactive Users', Colors.grey, inactiveUsers),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildActivityLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserEngagementByMedium() {
    // Create simulated data for user engagement by medium
    final Map<String, Map<String, double>> engagementData = {
      'Video Consumption': {
        'English': 45.0,
        'Hindi': 30.0,
        'Bengali': 15.0,
        'Other': 10.0,
      },
      'PDF Downloads': {
        'English': 55.0,
        'Hindi': 25.0,
        'Bengali': 12.0,
        'Other': 8.0,
      },
      'Quiz Participation': {
        'English': 50.0,
        'Hindi': 35.0,
        'Bengali': 10.0,
        'Other': 5.0,
      },
    };

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Engagement by Medium',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),

            SizedBox(height: 20),

            // Create a horizontal bar chart for each engagement type
            for (var entry in engagementData.entries) ...[
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 12),

              for (var mediumEntry in entry.value.entries) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        mediumEntry.key,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: mediumEntry.value / 100,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getMediumColor(mediumEntry.key),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${mediumEntry.value.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
              ],

              SizedBox(height: 20),
            ],

            // Insight box
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insight',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'English medium content has the highest engagement across all content types. Consider expanding content in Hindi and Bengali to reach a broader audience.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Color _getMediumColor(String medium) {
    switch (medium) {
      case 'English':
        return Colors.blue;
      case 'Hindi':
        return Colors.green;
      case 'Bengali':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  List<PieChartSectionData> _getCoursesByCategoryPieSections(Map<String, int> data, [Color baseColor = AppColors.primaryGreen]) {
    // Sort data by value (descending)
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 categories
    final top5 = sortedEntries.take(5).toList();

    // Calculate total for percentages
    final total = data.values.fold<int>(0, (sum, value) => sum + value);

    // Base colors
    final List<Color> colors = [
      baseColor,
      baseColor.withOpacity(0.8),
      baseColor.withOpacity(0.6),
      baseColor.withOpacity(0.4),
      baseColor.withOpacity(0.2),
    ];

    return List.generate(
      top5.length,
          (index) {
        final entry = top5[index];
        final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;

        return PieChartSectionData(
          color: colors[index % colors.length],
          value: entry.value.toDouble(),
          title: percentage >= 10 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: 80,
          titleStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        );
      },
    );
  }

  Widget _buildTopCoursesChart() {
    if (_topCourses.isEmpty) {
      return _buildEmptyStateCard('No course data available');
    }

    // Sort by enrollments
    final sortedCourses = List<Map<String, dynamic>>.from(_topCourses)
      ..sort((a, b) => b['enrollments'].compareTo(a['enrollments']));

    // Take top 5
    final top5 = sortedCourses.take(5).toList();

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < top5.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: top5[i]['enrollments'].toDouble(),
              color: AppColors.accentMaroon,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${top5[group.x]['title']}\n',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '${rod.toY.toInt()} enrollments',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value >= 0 && value < top5.length) {
                            final title = top5[value.toInt()]['title'] as String;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                title.length > 10 ? '${title.substring(0, 10)}...' : title,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  barGroups: barGroups,
                ),
              ),
            ),
            SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: top5.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final course = top5[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentMaroon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentMaroon,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      course['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'By ${course['instructor']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentMaroon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${course['enrollments']} students',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentMaroon,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildCourseCompletionRateChart() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: AppColors.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Course Completion Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: _courseCompletionRates['Completed']?.toDouble() ?? 0,
                      title: 'Completed',
                      color: Colors.green,
                      radius: 100,
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    PieChartSectionData(
                      value: _courseCompletionRates['In Progress']?.toDouble() ?? 0,
                      title: 'In Progress',
                      color: Colors.amber,
                      radius: 100,
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    PieChartSectionData(
                      value: _courseCompletionRates['Not Started']?.toDouble() ?? 0,
                      title: 'Not Started',
                      color: Colors.grey,
                      radius: 100,
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Completed', Colors.green, _courseCompletionRates['Completed'] ?? 0),
                SizedBox(width: 5),
                _buildLegendItem('In Progress', Colors.amber, _courseCompletionRates['In Progress'] ?? 0),
                SizedBox(width: 5),
                _buildLegendItem('Not Started', Colors.grey, _courseCompletionRates['Not Started'] ?? 0),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.secondaryBlue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insight',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryBlue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'A ${(_courseCompletionRates['Completed'] ?? 0) / (_courseCompletionRates.values.fold(0, (a, b) => a + b)) * 100}% completion rate is ${_getCourseCompletionInsight()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildContentTypeCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 12),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentInsightRow({
    required String title,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueTrendsChart() {
    if (_revenueByMonth.isEmpty) {
      return _buildEmptyStateCard('No revenue data available');
    }

    final sortedKeys = _revenueByMonth.keys.toList()..sort();
    final values = sortedKeys.map((m) => _revenueByMonth[m]!).toList();

    List<FlSpot> spots = [];
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Revenue: \$${_dashboardStats['totalRevenue']?.toStringAsFixed(2) ?? "0.00"}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _selectedTimeRange,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final month = sortedKeys[spot.x.toInt()];
                          return LineTooltipItem(
                            '${formatMonthKey(month)}\n',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: '\$${spot.y.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value >= 0 && value < sortedKeys.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                sortedKeys[value.toInt()].split('-')[1],
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: spots.length - 1.0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primaryGreen,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryGreen.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: sortedKeys.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final month = sortedKeys[index];
                  final revenue = _revenueByMonth[month] ?? 0.0;

                  // Calculate month-over-month growth
                  double growth = 0;
                  if (index > 0) {
                    final previousMonth = sortedKeys[index - 1];
                    final previousRevenue = _revenueByMonth[previousMonth] ?? 0.0;
                    if (previousRevenue > 0) {
                      growth = ((revenue - previousRevenue) / previousRevenue) * 100;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 16,
                              color: AppColors.primaryGreen,
                            ),
                            SizedBox(width: 8),
                            Text(
                              formatMonthKey(month),
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (index > 0)
                              Container(
                                margin: EdgeInsets.only(right: 10),
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: growth >= 0
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                      size: 10,
                                      color: growth >= 0 ? Colors.green : Colors.red,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      '${growth.abs().toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: growth >= 0 ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              '\$${revenue.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  List<PieChartSectionData> _getRevenueBreakdownPieSections(Map<String, double> data, [Color baseColor = Colors.green]) {
    // Sort data by value (descending)
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 categories
    final top5 = sortedEntries.take(5).toList();

    // Calculate total for percentages
    final total = data.values.fold<double>(0, (sum, value) => sum + value);

    // Colors
    final List<Color> colors = [
      baseColor,
      baseColor.withOpacity(0.8),
      baseColor.withOpacity(0.6),
      baseColor.withOpacity(0.4),
      baseColor.withOpacity(0.2),
    ];

    return List.generate(
      top5.length,
          (index) {
        final entry = top5[index];
        final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;

        return PieChartSectionData(
          color: colors[index % colors.length],
          value: entry.value,
          title: percentage >= 10 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: 80,
          titleStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        );
      },
    );
  }

  Widget _buildRevenueMetricsCard() {
    // Calculate total revenue from monthly data
    double totalRevenue = _revenueByMonth.values.fold(0, (sum, value) => sum + value);

    // Estimate other metrics based on available data
    final totalEnrollments = _dashboardStats['totalEnrollments'] ?? 0;
    double averageRevenuePerUser = totalEnrollments > 0
        ? totalRevenue / totalEnrollments
        : 0;

    // For demonstration, let's estimate some metrics
    final daysInPeriod = _getMonthsFromTimeRange() * 30;
    double dailyRevenue = daysInPeriod > 0 ? totalRevenue / daysInPeriod : 0;

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.attach_money,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _selectedTimeRange,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildMetricRow('Total Revenue', '\$${totalRevenue.toStringAsFixed(2)}'),
            Divider(),
            _buildMetricRow('Average Revenue Per Enrollment', '\$${averageRevenuePerUser.toStringAsFixed(2)}'),
            Divider(),
            _buildMetricRow('Daily Average Revenue', '\$${dailyRevenue.toStringAsFixed(2)}'),
            Divider(),
            _buildMetricRow('Projected Monthly Revenue', '\$${(dailyRevenue * 30).toStringAsFixed(2)}'),
            Divider(),
            _buildMetricRow('Projected Annual Revenue', '\$${(dailyRevenue * 365).toStringAsFixed(2)}'),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildEmptyStateCard(String message) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 50,
                color: Colors.grey.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms);
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time Range Filter
                  const Text(
                    'Time Range',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Last Month',
                      'Last 3 Months',
                      'Last 6 Months',
                      'Last Year'
                    ].map((String value) {
                      return ChoiceChip(
                        label: Text(value),
                        selected: _selectedTimeRange == value,
                        onSelected: (bool selected) {
                          if (selected) {
                            setStateModal(() {
                              _selectedTimeRange = value;
                            });
                            // Update the parent state as well
                            setState(() {});
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _fetchInitialData(); // Refresh data with new filter
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSubjectFilterDialog(BuildContext context) {
    // Get unique subjects from courses
    final subjects = _coursesBySubject.keys.toList();
    subjects.insert(0, 'All Subjects');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter by Subject'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: subjects.map((subject) {
                return RadioListTile<String>(
                  title: Text(subject),
                  value: subject,
                  groupValue: _selectedSubject,
                  onChanged: (value) {
                    Navigator.pop(context);
                    setState(() {
                      _selectedSubject = value ?? 'All Subjects';
                    });
                    _fetchInitialData();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showMediumFilterDialog(BuildContext context) {
    // Get unique mediums from courses
    final mediums = _coursesByMedium.keys.toList();
    mediums.insert(0, 'All Mediums');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter by Medium'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: mediums.map((medium) {
                return RadioListTile<String>(
                  title: Text(medium),
                  value: medium,
                  groupValue: _selectedMedium,
                  onChanged: (value) {
                    Navigator.pop(context);
                    setState(() {
                      _selectedMedium = value ?? 'All Mediums';
                    });
                    _fetchInitialData();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}