import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../../Modals/User.dart';
import '../../Service/AuthService.dart';

// Custom color scheme
class AppColors {
  static const Color primaryGreen = Color(0xFF11261F);
  static const Color secondaryBlue = Color(0xFF123755);
  static const Color accentMaroon = Color(0xFF722626);
  static const Color lightBackground = Color(0xFFF5F7F9);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF242424);
  static const Color textSecondary = Color(0xFF6C6C6C);
}

/// Shows the total app revenue across all teachers (by month),
/// plus each individual teacher's monthly totals & course breakdown.
class TeacherPaymentsScreen extends StatefulWidget {
  const TeacherPaymentsScreen({Key? key}) : super(key: key);

  @override
  _TeacherPaymentsScreenState createState() => _TeacherPaymentsScreenState();
}

class _TeacherPaymentsScreenState extends State<TeacherPaymentsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedTimeRange = 'All Time';
  String _sortBy = 'Name';
  bool _showFloatingStats = false;
  double _totalRevenue = 0.0;
  int _totalTeachers = 0;
  int _totalCourses = 0;
  ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  Map<String, double> _monthlyRevenueData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final revenueData = await _fetchAppWideMonthlyRevenue();
      final totalRevenue =
      revenueData.values.fold(0.0, (sum, value) => sum + value);

      final authService = Provider.of<AuthService>(context, listen: false);
      final teachers = await _fetchAllTeachers(authService);

      final totalCourses = await _fetchTotalCourses();

      setState(() {
        _totalRevenue = totalRevenue;
        _totalTeachers = teachers.length;
        _totalCourses = totalCourses;
        _monthlyRevenueData = revenueData;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      // Error handling
    }
  }

  Future<int> _fetchTotalCourses() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('courses').get();
    return snapshot.docs.length;
  }

  // Format month key (YYYY-MM) to more readable format (Month YYYY)
  String formatMonthKey(String monthKey) {
    try {
      final parts = monthKey.split('-');
      if (parts.length == 2) {
        final year = parts[0];
        final month = int.tryParse(parts[1]);
        if (month != null) {
          return '${DateFormat('MMMM').format(DateTime(2023, month))} $year';
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
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Teacher Payments',
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
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.arrow_upward),
        label: Text('\$${_totalRevenue.toStringAsFixed(0)}'),
      )
          : null,
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.secondaryBlue),
            SizedBox(height: 16),
            Text('Loading payment data...'),
          ],
        ),
      )
          : SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Gradient header
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
                    // Title
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Financial Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Quick stats cards
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickStatCard(
                            title: 'Revenue',
                            value:
                            '\$${NumberFormat('#,###').format(_totalRevenue)}',
                            icon: Icons.attach_money,
                            color: AppColors.primaryGreen,
                          ),
                          _buildQuickStatCard(
                            title: 'Teachers',
                            value: _totalTeachers.toString(),
                            icon: Icons.person,
                            color: AppColors.secondaryBlue,
                          ),
                          _buildQuickStatCard(
                            title: 'Courses',
                            value: _totalCourses.toString(),
                            icon: Icons.book,
                            color: AppColors.accentMaroon,
                          ),
                        ],
                      ),
                    ),

                    // Search bar
                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextFormField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search teachers...',
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textSecondary),
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
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                                color: AppColors.secondaryBlue, width: 1),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
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
                  tabs: const [
                    Tab(
                      text: 'Revenue',
                      icon: Icon(Icons.bar_chart),
                    ),
                    Tab(
                      text: 'Teachers',
                      icon: Icon(Icons.people),
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              // Revenue Tab
              _buildRevenueTab(context),

              // Teachers Tab
              _buildTeachersTab(context, authService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
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
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.2);
  }

  Widget _buildRevenueTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue overview card
          Card(
            elevation: 2,
            shadowColor: Colors.black12,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total App Revenue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${_totalRevenue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildTimePeriodDropdown(),
                          const SizedBox(height: 4),
                          const Text(
                            'vs. Previous',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Monthly Revenue Chart
                  const Text(
                    'Monthly Revenue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  FutureBuilder<Map<String, double>>(
                    future: _fetchAppWideMonthlyRevenue(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
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
                        final monthlyData = snapshot.data ?? {};
                        if (monthlyData.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No revenue data available'),
                            ),
                          );
                        }

                        return _buildEnhancedRevenueChart(monthlyData);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Top Earning Teachers
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
          const Text(
            'Best Selling Courses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
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
                  children:
                  courses.map((course) => _buildCourseCard(course)).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<String>(
        value: _selectedTimeRange,
        icon: const Icon(Icons.arrow_drop_down, size: 16),
        underline: const SizedBox.shrink(),
        isDense: true,
        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
        items: ['Last Month', 'Last Quarter', 'Last Year', 'All Time']
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
            });
          }
        },
      ),
    );
  }

  Widget _buildEnhancedRevenueChart(Map<String, double> monthlyData) {
    // Sort months
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

    return Column(
      children: [
        // Growth indicator
        if (values.length >= 2)
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: growthPercentage >= 0
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    growthPercentage >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: growthPercentage >= 0 ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${growthPercentage.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: growthPercentage >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        // Chart visualization
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              values.length,
                  (index) => Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Month value tooltip (for last column)
                    Positioned(
                      top: 0,
                      child: sortedKeys[index] == sortedKeys.last
                          ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${values[index].toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),

                    // Bar
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => _showMonthDetails(
                              context, sortedKeys[index], values[index]),
                          child: Container(
                            height: maxValue == 0
                                ? 0
                                : (values[index] / maxValue) * 150,
                            width: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.primaryGreen,
                                  sortedKeys[index] == sortedKeys.last
                                      ? AppColors.primaryGreen
                                      : AppColors.primaryGreen.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              boxShadow: sortedKeys[index] == sortedKeys.last
                                  ? [
                                BoxShadow(
                                  color: AppColors.primaryGreen
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sortedKeys[index].split('-')[1],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: sortedKeys[index] == sortedKeys.last
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: sortedKeys[index] == sortedKeys.last
                                ? AppColors.primaryGreen
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Monthly Revenue',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Data table
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
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
                final earnings = monthlyData[month] ?? 0;

                // Calculate month-over-month change
                double changePercentage = 0;
                if (index > 0) {
                  final currentValue = values[index];
                  final previousValue = values[index - 1];
                  if (previousValue > 0) {
                    changePercentage =
                        ((currentValue - previousValue) / previousValue) * 100;
                  }
                }

                return ListTile(
                  dense: true,
                  onTap: () => _showMonthDetails(context, month, earnings),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      size: 18,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  title: Text(
                    formatMonthKey(month),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: changePercentage >= 0
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                changePercentage >= 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 12,
                                color: changePercentage >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              Text(
                                '${changePercentage.abs().toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: changePercentage >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        '\$${earnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopTeacherCard(Map<String, dynamic> teacher, int index) {
    final teacherName = teacher['name'] ?? 'Unknown';
    final earnings = teacher['earnings'] ?? 0.0;
    final teacherInitial =
    teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: [
                AppColors.primaryGreen,
                AppColors.secondaryBlue,
                AppColors.accentMaroon,
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
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    color: [
                      AppColors.primaryGreen,
                      AppColors.secondaryBlue,
                      AppColors.accentMaroon,
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
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          teacher['email'] ?? '',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${earnings.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primaryGreen,
              ),
            ),
            Text(
              '${teacher['courses'] ?? 0} courses',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fade(duration: 400.ms)
        .slideX(begin: 0.05, delay: Duration(milliseconds: index * 100));
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final courseTitle = course['title'] ?? 'Untitled Course';
    final enrollments = course['enrollments'] ?? 0;
    final revenue = course['revenue'] ?? 0.0;
    final teacherName = course['teacher'] ?? 'Unknown';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.accentMaroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.book,
                color: AppColors.accentMaroon,
                size: 24,
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
                      fontWeight: FontWeight.bold,
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
                        color: AppColors.secondaryBlue,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricChip(
                        label: 'Revenue',
                        value: '\$${revenue.toStringAsFixed(0)}',
                        icon: Icons.attach_money,
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
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
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersTab(BuildContext context, AuthService authService) {
    return FutureBuilder<List<CustomUser>>(
      future: _fetchAllTeachers(authService),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return _CustomErrorWidget(
            message: 'Error loading teachers: ${snapshot.error}',
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _EmptyStateWidget(
            icon: Icons.person_off,
            message: 'No teachers found in the system',
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
          if (_sortBy == 'Name') {
            filteredTeachers.sort(
                    (a, b) => (a.name ?? '').compareTo(b.name ?? ''));
          }
          // You could add more sorting logic for 'Earnings' or 'Courses' if desired.

          return filteredTeachers.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No teachers match your search'),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTeachers.length,
            itemBuilder: (context, index) {
              final teacher = filteredTeachers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTeacherTile(teacher),
              );
            },
          );
        }
      },
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
                      'Last Quarter',
                      'Last Year',
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
                    children: ['Name', 'Earnings', 'Courses'].map((String value) {
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
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
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

  void _showMonthDetails(BuildContext context, String month, double revenue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(formatMonthKey(month)),
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Here you would navigate to a detailed report for this month
              },
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
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  'Revenue Tab',
                  'Shows monthly revenue data and top performing teachers and courses.',
                ),
                _buildHelpItem(
                  'Teachers Tab',
                  'Lists all teachers with detailed breakdown of their earnings and courses.',
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
                  'Charts',
                  'Click on any bar in the charts to see detailed information for that period.',
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
  // Data fetching methods for the new analyses
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchTopEarningTeachers() async {
    // In a real app, this would query Firestore more efficiently
    final authService = Provider.of<AuthService>(context, listen: false);
    final allTeachers = await _fetchAllTeachers(authService);

    List<Map<String, dynamic>> teacherEarnings = [];

    for (var teacher in allTeachers) {
      if (teacher.email != null) {
        final earnings =
        await _fetchMonthlyEarningsAllCourses(teacher.email!);
        final totalEarnings =
        earnings.values.fold(0.0, (sum, value) => sum + value);

        final courses = await _fetchTeacherCourses(teacher.email!);

        teacherEarnings.add({
          'name': teacher.name ?? 'Unknown',
          'email': teacher.email,
          'earnings': totalEarnings,
          'courses': courses.length,
        });
      }
    }

    // Sort by earnings (highest first)
    teacherEarnings.sort((a, b) =>
        (b['earnings'] as double).compareTo(a['earnings'] as double));

    // Return top 3 (or all if less than 3)
    return teacherEarnings.take(3).toList();
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
    courseDataList
        .sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

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

  /// (A) Fetch ALL teachers (role == 'Teacher')
  Future<List<CustomUser>> _fetchAllTeachers(AuthService authService) async {
    final allUsers = await authService.fetchAllUsers();
    return allUsers.where((user) => user.role == 'Teacher').toList();
  }

  // ---------------------------------------------------------------------------
  // (B) Build each teacher's tile (includes monthly combined totals + courses)
  // ---------------------------------------------------------------------------
  Widget _buildTeacherTile(CustomUser teacher) {
    final teacherName = teacher.name ?? teacher.email ?? 'Unknown';
    final teacherEmail = teacher.email ?? 'No Email';
    final teacherInitial =
    teacherName.isNotEmpty ? teacherName[0].toUpperCase() : 'T';

    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.secondaryBlue,
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
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teacherEmail,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
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
                    final totalEarnings = snapshot.data!.values
                        .fold(0.0, (sum, value) => sum + value);
                    return Row(
                      children: [
                        const Icon(
                          Icons.paid,
                          color: AppColors.accentMaroon,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Total Earnings: \$${totalEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentMaroon,
                            fontSize: 13,
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
              child: Text('Export Data'),
            ),
            const PopupMenuItem<String>(
              value: 'details',
              child: Text('View Detailed Report'),
            ),
          ],
        ),
        children: [
          // B1) Monthly combined totals for this teacher
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Monthly Earnings',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<Map<String, double>>(
            future: _fetchMonthlyEarningsAllCourses(teacherEmail),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              } else {
                final monthlyTotals = snapshot.data ?? {};
                if (monthlyTotals.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: _EmptyStateWidget(
                      icon: Icons.money_off,
                      message: 'No earnings data available',
                    ),
                  );
                }
                return _buildMonthlyEarningsChart(monthlyTotals);
              }
            },
          ),

          // B2) Each course -> monthly breakdown
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.accentMaroon,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Courses',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentMaroon,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchTeacherCourses(teacherEmail),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              } else {
                final courses = snapshot.data ?? [];
                if (courses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: _EmptyStateWidget(
                      icon: Icons.book_outlined,
                      message: 'No courses found for this teacher',
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children:
                    courses.map((course) => _buildCourseTile(course)).toList(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.05);
  }

  // Monthly earnings chart for teacher
  Widget _buildMonthlyEarningsChart(Map<String, double> monthlyData) {
    // Sort months
    final sortedKeys = monthlyData.keys.toList()..sort();
    final List<double> values = sortedKeys.map((m) => monthlyData[m]!).toList();
    final double maxValue = values.isNotEmpty ? values.reduce(math.max) : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Chart visualization
          if (values.isNotEmpty)
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  values.length,
                      (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => _showMonthDetails(
                                context, sortedKeys[index], values[index]),
                            child: Container(
                              height: maxValue == 0
                                  ? 0
                                  : (values[index] / maxValue) * 80,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBlue.withOpacity(0.7),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sortedKeys[index].split('-')[1],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Data table
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                for (int i = 0; i < sortedKeys.length; i++)
                  Container(
                    decoration: BoxDecoration(
                      border: i < sortedKeys.length - 1
                          ? Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                      )
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatMonthKey(sortedKeys[i]),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '\$${values[i].toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryBlue,
                            ),
                          ),
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

  // ---------------------------------------------------------------------------
  // (C) Courses & Earnings
  // ---------------------------------------------------------------------------
  Widget _buildCourseTile(Map<String, dynamic> course) {
    final courseTitle = course['courseTitle'] ?? 'Untitled Course';
    final coursePrice = course['price']?.toDouble() ?? 0.0;
    final courseId = course['id'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding:
          const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentMaroon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.book,
              color: AppColors.accentMaroon,
              size: 20,
            ),
          ),
          title: Text(
            courseTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  'Price: \$${coursePrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.circle,
                  size: 6,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                FutureBuilder<Map<String, double>>(
                  future: _fetchMonthlyEarningsForCourse(courseId, coursePrice),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
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
                      return Text(
                        '$totalStudents students',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
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
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
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
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'No enrollments for this course',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }

                  // Sort months
                  final sortedKeys = monthlyData.keys.toList()..sort();
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < sortedKeys.length; i++)
                          Container(
                            decoration: BoxDecoration(
                              border: i < sortedKeys.length - 1
                                  ? Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              )
                                  : null,
                            ),
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              title: Text(
                                formatMonthKey(sortedKeys[i]),
                                style: const TextStyle(fontSize: 13),
                              ),
                              trailing: Text(
                                '\$${monthlyData[sortedKeys[i]]!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.accentMaroon,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// (C1) Fetch teacher's courses
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

  /// (C2) Calculate monthly earnings for a single course
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

  /// (C3) Calculate combined monthly earnings for ALL courses by a single teacher
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

  /// (D) Calculate APP-WIDE revenue for all teachers/courses
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

            // Note: Use update() or [key] = value, not add().
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

/// Simple loading card for the revenue section
class _RevenueLoadingCard extends StatelessWidget {
  const _RevenueLoadingCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.secondaryBlue,
              ),
            ),
            SizedBox(width: 16),
            Text(
              'Calculating App Revenue...',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card that shows an error for the revenue section
class _RevenueErrorCard extends StatelessWidget {
  final String errorMessage;

  const _RevenueErrorCard({
    Key? key,
    required this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.error_outline, color: Colors.red.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Error loading revenue data: $errorMessage',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card that shows the app-wide monthly revenue data
class _AppRevenueCard extends StatelessWidget {
  final Map<String, double> monthlyData;
  final double totalRevenue;

  const _AppRevenueCard({
    Key? key,
    required this.monthlyData,
    required this.totalRevenue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return const Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No revenue data available',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    final sortedKeys = monthlyData.keys.toList()..sort((a, b) => a.compareTo(b));
    final List<double> values = sortedKeys.map((m) => monthlyData[m]!).toList();
    final double maxValue = values.reduce(math.max);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with total
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total App Revenue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${totalRevenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Text(
              'Monthly Breakdown',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Chart visualization
            if (values.isNotEmpty)
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    values.length,
                        (index) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: (values[index] / maxValue) * 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppColors.primaryGreen,
                                    AppColors.primaryGreen.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              sortedKeys[index].split('-')[1],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Detailed data
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
                  final earnings = monthlyData[month] ?? 0;
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
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatMonthKey(month),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Text(
                          '\$${earnings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
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
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeIn);
  }

  String _formatMonthKey(String monthKey) {
    try {
      final parts = monthKey.split('-');
      if (parts.length == 2) {
        final year = parts[0];
        final month = int.tryParse(parts[1]);
        if (month != null) {
          return '${DateFormat('MMMM').format(DateTime(2023, month))} $year';
        }
      }
    } catch (e) {
      // Fall back to original format in case of any error
    }
    return monthKey;
  }
}

/// Empty state widget
class _EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom error widget
class _CustomErrorWidget extends StatelessWidget {
  final String message;

  const _CustomErrorWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          ],
        ),
      ),
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