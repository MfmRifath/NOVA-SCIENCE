import 'dart:async';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../Service/AuthService.dart';
import '../../Service/CourseProvider.dart';
import '../../Service/AdvertisementProvider.dart';

class AppColors {
  static const Color primary = Color(0xFF11261F);
  static const Color secondary = Color(0xFF123755);
  static const Color accent = Color(0xFF722626);
  static const Color bgLight = Color(0xFFF9FAFB);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const List<Color> primaryGradient = [
    Color(0xFF11261F),
    Color(0xFF1D3A2F),
  ];
  static const List<Color> secondaryGradient = [
    Color(0xFF123755),
    Color(0xFF1E4E7A),
  ];
  static const List<Color> accentGradient = [
    Color(0xFF722626),
    Color(0xFF8F3535),
  ];
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  // Dashboard metrics
  int _totalUsers = 0;
  int _coursesAvailable = 0;
  int _activeStudents = 0;
  double _totalRevenue = 0.0;
  double _appRevenue = 0.0;
  double _teacherRevenue = 0.0;
  double _averageRating = 0.0;
  int _totalEnrollments = 0;
  int _pendingApprovals = 0;
  int _activeAdvertisements = 0;

  // Monthly data
  List<double> _monthlyRegistrations = List.filled(12, 0);
  List<double> _monthlyRevenue = List.filled(12, 0);

  // Trend strings
  String registrationTrend = "0%";
  String revenueTrend = "0%";

  // Animation and page controllers
  late AnimationController _controller;
  late Animation<double> _animation;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Loading and error state
  bool _isLoading = true;
  String? _errorMessage;

  // Firestore subscriptions
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  StreamSubscription<QuerySnapshot>? _coursesSubscription;
  StreamSubscription<QuerySnapshot>? _advertisementsSubscription;

  // Helper to calculate percentage change
  String calculateTrend(double previous, double current) {
    if (previous == 0) return current > 0 ? "+100%" : "0%";
    double change = ((current - previous) / previous) * 100;
    return (change >= 0 ? "+" : "") + change.toStringAsFixed(1) + "%";
  }

