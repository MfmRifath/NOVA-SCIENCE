import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nova_science/Screens/StartScreen/AppTheme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/AuthService.dart';
import '../../Service/CourseProvider.dart';
import 'EarningsDashboard.dart';
import 'ManageSectionsScreen.dart';

// Modern Material 3 color scheme
class AppColorScheme {
  // Primary colors
  static const Color primary = Color(0xFF1A5F7A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD1E9FF);
  static const Color onPrimaryContainer = Color(0xFF001D31);

  // Secondary colors
  static const Color secondary = Color(0xFF53B175);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD9F4E3);
  static const Color onSecondaryContainer = Color(0xFF002111);

  // Tertiary/Accent colors
  static const Color tertiary = Color(0xFFE86B02);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFDCC2);
  static const Color onTertiaryContainer = Color(0xFF2E1400);

  // Background colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color onBackground = Color(0xFF1A1C1E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1C1E);

  // Status colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFF9A825);
  static const Color info = Color(0xFF2196F3);

  // Common grays
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);
}

// Enhanced text styles with consistent typography
class AppTextStyles {
  static final TextStyle headline1 = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColorScheme.onBackground,
    letterSpacing: -0.5,
  );

  static final TextStyle headline2 = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColorScheme.onBackground,
    letterSpacing: -0.5,
  );

  static final TextStyle headline3 = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColorScheme.onBackground,
  );

  static final TextStyle subtitle1 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColorScheme.onBackground,
  );

  static final TextStyle subtitle2 = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColorScheme.onBackground,
  );

  static final TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColorScheme.onBackground,
  );

  static final TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColorScheme.onBackground,
  );

  static final TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColorScheme.onBackground.withOpacity(0.7),
  );

  static final TextStyle caption = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColorScheme.onBackground.withOpacity(0.6),
  );

  static final TextStyle button = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColorScheme.onPrimary,
    letterSpacing: 0.5,
  );

  static final TextStyle overline = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColorScheme.onBackground.withOpacity(0.6),
    letterSpacing: 1.0,
    textBaseline: TextBaseline.alphabetic,
  );
}

// Modern Teacher Dashboard Screen with enhanced UI/UX
class TeacherScreen extends StatefulWidget {
  @override
  _ModernTeacherScreenState createState() => _ModernTeacherScreenState();
}

class _ModernTeacherScreenState extends State<TeacherScreen> with SingleTickerProviderStateMixin {
  // Tab controller for multiple views
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _courseImage;

  // Currently editing course
  String? _currentCourseId;
  String? _currentImageUrl;

  // Dropdown for Medium
  String? _selectedMedium;

  String _searchQuery = '';

  // Scroll controllers
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _coursesScrollController = ScrollController();

  // Analytics state
  bool _isLoadingAnalytics = false;
  int _totalEnrollments = 0;
  double _completionRate = 0.0;
  double _totalEarnings = 0.0;

  // Course list sort option
  String _sortOption = 'Default';

  // Real-time data streams
  Stream<QuerySnapshot>? _enrollmentStream;
  Stream<QuerySnapshot>? _earningsStream;

  // Selected tab for analytics
  int _selectedAnalyticsTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Add listener to search controller
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Add listener to tab controller
    _tabController.addListener(() {
      setState(() {});
    });

