import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Added for better charts
import 'dart:math' as math;

import '../../Modals/User.dart';
import '../../Service/AuthService.dart';

// Enhanced color scheme with more professional palette
class AppColors {
  static const Color primary = Color(0xFF1E3A8A);      // Deep blue
  static const Color secondary = Color(0xFF0284C7);    // Bright blue
  static const Color accent = Color(0xFFEF4444);       // Red
  static const Color success = Color(0xFF10B981);      // Green
  static const Color warning = Color(0xFFF59E0B);      // Amber
  static const Color background = Color(0xFFF8FAFC);   // Light gray
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);  // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color border = Color(0xFFE2E8F0);       // Slate 200
}

class TeacherPaymentsScreen extends StatefulWidget {
  const TeacherPaymentsScreen({Key? key}) : super(key: key);

  @override
  _TeacherPaymentsScreenState createState() => _TeacherPaymentsScreenState();
}

class _TeacherPaymentsScreenState extends State<TeacherPaymentsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedTimeRange = 'Last 12 Months';
  String _sortBy = 'Earnings (High to Low)';
  bool _showFloatingStats = false;
  double _totalRevenue = 0.0;
  int _totalTeachers = 0;
  int _totalCourses = 0;
  int _totalStudents = 0;
  ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  Map<String, double> _monthlyRevenueData = {};

  // Added for better analytics
  double _averageCoursePrice = 0.0;
  double _prevMonthRevenue = 0.0;
  double _currentMonthRevenue = 0.0;
  double _growthRate = 0.0;
  Map<String, double> _categoryRevenue = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Added Analytics tab
    _scrollController.addListener(_onScroll);
    _fetchInitialData();
  }

  void _onScroll() {
    setState(() {
      _showFloatingStats = _scrollController.offset > 180;
    });
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch revenue data
      final revenueData = await _fetchAppWideMonthlyRevenue();
      final totalRevenue = revenueData.values.fold(0.0, (sum, value) => sum + value);

      // Calculate growth rate
      if (revenueData.length >= 2) {
        final sortedMonths = revenueData.keys.toList()..sort();
        if (sortedMonths.length >= 2) {
          _currentMonthRevenue = revenueData[sortedMonths.last] ?? 0;
          _prevMonthRevenue = revenueData[sortedMonths[sortedMonths.length - 2]] ?? 0;
          if (_prevMonthRevenue > 0) {
            _growthRate = ((_currentMonthRevenue - _prevMonthRevenue) / _prevMonthRevenue) * 100;
          }
        }
      }

      // Fetch other stats
      final authService = Provider.of<AuthService>(context, listen: false);
      final teachers = await _fetchAllTeachers(authService);
      final totalCourses = await _fetchTotalCourses();
      final totalStudents = await _fetchTotalStudents();
      final averageCoursePrice = await _fetchAverageCoursePrice();

      // Category breakdown (simulated data for now)
      _categoryRevenue = {
        'Technology': totalRevenue * 0.45,
        'Business': totalRevenue * 0.25,
        'Arts': totalRevenue * 0.15,
        'Science': totalRevenue * 0.10,
        'Other': totalRevenue * 0.05,
      };

      setState(() {
        _totalRevenue = totalRevenue;
        _totalTeachers = teachers.length;
        _totalCourses = totalCourses;
        _totalStudents = totalStudents;
        _monthlyRevenueData = revenueData;
        _averageCoursePrice = averageCoursePrice;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      // Error handling with more user-friendly message
      _showErrorSnackbar("Couldn't load payment data. Please try again later.");
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _fetchInitialData(),
        ),
      ),
    );
  }

  Future<int> _fetchTotalCourses() async {
    final snapshot = await FirebaseFirestore.instance.collection('courses').get();
    return snapshot.docs.length;
  }

  Future<int> _fetchTotalStudents() async {
    // Count unique students (users who have enrolled in at least one course)
    final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
    int studentCount = 0;

    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data();
      final enrolledCourses = userData['enrolledCourses'] as List<dynamic>?;

      if (enrolledCourses != null && enrolledCourses.isNotEmpty) {
        studentCount++;
      }
    }

    return studentCount;
  }

  Future<double> _fetchAverageCoursePrice() async {
    final courseSnapshot = await FirebaseFirestore.instance.collection('courses').get();
    double totalPrice = 0;
    int courseCount = courseSnapshot.docs.length;

    if (courseCount == 0) return 0;

    for (var courseDoc in courseSnapshot.docs) {
      final docData = courseDoc.data();
      final coursePrice = double.tryParse(docData['price'].toString()) ?? 0.0;
      totalPrice += coursePrice;
    }

    return totalPrice / courseCount;
  }

  // Format month key (YYYY-MM) to more readable format (Month YYYY)
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

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Teacher Payments',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Open drawer or navigation menu
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filter options',
            onPressed: () => _showFilterOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export data',
            onPressed: () => _showExportOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      floatingActionButton: _showFloatingStats
          ? FloatingActionButton.extended(
        onPressed: () {
          _scrollController.animateTo(0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.arrow_upward),
        label: Text('\$${NumberFormat('#,###').format(_totalRevenue)}'),
      )
          : null,
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.secondary),
            SizedBox(height: 16),
            Text('Loading payment data...'),
          ],
        ),
      )
          : SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Top gradient header with stats cards
            SliverToBoxAdapter(
              child: _buildHeaderSection(),
            ),

            // Tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                      text: 'Overview',
                      icon: Icon(Icons.dashboard),
                    ),
                    Tab(
                      text: 'Teachers',
                      icon: Icon(Icons.people),
                    ),
                    Tab(
                      text: 'Analytics',
                      icon: Icon(Icons.insights),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              // Overview Tab
              _buildOverviewTab(context),

              // Teachers Tab
              _buildTeachersTab(context, authService),

              // Analytics Tab
              _buildAnalyticsTab(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
            AppColors.background,
          ],
        ),
      ),
      child: Column(
        children: [
          // Title with subtitle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Financial Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _growthRate >= 0 ? Icons.trending_up : Icons.trending_down,
                            color: _growthRate >= 0 ? AppColors.success : AppColors.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_growthRate.abs().toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Monitor revenue and teacher payouts',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Key metrics cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildKeyMetricCard(
                    title: 'Revenue',
                    value: '\$${NumberFormat('#,###').format(_totalRevenue)}',
                    icon: Icons.attach_money,
                    color: AppColors.success,
                    subtitle: 'Total earnings',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKeyMetricCard(
                    title: 'Teachers',
                    value: _totalTeachers.toString(),
                    icon: Icons.person,
                    color: AppColors.secondary,
                    subtitle: '${(_totalTeachers > 0 ? _totalRevenue / _totalTeachers : 0).toStringAsFixed(0)}/teacher',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKeyMetricCard(
                    title: 'Students',
                    value: _totalStudents.toString(),
                    icon: Icons.school,
                    color: AppColors.warning,
                    subtitle: '$_totalCourses courses',
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search teachers, courses...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.secondary, width: 1),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.2);
  }

  // OVERVIEW TAB
  Widget _buildOverviewTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue trend card
          _buildRevenueTrendCard(),

          const SizedBox(height: 24),

          // Top earning teachers
          const Text(
            'Top Earning Teachers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchTopEarningTeachers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              } else {
                final teachers = snapshot.data ?? [];
                if (teachers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No teacher data available'),
                    ),
                  );
                }

                return Column(
                  children: teachers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final teacher = entry.value;
                    return _buildTopTeacherCard(teacher, index);
                  }).toList(),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // Best Selling Courses
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Best Selling Courses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to detailed courses page
                },
                child: const Row(
                  children: [
                    Text('View All'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchBestSellingCourses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              } else {
                final courses = snapshot.data ?? [];
                if (courses.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No course data available'),
                    ),
                  );
                }

                return Column(
                  children: courses.map((course) => _buildCourseCard(course)).toList(),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // Recent Transactions
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          _buildRecentTransactionsCard(),
        ],
      ),
    );
  }

  Widget _buildRevenueTrendCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenue Trend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_selectedTimeRange',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                _buildTimeRangeDropdown(),
              ],
            ),
            const SizedBox(height: 24),

            // Revenue overview stats
            Row(
              children: [
                Expanded(
                  child: _buildRevenueStat(
                    title: 'Total Revenue',
                    value: '\$${NumberFormat('#,###').format(_totalRevenue)}',
                    icon: Icons.payments_outlined,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildRevenueStat(
                    title: 'Average Price',
                    value: '\$${_averageCoursePrice.toStringAsFixed(2)}',
                    icon: Icons.shopping_basket_outlined,
                    color: AppColors.secondary,
                  ),
                ),
                Expanded(
                  child: _buildRevenueStat(
                    title: 'Growth',
                    value: '${_growthRate.toStringAsFixed(1)}%',
                    icon: _growthRate >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: _growthRate >= 0 ? AppColors.success : AppColors.accent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Revenue chart
            SizedBox(
              height: 220,
              child: FutureBuilder<Map<String, double>>(
                future: _fetchAppWideMonthlyRevenue(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    final monthlyData = snapshot.data ?? {};
                    if (monthlyData.isEmpty) {
                      return const Center(
                        child: Text('No revenue data available'),
                      );
                    }

                    return _buildBarChart(monthlyData);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueStat({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBarChart(Map<String, double> monthlyData) {
    // Sort months chronologically
    final sortedKeys = monthlyData.keys.toList()..sort();

    // Only show last 6 months if we have more data
    final displayKeys = sortedKeys.length > 6
        ? sortedKeys.sublist(sortedKeys.length - 6)
        : sortedKeys;

    final displayData = Map.fromEntries(
        displayKeys.map((k) => MapEntry(k, monthlyData[k]!))
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: displayData.values.fold(0, (max, value) => math.max(max , value.toInt())) * 1.2,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return const Text('');
                  }
                  // Format as 1K, 2K, etc.
                  final formattedValue = value >= 1000
                      ? '${(value / 1000).toStringAsFixed(1)}K'
                      : value.toInt().toString();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      formattedValue,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= displayKeys.length) {
                    return const Text('');
                  }
                  final month = displayKeys[index].split('-')[1];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      month,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            horizontalInterval: 1000,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          barGroups: displayData.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final monthData = entry.value;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: monthData.value,
                  width: 20,
                  color: displayKeys[index] == sortedKeys.last
                      ? AppColors.primary
                      : AppColors.secondary.withOpacity(0.7),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: displayData.values.fold(0, (max, value) => math.max(max , value.toInt())) * 1.2,
                    color: AppColors.border.withOpacity(0.2),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimeRangeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<String>(
        value: _selectedTimeRange,
        icon: const Icon(Icons.keyboard_arrow_down, size: 16),
        underline: const SizedBox.shrink(),
        isDense: true,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        items: ['Last 30 Days', 'Last 90 Days', 'Last 12 Months', 'All Time']
            .map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            setState(() {
              _selectedTimeRange = newValue;
              // Here you would typically refresh the data based on the new time range
            });
          }
        },
      ),
    );
  }

  Widget _buildTopTeacherCard(Map<String, dynamic> teacher, int index) {
    final teacherName = teacher['name'] ?? 'Unknown';
    final earnings = teacher['earnings'] ?? 0.0;
    final courses = teacher['courses'] ?? 0;
    final teacherInitial = teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: [
                AppColors.primary,
                AppColors.secondary,
                AppColors.accent,
              ][index % 3],
              child: Text(
                teacherInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    color: [
                      AppColors.primary,
                      AppColors.secondary,
                      AppColors.accent,
                    ][index % 3],
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          teacherName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              teacher['email'] ?? '',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMetricChip(
                  label: 'Courses',
                  value: courses.toString(),
                  icon: Icons.book,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                _buildMetricChip(
                  label: 'Students',
                  value: teacher['students']?.toString() ?? '0',
                  icon: Icons.people,
                  color: AppColors.warning,
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${NumberFormat('#,###').format(earnings)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 12,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${(10 + index * 3).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate to teacher details
        },
      ),
    ).animate().fade(duration: 400.ms).slideX(begin: 0.05, delay: Duration(milliseconds: index * 100));
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final courseTitle = course['title'] ?? 'Untitled Course';
    final enrollments = course['enrollments'] ?? 0;
    final revenue = course['revenue'] ?? 0.0;
    final teacherName = course['teacher'] ?? 'Unknown';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.book,
                  color: AppColors.accent,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    courseTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'By $teacherName',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildMetricChip(
                        label: 'Enrollments',
                        value: enrollments.toString(),
                        icon: Icons.people,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricChip(
                        label: 'Revenue',
                        value: '\$${NumberFormat('#,###').format(revenue)}',
                        icon: Icons.attach_money,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                // Navigate to course details
              },
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildRecentTransactionsCard() {
    final transactions = [
      {
        'id': 'TX-12345',
        'date': DateTime.now().subtract(Duration(hours: 2)),
        'student': 'John Smith',
        'course': 'Advanced Flutter Development',
        'amount': 49.99,
        'teacher': 'Sarah Johnson',
        'status': 'completed',
      },
      {
        'id': 'TX-12344',
        'date': DateTime.now().subtract(Duration(hours: 5)),
        'student': 'Emma Davis',
        'course': 'UI/UX Design Masterclass',
        'amount': 59.99,
        'teacher': 'Michael Brown',
        'status': 'completed',
      },
      {
        'id': 'TX-12343',
        'date': DateTime.now().subtract(Duration(hours: 12)),
        'student': 'Robert Wilson',
        'course': 'iOS App Development',
        'amount': 79.99,
        'teacher': 'Jennifer Lee',
        'status': 'pending',
      },
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Transactions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full transaction history
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...transactions.map((tx) => _buildTransactionItem(tx)).toList(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                // View transaction history
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('View All Transactions'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final formatter = DateFormat('MMM d, h:mm a');
    final formattedDate = formatter.format(transaction['date'] as DateTime);

    Color statusColor;
    IconData statusIcon;

    switch (transaction['status']) {
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.access_time;
        break;
      case 'failed':
        statusColor = AppColors.accent;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.help;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.receipt_long,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          transaction['course'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '\$${transaction['amount'].toString()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${transaction['student']} • $formattedDate',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              statusIcon,
                              size: 12,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              transaction['status'].toString().capitalize(),
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // TEACHERS TAB
  Widget _buildTeachersTab(BuildContext context, AuthService authService) {
    return FutureBuilder<List<CustomUser>>(
      future: _fetchAllTeachers(authService),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.accent),
                const SizedBox(height: 16),
                Text(
                  'Error loading teachers: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Refresh
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_outlined, size: 64, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text(
                  'No teachers found in the system',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Add teachers to start tracking payments',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        } else {
          final allTeachers = snapshot.data!;

          // Filter teachers based on search query
          final filteredTeachers = _searchQuery.isEmpty
              ? allTeachers
              : allTeachers.where((teacher) {
            final name = teacher.name?.toLowerCase() ?? '';
            final email = teacher.email?.toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || email.contains(query);
          }).toList();

          // Sort teachers based on selected sort option
          if (_sortBy == 'Name (A-Z)') {
            filteredTeachers.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
          } else if (_sortBy == 'Name (Z-A)') {
            filteredTeachers.sort((a, b) => (b.name ?? '').compareTo(a.name ?? ''));
          }
          // More sorting options would be implemented here

          return filteredTeachers.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'No teachers match "${_searchQuery}"',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Text('Clear Search'),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTeachers.length,
            itemBuilder: (context, index) {
              final teacher = filteredTeachers[index];
              return _buildTeacherExpandableCard(teacher, index);
            },
          );
        }
      },
    );
  }

  Widget _buildTeacherExpandableCard(CustomUser teacher, int index) {
    final teacherName = teacher.name ?? teacher.email ?? 'Unknown';
    final teacherEmail = teacher.email ?? 'No Email';
    final teacherInitial = teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.secondary,
          child: Text(
            teacherInitial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          teacherName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              teacherEmail,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<Map<String, double>>(
              future: _fetchMonthlyEarningsAllCourses(teacherEmail),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    'Calculating earnings...',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  );
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return const Text(
                    'Unable to load earnings data',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  );
                } else {
                  final totalEarnings = snapshot.data!.values.fold(0.0, (sum, value) => sum + value);
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.paid,
                              color: AppColors.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '\$${NumberFormat('#,###.##').format(totalEarnings)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'export') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting data...')),
              );
            } else if (value == 'details') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Viewing detailed report...')),
              );
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 18),
                  SizedBox(width: 8),
                  Text('Export Data'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.analytics, size: 18),
                  SizedBox(width: 8),
                  Text('View Detailed Report'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'message',
              child: Row(
                children: [
                  Icon(Icons.message, size: 18),
                  SizedBox(width: 8),
                  Text('Send Message'),
                ],
              ),
            ),
          ],
        ),
        children: [
          // Monthly earnings section
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Monthly Earnings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, double>>(
            future: _fetchMonthlyEarningsAllCourses(teacherEmail),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.accent),
                    ),
                  ),
                );
              } else {
                final monthlyTotals = snapshot.data ?? {};
                if (monthlyTotals.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.money_off, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No earnings data available',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _buildEnhancedMonthlyEarningsChart(monthlyTotals);
              }
            },
          ),

          // Courses section
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Courses',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchTeacherCourses(teacherEmail),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.accent),
                    ),
                  ),
                );
              } else {
                final courses = snapshot.data ?? [];
                if (courses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.book_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'No courses found for this teacher',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: courses.map((course) => _buildEnhancedCourseTile(course)).toList(),
                );
              }
            },
          ),

          // Action buttons
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // View full profile
                },
                icon: const Icon(Icons.account_circle),
                label: const Text('Full Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // Export data
                },
                icon: const Icon(Icons.download),
                label: const Text('Export Data'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildEnhancedMonthlyEarningsChart(Map<String, double> monthlyData) {
    // Sort months chronologically
    final sortedKeys = monthlyData.keys.toList()..sort();
    final values = sortedKeys.map((m) => monthlyData[m]!).toList();
    final maxValue = values.isNotEmpty ? values.reduce(math.max) : 0;

    // Calculate growth percentage
    double growthPercentage = 0;
    if (values.length >= 2) {
      final lastMonth = values.last;
      final previousMonth = values[values.length - 2];
      if (previousMonth > 0) {
        growthPercentage = ((lastMonth - previousMonth) / previousMonth) * 100;
      }
    }

    // Calculate total earnings
    final totalEarnings = values.fold(0.0, (sum, value) => sum + value);

    return Column(
      children: [
        // Key stats row
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Total Earnings',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${NumberFormat('#,###').format(totalEarnings)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 40, width: 1, color: AppColors.border),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Last Month',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${NumberFormat('#,###').format(values.isNotEmpty ? values.last : 0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 40, width: 1, color: AppColors.border),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Growth',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          growthPercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: growthPercentage >= 0 ? AppColors.success : AppColors.accent,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${growthPercentage.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: growthPercentage >= 0 ? AppColors.success : AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Line chart
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxValue / 5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.border,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= sortedKeys.length) {
                        return const Text('');
                      }
                      final monthName = formatMonthKey(sortedKeys[index]);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          monthName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: sortedKeys.length - 1.0,
              minY: 0,
              maxY: maxValue * 1.2,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(sortedKeys.length, (i) => FlSpot(i.toDouble(), values[i])),
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [AppColors.secondary.withOpacity(0.8), AppColors.secondary],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.secondary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.3),
                        AppColors.secondary.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Monthly breakdown table
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Month',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Text(
                      'Earnings',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: AppColors.border),
              for (int i = sortedKeys.length - 1; i >= 0; i--)
                _buildMonthlyEarningRow(
                  month: formatMonthKey(sortedKeys[i]),
                  earnings: values[i],
                  isLast: i == 0,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyEarningRow({
    required String month,
    required double earnings,
    required bool isLast,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month,
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                '\$${NumberFormat('#,##0.00').format(earnings)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: AppColors.border.withOpacity(0.5)),
      ],
    );
  }

  Widget _buildEnhancedCourseTile(Map<String, dynamic> course) {
    final courseTitle = course['courseTitle'] ?? 'Untitled Course';
    final coursePrice = course['price']?.toDouble() ?? 0.0;
    final courseId = course['id'];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.all(16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.book,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          title: Text(
            courseTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price: \$${coursePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<Map<String, double>>(
                  future: _fetchMonthlyEarningsForCourse(courseId, coursePrice),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text(
                        'Loading...',
                        style: TextStyle(fontSize: 12),
                      );
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      return const Text(
                        'Error',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      );
                    } else {
                      final totalStudents = snapshot.data!.values
                          .fold(0.0, (sum, value) => sum + (value / coursePrice))
                          .round();
                      final totalEarnings = snapshot.data!.values
                          .fold(0.0, (sum, value) => sum + value);

                      return Wrap(
                        spacing: 8,
                        children: [
                          _buildMetricChip(
                            label: 'Students',
                            value: totalStudents.toString(),
                            icon: Icons.people,
                            color: AppColors.secondary,
                          ),
                          _buildMetricChip(
                            label: 'Earnings',
                            value: '\$${NumberFormat('#,###').format(totalEarnings)}',
                            icon: Icons.paid,
                            color: AppColors.primary,
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          children: [
            FutureBuilder<Map<String, double>>(
              future: _fetchMonthlyEarningsForCourse(courseId, coursePrice),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  );
                } else {
                  final monthlyData = snapshot.data ?? {};
                  if (monthlyData.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No enrollments for this course',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  // Sort months
                  final sortedKeys = monthlyData.keys.toList()..sort();
                  final values = sortedKeys.map((k) => monthlyData[k]!).toList();

                  return Column(
                    children: [
                      // Mini chart for course
                      Container(
                        height: 120,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 18,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= sortedKeys.length) {
                                      return const Text('');
                                    }
                                    return Text(
                                      sortedKeys[index].split('-')[1],
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 9,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: sortedKeys.length - 1.0,
                            minY: 0,
                            maxY: values.isNotEmpty ? values.reduce(math.max) * 1.2 : 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                    sortedKeys.length,
                                        (i) => FlSpot(i.toDouble(), values[i])
                                ),
                                isCurved: true,
                                color: AppColors.accent,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) =>
                                      FlDotCirclePainter(
                                        radius: 3,
                                        color: AppColors.accent,
                                        strokeWidth: 1,
                                        strokeColor: Colors.white,
                                      ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.accent.withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Monthly earnings table for this course
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Month',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const Text(
                                    'Earnings',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: AppColors.border),
                            for (int i = sortedKeys.length - 1; i >= math.max(0, sortedKeys.length - 6); i--)
                              _buildEarningTableRow(
                                formatMonthKey(sortedKeys[i]),
                                monthlyData[sortedKeys[i]] ?? 0,
                                i == math.max(0, sortedKeys.length - 6),
                              ),
                            if (sortedKeys.length > 6)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: TextButton(
                                  onPressed: () {
                                    // Show all months
                                  },
                                  child: const Text('View All Months'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningTableRow(String month, double earnings, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month,
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '\$${earnings.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: AppColors.border.withOpacity(0.5)),
      ],
    );
  }

  // ANALYTICS TAB
  Widget _buildAnalyticsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue over time
          _buildAdvancedRevenueCard(),

          const SizedBox(height: 24),

          // Revenue breakdown
          _buildRevenueBreakdownCard(),

          const SizedBox(height: 24),

          // Teacher performance
          _buildTeacherPerformanceCard(),

          const SizedBox(height: 24),

          // Course performance
          _buildCoursePerformanceCard(),

          const SizedBox(height: 24),

          // Student engagement
          _buildStudentEngagementCard(),
        ],
      ),
    );
  }

  Widget _buildAdvancedRevenueCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenue Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedTimeRange,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                _buildTimeRangeDropdown(),
              ],
            ),

            const SizedBox(height: 24),

            // KPI Row
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsStat(
                    label: 'Total Revenue',
                    value: '\$${NumberFormat('#,###').format(_totalRevenue)}',
                    trend: '+12.5%',
                    isPositive: true,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsStat(
                    label: 'Avg. per Student',
                    value: '\$${(_totalStudents > 0 ? _totalRevenue / _totalStudents : 0).toStringAsFixed(2)}',
                    trend: '+8.3%',
                    isPositive: true,
                  ),
                ),
                Expanded(
                  child: _buildAnalyticsStat(
                    label: 'Conversion Rate',
                    value: '64.2%',
                    trend: '-2.1%',
                    isPositive: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Main chart
            SizedBox(
              height: 240,
              child: FutureBuilder<Map<String, double>>(
                future: _fetchAppWideMonthlyRevenue(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    final monthlyData = snapshot.data ?? {};
                    if (monthlyData.isEmpty) {
                      return const Center(
                        child: Text('No revenue data available'),
                      );
                    }

                    return _buildRevenueLineChart(monthlyData);
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // Current period highlight
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Period Highlights',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildHighlightItem(
                        icon: Icons.trending_up,
                        label: 'Highest Growth',
                        value: 'Business & Finance',
                        color: AppColors.success,
                      ),
                      _buildHighlightItem(
                        icon: Icons.person_add,
                        label: 'New Enrollments',
                        value: '${((_totalStudents * 0.23).round())}',
                        color: AppColors.secondary,
                      ),
                      _buildHighlightItem(
                        icon: Icons.star,
                        label: 'Top Teacher',
                        value: 'Sarah Johnson',
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsStat({
    required String label,
    required String value,
    required String trend,
    required bool isPositive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              size: 10,
              color: isPositive ? AppColors.success : AppColors.accent,
            ),
            const SizedBox(width: 2),
            Text(
              trend,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: isPositive ? AppColors.success : AppColors.accent,
              ),
            ),
            Text(
              ' vs. prev period',
              style: TextStyle(
                fontSize: 5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueLineChart(Map<String, double> monthlyData) {
    // Sort months
    final sortedKeys = monthlyData.keys.toList()..sort();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
        leftTitles: AxisTitles(
        sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
        getTitlesWidget: (value, meta) {
          if (value == 0) {
            return const Text('');
          }
          // Format as 1K, 2K, etc.
          String formattedValue;
          if (value >= 1000) {
            formattedValue = '${(value / 1000).toStringAsFixed(1)}K';
          } else {
            formattedValue = value.toInt().toString();
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              formattedValue,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          );
        },
      ),
    ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedKeys.length) {
                  return const Text('');
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    formatMonthKey(sortedKeys[index]),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: sortedKeys.length - 1.0,
        minY: 0,
        maxY: monthlyData.values.fold(0.0, (max, value) => math.max(max, value)) * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
                sortedKeys.length,
                    (i) => FlSpot(i.toDouble(), monthlyData[sortedKeys[i]] ?? 0)
            ),
            isCurved: true,
            gradient: const LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.secondary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.4),
                  AppColors.secondary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipBorder: BorderSide(color: AppColors.border),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final monthIndex = spot.x.toInt();
                if (monthIndex < 0 || monthIndex >= sortedKeys.length) {
                  return null;
                }

                final month = formatMonthKey(sortedKeys[monthIndex]);
                final value = spot.y;

                return LineTooltipItem(
                  '$month\n',
                  const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: '\$${NumberFormat('#,##0.00').format(value)}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdownCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Revenue by category',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 220,
              child: Row(
                children: [
                  // Pie chart
                  Expanded(
                    flex: 5,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _getCategoryPieSections(),
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // Handle touch events for interactivity
                          },
                        ),
                      ),
                    ),
                  ),

                  // Legend
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRevenueCategoryItem(
                            'Technology',
                            _categoryRevenue['Technology'] ?? 0,
                            Colors.blue,
                          ),
                          _buildRevenueCategoryItem(
                            'Business',
                            _categoryRevenue['Business'] ?? 0,
                            Colors.green,
                          ),
                          _buildRevenueCategoryItem(
                            'Arts',
                            _categoryRevenue['Arts'] ?? 0,
                            Colors.orange,
                          ),
                          _buildRevenueCategoryItem(
                            'Science',
                            _categoryRevenue['Science'] ?? 0,
                            Colors.purple,
                          ),
                          _buildRevenueCategoryItem(
                            'Other',
                            _categoryRevenue['Other'] ?? 0,
                            Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Summary table
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 2,
                          child: Text(
                            'Category',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Revenue',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Growth',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: AppColors.border),

                  // Category rows
                  _buildCategoryDataRow('Technology', _categoryRevenue['Technology'] ?? 0, 12.5),
                  _buildCategoryDataRow('Business', _categoryRevenue['Business'] ?? 0, 8.3),
                  _buildCategoryDataRow('Arts', _categoryRevenue['Arts'] ?? 0, -2.1),
                  _buildCategoryDataRow('Science', _categoryRevenue['Science'] ?? 0, 15.7),
                  _buildCategoryDataRow('Other', _categoryRevenue['Other'] ?? 0, 4.2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getCategoryPieSections() {
    final categories = [
      {'name': 'Technology', 'color': Colors.blue, 'value': _categoryRevenue['Technology'] ?? 0},
      {'name': 'Business', 'color': Colors.green, 'value': _categoryRevenue['Business'] ?? 0},
      {'name': 'Arts', 'color': Colors.orange, 'value': _categoryRevenue['Arts'] ?? 0},
      {'name': 'Science', 'color': Colors.purple, 'value': _categoryRevenue['Science'] ?? 0},
      {'name': 'Other', 'color': Colors.grey, 'value': _categoryRevenue['Other'] ?? 0},
    ];

    final total = categories.fold(0.0, (sum, item) => sum + (item['value'] as double));

    return categories.map((category) {
      final value = category['value'] as double;
      final percentage = total > 0 ? (value / total) * 100 : 0;

      return PieChartSectionData(
        color: category['color'] as Color,
        value: value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildRevenueCategoryItem(String category, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '\$${NumberFormat('#,###').format(amount)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDataRow(String category, double amount, double growthRate) {
    final isPositive = growthRate >= 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '\$${NumberFormat('#,###').format(amount)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isPositive ? AppColors.success : AppColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${growthRate.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isPositive ? AppColors.success : AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.border),
      ],
    );
  }

  Widget _buildTeacherPerformanceCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher Performance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Top 5 teachers by revenue',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                OutlinedButton(
                  onPressed: () {
                    // View all teachers
                    _tabController.animateTo(1); // Switch to teachers tab
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTopEarningTeachers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  final teachers = snapshot.data ?? [];
                  if (teachers.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No teacher data available'),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Performance chart
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: teachers.fold(0.0,
                                    (max, teacher) => math.max(max, teacher['earnings'] as double)) * 1.2,
                            barGroups: teachers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final teacher = entry.value;

                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: teacher['earnings'] as double,
                                    width: 16,
                                    color: index == 0
                                        ? AppColors.primary
                                        : AppColors.secondary.withOpacity(0.7 - (index * 0.1)),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                  ),
                                ],
                              );
                            }).toList(),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= teachers.length) {
                                      return const Text('');
                                    }

                                    final name = teachers[index]['name'] as String;
                                    final initials = name.split(' ')
                                        .map((part) => part.isNotEmpty ? part[0] : '')
                                        .join('')
                                        .toUpperCase();

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: index == 0
                                                ? AppColors.primary
                                                : AppColors.secondary.withOpacity(0.7 - (index * 0.1)),
                                            child: Text(
                                              initials,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: 60,
                                            child: Text(
                                              name.split(' ')[0],
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  reservedSize: 44,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) {
                                      return const Text('');
                                    }

                                    final formattedValue = value >= 1000
                                        ? '${(value / 1000).toStringAsFixed(1)}K'
                                        : value.toInt().toString();

                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        '\$${formattedValue}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: AppColors.border,
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Teacher leaderboard list
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Rank',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Teacher',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Earnings',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Courses',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, thickness: 1, color: AppColors.border),

                            for (int i = 0; i < teachers.length; i++)
                              _buildTeacherRankingRow(teachers[i], i),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherRankingRow(Map<String, dynamic> teacher, int index) {
    final name = teacher['name'] as String;
    final earnings = teacher['earnings'] as double;
    final courses = teacher['courses'] as int;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank
              Expanded(
                flex: 1,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: index == 0
                        ? AppColors.primary.withOpacity(0.1)
                        : index == 1
                        ? AppColors.secondary.withOpacity(0.1)
                        : index == 2
                        ? AppColors.accent.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: index == 0
                            ? AppColors.primary
                            : index == 1
                            ? AppColors.secondary
                            : index == 2
                            ? AppColors.accent
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),

              // Teacher name
              Expanded(
                flex: 3,
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),

              // Earnings
              Expanded(
                flex: 2,
                child: Text(
                  '\$${NumberFormat('#,###').format(earnings)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),

              // Courses
              Expanded(
                flex: 2,
                child: Text(
                  courses.toString(),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.border),
      ],
    );
  }

  Widget _buildCoursePerformanceCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Course Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Top performing courses by revenue',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchBestSellingCourses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else {
                  final courses = snapshot.data ?? [];
                  if (courses.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No course data available'),
                      ),
                    );
                  }

                  return Column(
                    children: courses.map((course) => _buildCourseDataCard(course)).toList(),
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  // View all courses
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View All Courses'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseDataCard(Map<String, dynamic> course) {
    final title = course['title'] as String;
    final revenue = course['revenue'] as double;
    final enrollments = course['enrollments'] as int;
    final teacher = course['teacher'] as String;

    // Calculate percentage of total revenue
    final percentOfTotal = _totalRevenue > 0 ? (revenue / _totalRevenue) * 100 : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.book,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By $teacher',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${NumberFormat('#,###').format(revenue)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${percentOfTotal.toStringAsFixed(1)}% of total',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar showing percentage of total revenue
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentOfTotal / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              Expanded(
                child: _buildCourseStat(
                  'Enrollments',
                  enrollments.toString(),
                  Icons.person_add,
                ),
              ),
              Expanded(
                child: _buildCourseStat(
                  'Price',
                  '\$${(revenue / enrollments).toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
              ),
              Expanded(
                child: _buildCourseStat(
                  'Per Student',
                  '\$${(revenue / enrollments).toStringAsFixed(2)}',
                  Icons.school,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.secondary,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentEngagementCard() {
    // This is a placeholder for student engagement metrics
    // In a real app, this would be populated with actual student data

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Engagement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enrollment trends and completion rates',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // Student stats row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Active Students',
                    value: '$_totalStudents',
                    trend: '+15.2%',
                    isPositive: true,
                    icon: Icons.people,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'New Enrollments',
                    value: '${(_totalStudents * 0.23).round()}',
                    trend: '+8.7%',
                    isPositive: true,
                    icon: Icons.school,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Completion Rate',
                    value: '76.4%',
                    trend: '-2.1%',
                    isPositive: false,
                    icon: Icons.verified,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Enrollment trends chart (placeholder)
            const Text(
              'Enrollment Trends',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Student enrollment data will be displayed here',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notes for future development
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Development Note',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This section requires additional student engagement metrics from the database. Once available, this card will show completion rates, active learning time, and student satisfaction scores.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
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
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String trend,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: isPositive ? AppColors.success : AppColors.accent,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 12,
                  color: isPositive ? AppColors.success : AppColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper methods for filter, sort, and dialog displays
  // ---------------------------------------------------------------------------
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
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
                    runSpacing: 8,
                    children: [
                      'Last 30 Days',
                      'Last 90 Days',
                      'Last 12 Months',
                      'All Time'
                    ].map((String value) {
                      return ChoiceChip(
                        label: Text(value),
                        selected: _selectedTimeRange == value,
                        onSelected: (bool selected) {
                          setStateModal(() {
                            _selectedTimeRange = value;
                          });
                          // Update the parent state as well
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Sort By
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Earnings (High to Low)',
                      'Earnings (Low to High)',
                      'Name (A-Z)',
                      'Name (Z-A)',
                      'Courses (Most)',
                      'Courses (Least)',
                    ].map((String value) {
                      return ChoiceChip(
                        label: Text(value),
                        selected: _sortBy == value,
                        onSelected: (bool selected) {
                          setStateModal(() {
                            _sortBy = value;
                          });
                          // Update the parent state as well
                          setState(() {});
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
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        // Here you would apply the filters and refresh the data
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

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a format to export your data',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              _buildExportOption(
                icon: Icons.table_chart,
                title: 'CSV Spreadsheet',
                subtitle: 'Export all data as CSV file',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting as CSV...')),
                  );
                },
              ),

              _buildExportOption(
                icon: Icons.picture_as_pdf,
                title: 'PDF Report',
                subtitle: 'Generate a detailed PDF report',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating PDF report...')),
                  );
                },
              ),

              _buildExportOption(
                icon: Icons.print,
                title: 'Print',
                subtitle: 'Print current view directly',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preparing to print...')),
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showMonthDetails(BuildContext context, String month, double revenue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            formatMonthKey(month),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Total Revenue',
                    '\$${revenue.toStringAsFixed(2)}'),
                const Divider(),
                FutureBuilder<Map<String, dynamic>>(
                  future: _fetchMonthDetails(month),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      final details = snapshot.data ?? {};
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Enrollments',
                              '${details['enrollments'] ?? 0}'),
                          _buildDetailRow('Courses Sold',
                              '${details['coursesSold'] ?? 0}'),
                          _buildDetailRow('Active Teachers',
                              '${details['activeTeachers'] ?? 0}'),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Here you would navigate to a detailed report for this month
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('View Full Report'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Teacher Payment Dashboard Help'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  'Overview Tab',
                  'Shows monthly revenue data, top earning teachers, and best selling courses.',
                ),
                _buildHelpItem(
                  'Teachers Tab',
                  'Lists all teachers with detailed breakdown of their earnings and courses.',
                ),
                _buildHelpItem(
                  'Analytics Tab',
                  'Provides in-depth analysis of revenue trends and teacher performance.',
                ),
                _buildHelpItem(
                  'Search',
                  'Use the search bar to find specific teachers by name or email.',
                ),
                _buildHelpItem(
                  'Filters',
                  'Click the filter icon in the app bar to filter by time period or sort in different ways.',
                ),
                _buildHelpItem(
                  'Export',
                  'Use the download icon to export data in various formats.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Data fetching methods
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchTopEarningTeachers() async {
    // In a real app, this would query Firestore more efficiently
    final authService = Provider.of<AuthService>(context, listen: false);
    final allTeachers = await _fetchAllTeachers(authService);

    List<Map<String, dynamic>> teacherEarnings = [];

    for (var teacher in allTeachers) {
      if (teacher.email != null) {
        final earnings = await _fetchMonthlyEarningsAllCourses(teacher.email!);
        final totalEarnings = earnings.values.fold(0.0, (sum, value) => sum + value);

        final courses = await _fetchTeacherCourses(teacher.email!);

        // Count total students across all courses
        int totalStudents = 0;
        for (var course in courses) {
          final courseId = course['id'];
          final coursePrice = course['price']?.toDouble() ?? 0.0;

          if (coursePrice > 0) {
            final courseEarnings = await _fetchMonthlyEarningsForCourse(courseId, coursePrice);
            final courseStudents = courseEarnings.values.fold(
                0.0, (sum, value) => sum + (value / coursePrice)
            ).round();

            totalStudents += courseStudents;
          }
        }

        teacherEarnings.add({
          'name': teacher.name ?? 'Unknown',
          'email': teacher.email,
          'earnings': totalEarnings,
          'courses': courses.length,
          'students': totalStudents,
        });
      }
    }

    // Sort by earnings (highest first)
    teacherEarnings.sort((a, b) =>
        (b['earnings'] as double).compareTo(a['earnings'] as double));

    // Return top 5 (or all if less than 5)
    return teacherEarnings.take(5).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchBestSellingCourses() async {
    final courseSnapshot =
    await FirebaseFirestore.instance.collection('courses').get();

    List<Map<String, dynamic>> courseDataList = [];

    for (var courseDoc in courseSnapshot.docs) {
      final docData = courseDoc.data();
      final courseId = courseDoc.id;
      final coursePrice = double.tryParse(docData['price'].toString()) ?? 0.0;
      final courseTitle = docData['courseTitle'] ?? 'Untitled Course';
      final teacherEmail = docData['instructorEmail'] ?? '';

      // Count enrollments for this course
      final userSnapshot =
      await FirebaseFirestore.instance.collection('users').get();
      int enrollmentCount = 0;

      for (var userDoc in userSnapshot.docs) {
        final userData = userDoc.data();
        final enrolledCourses = userData['enrolledCourses'] as List<dynamic>?;

        if (enrolledCourses != null) {
          for (var enrolled in enrolledCourses) {
            if (enrolled is Map<String, dynamic> &&
                enrolled['courseId'] == courseId) {
              enrollmentCount++;
            }
          }
        }
      }

      // Find teacher name
      String teacherName = 'Unknown';
      if (teacherEmail.isNotEmpty) {
        final teacherSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: teacherEmail)
            .limit(1)
            .get();

        if (teacherSnapshot.docs.isNotEmpty) {
          teacherName =
              teacherSnapshot.docs.first.data()['name'] ?? 'Unknown';
        }
      }

      courseDataList.add({
        'id': courseId,
        'title': courseTitle,
        'price': coursePrice,
        'enrollments': enrollmentCount,
        'revenue': enrollmentCount * coursePrice,
        'teacher': teacherName,
      });
    }

    // Sort by revenue (highest first)
    courseDataList.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

    // Return top 3 (or all if less than 3)
    return courseDataList.take(3).toList();
  }

  Future<Map<String, dynamic>> _fetchMonthDetails(String month) async {
    // Normally this would be a more optimized query
    // This is a simplified implementation

    int enrollments = 0;
    Set<String> coursesSold = {};
    Set<String> activeTeachers = {};

    // Get all enrollments for this month
    final userSnapshot =
    await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data();
      final enrolledCourses = userData['enrolledCourses'] as List<dynamic>?;

      if (enrolledCourses != null) {
        for (var enrolled in enrolledCourses) {
          if (enrolled is Map<String, dynamic>) {
            final Timestamp? ts = enrolled['enrollmentDate'];
            if (ts != null) {
              final date = ts.toDate();
              final monthKey =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}';

              if (monthKey == month) {
                enrollments++;
                coursesSold.add(enrolled['courseId'] as String);

                // Find the teacher for this course
                final courseId = enrolled['courseId'];
                final courseDoc = await FirebaseFirestore.instance
                    .collection('courses')
                    .doc(courseId)
                    .get();

                if (courseDoc.exists) {
                  final courseData = courseDoc.data();
                  if (courseData != null &&
                      courseData['instructorEmail'] != null) {
                    activeTeachers.add(
                      courseData['instructorEmail'] as String,
                    );
                  }
                }
              }
            }
          }
        }
      }
    }

    return {
      'enrollments': enrollments,
      'coursesSold': coursesSold.length,
      'activeTeachers': activeTeachers.length,
    };
  }

  /// Fetch ALL teachers (role == 'Teacher')
  Future<List<CustomUser>> _fetchAllTeachers(AuthService authService) async {
    final allUsers = await authService.fetchAllUsers();
    return allUsers.where((user) => user.role == 'Teacher').toList();
  }

  /// Fetch teacher's courses
  Future<List<Map<String, dynamic>>> _fetchTeacherCourses(
      String teacherEmail) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: teacherEmail)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Calculate monthly earnings for a single course
  Future<Map<String, double>> _fetchMonthlyEarningsForCourse(
      String courseId,
      double coursePrice,
      ) async {
    final userSnapshot =
    await FirebaseFirestore.instance.collection('users').get();

    final Map<String, int> monthCount = {};
    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final enrolledCourses = userData['enrolledCourses'] as List<dynamic>?;

      if (enrolledCourses == null) continue;

      for (var enrolled in enrolledCourses) {
        if (enrolled is Map<String, dynamic>) {
          final String? cId = enrolled['courseId'];
          if (cId == courseId) {
            final Timestamp? ts = enrolled['enrollmentDate'];
            if (ts == null) continue;

            final date = ts.toDate();
            final monthKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}';

            monthCount.update(
              monthKey,
                  (existing) => existing + 1,
              ifAbsent: () => 1,
            );
          }
        }
      }
    }

    final Map<String, double> monthlyEarnings = {};
    monthCount.forEach((month, count) {
      monthlyEarnings[month] = count * coursePrice;
    });

    return monthlyEarnings;
  }

  /// Calculate combined monthly earnings for ALL courses by a single teacher
  Future<Map<String, double>> _fetchMonthlyEarningsAllCourses(
      String teacherEmail) async {
    final courseSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: teacherEmail)
        .get();

    // Map of courseId -> coursePrice for teacher's courses
    final Map<String, double> teacherCourses = {};
    for (var doc in courseSnapshot.docs) {
      final data = doc.data();
      final priceValue = data['price'] ?? 0.0;
      final double coursePrice = double.tryParse(priceValue.toString()) ?? 0.0;
      teacherCourses[doc.id] = coursePrice;
    }

    final Map<String, double> monthlyEarnings = {};
    final userSnapshot =
    await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final enrolledCourses = userData['enrolledCourses'] as List<dynamic>?;

      if (enrolledCourses == null) continue;

      for (var enrolled in enrolledCourses) {
        if (enrolled is Map<String, dynamic>) {
          final String? cId = enrolled['courseId'];
          if (cId != null && teacherCourses.containsKey(cId)) {
            final Timestamp? ts = enrolled['enrollmentDate'];
            if (ts == null) continue;

            final date = ts.toDate();
            final monthKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}';

            final price = teacherCourses[cId] ?? 0.0;
            monthlyEarnings.update(
              monthKey,
                  (existing) => existing + price,
              ifAbsent: () => price,
            );
          }
        }
      }
    }

    return monthlyEarnings;
  }

  /// Calculate APP-WIDE revenue for all teachers/courses
  Future<Map<String, double>> _fetchAppWideMonthlyRevenue() async {
    final courseSnapshot =
    await FirebaseFirestore.instance.collection('courses').get();

    // Map of courseId -> coursePrice (all courses)
    final Map<String, double> allCourses = {};
    for (var doc in courseSnapshot.docs) {
      final data = doc.data();
      final priceValue = data['price'] ?? 0.0;
      final double coursePrice = double.tryParse(priceValue.toString()) ?? 0.0;
      allCourses[doc.id] = coursePrice;
    }

    final Map<String, double> monthlyRevenue = {};
    final userSnapshot =
    await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final enrolledCourses = userData['enrolledCourses'] as List<dynamic>?;

      if (enrolledCourses == null) continue;

      for (var enrolled in enrolledCourses) {
        if (enrolled is Map<String, dynamic>) {
          final String? cId = enrolled['courseId'];
          if (cId != null && allCourses.containsKey(cId)) {
            final Timestamp? ts = enrolled['enrollmentDate'];
            if (ts == null) continue;

            final date = ts.toDate();
            final monthKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}';
            final double price = allCourses[cId] ?? 0.0;

            monthlyRevenue.update(
              monthKey,
                  (existing) => existing + price,
              ifAbsent: () => price,
            );
          }
        }
      }
    }

    return monthlyRevenue;
  }
}

// Helper classes
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

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}