  // Update trends based on current monthly data arrays
  void updateTrends() {
    int currentMonthIndex = DateTime.now().month - 1;
    if (currentMonthIndex > 0) {
      double previousRegs = _monthlyRegistrations[currentMonthIndex - 1];
      double currentRegs = _monthlyRegistrations[currentMonthIndex];
      registrationTrend = calculateTrend(previousRegs, currentRegs);

      double previousRevenue = _monthlyRevenue[currentMonthIndex - 1];
      double currentRevenue = _monthlyRevenue[currentMonthIndex];
      revenueTrend = calculateTrend(previousRevenue, currentRevenue);
    } else {
      registrationTrend = "0%";
      revenueTrend = "0%";
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      _subscribeToUsers();
      _subscribeToCourses();
      _subscribeToAdvertisements();
      await _calculateTeacherAndAppRevenue();
      await _calculateEnrollments();
      // Delay to allow animations and data stabilization
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _controller.forward();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load dashboard data. Please try again.";
        _isLoading = false;
      });
      print('Error loading dashboard: $e');
    }
  }

  void _subscribeToUsers() {
    _usersSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        int activeCount = 0;
        List<double> monthlyRegs = List.filled(12, 0);
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isLoggedin'] == true) activeCount++;
          if (data['registeredDate'] != null) {
            Timestamp ts = data['registeredDate'];
            DateTime regDate = ts.toDate();
            if (regDate.year == DateTime.now().year) {
              monthlyRegs[regDate.month - 1] += 1;
            }
          }
        }
        setState(() {
          _totalUsers = snapshot.size;
          _activeStudents = activeCount;
          _monthlyRegistrations = monthlyRegs;
        });
        updateTrends();
      }
    }, onError: (error) {
      setState(() {
        _errorMessage = "Error loading user data.";
      });
      print('Error in users subscription: $error');
    });
  }

  void _subscribeToCourses() {
    _coursesSubscription = FirebaseFirestore.instance
        .collection('courses')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        int pendingCount = 0;
        double totalRating = 0.0;
        int ratedCourses = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isApproved'] != true) pendingCount++;
          if (data['averageRating'] != null) {
            totalRating += (data['averageRating'] as num).toDouble();
            ratedCourses++;
          }
        }
        setState(() {
          _coursesAvailable = snapshot.size;
          _pendingApprovals = pendingCount;
          _averageRating = ratedCourses > 0 ? totalRating / ratedCourses : 0.0;
        });
      }
    }, onError: (error) {
      setState(() {
        _errorMessage = "Error loading course data.";
      });
      print('Error in courses subscription: $error');
    });
  }

  void _subscribeToAdvertisements() {
    _advertisementsSubscription = FirebaseFirestore.instance
        .collection('advertisements')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _activeAdvertisements = snapshot.size;
        });
      }
    }, onError: (error) {
      print('Error in advertisements subscription: $error');
    });
  }

  Future<void> _calculateTeacherAndAppRevenue() async {
    try {
      QuerySnapshot courseSnapshot =
      await FirebaseFirestore.instance.collection('courses').get();
      double totalTeacherRevenue = 0.0;
      Map<String, double> coursePrices = {};
      for (var doc in courseSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['price'] != null) {
          double price = (data['price'] is double)
              ? data['price']
              : (data['price'] as num).toDouble();
          coursePrices[doc.id] = price;
        }
      }
      QuerySnapshot userSnapshot =
      await FirebaseFirestore.instance.collection('users').get();
      for (var userDoc in userSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final enrolled = userData['enrolledCourses'] as List<dynamic>?;
        if (enrolled != null) {
          for (var item in enrolled) {
            String courseId;
            if (item is String) {
              courseId = item;
            } else if (item is Map<String, dynamic> && item['courseId'] != null) {
              courseId = item['courseId'] as String;
            } else continue;
            if (coursePrices.containsKey(courseId)) {
              totalTeacherRevenue += coursePrices[courseId]!;
              _totalEnrollments++;
              if (item is Map<String, dynamic> && item['enrollmentDate'] != null) {
                DateTime date = (item['enrollmentDate'] as Timestamp).toDate();
                if (date.year == DateTime.now().year) {
                  _monthlyRevenue[date.month - 1] += coursePrices[courseId]!;
                }
              }
            }
          }
        }
      }
      double appRevenue = totalTeacherRevenue * 0.2;
      setState(() {
        _teacherRevenue = totalTeacherRevenue;
        _appRevenue = appRevenue;
        _totalRevenue = totalTeacherRevenue + appRevenue;
      });
      updateTrends();
    } catch (e) {
      print('Error calculating revenue: $e');
      rethrow;
    }
  }

  Future<void> _calculateEnrollments() async {
    try {
      QuerySnapshot userSnapshot =
      await FirebaseFirestore.instance.collection('users').get();
      int total = 0;
      for (var doc in userSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final enrolled = data['enrolledCourses'] as List<dynamic>?;
        if (enrolled != null) total += enrolled.length;
      }
      setState(() {
        _totalEnrollments = total;
      });
    } catch (e) {
      print('Error calculating enrollments: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _coursesSubscription?.cancel();
    _advertisementsSubscription?.cancel();
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ----------------- UI Widgets -----------------

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool isPositive,
  }) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      color: isPositive ? AppColors.success : AppColors.error,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      height: 6,
      width: _currentPage == index ? 20 : 6,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppColors.primary
            : AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    double maxY = _monthlyRegistrations.reduce((a, b) => a > b ? a : b) + 5;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 12,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: color.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 180,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.primaryGradient,
                ),
              ),
            ),
          ),
          Positioned(
            right: -50,
            top: -20,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(125),
                  border: Border.all(color: Colors.white, width: 30),
                ),
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: -50,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(90),
                  border: Border.all(color: Colors.white, width: 25),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Dashboard',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Consumer<AuthService>(
                            builder: (context, authService, child) {
                              final String userName =
                                  authService.user?.name ?? 'Admin';
                              return Text(
                                'Welcome back, $userName',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/notifications');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                              if (_pendingApprovals > 0)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      '$_pendingApprovals',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/editProfile');
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Consumer<AuthService>(
                                builder: (context, authService, child) {
                                  String profileImageUrl = authService.user?.profileImageUrl ??
                                      "https://via.placeholder.com/150";
                                  return Hero(
                                    tag: 'profilePic',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        profileImageUrl,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 40,
                                            height: 40,
                                            color: AppColors.secondary,
                                            child: const Icon(Icons.person, color: Colors.white),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.white.withOpacity(0.8),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search users, courses...',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label,
      {bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textLight,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textLight,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon,
      {VoidCallback? onActionTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          if (onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionWidget({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            splashColor: color.withOpacity(0.1),
            highlightColor: color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _fetchDashboardData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDataWidget(String title, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary.withOpacity(0.5), size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPullToRefresh({required Widget child}) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: Colors.white,
      onRefresh: () async {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        await _fetchDashboardData();
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    int currentMonthIndex = DateTime.now().month - 1;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading dashboard...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: AppBar(
          title: Text(
            'Dashboard',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: _buildErrorWidget(_errorMessage!),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildPullToRefresh(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 10.0 : 20.0,
                          vertical: isSmallScreen ? 10.0 : 24.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Metrics Section
                            SizedBox(
                              height: isSmallScreen ? 300 : 145,
                              child: isSmallScreen
                                  ? SingleChildScrollView(
                                    child: Column(
                                                                    children: [
                                    // For small screens, display new registration metric
                                    _buildMetricCard(
                                      title: 'New Registrations',
                                      value: currentMonthIndex >= 0
                                          ? _monthlyRegistrations[currentMonthIndex].toStringAsFixed(0)
                                          : '0',
                                      icon: Icons.person_add,
                                      color: AppColors.primary,
                                      trend: registrationTrend,
                                      isPositive: registrationTrend.startsWith('+'),
                                    ),
                                    _buildMetricCard(
                                      title: 'Monthly Revenue',
                                      value: currentMonthIndex >= 0
                                          ? '₹${NumberFormat('#,##,###').format(_monthlyRevenue[currentMonthIndex].round())}'
                                          : '₹0',
                                      icon: Icons.attach_money,
                                      color: AppColors.primary,
                                      trend: revenueTrend,
                                      isPositive: revenueTrend.startsWith('+'),
                                    ),
                                    _buildMetricCard(
                                      title: 'Active Students',
                                      value: '$_activeStudents',
                                      icon: Icons.school,
                                      color: AppColors.secondary,
                                      trend: registrationTrend,
                                      isPositive: true,
                                    ),
                                    _buildMetricCard(
                                      title: 'Pending Approvals',
                                      value: '$_pendingApprovals',
                                      icon: Icons.hourglass_empty,
                                      color: AppColors.accent,
                                      trend: '-2.3%',
                                      isPositive: false,
                                    ),
                                                                    ],
                                                                  ),
                                  )
                                  : FadeInUp(
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 200),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 125,
                                      child: PageView(
                                        controller: _pageController,
                                        onPageChanged: (index) {
                                          setState(() {
                                            _currentPage = index;
                                          });
                                        },
                                        children: [
                                          // Page 1: User Metrics
                                          Padding(
                                            padding: const EdgeInsets.only(left: 20),
                                            child: Row(
                                              children: [
                                                _buildMetricCard(
                                                  title: 'Total Users',
                                                  value: '$_totalUsers',
                                                  icon: Icons.people,
                                                  color: AppColors.primary,
                                                  trend: '+0%', // No trend for cumulative
                                                  isPositive: true,
                                                ),
                                                _buildMetricCard(
                                                  title: 'Active Students',
                                                  value: '$_activeStudents',
                                                  icon: Icons.school,
                                                  color: AppColors.secondary,
                                                  trend: '+0%',
                                                  isPositive: true,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Page 2: Course Metrics
                                          Padding(
                                            padding: const EdgeInsets.only(left: 20),
                                            child: Row(
                                              children: [
                                                _buildMetricCard(
                                                  title: 'Total Courses',
                                                  value: '$_coursesAvailable',
                                                  icon: Icons.book,
                                                  color: AppColors.secondary,
                                                  trend: '+0%',
                                                  isPositive: true,
                                                ),
                                                _buildMetricCard(
                                                  title: 'Pending Approvals',
                                                  value: '$_pendingApprovals',
                                                  icon: Icons.hourglass_empty,
                                                  color: AppColors.accent,
                                                  trend: '-0%',
                                                  isPositive: false,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Page 3: Revenue Metrics (Cumulative)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 20),
                                            child: Row(
                                              children: [
                                                _buildMetricCard(
                                                  title: 'App Revenue',
                                                  value: '₹${_appRevenue.toStringAsFixed(0)}',
                                                  icon: Icons.attach_money,
                                                  color: AppColors.primary,
                                                  trend: '+0%',
                                                  isPositive: true,
                                                ),
                                                _buildMetricCard(
                                                  title: 'Teacher Revenue',
                                                  value: '₹${_teacherRevenue.toStringAsFixed(0)}',
                                                  icon: Icons.account_balance_wallet,
                                                  color: AppColors.accent,
                                                  trend: '+0%',
                                                  isPositive: true,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Page 4: Trends (New Registrations & Monthly Revenue)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 20),
                                            child: Row(
                                              children: [
                                                _buildMetricCard(
                                                  title: 'New Registrations',
                                                  value: currentMonthIndex >= 0
                                                      ? _monthlyRegistrations[currentMonthIndex].toStringAsFixed(0)
                                                      : '0',
                                                  icon: Icons.person_add,
                                                  color: AppColors.primary,
                                                  trend: registrationTrend,
                                                  isPositive: registrationTrend.startsWith('+'),
                                                ),
                                                _buildMetricCard(
                                                  title: 'Monthly Revenue',
                                                  value: currentMonthIndex >= 0
                                                      ? '₹${NumberFormat('#,##,###').format(_monthlyRevenue[currentMonthIndex].round())}'
                                                      : '₹0',
                                                  icon: Icons.attach_money,
                                                  color: AppColors.primary,
                                                  trend: revenueTrend,
                                                  isPositive: revenueTrend.startsWith('+'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(4, (index) => _buildDotIndicator(index)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Quick Actions
                            _buildSectionHeader('Quick Actions', Icons.bolt),
                            const SizedBox(height: 16),
                            FadeInUp(
                              duration: const Duration(milliseconds: 600),
                              delay: const Duration(milliseconds: 300),
                              child: isSmallScreen
                                  ? Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildQuickActionWidget(
                                    icon: Icons.book_outlined,
                                    label: 'Manage Courses',
                                    color: AppColors.primary,
                                    onTap: () => Navigator.pushNamed(context, '/courseManagement'),
                                  ),
                                  _buildQuickActionWidget(
                                    icon: Icons.people_outline,
                                    label: 'Manage Users',
                                    color: AppColors.secondary,
                                    onTap: () => Navigator.pushNamed(context, '/userManagement'),
                                  ),
                                  _buildQuickActionWidget(
                                    icon: Icons.campaign_outlined,
                                    label: 'Advertisements',
                                    color: AppColors.accent,
                                    onTap: () => Navigator.pushNamed(context, '/manageAdvertisements'),
                                  ),
                                  _buildQuickActionWidget(
                                    icon: Icons.analytics_outlined,
                                    label: 'Reports',
                                    color: Colors.grey.shade700,
                                    onTap: () => Navigator.pushNamed(context, '/reports'),
                                  ),
                                ],
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildQuickActionWidget(
                                    icon: Icons.book_outlined,
                                    label: 'Manage Courses',
                                    color: AppColors.primary,
                                    onTap: () => Navigator.pushNamed(context, '/courseManagement'),
                                  ),
                                  _buildQuickActionWidget(
                                    icon: Icons.people_outline,
                                    label: 'Manage Users',
                                    color: AppColors.secondary,
                                    onTap: () => Navigator.pushNamed(context, '/userManagement'),
                                  ),
                                  _buildQuickActionWidget(
                                    icon: Icons.campaign_outlined,
                                    label: 'Advertisements',
                                    color: AppColors.accent,
                                    onTap: () => Navigator.pushNamed(context, '/manageAdvertisements'),
                                  ),
                                  _buildQuickActionWidget(
                                    icon: Icons.analytics_outlined,
                                    label: 'Reports',
                                    color: Colors.grey.shade700,
                                    onTap: () => Navigator.pushNamed(context, '/reports'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Revenue Overview Section
                            _buildSectionHeader('Revenue Overview', Icons.payments_outlined),
                            const SizedBox(height: 16),
                            FadeInUp(
                              duration: const Duration(milliseconds: 600),
                              delay: const Duration(milliseconds: 400),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: isSmallScreen
                                    ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Revenue',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '₹${NumberFormat('#,##,###').format(_totalRevenue.round())}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildRevenueItem(
                                          title: 'App Revenue',
                                          value: '₹${NumberFormat('#,##,###').format(_appRevenue.round())}',
                                          color: AppColors.primary,
                                        ),
                                        _buildRevenueItem(
                                          title: 'Teacher Revenue',
                                          value: '₹${NumberFormat('#,##,###').format(_teacherRevenue.round())}',
                                          color: AppColors.accent,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(context, '/reports');
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'View Detailed Report',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                    : Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Revenue',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            '₹${NumberFormat('#,##,###').format(_totalRevenue.round())}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const Spacer(),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.trending_up, color: Colors.green, size: 14),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '+12.5%',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'vs. last month',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: AppColors.textLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildRevenueItem(
                                                title: 'App Revenue',
                                                value: '₹${NumberFormat('#,##,###').format(_appRevenue.round())}',
                                                color: AppColors.primary,
                                              ),
                                              _buildRevenueItem(
                                                title: 'Teacher Revenue',
                                                value: '₹${NumberFormat('#,##,###').format(_teacherRevenue.round())}',
                                                color: AppColors.accent,
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.pushNamed(context, '/reports');
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                'View Detailed Report',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 32 : 24),
                            // Course Management Section
                            _buildSectionHeader('Course Management', Icons.class_outlined),
                            const SizedBox(height: 16),
                            FadeInUp(
                              duration: const Duration(milliseconds: 600),
                              delay: const Duration(milliseconds: 600),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    if (_pendingApprovals > 0)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.warning.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.warning.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.assignment_late,
                                                color: AppColors.warning,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '$_pendingApprovals Course${_pendingApprovals > 1 ? 's' : ''} Pending Approval',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textDark,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Review and approve pending courses',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      color: AppColors.textLight,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pushNamed(context, '/courseManagement');
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.warning,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text(
                                                'Review',
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildSummaryCard(
                                            title: 'Total Courses',
                                            value: '$_coursesAvailable',
                                            icon: Icons.book,
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildSummaryCard(
                                            title: 'Enrollments',
                                            value: '$_totalEnrollments',
                                            icon: Icons.how_to_reg,
                                            color: AppColors.success,
                                          ),
                                        ),
                                        if (!isSmallScreen) ...[
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildSummaryCard(
                                              title: 'Avg Rating',
                                              value: _averageRating.toStringAsFixed(1),
                                              icon: Icons.star,
                                              color: AppColors.warning,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (isSmallScreen) ...[
                                      const SizedBox(height: 16),
                                      _buildSummaryCard(
                                        title: 'Average Rating',
                                        value: _averageRating.toStringAsFixed(1),
                                        icon: Icons.star,
                                        color: AppColors.warning,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.pushNamed(context, '/courseManagement');
                                            },
                                            icon: Icon(Icons.add_circle_outline),
                                            label: Text('Add Course'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.primary,
                                              side: BorderSide(color: AppColors.primary),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.pushNamed(context, '/enrollUsers');
                                            },
                                            icon: Icon(Icons.school_outlined),
                                            label: Text('Enroll Students'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 32 : 24),
                            // Teacher Payments Section
                            _buildSectionHeader('Teacher Payments', Icons.payments_outlined),
                            const SizedBox(height: 16),
                            FadeInUp(
                              duration: const Duration(milliseconds: 600),
                              delay: const Duration(milliseconds: 700),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/teachersPayment');
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.account_balance,
                                          color: AppColors.secondary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Manage Teacher Payments',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Process payments and view payment history',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, color: AppColors.textLight),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 32 : 24),
                            // Advertisement Section
                            _buildSectionHeader('Advertisements', Icons.campaign_outlined),
                            const SizedBox(height: 16),
                            FadeInUp(
                              duration: const Duration(milliseconds: 600),
                              delay: const Duration(milliseconds: 800),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/manageAdvertisements');
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.ad_units,
                                          color: AppColors.accent,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Active Advertisements',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$_activeAdvertisements active advertisements',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, color: AppColors.textLight),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              Icons.dashboard,
              'Dashboard',
              isSelected: true,
              onTap: () {
                // Already on dashboard
              },
            ),
            _buildNavItem(
              Icons.book,
              'Courses',
              onTap: () => Navigator.pushNamed(context, '/courseManagement'),
            ),
            _buildNavItem(
              Icons.people,
              'Users',
              onTap: () => Navigator.pushNamed(context, '/userManagement'),
            ),
            _buildNavItem(
              Icons.settings,
              'Settings',
              onTap: () => Navigator.pushNamed(context, '/systemSettings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}