    // Initialize analytics data
    _initializeRealTimeAnalytics();
  }

  Future<void> _initializeRealTimeAnalytics() async {
    setState(() {
      _isLoadingAnalytics = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final email = await authService.getCurrentUserEmail();

      if (email != null) {
        // Set up real-time streams for analytics
        _setupRealTimeEnrollmentStream(email);
        _setupRealTimeEarningsStream(email);
      }
    } catch (e) {
      print('Error initializing real-time analytics: $e');
    } finally {
      setState(() {
        _isLoadingAnalytics = false;
      });
    }
  }

  void _setupRealTimeEnrollmentStream(String teacherEmail) {
    // First, get all courses by this teacher
    FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: teacherEmail)
        .get()
        .then((courseSnapshot) {

      final courseIds = courseSnapshot.docs.map((doc) => doc.id).toList();

      if (courseIds.isEmpty) return;

      // Set up a stream to listen for changes to users collection
      // We'll use this to track enrollments
      _enrollmentStream = FirebaseFirestore.instance
          .collection('users')
          .snapshots();

      // Listen to the stream
      _enrollmentStream!.listen((usersSnapshot) {
        int enrollmentCount = 0;
        int completedCount = 0;

        for (var userDoc in usersSnapshot.docs) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final List<dynamic>? enrolledCourses = userData['enrolledCourses'];

          if (enrolledCourses != null) {
            for (var enrollment in enrolledCourses) {
              if (enrollment is Map<String, dynamic>) {
                final String? courseId = enrollment['courseId'];
                if (courseId != null && courseIds.contains(courseId)) {
                  enrollmentCount++;

                  // Check if course is completed
                  if (enrollment['isCompleted'] == true) {
                    completedCount++;
                  }
                }
              }
            }
          }
        }

        setState(() {
          _totalEnrollments = enrollmentCount;
          _completionRate = enrollmentCount > 0
              ? (completedCount / enrollmentCount) * 100
              : 0.0;
        });
      });
    });
  }

  void _setupRealTimeEarningsStream(String teacherEmail) {
    // First, get all courses by this teacher
    FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: teacherEmail)
        .snapshots()
        .listen((courseSnapshot) {

      final courses = courseSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'price': data['price'] != null
              ? double.tryParse(data['price'].toString()) ?? 0.0
              : 0.0,
        };
      }).toList();

      if (courses.isEmpty) return;

      // Listen to the users collection for enrollment changes
      _earningsStream = FirebaseFirestore.instance
          .collection('users')
          .snapshots();

      _earningsStream!.listen((usersSnapshot) {
        double totalEarnings = 0.0;

        for (var userDoc in usersSnapshot.docs) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final List<dynamic>? enrolledCourses = userData['enrolledCourses'];

          if (enrolledCourses != null) {
            for (var enrollment in enrolledCourses) {
              if (enrollment is Map<String, dynamic>) {
                final String? courseId = enrollment['courseId'];
                if (courseId != null) {
                  // Find the course in our list
                  final courseMatch = courses.firstWhere(
                        (course) => course['id'] == courseId,
                    orElse: () => {'id': '', 'price': 0.0},
                  );

                  if (courseMatch['id'] != null) {
                    totalEarnings += courseMatch['price'] as double;
                  }
                }
              }
            }
          }
        }

        setState(() {
          _totalEarnings = totalEarnings;
        });
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _subjectController.dispose();
    _instructorController.dispose();
    _searchController.dispose();
    _mainScrollController.dispose();
    _coursesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColorScheme.background,
      appBar: _buildAppBar(context, authService),
      body: TabBarView(
        controller: _tabController,
        children: [
          // DASHBOARD TAB
          _buildDashboardTab(authService, courseProvider),

          // COURSES TAB
          _buildCoursesTab(authService, courseProvider),

          // CREATE COURSE TAB
          _buildCreateCourseTab(context, authService, courseProvider),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColorScheme.primary,
            indicatorWeight: 3,
            labelColor: AppColorScheme.primary,
            unselectedLabelColor: AppColorScheme.gray600,
            labelStyle: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.dashboard_outlined),
                text: "Dashboard",
              ),
              Tab(
                icon: Icon(Icons.school_outlined),
                text: "Courses",
              ),
              Tab(
                icon: Icon(Icons.add_circle_outline),
                text: "Create",
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _tabController.index == 1 ? FloatingActionButton(
        onPressed: () {
          _tabController.animateTo(2);
        },
        backgroundColor: AppColorScheme.secondary,
        child: Icon(Icons.add, color: AppColorScheme.onSecondary),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ) : null,
    );
  }

  // -------------------------------------------------------------------------
  // APP BAR
  // -------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context, AuthService authService) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColorScheme.primary,
      scrolledUnderElevation: 0,
      title: FutureBuilder<String?>(
        future: authService.getCurrentUserEmail(),
        builder: (context, snapshot) {
          final email = snapshot.data;
          final name = email != null ? email.split('@').first.capitalize() : 'Teacher';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teacher Dashboard',
                style: AppTextStyles.subtitle1.copyWith(
                  color: AppColorScheme.onPrimary,
                ),
              ),
              Text(
                name,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColorScheme.onPrimary.withOpacity(0.8),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        // Notifications icon with badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: AppColorScheme.onPrimary),
              onPressed: () {
                _showNotificationsDialog(context);
              },
              tooltip: 'Notifications',
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        // Profile icon
        FutureBuilder<String?>(
          future: authService.getCurrentUserEmail(),
          builder: (context, snapshot) {
            final email = snapshot.data;
            final initial = email != null && email.isNotEmpty ? email[0].toUpperCase() : 'T';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GestureDetector(
                onTap: () {
                  _showProfileMenu(context, authService);
                },
                child: CircleAvatar(
                  backgroundColor: AppColorScheme.tertiary,
                  radius: 16,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: AppColorScheme.onTertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // DASHBOARD TAB
  // -------------------------------------------------------------------------
  Widget _buildDashboardTab(AuthService authService, CourseProvider courseProvider) {
    return RefreshIndicator(
      onRefresh: _initializeRealTimeAnalytics,
      color: AppColorScheme.primary,
      child: SingleChildScrollView(
        controller: _mainScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section with key metrics
            _buildWelcomeSection(),
            const SizedBox(height: 24),

            // Income summary card
            _buildIncomeSummaryCard(),
            const SizedBox(height: 24),

            // Real-time stats cards
            _buildRealTimeStatsGrid(authService, courseProvider),
            const SizedBox(height: 24),

            // Analytics tabs (Graph/Chart display)
            _buildAnalyticsTabs(),
            const SizedBox(height: 16),

            // Analytics content based on selected tab
            _selectedAnalyticsTab == 0
                ? _buildEarningsAnalytics(authService)
                : _buildEnrollmentAnalytics(authService),
            const SizedBox(height: 24),

            // Top performing courses
            _buildTopPerformingCourses(authService),
            const SizedBox(height: 24),

            // Recent activities
            _buildActivitySection(courseProvider),
            const SizedBox(height: 24),

            // Quick actions
            _buildQuickActions(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    // Get current time to display appropriate greeting
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<String?>(
          future: Provider.of<AuthService>(context, listen: false).getCurrentUserEmail(),
          builder: (context, snapshot) {
            final email = snapshot.data;
            final name = email != null ? email.split('@').first.capitalize() : 'Teacher';

            return Text(
              '$greeting, $name',
              style: AppTextStyles.headline2,
            ).animate().fade().slideX(begin: -0.1, end: 0);
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Here\'s what\'s happening with your courses today',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColorScheme.gray700,
          ),
        ).animate(delay: 100.ms).fade().slideX(begin: -0.1, end: 0),

        // Today's summary - New enrollments and revenue today
        FutureBuilder<Map<String, dynamic>>(
          future: _fetchTodaysMetrics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(color: AppColorScheme.primary),
                ),
              );
            }

            final today = snapshot.data ?? {'enrollments': 0, 'revenue': 0.0};

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTodayMetricCard(
                      title: 'New Enrollments',
                      value: '${today['enrollments']}',
                      icon: Icons.people_alt_outlined,
                      color: AppColorScheme.primary,
                      percentage: today['enrollmentPercentage'],
                      isUp: today['isEnrollmentUp'] ?? true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTodayMetricCard(
                      title: 'Today\'s Revenue',
                      value: 'Rs. ${today['revenue'].toStringAsFixed(0)}',
                      icon: Icons.payments_outlined,
                      color: AppColorScheme.secondary,
                      percentage: today['revenuePercentage'],
                      isUp: today['isRevenueUp'] ?? true,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fade().scale(begin: Offset(0.95, 0.95));
          },
        ),
      ],
    );
  }

  Widget _buildTodayMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double? percentage, // Make percentage nullable
    required bool isUp,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (percentage != null) // Only show percentage badge if data is available
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUp ? AppColorScheme.secondaryContainer : AppColorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isUp ? AppColorScheme.secondary : AppColorScheme.tertiary,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: AppTextStyles.caption.copyWith(
                          color: isUp ? AppColorScheme.secondary : AppColorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headline3,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColorScheme.gray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSummaryCard() {
    // Get currency formatter
    final formatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColorScheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: AppColorScheme.secondary,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earnings',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColorScheme.gray700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formatter.format(_totalEarnings),
                          style: AppTextStyles.headline3,
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sync,
                                size: 10,
                                color: AppColorScheme.tertiary,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Live',
                                style: AppTextStyles.overline.copyWith(
                                  color: AppColorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Divider(height: 1, color: AppColorScheme.gray200),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIncomeMetric(
                  title: 'Students',
                  value: '$_totalEnrollments',
                  icon: Icons.people_alt_outlined,
                  iconColor: AppColorScheme.primary,
                ),
                Container(height: 30, width: 1, color: AppColorScheme.gray200),
                _buildIncomeMetric(
                  title: 'Completion',
                  value: '${_completionRate.toStringAsFixed(1)}%',
                  icon: Icons.verified_outlined,
                  iconColor: AppColorScheme.tertiary,
                ),
                Container(height: 30, width: 1, color: AppColorScheme.gray200),
                _buildIncomeMetric(
                  title: 'Per Student',
                  value: 'Rs. ${_totalEnrollments > 0 ? (_totalEarnings / _totalEnrollments).round() : 0}',
                  icon: Icons.person_outline,
                  iconColor: AppColorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildIncomeMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: iconColor),
        SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.subtitle2,
        ),
        Text(
          title,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildRealTimeStatsGrid(AuthService authService, CourseProvider courseProvider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchTeacherCourses(authService),
        builder: (context, snapshot) {
          final courseCount = snapshot.hasData ? snapshot.data!.length : 0;

          // Real-time enrollments from stream
          final enrollmentCount = _totalEnrollments;
          final completionRate = _completionRate;
          final totalEarnings = _totalEarnings;

          return GridView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
            ),
            children: [
              _buildStatCard(
                title: 'Courses',
                value: '$courseCount',
                icon: Icons.school_outlined,
                color: AppColorScheme.primary,
                isLoading: snapshot.connectionState == ConnectionState.waiting,
              ),
              _buildStatCard(
                title: 'Students',
                value: '$enrollmentCount',
                icon: Icons.people_outline,
                color: AppColorScheme.tertiary,
                isLoading: _isLoadingAnalytics,
                isRealTime: true,
              ),
              _buildStatCard(
                title: 'Completion',
                value: '${completionRate.toStringAsFixed(1)}%',
                icon: Icons.verified_outlined,
                color: AppColorScheme.secondary,
                isLoading: _isLoadingAnalytics,
                isRealTime: true,
              ),
              _buildStatCard(
                title: 'This Month',
                value: 'Rs. ${(totalEarnings * 0.7).round()}',
                icon: Icons.calendar_today_outlined,
                color: AppColorScheme.info,
                isLoading: _isLoadingAnalytics,
                isRealTime: true,
              ),
            ],
          ).animate(delay: 200.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0);
        }
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLoading = false,
    bool isRealTime = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: color,
            strokeWidth: 2,
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                if (isRealTime)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sync, size: 8, color: AppColorScheme.tertiary),
                        SizedBox(width: 2),
                        Text(
                          'Live',
                          style: AppTextStyles.overline.copyWith(
                            color: AppColorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Spacer(),
            Text(
              value,
              style: AppTextStyles.subtitle1,
            ),
            Text(
              title,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTabs() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAnalyticsTab = 0;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedAnalyticsTab == 0
                      ? AppColorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Earnings',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _selectedAnalyticsTab == 0
                          ? AppColorScheme.onPrimary
                          : AppColorScheme.gray700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAnalyticsTab = 1;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _selectedAnalyticsTab == 1
                      ? AppColorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Enrollments',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _selectedAnalyticsTab == 1
                          ? AppColorScheme.onPrimary
                          : AppColorScheme.gray700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsAnalytics(AuthService authService) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColorScheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Earnings',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColorScheme.primary,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColorScheme.primary,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 20, color: AppColorScheme.gray800),
                          SizedBox(width: 8),
                          Text('Download Report'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 20, color: AppColorScheme.gray800),
                          SizedBox(width: 8),
                          Text('Share Report'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'filter',
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, size: 20, color: AppColorScheme.gray800),
                          SizedBox(width: 8),
                          Text('Filter Data'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    // Handle menu selection
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: FutureBuilder<Map<String, double>>(
                future: _fetchMonthlyEarningsForTeacher(authService),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColorScheme.primary),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 48,
                            color: AppColorScheme.gray400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No earnings data yet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColorScheme.gray600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Format the data for the chart
                  final monthlyData = snapshot.data!;
                  return _buildMonthlyEarningsChart(monthlyData);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyEarningsChart(Map<String, double> monthlyData) {
    final sortedKeys = monthlyData.keys.toList()
      ..sort((a, b) {
        final aParts = a.split('-');
        final bParts = b.split('-');

        if (aParts.length != 2 || bParts.length != 2) return 0;

        final aYear = int.tryParse(aParts[0]) ?? 0;
        final aMonth = int.tryParse(aParts[1]) ?? 0;
        final bYear = int.tryParse(bParts[0]) ?? 0;
        final bMonth = int.tryParse(bParts[1]) ?? 0;

        if (aYear != bYear) return aYear.compareTo(bYear);
        return aMonth.compareTo(bMonth);
      });

    if (sortedKeys.length > 6) {
      // Only show the last 6 months
      sortedKeys.removeRange(0, sortedKeys.length - 6);
    }

    final values = sortedKeys.map((k) => monthlyData[k]!).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue * 1.2,
        titlesData: FlTitlesData(
          show: true,
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                  final month = sortedKeys[value.toInt()];
                  final parts = month.split('-');
                  if (parts.length == 2) {
                    final monthNum = int.tryParse(parts[1]) ?? 1;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _getShortMonthName(monthNum),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColorScheme.gray600,
                        ),
                      ),
                    );
                  }
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == maxValue / 2 || value == maxValue) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      'Rs.${value.toInt()}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColorScheme.gray600,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxValue / 4,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColorScheme.gray200,
            strokeWidth: 1,
          ),
        ),
        barGroups: List.generate(
          sortedKeys.length,
              (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: monthlyData[sortedKeys[index]]!,
                color: AppColorScheme.primary,
                width: 16,
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxValue * 1.2,
                  color: AppColorScheme.primaryContainer.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final month = sortedKeys[group.x.toInt()];
              final earnings = monthlyData[month]!;

              String monthName = month;
              final parts = month.split('-');
              if (parts.length == 2) {
                final monthNum = int.tryParse(parts[1]) ?? 1;
                monthName = _getMonthName(monthNum);
              }

              return BarTooltipItem(
                '$monthName\nRs. ${earnings.toInt()}',
                AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEnrollmentAnalytics(AuthService authService) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColorScheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enrollment Trend',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColorScheme.primary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sync,
                            size: 10,
                            color: AppColorScheme.tertiary,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Real-time',
                            style: AppTextStyles.overline.copyWith(
                              color: AppColorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: AppColorScheme.primary,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'download',
                          child: Row(
                            children: [
                              Icon(Icons.download, size: 20, color: AppColorScheme.gray800),
                              SizedBox(width: 8),
                              Text('Download Report'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 20, color: AppColorScheme.gray800),
                              SizedBox(width: 8),
                              Text('Share Report'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'filter',
                          child: Row(
                            children: [
                              Icon(Icons.filter_list, size: 20, color: AppColorScheme.gray800),
                              SizedBox(width: 8),
                              Text('Filter Data'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: StreamBuilder<QuerySnapshot>(
                // Stream enrollments from the users collection where we'll track course enrollments
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColorScheme.primary),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 48,
                            color: AppColorScheme.gray400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error loading enrollment data',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColorScheme.gray600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Process the enrollment data from snapshot
                  return FutureBuilder<Map<String, int>>(
                      future: _processEnrollmentTrend(authService, snapshot.data!.docs),
                      builder: (context, trendSnapshot) {
                        if (!trendSnapshot.hasData || trendSnapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.show_chart,
                                  size: 48,
                                  color: AppColorScheme.gray400,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No enrollment data yet',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColorScheme.gray600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return _buildEnrollmentTrendChart(trendSnapshot.data!);
                      }
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _processEnrollmentTrend(AuthService authService, List<QueryDocumentSnapshot> userDocs) async {
    Map<String, int> monthlyEnrollments = {};
    String? instructorEmail = await authService.getCurrentUserEmail();

    if (instructorEmail == null) return {};

    // Get courses taught by this instructor
    List<String> instructorCourseIds = [];
    QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: instructorEmail)
        .get();

    for (var courseDoc in coursesSnapshot.docs) {
      instructorCourseIds.add(courseDoc.id);
    }

    if (instructorCourseIds.isEmpty) return {};

    // Process each user's enrollments
    for (var userDoc in userDocs) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      List<dynamic> enrolledCourses = userData['enrolledCourses'] ?? [];

      for (var enrollment in enrolledCourses) {
        if (enrollment is Map<String, dynamic>) {
          String? courseId = enrollment['courseId'];
          if (courseId != null && instructorCourseIds.contains(courseId)) {
            // Get enrollment date
            Timestamp? enrollmentDate = enrollment['enrollmentDate'];
            if (enrollmentDate != null) {
              DateTime date = enrollmentDate.toDate();
              String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

              // Increment the count for this month
              monthlyEnrollments[monthKey] = (monthlyEnrollments[monthKey] ?? 0) + 1;
            }
          }
        }
      }
    }

    // Sort the map by keys (chronologically)
    Map<String, int> sortedMap = Map.fromEntries(
        monthlyEnrollments.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key))
    );

    return sortedMap;
  }


  Widget _buildEnrollmentTrendChart(Map<String, int> data) {
    final sortedKeys = data.keys.toList()..sort();
    final values = sortedKeys.map((m) => data[m]!).toList();
    final maxY = values.isEmpty ? 10 : values.reduce(max) * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColorScheme.gray200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                  final monthKey = sortedKeys[value.toInt()];
                  final parts = monthKey.split('-');
                  if (parts.length == 2) {
                    final monthNum = int.tryParse(parts[1]) ?? 1;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _getShortMonthName(monthNum),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColorScheme.gray600,
                        ),
                      ),
                    );
                  }
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value % 5 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      value.toInt().toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColorScheme.gray600,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              sortedKeys.length,
                  (index) => FlSpot(index.toDouble(), data[sortedKeys[index]]!.toDouble()),
            ),
            isCurved: true,
            color: AppColorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: AppColorScheme.tertiary,
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColorScheme.primaryContainer.withOpacity(0.4),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final monthIndex = touchedSpot.x.toInt();
                if (monthIndex >= 0 && monthIndex < sortedKeys.length) {
                  final month = sortedKeys[monthIndex];
                  final count = data[month] ?? 0;

                  String monthName = month;
                  final parts = month.split('-');
                  if (parts.length == 2) {
                    final monthNum = int.tryParse(parts[1]) ?? 1;
                    monthName = _getMonthName(monthNum);
                  }

                  return LineTooltipItem(
                    '$monthName\n$count enrollments',
                    AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopPerformingCourses(AuthService authService) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColorScheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Performing Courses',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColorScheme.primary,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sync,
                        size: 10,
                        color: AppColorScheme.tertiary,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Real-time',
                        style: AppTextStyles.overline.copyWith(
                          color: AppColorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            FutureBuilder<String?>(
                future: authService.getCurrentUserEmail(),
                builder: (context, emailSnapshot) {
                  if (!emailSnapshot.hasData) {
                    return _buildCourseListPlaceholder();
                  }

                  final email = emailSnapshot.data!;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('courses')
                        .where('instructorEmail', isEqualTo: email)
                        .snapshots(),
                    builder: (context, courseSnapshot) {
                      if (courseSnapshot.connectionState == ConnectionState.waiting) {
                        return _buildCourseListPlaceholder();
                      }

                      if (courseSnapshot.hasError || !courseSnapshot.hasData || courseSnapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No courses available',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColorScheme.gray600,
                              ),
                            ),
                          ),
                        );
                      }

                      final courses = courseSnapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return {
                          'id': doc.id,
                          'title': data['courseTitle'] ?? 'Untitled Course',
                          'imageUrl': data['imageUrl'],
                          'price': data['price'] != null
                              ? double.tryParse(data['price'].toString()) ?? 0.0
                              : 0.0,
                        };
                      }).toList();

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').snapshots(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return _buildCourseListPlaceholder();
                          }

                          if (userSnapshot.hasError || !userSnapshot.hasData) {
                            return Center(
                              child: Text(
                                'Error loading data',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColorScheme.gray600,
                                ),
                              ),
                            );
                          }

                          // Calculate enrollments and revenue for each course
                          for (var course in courses) {
                            int enrollments = 0;

                            for (var userDoc in userSnapshot.data!.docs) {
                              final userData = userDoc.data() as Map<String, dynamic>;
                              final enrolledCourses = userData['enrolledCourses'] as List<dynamic>? ?? [];

                              bool isEnrolled = enrolledCourses.any((enrollment) {
                                if (enrollment is Map<String, dynamic>) {
                                  return enrollment['courseId'] == course['id'];
                                }
                                return false;
                              });

                              if (isEnrolled) {
                                enrollments++;
                              }
                            }

                            course['enrollments'] = enrollments;
                            course['revenue'] = enrollments * (course['price'] as double);
                          }

                          // Sort by revenue (highest first)
                          courses.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

                          return Column(
                            children: courses.take(3).map((course) =>
                                _buildCoursePerformanceItem(course)
                            ).toList(),
                          );
                        },
                      );
                    },
                  );
                }
            ),

            // View all button
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: TextButton.icon(
                  onPressed: () {
                    // Navigate to a detailed view
                    _tabController.animateTo(1); // Go to courses tab
                  },
                  icon: Icon(
                    Icons.bar_chart,
                    size: 18,
                    color: AppColorScheme.primary,
                  ),
                  label: Text(
                    'View All Course Analytics',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: AppColorScheme.primary.withOpacity(0.3)),
                    ),
                    backgroundColor: AppColorScheme.primaryContainer.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseListPlaceholder() {
    return Column(
      children: List.generate(3, (index) =>
          Shimmer.fromColors(
            baseColor: AppColorScheme.gray300,
            highlightColor: AppColorScheme.gray100,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildCoursePerformanceItem(Map<String, dynamic> course) {
    final formatter = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return InkWell(
      onTap: () {
        // Navigate to detailed course analytics or edit
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Course image
            Hero(
              tag: 'course-image-${course['id']}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: course['imageUrl'] != null
                    ? Image.network(
                  course['imageUrl'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholderImage(size: 60),
                )
                    : _buildPlaceholderImage(size: 60),
              ),
            ),
            SizedBox(width: 16),
            // Course details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['title'],
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: AppColorScheme.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${course['enrollments']} students',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Revenue
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(course['revenue']),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColorScheme.secondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Revenue',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColorScheme.gray600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Activity Section with real-time data
  Widget _buildActivitySection(CourseProvider courseProvider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColorScheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: AppColorScheme.primary,
                  ),
                  onPressed: () {
                    // Filter activities
                  },
                  tooltip: 'Filter activities',
                ),
              ],
            ),
            SizedBox(height: 16),

            // Stream of recent activities
            FutureBuilder<String?>(
                future: Provider.of<AuthService>(context, listen: false).getCurrentUserEmail(),
                builder: (context, emailSnapshot) {
                  if (!emailSnapshot.hasData) {
                    return _buildActivityPlaceholder();
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('activities')
                        .where('teacherId', isEqualTo: emailSnapshot.data)
                        .orderBy('timestamp', descending: true)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildActivityPlaceholder();
                      }

                      // If there's no activity stream collection yet or no data
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none_outlined,
                                size: 48,
                                color: AppColorScheme.gray400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No activity recorded yet',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColorScheme.gray600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Student activities will appear here as they interact with your courses',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColorScheme.gray500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      final activities = snapshot.data!.docs;

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: activities.length > 3 ? 3 : activities.length,
                        separatorBuilder: (context, index) => Divider(height: 16, color: AppColorScheme.gray200),
                        itemBuilder: (context, index) {
                          final activity = activities[index].data() as Map<String, dynamic>;
                          return _buildActivityItem(
                            icon: _getActivityIcon(activity['type']),
                            color: _getActivityColor(activity['type']),
                            title: activity['title'] ?? 'Activity',
                            description: activity['description'] ?? 'No description',
                            time: _formatTimestamp(activity['timestamp']),
                          );
                        },
                      );
                    },
                  );
                }
            ),

            // Show all button when there's data
            FutureBuilder<bool>(
                future: _hasActivities(),
                builder: (context, snapshot) {
                  final hasActivities = snapshot.data ?? false;

                  if (hasActivities) {
                    return Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: TextButton.icon(
                          onPressed: () {
                            // Navigate to all activities screen
                          },
                          icon: Icon(
                            Icons.history,
                            size: 18,
                            color: AppColorScheme.primary,
                          ),
                          label: Text(
                            'View All Activities',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: AppColorScheme.primary.withOpacity(0.3)),
                            ),
                            backgroundColor: AppColorScheme.primaryContainer.withOpacity(0.2),
                          ),
                        ),
                      ),
                    );
                  }

                  return SizedBox.shrink();
                }
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Future<bool> _hasActivities() async {
    try {
      final email = await Provider.of<AuthService>(context, listen: false).getCurrentUserEmail();
      if (email == null) return false;

      final snapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where('teacherId', isEqualTo: email)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking activities: $e');
      return false;
    }
  }


  Widget _buildActivityPlaceholder() {
    return Shimmer.fromColors(
      baseColor: AppColorScheme.gray300,
      highlightColor: AppColorScheme.gray100,
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (context, index) => Divider(height: 16, color: AppColorScheme.gray200),
        itemBuilder: (context, index) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper function to get the appropriate icon for an activity type
  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'enrollment':
        return Icons.person_add_outlined;
      case 'rating':
        return Icons.star_outline;
      case 'comment':
        return Icons.comment_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'completion':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  // Helper function to get the appropriate color for an activity type
  Color _getActivityColor(String? type) {
    switch (type) {
      case 'enrollment':
        return AppColorScheme.primary;
      case 'rating':
        return AppColorScheme.tertiary;
      case 'comment':
        return AppColorScheme.info;
      case 'payment':
        return AppColorScheme.secondary;
      case 'completion':
        return AppColorScheme.success;
      default:
        return AppColorScheme.primary;
    }
  }

  // Helper function to format a timestamp into a relative time string
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'Unknown time';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, yyyy').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Sample activities for when there's no activity collection yet
  Widget _buildSampleActivities() {
    return ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildActivityItem(
          icon: Icons.person_add_outlined,
          color: AppColorScheme.primary,
          title: 'New Enrollment',
          description: 'A student has enrolled in your "Flutter Development" course',
          time: '2 hours ago',
        ),
        Divider(height: 16, color: AppColorScheme.gray200),
        _buildActivityItem(
          icon: Icons.star_outline,
          color: AppColorScheme.tertiary,
          title: 'Course Rating',
          description: 'Your course "Web Development" received a 5-star rating',
          time: '1 day ago',
        ),
        Divider(height: 16, color: AppColorScheme.gray200),
        _buildActivityItem(
          icon: Icons.comment_outlined,
          color: AppColorScheme.info,
          title: 'New Comment',
          description: 'A student commented on your "Introduction to Flutter" video',
          time: '2 days ago',
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String time,
  }) {
    return InkWell(
      onTap: () {
        // View activity details
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: AppTextStyles.caption.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColorScheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: AppTextStyles.subtitle1.copyWith(
                color: AppColorScheme.primary,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionItem(
                  icon: Icons.add_circle_outline,
                  label: 'New Course',
                  color: AppColorScheme.primary,
                  onTap: () => _tabController.animateTo(2),
                ),
                _buildQuickActionItem(
                  icon: Icons.analytics_outlined,
                  label: 'Full Analytics',
                  color: AppColorScheme.secondary,
                  onTap: () {
                    // Navigate to analytics page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EarningsDashboard(primaryColor: AppColorScheme.primary, secondaryColor: AppColorScheme.secondary, accentColor: AppTheme.accentColor, textDarkColor: AppTheme.textTertiaryColor, textLightColor: AppTheme.textTertiaryColor, surfaceColor: AppColorScheme.surface, successColor: AppColorScheme.success,),
                      ),
                    );
                  },
                ),
                _buildQuickActionItem(
                  icon: Icons.message_outlined,
                  label: 'Messages',
                  color: AppColorScheme.tertiary,
                  onTap: () {
                    // Navigate to messages
                  },
                ),
                _buildQuickActionItem(
                  icon: Icons.people_outline,
                  label: 'Students',
                  color: AppColorScheme.info,
                  onTap: () {
                    // Navigate to students list
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // COURSES TAB
  // -------------------------------------------------------------------------
  Widget _buildCoursesTab(AuthService authService, CourseProvider courseProvider) {
    return Column(
      children: [
        // Search and filter header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          color: AppColorScheme.background,
          child: Column(
            children: [
              _buildSearchBar(),
              SizedBox(height: 16),
              _buildFilterOptions(),
            ],
          ),
        ),

        // Courses list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTeacherCourses(authService),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColorScheme.primary,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColorScheme.error.withOpacity(0.7),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error loading courses.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColorScheme.error,
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {});
                          },
                          child: Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColorScheme.primary,
                            foregroundColor: AppColorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyCoursesList();
                } else {
                  final allCourses = snapshot.data!;

                  // Filter courses by search query
                  final filteredCourses = _searchQuery.isEmpty
                      ? allCourses
                      : allCourses.where((course) {
                    final title = course['courseTitle']?.toString().toLowerCase() ?? '';
                    final description = course['description']?.toString().toLowerCase() ?? '';
                    final subject = course['subject']?.toString().toLowerCase() ?? '';
                    return title.contains(_searchQuery) ||
                        description.contains(_searchQuery) ||
                        subject.contains(_searchQuery);
                  }).toList();

                  // Sort courses based on selected option
                  _sortCourses(filteredCourses);

                  if (filteredCourses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_outlined,
                            size: 64,
                            color: AppColorScheme.gray400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No courses match your search',
                            style: AppTextStyles.subtitle1.copyWith(
                              color: AppColorScheme.gray700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try different keywords or clear filters',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColorScheme.gray600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () {
                              _searchController.clear();
                            },
                            icon: Icon(Icons.clear),
                            label: Text('Clear Search'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColorScheme.primary,
                              side: BorderSide(color: AppColorScheme.primary),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                      return Future.delayed(Duration(milliseconds: 1500));
                    },
                    color: AppColorScheme.primary,
                    child: ListView.builder(
                      padding: EdgeInsets.only(top: 16, bottom: 80),
                      controller: _coursesScrollController,
                      itemCount: filteredCourses.length,
                      itemBuilder: (context, index) {
                        final course = filteredCourses[index];
                        return _buildCourseCard(course, authService, courseProvider)
                            .animate()
                            .fade(duration: 300.ms, delay: 50.ms * index)
                            .slideX(begin: 0.1, end: 0);
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search your courses...',
          prefixIcon: Icon(Icons.search, color: AppColorScheme.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: AppColorScheme.gray600),
            onPressed: () {
              _searchController.clear();
            },
            tooltip: 'Clear search',
          )
              : null,
          border: InputBorder.none,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColorScheme.gray500,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSortOption('Default'),
          _buildSortOption('Popular'),
          _buildSortOption('Recent'),
          _buildSortOption('Oldest'),
          _buildSortOption('Price: High-Low'),
          _buildSortOption('Price: Low-High'),
        ],
      ),
    );
  }

  Widget _buildSortOption(String option) {
    final isSelected = _sortOption == option;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          option,
          style: AppTextStyles.caption.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColorScheme.primary : AppColorScheme.gray700,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColorScheme.primaryContainer,
        backgroundColor: AppColorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? AppColorScheme.primary : AppColorScheme.gray300,
            width: isSelected ? 1 : 0.5,
          ),
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _sortOption = option;
            });
          }
        },
        padding: EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  // Continuing from previous code...

  void _sortCourses(List<Map<String, dynamic>> courses) {
    switch (_sortOption) {
      case 'Popular':
      // We would need actual enrollment data, using a random metric for demo
        courses.sort((a, b) => (b['revenue'] ?? 0).compareTo(a['revenue'] ?? 0));
        break;
      case 'Recent':
      // Assuming there's a creation date field, or using ID as proxy
        courses.sort((a, b) => b['id'].compareTo(a['id']));
        break;
      case 'Oldest':
        courses.sort((a, b) => a['id'].compareTo(b['id']));
        break;
      case 'Price: High-Low':
        courses.sort((a, b) {
          final priceA = a['price'] != null ? double.tryParse(a['price'].toString()) ?? 0.0 : 0.0;
          final priceB = b['price'] != null ? double.tryParse(b['price'].toString()) ?? 0.0 : 0.0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'Price: Low-High':
        courses.sort((a, b) {
          final priceA = a['price'] != null ? double.tryParse(a['price'].toString()) ?? 0.0 : 0.0;
          final priceB = b['price'] != null ? double.tryParse(b['price'].toString()) ?? 0.0 : 0.0;
          return priceA.compareTo(priceB);
        });
        break;
      default:
      // Default sorting (by title)
        courses.sort((a, b) => (a['courseTitle'] ?? '').compareTo(b['courseTitle'] ?? ''));
    }
  }

  Widget _buildEmptyCoursesList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              size: 64,
              color: AppColorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No courses yet',
            style: AppTextStyles.headline3,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first course to get started',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColorScheme.gray600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _tabController.animateTo(2);
            },
            icon: Icon(Icons.add),
            label: Text('Create Course'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primary,
              foregroundColor: AppColorScheme.onPrimary,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
      Map<String, dynamic> course,
      AuthService authService,
      CourseProvider courseProvider
      ) {
    return Slidable(
      key: ValueKey(course['id']),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              _editCourse(context, course, courseProvider);
              _tabController.animateTo(2);
            },
            backgroundColor: AppColorScheme.primary,
            foregroundColor: AppColorScheme.onPrimary,
            icon: Icons.edit_outlined,
            label: 'Edit',
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(12),
            ),
          ),
          SlidableAction(
            onPressed: (_) {
              // Navigate to Enhanced Section Management
              _navigateToSectionManagement(context, course['id']);
            },
            backgroundColor: AppColorScheme.tertiary,
            foregroundColor: AppColorScheme.onTertiary,
            icon: Icons.folder_outlined,
            label: 'Sections',
          ),
          SlidableAction(
            onPressed: (_) async {
              await _showDeleteConfirmationDialog(
                context,
                course['id'],
                courseProvider,
              );
            },
            backgroundColor: AppColorScheme.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColorScheme.gray200),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Show course details/analytics modal
            _showCourseDetailsModal(context, course, courseProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course image
                    Hero(
                      tag: 'course-image-${course['id']}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: course['imageUrl'] != null
                            ? Image.network(
                          course['imageUrl'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(size: 80),
                        )
                            : _buildPlaceholderImage(size: 80),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Course info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['courseTitle'] ?? 'Untitled Course',
                            style: AppTextStyles.subtitle2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            course['description'] ?? 'No description',
                            style: AppTextStyles.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Tags row
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildTag(
                                course['subject'] ?? 'No Subject',
                                color: AppColorScheme.primary,
                              ),
                              _buildTag(
                                course['medium'] ?? 'Language',
                                color: AppColorScheme.tertiary,
                              ),
                              _buildTag(
                                'Rs. ${course['price'] ?? 0}',
                                color: AppColorScheme.secondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Course stats
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    int enrollmentCount = 0;
                    double totalEarnings = 0.0;

                    if (snapshot.hasData) {
                      final courseId = course['id'];
                      final price = course['price'] != null
                          ? double.tryParse(course['price'].toString()) ?? 0.0
                          : 0.0;

                      for (var doc in snapshot.data!.docs) {
                        final userData = doc.data() as Map<String, dynamic>;
                        final enrolledCourses = userData['enrolledCourses'] as List<dynamic>? ?? [];

                        bool isEnrolled = enrolledCourses.any((enrollment) {
                          if (enrollment is Map<String, dynamic>) {
                            return enrollment['courseId'] == courseId;
                          }
                          return false;
                        });

                        if (isEnrolled) {
                          enrollmentCount++;
                          totalEarnings += price;
                        }
                      }
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCourseStatItem(
                          icon: Icons.people_outline,
                          value: enrollmentCount.toString(),
                          label: 'Students',
                          isRealTime: true,
                        ),
                        Container(height: 30, width: 1, color: AppColorScheme.gray200),
                        _buildCourseStatItem(
                          icon: Icons.timer_outlined,
                          value: course['duration'] ?? 'N/A',
                          label: 'Duration',
                        ),
                        Container(height: 30, width: 1, color: AppColorScheme.gray200),
                        _buildCourseStatItem(
                          icon: Icons.account_balance_wallet_outlined,
                          value: 'Rs. ${totalEarnings.toStringAsFixed(0)}',
                          label: 'Revenue',
                          isRealTime: true,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCourseDetailsModal(BuildContext context, Map<String, dynamic> course, CourseProvider courseProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AppColorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColorScheme.gray300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Course header
              _buildCourseDetailsHeader(course),

              // Tabs
              DefaultTabController(
                length: 3,
                child: Expanded(
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: AppColorScheme.primary,
                        unselectedLabelColor: AppColorScheme.gray600,
                        indicatorColor: AppColorScheme.primary,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(text: 'Analytics'),
                          Tab(text: 'Students'),
                          Tab(text: 'Content'),
                        ],
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        labelStyle: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: AppTextStyles.bodyMedium,
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Analytics tab
                            SingleChildScrollView(
                              controller: controller,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    _buildCourseAnalyticsCard(course),
                                    SizedBox(height: 16),
                                    _buildCourseEnrollmentChart(course),
                                  ],
                                ),
                              ),
                            ),

                            // Students tab
                            _buildCourseStudentsTab(course['id']),

                            // Content tab
                            _buildCourseContentTab(course['id'], controller),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseDetailsHeader(Map<String, dynamic> course) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorScheme.primary,
            AppColorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course image
          Hero(
            tag: 'course-detail-${course['id']}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: course['imageUrl'] != null
                  ? Image.network(
                course['imageUrl'],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      width: 80,
                      height: 80,
                      color: AppColorScheme.tertiaryContainer,
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColorScheme.tertiary,
                        size: 40,
                      ),
                    ),
              )
                  : Container(
                width: 80,
                height: 80,
                color: AppColorScheme.tertiaryContainer,
                child: Icon(
                  Icons.image_outlined,
                  color: AppColorScheme.tertiary,
                  size: 40,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),

          // Course info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['courseTitle'] ?? 'Untitled Course',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColorScheme.onPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  course['subject'] ?? 'No subject',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 8),

                // Stats row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCourseHeaderStat(
                      'Rs. ${course['price'] ?? 0}',
                      Icons.monetization_on_outlined,
                    ),
                    _buildCourseHeaderStat(
                      course['duration'] ?? 'N/A',
                      Icons.timer_outlined,
                    ),
                    _buildCourseHeaderStat(
                      course['medium'] ?? 'Language',
                      Icons.language_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseHeaderStat(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColorScheme.onPrimary,
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
  Future<Map<String, dynamic>> _fetchCourseAnalytics(String courseId) async {
    try {
      // Fetch course price
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get();

      if (!courseDoc.exists) {
        return {
          'enrollments': 0,
          'revenue': 0.0,
          'completionRate': 0.0,
          'rating': 0.0
        };
      }

      final courseData = courseDoc.data()!;
      final priceValue = courseData['price'] ?? 0.0;
      final double coursePrice = double.tryParse(priceValue.toString()) ?? 0.0;

      // Fetch users enrolled in this course
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      int enrollmentCount = 0;
      int completedCount = 0;
      double totalRating = 0.0;
      int ratingCount = 0;

      for (var userDoc in userSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final enrolledCourses = userData['enrolledCourses'] as List<dynamic>? ?? [];

        for (var enrollment in enrolledCourses) {
          if (enrollment is Map<String, dynamic> && enrollment['courseId'] == courseId) {
            enrollmentCount++;

            // Check completion
            if (enrollment['isCompleted'] == true) {
              completedCount++;
            }

            // Check rating
            if (enrollment['rating'] != null) {
              totalRating += double.tryParse(enrollment['rating'].toString()) ?? 0.0;
              ratingCount++;
            }
          }
        }
      }

      // Calculate metrics
      final revenue = enrollmentCount * coursePrice;
      final completionRate = enrollmentCount > 0
          ? (completedCount / enrollmentCount) * 100
          : 0.0;
      final rating = ratingCount > 0
          ? totalRating / ratingCount
          : 0.0;

      return {
        'enrollments': enrollmentCount,
        'revenue': revenue,
        'completionRate': completionRate,
        'rating': rating
      };
    } catch (e) {
      print('Error fetching course analytics: $e');
      return {
        'enrollments': 0,
        'revenue': 0.0,
        'completionRate': 0.0,
        'rating': 0.0
      };
    }
  }

  Widget _buildCourseAnalyticsCard(Map<String, dynamic> course) {
    final courseId = course['id'];

    return FutureBuilder<Map<String, dynamic>>(
        future: _fetchCourseAnalytics(courseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: CircularProgressIndicator(color: AppColorScheme.primary),
              ),
            );
          }

          final analytics = snapshot.data ?? {
            'enrollments': 0,
            'revenue': 0.0,
            'completionRate': 0.0,
            'rating': 0.0
          };

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColorScheme.gray200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Course Performance',
                        style: AppTextStyles.subtitle1.copyWith(
                          color: AppColorScheme.primary,
                        ),
                      ),
                      // Download report button
                      IconButton(
                        icon: Icon(
                          Icons.download,
                          color: AppColorScheme.primary,
                        ),
                        onPressed: () {
                          // Download analytics report
                        },
                        tooltip: 'Download report',
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Metrics grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildAnalyticTile(
                        title: 'Students',
                        value: analytics['enrollments'].toString(),
                        icon: Icons.people_outline,
                        color: AppColorScheme.primary,
                      ),
                      _buildAnalyticTile(
                        title: 'Revenue',
                        value: 'Rs. ${analytics['revenue'].toInt()}',
                        icon: Icons.payments_outlined,
                        color: AppColorScheme.secondary,
                      ),
                      _buildAnalyticTile(
                        title: 'Completion',
                        value: '${analytics['completionRate'].toStringAsFixed(1)}%',
                        icon: Icons.check_circle_outline,
                        color: AppColorScheme.tertiary,
                      ),
                      _buildAnalyticTile(
                        title: 'Rating',
                        value: analytics['rating'].toStringAsFixed(1),
                        icon: Icons.star_outline,
                        color: AppColorScheme.info,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
    );
  }

  Widget _buildAnalyticTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          Spacer(),
          Text(
            value,
            style: AppTextStyles.subtitle1,
          ),
          Text(
            title,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseEnrollmentChart(Map<String, dynamic> course) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColorScheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enrollment Trend',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColorScheme.primary,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColorScheme.primary),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'month', child: Text('Monthly View')),
                    PopupMenuItem(value: 'week', child: Text('Weekly View')),
                    PopupMenuItem(value: 'custom', child: Text('Custom Range')),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: FutureBuilder<Map<String, int>>(
                future: _fetchCourseEnrollmentTrend(course['id']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColorScheme.primary),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.show_chart, size: 48, color: AppColorScheme.gray400),
                          SizedBox(height: 16),
                          Text(
                            'No enrollment data yet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColorScheme.gray600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Format data for chart
                  final data = snapshot.data!;
                  final sortedKeys = data.keys.toList()..sort();
                  final values = sortedKeys.map((m) => data[m]!).toList();
                  final maxY = values.isEmpty ? 10 : values.reduce(max) * 1.2;

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 5,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColorScheme.gray200,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < sortedKeys.length) {
                                final monthKey = sortedKeys[value.toInt()];
                                final parts = monthKey.split('-');
                                if (parts.length == 2) {
                                  final monthNum = int.tryParse(parts[1]) ?? 1;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _getShortMonthName(monthNum),
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColorScheme.gray600,
                                      ),
                                    ),
                                  );
                                }
                              }
                              return const SizedBox();
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              if (value % 5 == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColorScheme.gray600,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            sortedKeys.length,
                                (index) => FlSpot(index.toDouble(), data[sortedKeys[index]]!.toDouble()),
                          ),
                          isCurved: true,
                          color: AppColorScheme.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 4,
                              color: AppColorScheme.tertiary,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColorScheme.primaryContainer.withOpacity(0.4),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (List<LineBarSpot> spots) {
                            return spots.map((spot) {
                              final index = spot.x.toInt();
                              if (index >= 0 && index < sortedKeys.length) {
                                final month = sortedKeys[index];
                                final parts = month.split('-');
                                String monthName = month;
                                if (parts.length == 2) {
                                  final monthNum = int.tryParse(parts[1]) ?? 1;
                                  monthName = _getMonthName(monthNum);
                                }
                                return LineTooltipItem(
                                  '$monthName\n${spot.y.toInt()} enrollments',
                                  AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }
                              return null;
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Note about data
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColorScheme.gray600,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Real enrollment data shown by month. Click "Download Report" for detailed analytics.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColorScheme.gray600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _fetchCourseEnrollmentTrend(String courseId) async {
    Map<String, int> monthlyEnrollments = {};

    try {
      // Get users enrolled in this course
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      for (var userDoc in userSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final enrolledCourses = userData['enrolledCourses'] as List<dynamic>? ?? [];

        for (var enrollment in enrolledCourses) {
          if (enrollment is Map<String, dynamic> && enrollment['courseId'] == courseId) {
            // Get enrollment date
            Timestamp? enrollmentDate = enrollment['enrollmentDate'];
            if (enrollmentDate != null) {
              DateTime date = enrollmentDate.toDate();
              String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

              // Increment the count for this month
              monthlyEnrollments[monthKey] = (monthlyEnrollments[monthKey] ?? 0) + 1;
            }
          }
        }
      }

      // Sort the map by keys (chronologically)
      Map<String, int> sortedMap = Map.fromEntries(
          monthlyEnrollments.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key))
      );

      return sortedMap;
    } catch (e) {
      print('Error fetching course enrollment trend: $e');
      return {};
    }
  }

  Widget _buildCourseStudentsTab(String courseId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColorScheme.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColorScheme.error.withOpacity(0.7),
                ),
                SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColorScheme.error,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppColorScheme.gray400,
                ),
                SizedBox(height: 16),
                Text(
                  'No students enrolled yet',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColorScheme.gray700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Filter users who are enrolled in this course
        List<Map<String, dynamic>> enrolledStudents = [];

        for (var userDoc in snapshot.data!.docs) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final enrolledCourses = userData['enrolledCourses'] as List<dynamic>? ?? [];

          bool isEnrolled = enrolledCourses.any((enrollment) {
            if (enrollment is Map<String, dynamic>) {
              return enrollment['courseId'] == courseId;
            }
            return false;
          });

          if (isEnrolled) {
            // Find this specific course enrollment
            Map<String, dynamic>? courseEnrollment;

            for (var enrollment in enrolledCourses) {
              if (enrollment is Map<String, dynamic> && enrollment['courseId'] == courseId) {
                courseEnrollment = enrollment;
                break;
              }
            }

            enrolledStudents.add({
              'id': userDoc.id,
              'name': userData['name'] ?? 'Unknown User',
              'email': userData['email'] ?? 'No Email',
              'profileImage': userData['profileImageUrl'],
              'progress': courseEnrollment?['progress'] ?? 0,
              'enrollmentDate': courseEnrollment?['enrollmentDate'],
              'completed': courseEnrollment?['isCompleted'] ?? false,
            });
          }
        }

        if (enrolledStudents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: AppColorScheme.gray400,
                ),
                SizedBox(height: 16),
                Text(
                  'No students enrolled yet',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColorScheme.gray700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Sort by enrollment date (newest first)
        enrolledStudents.sort((a, b) {
          if (a['enrollmentDate'] == null || b['enrollmentDate'] == null) return 0;
          return (b['enrollmentDate'] as Timestamp)
              .compareTo(a['enrollmentDate'] as Timestamp);
        });

        return Column(
          children: [
            // Student search and filter
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: Icon(Icons.search, color: AppColorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorScheme.gray300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorScheme.gray300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColorScheme.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColorScheme.surface,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            // Student counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${enrolledStudents.length} Students',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColorScheme.primary,
                    ),
                  ),
                  // Export button
                  TextButton.icon(
                    onPressed: () {
                      // Export student list
                    },
                    icon: Icon(
                      Icons.download,
                      size: 18,
                    ),
                    label: Text('Export'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: AppColorScheme.gray200),

            // Student list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: enrolledStudents.length,
                itemBuilder: (context, index) {
                  final student = enrolledStudents[index];
                  return _buildStudentCard(student);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final progress = (student['progress'] as num?)?.toDouble() ?? 0.0;
    final enrollmentDate = student['enrollmentDate'] != null
        ? (student['enrollmentDate'] as Timestamp).toDate()
        : null;
    final dateFormatted = enrollmentDate != null
        ? DateFormat('MMM d, yyyy').format(enrollmentDate)
        : 'Unknown';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColorScheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Student avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColorScheme.primaryContainer,
                  backgroundImage: student['profileImage'] != null
                      ? NetworkImage(student['profileImage'])
                      : null,
                  child: student['profileImage'] == null
                      ? Text(
                    student['name'].toString().isNotEmpty
                        ? student['name'][0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: AppColorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
                SizedBox(width: 16),

                // Student details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'] ?? 'Unknown User',
                        style: AppTextStyles.subtitle2,
                      ),
                      Text(
                        student['email'] ?? 'No email',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),

                // Completion badge
                if (student['completed'] == true)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColorScheme.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColorScheme.secondary,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),

            // Progress section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: ${progress.toInt()}%',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Enrolled: $dateFormatted',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: AppColorScheme.gray200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        progress < 30
                            ? AppColorScheme.tertiary
                            : progress < 70
                            ? AppColorScheme.primary
                            : AppColorScheme.secondary
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),

            // Actions
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Message student action
                  },
                  icon: Icon(Icons.message_outlined, size: 16),
                  label: Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColorScheme.primary,
                    side: BorderSide(color: AppColorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    // View student profile action
                  },
                  icon: Icon(Icons.visibility_outlined, size: 16),
                  label: Text('View Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColorScheme.secondary,
                    side: BorderSide(color: AppColorScheme.secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseContentTab(String courseId, ScrollController parentController) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('courses').doc(courseId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColorScheme.primary));
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColorScheme.error.withOpacity(0.7),
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading course content',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColorScheme.error,
                  ),
                ),
              ],
            ),
          );
        }

        final courseData = snapshot.data!.data() as Map<String, dynamic>;
        final List<dynamic> sections = courseData['sections'] ?? [];

        if (sections.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 64,
                  color: AppColorScheme.gray400,
                ),
                SizedBox(height: 16),
                Text(
                  'No content added yet',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: AppColorScheme.gray700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _navigateToSectionManagement(context, courseId);
                  },
                  icon: Icon(Icons.add),
                  label: Text('Add Course Content'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorScheme.primary,
                    foregroundColor: AppColorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Manage content button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  _navigateToSectionManagement(context, courseId);
                },
                icon: Icon(Icons.edit),
                label: Text('Manage Course Content'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorScheme.primary,
                  foregroundColor: AppColorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ),

            // Content summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildContentSummaryItem(
                    icon: Icons.video_library_outlined,
                    label: 'Videos',
                    count: _countVideos(sections),
                    color: AppColorScheme.primary,
                  ),
                  SizedBox(width: 12),
                  _buildContentSummaryItem(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDFs',
                    count: _countPdfs(sections),
                    color: AppColorScheme.tertiary,
                  ),
                  SizedBox(width: 12),
                  _buildContentSummaryItem(
                    icon: Icons.folder_outlined,
                    label: 'Sections',
                    count: sections.length,
                    color: AppColorScheme.secondary,
                  ),
                ],
              ),
            ),

            // Sections list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final section = sections[index] as Map<String, dynamic>;
                  final List<dynamic> videos = section['videos'] ?? [];
                  final List<dynamic> pdfs = section['pdfs'] ?? [];

                  return _buildSectionCard(
                    title: section['sectionTitle'] ?? 'Untitled Section',
                    videos: videos,
                    pdfs: pdfs,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  int _countVideos(List<dynamic> sections) {
    int count = 0;
    for (var section in sections) {
      if (section is Map<String, dynamic>) {
        count += (section['videos'] as List?)?.length ?? 0;
      }
    }
    return count;
  }

  int _countPdfs(List<dynamic> sections) {
    int count = 0;
    for (var section in sections) {
      if (section is Map<String, dynamic>) {
        count += (section['pdfs'] as List?)?.length ?? 0;
      }
    }
    return count;
  }

  Widget _buildContentSummaryItem({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 4),
            Text(
              '$count',
              style: AppTextStyles.subtitle2.copyWith(
                color: color,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<dynamic> videos,
    required List<dynamic> pdfs,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColorScheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorScheme.primaryContainer,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, color: AppColorScheme.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.subtitle2,
                      ),
                      SizedBox(height: 2),
                      Text(
                        '${videos.length} videos, ${pdfs.length} resources',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColorScheme.gray700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.expand_more,
                    color: AppColorScheme.primary,
                  ),
                  onPressed: () {
                    // Toggle expand/collapse
                  },
                  splashRadius: 24,
                  tooltip: 'Expand/Collapse',
                ),
              ],
            ),
          ),

          // Content list
          if (videos.isEmpty && pdfs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No content in this section',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColorScheme.gray500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: videos.length + pdfs.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: AppColorScheme.gray200),
              itemBuilder: (context, index) {
                if (index < videos.length) {
                  // Video item
                  final video = videos[index] as Map<String, dynamic>;
                  return _buildVideoItem(video, index + 1);
                } else {
                  // PDF resource item
                  final pdf = pdfs[index - videos.length] as Map<String, dynamic>;
                  return _buildPdfItem(pdf, index + 1);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video, int index) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.play_arrow,
            color: AppColorScheme.primary,
          ),
        ],
      ),
      title: Text(
        video['title'] ?? 'Untitled Video',
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: video['duration'] != null ? Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          'Duration: ${video['duration']}',
          style: AppTextStyles.caption,
        ),
      ) : null,
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: AppColorScheme.gray600),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'preview',
            child: Row(
              children: [
                Icon(Icons.visibility, size: 20, color: AppColorScheme.gray800),
                SizedBox(width: 8),
                Text('Preview'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20, color: AppColorScheme.gray800),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: AppColorScheme.error),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: AppColorScheme.error)),
              ],
            ),
          ),
        ],
      ),
      onTap: () {
        // View video details
      },
    );
  }

  Widget _buildPdfItem(Map<String, dynamic> pdf, int index) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColorScheme.tertiaryContainer,
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.picture_as_pdf,
            color: AppColorScheme.tertiary,
          ),
        ],
      ),
      title: Text(
        pdf['title'] ?? 'Untitled PDF',
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: pdf['size'] != null ? Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          'Size: ${pdf['size']}',
          style: AppTextStyles.caption,
        ),
      ) : null,
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: AppColorScheme.gray600),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'preview',
            child: Row(
              children: [
                Icon(Icons.visibility, size: 20, color: AppColorScheme.gray800),
                SizedBox(width: 8),
                Text('Preview'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'download',
            child: Row(
              children: [
                Icon(Icons.download, size: 20, color: AppColorScheme.gray800),
                SizedBox(width: 8),
                Text('Download'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: AppColorScheme.error),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: AppColorScheme.error)),
              ],
            ),
          ),
        ],
      ),
      onTap: () {
        // View PDF details
      },
    );
  }

  // Navigate to enhanced section management
  void _navigateToSectionManagement(BuildContext context, String courseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedSectionManagement(
          courseId: courseId,
        ),
      ),
    );
  }

  Widget _buildTag(String text, {required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.overline.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCourseStatItem({
    required IconData icon,
    required String value,
    required String label,
    bool isRealTime = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColorScheme.primary),
            if (isRealTime) ...[
              SizedBox(width: 2),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // CREATE COURSE TAB
  // -------------------------------------------------------------------------
  Widget _buildCreateCourseTab(BuildContext context, AuthService authService, CourseProvider courseProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          Text(
            _currentCourseId == null ? 'Create New Course' : 'Edit Course',
            style: AppTextStyles.headline2,
          ).animate().fade().slideX(begin: -0.1, end: 0, duration: 300.ms),
          Text(
            _currentCourseId == null
                ? 'Fill in the details to create a new course'
                : 'Update your course information',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColorScheme.gray600,
            ),
          ).animate().fade().slideX(begin: -0.1, end: 0, duration: 300.ms, delay: 100.ms),
          const SizedBox(height: 32),

          // Course form
          _buildCourseForm(context, authService, courseProvider),
        ],
      ),
    );
  }

  // Mobile optimized course form
  Widget _buildCourseForm(BuildContext context, AuthService authService,
      CourseProvider courseProvider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColorScheme.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE PICKER
              _buildImagePicker(context),
              const SizedBox(height: 32),

              // FORM FIELDS
              _buildTextField(_titleController, 'Course Title', Icons.title),
              const SizedBox(height: 20),
              _buildTextField(
                _descriptionController, 'Description', Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                _instructorController, 'Instructor', Icons.person,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                _priceController, 'Price', Icons.attach_money,
                isNumeric: true,
                prefixText: 'Rs. ',
              ),
              const SizedBox(height: 20),
              _buildTextField(_durationController, 'Duration', Icons.timer),
              const SizedBox(height: 20),
              _buildTextField(_subjectController, 'Subject', Icons.subject),
              const SizedBox(height: 24),

              // DROPDOWN
              _buildMediumDropdown(),
              const SizedBox(height: 40),

              // SUBMIT BUTTON
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Show loading overlay
                      _showLoadingOverlay(context);

                      try {
                        // 1) Get instructor email
                        String? instructorEmail =
                        await authService.getCurrentUserEmail();
                        if (instructorEmail == null) {
                          Navigator.pop(context); // Dismiss loading overlay
                          _showMessage(
                            context,
                            'Error: Instructor email not found',
                            isError: true,
                          );
                          return;
                        }

                        // 2) Course ID
                        String courseId = _currentCourseId ??
                            DateTime.now().millisecondsSinceEpoch.toString();

                        // 3) Upload image
                        String? imageUrl = await _uploadCourseImage(courseId);

                        // 4) Create / Update
                        if (_currentCourseId == null) {
                          await courseProvider.addCourse(
                            title: _titleController.text,
                            description: _descriptionController.text,
                            price: double.tryParse(_priceController.text),
                            duration: _durationController.text,
                            subject: _subjectController.text,
                            instructor: _instructorController.text,
                            status: 'Premium',
                            instructorEmail: instructorEmail,
                            imageUrl: imageUrl,
                            medium: _selectedMedium,
                          );
                        } else {
                          await courseProvider.editCourse(
                            _currentCourseId!,
                            _titleController.text,
                            _descriptionController.text,
                            double.tryParse(_priceController.text),
                            _subjectController.text,
                            imageUrl ?? _currentImageUrl!,
                            _selectedMedium!,
                          );
                        }

                        // Dismiss loading overlay
                        Navigator.pop(context);

                        // 5) Show success
                        _showMessage(
                          context,
                          _currentCourseId == null
                              ? 'Course created successfully!'
                              : 'Course updated successfully!',
                        );

                        // 6) Clear
                        _clearFormFields();

                        // 7) Navigate to courses tab
                        _tabController.animateTo(1);
                      } catch (e) {
                        // Dismiss loading overlay and show error
                        Navigator.pop(context);
                        _showMessage(
                          context,
                          'Error: ${e.toString()}',
                          isError: true,
                        );
                      }
                    }
                  },
                  icon: Icon(_currentCourseId == null ? Icons.add : Icons.save),
                  label: Text(
                    _currentCourseId == null ? 'CREATE COURSE' : 'UPDATE COURSE',
                    style: AppTextStyles.button,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorScheme.primary,
                    foregroundColor: AppColorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              // Cancel button (if editing)
              if (_currentCourseId != null)
                Center(
                  child: TextButton(
                    onPressed: () {
                      _clearFormFields();
                    },
                    child: Text(
                      'CANCEL',
                      style: AppTextStyles.button.copyWith(
                        color: AppColorScheme.gray700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms, delay: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool isNumeric = false,
        int maxLines = 1,
        String? prefixText,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColorScheme.gray400,
            ),
            prefixIcon: Icon(icon, color: AppColorScheme.primary, size: 20),
            prefixText: prefixText,
            prefixStyle: AppTextStyles.bodyMedium,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColorScheme.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColorScheme.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColorScheme.error),
            ),
            filled: true,
            fillColor: AppColorScheme.background,
            contentPadding: EdgeInsets.symmetric(
              vertical: maxLines > 1 ? 16 : 12,
              horizontal: 16,
            ),
          ),
          validator: (value) => value!.isEmpty ? '$label is required' : null,
        ),
      ],
    );
  }

  Widget _buildMediumDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medium',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedMedium,
          decoration: InputDecoration(
            hintText: 'Select medium',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColorScheme.gray400,
            ),
            prefixIcon: Icon(Icons.language, color: AppColorScheme.primary, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColorScheme.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColorScheme.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColorScheme.error),
            ),
            filled: true,
            fillColor: AppColorScheme.background,
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          style: AppTextStyles.bodyMedium,
          dropdownColor: AppColorScheme.surface,
          items: ['Tamil', 'English', 'Sinhala']
              .map(
                (medium) => DropdownMenuItem<String>(
              value: medium,
              child: Text(medium),
            ),
          )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedMedium = value;
            });
          },
          icon: Icon(Icons.arrow_drop_down, color: AppColorScheme.primary),
          validator: (value) =>
          (value == null || value.isEmpty) ? 'Select a medium' : null,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // IMAGE PICKER
  // ---------------------------------------------------------------------------
  Widget _buildImagePicker(BuildContext context) {
    return InkWell(
      onTap: () => _showImageSourceDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Center(
        child: Container(
          width: 280,
          height: 180,
          decoration: BoxDecoration(
            color: AppColorScheme.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // If user selected an image, display it
              if (_courseImage != null)
                Hero(
                  tag: 'course-image-preview',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _courseImage!,
                      fit: BoxFit.cover,
                      width: 280,
                      height: 180,
                    ).animate().fade(duration: 500.ms),
                  ),
                )
              // If an image URL exists, load it from network
              else if (_currentImageUrl != null)
                Hero(
                  tag: 'course-image-preview',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _currentImageUrl!,
                      fit: BoxFit.cover,
                      width: 280,
                      height: 180,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                (progress.expectedTotalBytes ?? 1)
                                : null,
                            color: AppColorScheme.tertiary,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImagePlaceholder(),
                    ),
                  ),
                ).animate().fade(duration: 500.ms)
              // Otherwise, show placeholder with dotted border
              else
                _buildImagePlaceholder(),

              // Overlay edit icon
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColorScheme.primary.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: AppColorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: Radius.circular(12),
      color: AppColorScheme.primary.withOpacity(0.6),
      strokeWidth: 2,
      dashPattern: [6, 4],
      child: Center(
        child: Container(
          width: 280,
          height: 180,
          decoration: BoxDecoration(
            color: AppColorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 40,
                color: AppColorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload Course Image',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Recommended size: 1280 x 720 px',
                style: AppTextStyles.caption.copyWith(
                  color: AppColorScheme.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade().slideY(begin: 0.1, duration: 400.ms);
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(bottom: 16),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColorScheme.gray300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Text(
                'Select Image Source',
                style: AppTextStyles.subtitle1.copyWith(
                  color: AppColorScheme.primary,
                ),
              ),
              SizedBox(height: 24),

              // Camera option
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColorScheme.primaryContainer,
                  ),
                  child: Icon(Icons.camera_alt, color: AppColorScheme.primary),
                ),
                title: Text(
                  'Camera',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Take a new photo',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColorScheme.gray600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),

              // Gallery option
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColorScheme.tertiaryContainer,
                  ),
                  child: Icon(Icons.photo_library, color: AppColorScheme.tertiary),
                ),
                title: Text(
                  'Gallery',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Choose from your photos',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColorScheme.gray600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1280,
      maxHeight: 720,
    );
    if (image != null) {
      setState(() {
        _courseImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadCourseImage(String courseId) async {
    if (_courseImage == null) return null;
    try {
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('course_images')
          .child('$courseId.jpg');
      await storageRef.putFile(_courseImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildPlaceholderImage({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_outlined,
        color: AppColorScheme.primary.withOpacity(0.6),
        size: size / 2,
      ),
    );
  }

  // Loading overlay for async operations
  void _showLoadingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: AppColorScheme.primary,
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Please wait...',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DATA FETCHING & UTILITIES
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchTeacherCourses(
      AuthService authService) async {
    String? email = await authService.getCurrentUserEmail();
    if (email == null) return [];

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: email)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<Map<String, double>> _fetchMonthlyEarningsForTeacher(AuthService authService) async {
    final email = await authService.getCurrentUserEmail();
    if (email == null) return {};

    // First get all courses by this teacher
    final courseSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: email)
        .get();

    final Map<String, double> teacherCourses = {};
    for (var doc in courseSnapshot.docs) {
      final data = doc.data();
      final priceValue = data['price'] ?? 0.0;
      final double coursePrice = double.tryParse(priceValue.toString()) ?? 0.0;
      teacherCourses[doc.id] = coursePrice;
    }

    if (teacherCourses.isEmpty) return {};

    final Map<String, double> monthlyEarnings = {};

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data();
      final enrolledCourses = userData['enrolledCourses'] as List<dynamic>? ?? [];

      for (var enrollment in enrolledCourses) {
        if (enrollment is Map<String, dynamic>) {
          final String? courseId = enrollment['courseId'];

          if (courseId != null && teacherCourses.containsKey(courseId)) {
            final Timestamp? enrollmentDate = enrollment['enrollmentDate'];

            if (enrollmentDate != null) {
              final date = enrollmentDate.toDate();
              final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
              final price = teacherCourses[courseId] ?? 0.0;

              monthlyEarnings[monthKey] = (monthlyEarnings[monthKey] ?? 0.0) + price;
            }
          }
        }
      }
    }

    // Sort by month
    final sortedMap = Map<String, double>.fromEntries(
        monthlyEarnings.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key))
    );

    return sortedMap;
  }

  Future<Map<String, int>> _fetchEnrollmentTrend(AuthService authService) async {
    final email = await authService.getCurrentUserEmail();
    if (email == null) return {};

    // First get all courses by this teacher
    final courseSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: email)
        .get();

    final courseIds = courseSnapshot.docs.map((doc) => doc.id).toList();
    if (courseIds.isEmpty) return {};

    // Get users enrolled in these courses
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    Map<String, int> monthlyEnrollments = {};

    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data();
      final enrolledCourses = userData['enrolledCourses'] as List<dynamic>? ?? [];

      for (var enrollment in enrolledCourses) {
        if (enrollment is Map<String, dynamic> &&
            courseIds.contains(enrollment['courseId'])) {
          // Get enrollment date
          final timestamp = enrollment['enrollmentDate'] as Timestamp?;
          if (timestamp != null) {
            final date = timestamp.toDate();
            final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

            monthlyEnrollments[monthKey] = (monthlyEnrollments[monthKey] ?? 0) + 1;
          }
        }
      }
    }

    // Sort months chronologically
    final sortedMap = Map<String, int>.fromEntries(
        monthlyEnrollments.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key))
    );

    return sortedMap;
  }

  // Today's metrics - placeholder/mock values for now, could be replaced with real data
  Future<Map<String, dynamic>> _fetchTodaysMetrics() async {
    try {
      final email = await Provider.of<AuthService>(context, listen: false).getCurrentUserEmail();
      if (email == null) return {'enrollments': 0, 'revenue': 0.0, 'enrollmentPercentage': null, 'revenuePercentage': null};

      // Get today's start timestamp
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startTimestamp = Timestamp.fromDate(startOfDay);

      // Get yesterday's start timestamp for comparison
      final yesterday = startOfDay.subtract(const Duration(days: 1));
      final yesterdayTimestamp = Timestamp.fromDate(yesterday);

      // Get all courses by this teacher
      final courseSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('instructorEmail', isEqualTo: email)
          .get();

      final Map<String, double> teacherCourses = {};
      for (var doc in courseSnapshot.docs) {
        final data = doc.data();
        final priceValue = data['price'] ?? 0.0;
        final double coursePrice = double.tryParse(priceValue.toString()) ?? 0.0;
        teacherCourses[doc.id] = coursePrice;
      }

      if (teacherCourses.isEmpty) return {'enrollments': 0, 'revenue': 0.0, 'enrollmentPercentage': null, 'revenuePercentage': null};

      // Get users with enrollments
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      int todayEnrollments = 0;
      double todayRevenue = 0.0;
      int yesterdayEnrollments = 0;
      double yesterdayRevenue = 0.0;

      for (var userDoc in userSnapshot.docs) {
        final userData = userDoc.data();
        final enrolledCourses = userData['enrolledCourses'] as List<dynamic>? ?? [];

        for (var enrollment in enrolledCourses) {
          if (enrollment is Map<String, dynamic>) {
            final String? courseId = enrollment['courseId'];
            final Timestamp? enrollmentDate = enrollment['enrollmentDate'];

            if (courseId != null && teacherCourses.containsKey(courseId) && enrollmentDate != null) {
              if (enrollmentDate.compareTo(startTimestamp) >= 0) {
                // This is a today's enrollment
                todayEnrollments++;
                todayRevenue += teacherCourses[courseId] ?? 0.0;
              } else if (enrollmentDate.compareTo(yesterdayTimestamp) >= 0 &&
                  enrollmentDate.compareTo(startTimestamp) < 0) {
                // This is a yesterday's enrollment
                yesterdayEnrollments++;
                yesterdayRevenue += teacherCourses[courseId] ?? 0.0;
              }
            }
          }
        }
      }

      // Calculate percentage changes
      double? enrollmentPercentage;
      bool isEnrollmentUp = true;
      if (yesterdayEnrollments > 0) {
        enrollmentPercentage = ((todayEnrollments - yesterdayEnrollments) / yesterdayEnrollments) * 100;
        isEnrollmentUp = enrollmentPercentage >= 0;
        enrollmentPercentage = enrollmentPercentage.abs(); // Store absolute value for display
      }

      double? revenuePercentage;
      bool isRevenueUp = true;
      if (yesterdayRevenue > 0) {
        revenuePercentage = ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
        isRevenueUp = revenuePercentage >= 0;
        revenuePercentage = revenuePercentage.abs(); // Store absolute value for display
      }

      return {
        'enrollments': todayEnrollments,
        'revenue': todayRevenue,
        'enrollmentPercentage': enrollmentPercentage,
        'isEnrollmentUp': isEnrollmentUp,
        'revenuePercentage': revenuePercentage,
        'isRevenueUp': isRevenueUp,
      };
    } catch (e) {
      print('Error fetching today\'s metrics: $e');
      return {'enrollments': 0, 'revenue': 0.0, 'enrollmentPercentage': null, 'revenuePercentage': null};
    }
  }

  // Edit an existing course.
  void _editCourse(
      BuildContext context,
      Map course,
      CourseProvider courseProvider,
      ) {
    setState(() {
      _currentCourseId = course['id'];
      _titleController.text = course['courseTitle'] ?? '';
      _descriptionController.text = course['description'] ?? '';
      _priceController.text = course['price'] != null ? course['price'].toString() : '';
      _durationController.text = course['duration'] ?? '';
      _subjectController.text = course['subject'] ?? '';
      _instructorController.text = course['instructor'] ?? '';
      _currentImageUrl = course['imageUrl'];
      _courseImage = null;
      _selectedMedium = course['medium'];
    });

    // Navigate to create/edit tab
    _tabController.animateTo(2);
  }

  void _clearFormFields() {
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _durationController.clear();
    _subjectController.clear();
    _instructorController.clear();

    setState(() {
      _courseImage = null;
      _currentCourseId = null;
      _currentImageUrl = null;
      _selectedMedium = null;
    });
  }

  // Delete confirmation dialog
  Future<void> _showDeleteConfirmationDialog(
      BuildContext context,
      String courseId,
      CourseProvider courseProvider,
      ) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Course',
                style: AppTextStyles.subtitle1.copyWith(
                  color: AppColorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this course? All sections, resources, and student enrollments will be permanently removed. This action cannot be undone.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'CANCEL',
                style: AppTextStyles.button.copyWith(
                  color: AppColorScheme.primary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorScheme.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'DELETE',
                style: AppTextStyles.button,
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // Show loading overlay
      _showLoadingOverlay(context);

      try {
        await courseProvider.deleteCourse(courseId);

        // Dismiss loading overlay
        Navigator.pop(context);

        if (mounted) {
          _showMessage(context, 'Course deleted successfully!');
        }
      } catch (e) {
        // Dismiss loading overlay
        Navigator.pop(context);

        _showMessage(
          context,
          'Error deleting course: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  // Show notifications dialog
  void _showNotificationsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColorScheme.gray300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: AppTextStyles.subtitle1.copyWith(
                      color: AppColorScheme.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Mark all as read
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Mark All as Read',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: AppColorScheme.gray200),

            // Notifications list
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildNotificationItem(
                    title: 'New Enrollment',
                    message: 'A student has enrolled in your "Flutter Development" course',
                    time: '10 minutes ago',
                    isUnread: true,
                  ),
                  Divider(height: 1, indent: 68, color: AppColorScheme.gray200),
                  _buildNotificationItem(
                    title: 'Course Rating',
                    message: 'Your "Advanced React" course received a 5-star rating',
                    time: '2 hours ago',
                    isUnread: true,
                  ),
                  Divider(height: 1, indent: 68, color: AppColorScheme.gray200),
                  _buildNotificationItem(
                    title: 'Payment Received',
                    message: 'You received a payment of Rs. 2500 for course enrollments',
                    time: 'Yesterday',
                    isUnread: false,
                  ),
                  Divider(height: 1, indent: 68, color: AppColorScheme.gray200),
                  _buildNotificationItem(
                    title: 'Comment on Video',
                    message: 'A student commented on your "Introduction to Flutter" video',
                    time: '2 days ago',
                    isUnread: false,
                  ),
                  Divider(height: 1, indent: 68, color: AppColorScheme.gray200),
                  _buildNotificationItem(
                    title: 'Course Completion',
                    message: 'A student completed your "Web Development" course',
                    time: '3 days ago',
                    isUnread: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show profile menu
  void _showProfileMenu(BuildContext context, AuthService authService) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: FutureBuilder<String?>(
        future: authService.getCurrentUserEmail(),
    builder: (context, snapshot) {
    final email = snapshot.data ?? 'Teacher';
    final name = email.split('@').first.capitalize();

    return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    // Handle
    Container(
    margin: EdgeInsets.only(top: 12),
    width: 40,
    height: 5,
    decoration: BoxDecoration(
    color: AppColorScheme.gray300,
    borderRadius: BorderRadius.circular(10),
    ),
    ),
    SizedBox(height: 20),

    // Profile header
    CircleAvatar(
    backgroundColor: AppColorScheme.tertiary,
    radius: 40,
    child: Text(
    name[0].toUpperCase(),
    style: TextStyle(
    color: AppColorScheme.onTertiary,
    fontWeight: FontWeight.bold,
    fontSize: 32,
    ),
    ),
    ),
    SizedBox(height: 16),
    Text(
    name,
    style: AppTextStyles.subtitle1,
    ),
    Text(
    email,
    style: AppTextStyles.bodyMedium.copyWith(
    color: AppColorScheme.gray600,
    ),
    ),
    SizedBox(height: 20),

    Divider(height: 1, color: AppColorScheme.gray200),

    // Menu items
    _buildProfileMenuItem(
    icon: Icons.person_outline,
    title: 'View Profile',
    onTap: () {
    Navigator.pop(context);
    // Navigate to profile screen
    },
    ),
    _buildProfileMenuItem(
    icon: Icons.settings_outlined,
    title: 'Settings',
    onTap: () {
    Navigator.pop(context);
    // Navigate to settings screen
    },
    ),
    _buildProfileMenuItem(
    icon: Icons.help_outline,
    title: 'Help & Support',
    onTap: () {
    Navigator.pop(context);
    // Navigate to help screen
    },
    ),
    Divider(height: 1, color: AppColorScheme.gray200),
    _buildProfileMenuItem(
      // Continuing from previous code segment...
      icon: Icons.logout,
      title: 'Sign Out',
      isDestructive: true,
      onTap: () async {
        Navigator.pop(context);
        // Show confirmation
        bool? confirm = await _showSignOutConfirmationDialog(context);
        if (confirm == true) {
          await authService.signOut();
          // Navigate to login screen
        }
      },
    ),
      SizedBox(height: 20),
    ],
    );
    }
        ),
        ),
    );
  }

  Future<bool?> _showSignOutConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Sign Out',
          style: AppTextStyles.subtitle1.copyWith(
            color: AppColorScheme.primary,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCEL',
              style: AppTextStyles.button.copyWith(
                color: AppColorScheme.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primary,
              foregroundColor: AppColorScheme.onPrimary,
            ),
            child: Text(
              'SIGN OUT',
              style: AppTextStyles.button,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColorScheme.error : AppColorScheme.primary,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDestructive ? AppColorScheme.error : AppColorScheme.onBackground,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isUnread ? AppColorScheme.tertiaryContainer : AppColorScheme.gray100,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            _getNotificationIcon(title),
            size: 20,
            color: isUnread ? AppColorScheme.tertiary : AppColorScheme.gray600,
          ),
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColorScheme.gray700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            time,
            style: AppTextStyles.caption.copyWith(
              color: AppColorScheme.gray500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () {
        // Handle notification tap
      },
    );
  }

  IconData _getNotificationIcon(String title) {
    if (title.contains('Enrollment')) {
      return Icons.person_add_outlined;
    } else if (title.contains('Rating')) {
      return Icons.star_outline;
    } else if (title.contains('Payment')) {
      return Icons.payments_outlined;
    } else if (title.contains('Comment')) {
      return Icons.comment_outlined;
    } else if (title.contains('Completion')) {
      return Icons.check_circle_outline;
    } else {
      return Icons.notifications_outlined;
    }
  }

// Show snackbar message
  void _showMessage(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColorScheme.error : AppColorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

// Get month name from month number
  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }

// Get short month name from month number
  String _getShortMonthName(int month) {
    return _getMonthName(month).substring(0, 3);
  }
}

// Extension method to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}