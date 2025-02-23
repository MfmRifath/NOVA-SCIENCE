import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../Service/AuthService.dart';
import '../../Service/CourseProvider.dart';

class DashboardOverviewScreen extends StatefulWidget {
  @override
  _DashboardOverviewScreenState createState() => _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen>
    with SingleTickerProviderStateMixin {
  // Realtime metrics from subscriptions.
  int _totalUsers = 0;
  int _coursesAvailable = 0;
  int _activeStudents = 0;
  // App Revenue is defined as 20% of the Total Teacher Revenue.
  List<double> _monthlyRegistrations = List.filled(12, 0);

  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isLoading = true;

  // Firestore subscriptions.
  StreamSubscription<QuerySnapshot>? _usersSubscription;
  StreamSubscription<QuerySnapshot>? _coursesSubscription;
  // Local map of course prices: courseId -> price.
  Map<String, double> _coursePrices = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _subscribeToData();
  }

  void _subscribeToData() {
    // Listen to the courses collection.
    _coursesSubscription = FirebaseFirestore.instance
        .collection('courses')
        .snapshots()
        .listen((coursesSnapshot) {
      _coursesAvailable = coursesSnapshot.size;
      _coursePrices = {};
      for (var doc in coursesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        double price = 0.0;
        if (data.containsKey('price')) {
          price = (data['price'] is double)
              ? data['price']
              : (data['price'] as num).toDouble();
        }
        _coursePrices[doc.id] = price;
      }
      setState(() {});
    });

    // Listen to the users collection.
    _usersSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((usersSnapshot) {
      _totalUsers = usersSnapshot.size;
      int activeCount = 0;
      List<double> monthlyRegs = List.filled(12, 0);

      for (var doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Count active students (assuming an 'isOnline' flag).
        if (data['isOnline'] == true) {
          activeCount++;
        }
        // Count monthly registrations (for the current year, all 12 months).
        if (data.containsKey('registrationDate')) {
          Timestamp timestamp = data['registrationDate'];
          DateTime regDate = timestamp.toDate();
          int currentYear = DateTime.now().year;
          if (regDate.year == currentYear) {
            monthlyRegs[regDate.month - 1] += 1;
          }
        }
      }
      _activeStudents = activeCount;
      _monthlyRegistrations = monthlyRegs;

      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
        _controller.forward();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _coursesSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// ---------------------------------------------------------------------------
  /// Compute app‑wide monthly revenue by grouping enrollments using enrollmentDate.
  /// ---------------------------------------------------------------------------
  Future<Map<String, double>> _fetchAppWideMonthlyRevenue() async {
    final courseSnapshot =
    await FirebaseFirestore.instance.collection('courses').get();
    final Map<String, double> allCourses = {};
    for (var doc in courseSnapshot.docs) {
      final data = doc.data();
      final priceValue = data['price'] ?? 0.0;
      final double coursePrice =
          double.tryParse(priceValue.toString()) ?? 0.0;
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
            monthlyRevenue.update(monthKey, (existing) => existing + price,
                ifAbsent: () => price);
          }
        }
      }
    }
    return monthlyRevenue;
  }

  /// Compute the average monthly revenue from the app‑wide monthly revenue map.
  Future<double> _fetchAverageMonthlyRevenue() async {
    final monthlyRevenue = await _fetchAppWideMonthlyRevenue();
    if (monthlyRevenue.isEmpty) return 0.0;
    final total = monthlyRevenue.values.fold(0.0, (sum, value) => sum + value);
    return total / monthlyRevenue.length;
  }

  /// ---------------------------------------------------------------------------
  /// Compute total teacher revenue by summing enrollments for courses that have an instructor.
  /// ---------------------------------------------------------------------------
  Future<double> _fetchTotalTeacherRevenue() async {
    final courseSnapshot =
    await FirebaseFirestore.instance.collection('courses').get();
    double totalTeacherRevenue = 0.0;
    final Map<String, double> teacherCourses = {};
    for (var doc in courseSnapshot.docs) {
      final data = doc.data();
      if (data['instructorEmail'] != null &&
          data['instructorEmail'].toString().trim().isNotEmpty) {
        final priceValue = data['price'] ?? 0.0;
        final double coursePrice =
            double.tryParse(priceValue.toString()) ?? 0.0;
        teacherCourses[doc.id] = coursePrice;
      }
    }
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
            totalTeacherRevenue += teacherCourses[cId] ?? 0.0;
          }
        }
      }
    }
    return totalTeacherRevenue;
  }

  // Helper widget to build a metric card with improved styling.
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 44, color: color),
            const SizedBox(height: 12),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                )),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                )),
          ],
        ),
      ),
    );
  }

  // Helper to build a single bar for the registrations chart.
  BarChartGroupData _buildBarGroup(int x, double y) {
    double maxY = _monthlyRegistrations.reduce((a, b) => a > b ? a : b) + 5;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.blueAccent,
          width: 16,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: Colors.blueAccent.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Overview'),
          backgroundColor: Colors.blueAccent,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Determine responsive layout parameters.
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth < 600) {
      crossAxisCount = 1;
    } else if (screenWidth < 900) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 3;
    }
    double chartHeight = screenWidth < 600 ? 200 : 240;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Overview'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Key Metrics',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      FadeInUp(
                        delay: const Duration(milliseconds: 0),
                        child: _buildMetricCard(
                            'Total Users', '$_totalUsers', Icons.people, Colors.blue),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 100),
                        child: _buildMetricCard('Courses Available', '$_coursesAvailable',
                            Icons.book, Colors.orange),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: _buildMetricCard('Active Students', '$_activeStudents',
                            Icons.school, Colors.green),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        // App Revenue = 20% of Total Teacher Revenue.
                        child: FutureBuilder<double>(
                          future: _fetchTotalTeacherRevenue(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Card(child: Center(child: CircularProgressIndicator()));
                            } else if (snapshot.hasError) {
                              return const Card(child: Center(child: Text('Error')));
                            } else {
                              final teacherRevenue = snapshot.data ?? 0.0;
                              final appRevenue = teacherRevenue * 0.2;
                              return _buildMetricCard('App Revenue',
                                  '\RS: ${appRevenue.toStringAsFixed(2)}', Icons.attach_money, Colors.redAccent);
                            }
                          },
                        ),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: FutureBuilder<double>(
                          future: _fetchAverageMonthlyRevenue(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Card(child: Center(child: CircularProgressIndicator()));
                            } else if (snapshot.hasError) {
                              return const Card(child: Center(child: Text('Error')));
                            } else {
                              final avgRevenue = snapshot.data ?? 0.0;
                              return _buildMetricCard('Avg Monthly Revenue',
                                  '\RS: ${avgRevenue.toStringAsFixed(2)}', Icons.monetization_on, Colors.purple);
                            }
                          },
                        ),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 500),
                        child: FutureBuilder<double>(
                          future: _fetchTotalTeacherRevenue(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Card(child: Center(child: CircularProgressIndicator()));
                            } else if (snapshot.hasError) {
                              return const Card(child: Center(child: Text('Error')));
                            } else {
                              final teacherRevenue = snapshot.data ?? 0.0;
                              return _buildMetricCard('Total Teacher Revenue',
                                  '\RS: ${teacherRevenue.toStringAsFixed(2)}', Icons.account_balance_wallet, Colors.teal);
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text('User Registrations (Current Year)',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: SizedBox(
                  height: chartHeight,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _monthlyRegistrations.reduce((a, b) => a > b ? a : b) + 5,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                List<String> months = [
                                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                ];
                                String monthLabel = (group.x >= 0 && group.x < months.length)
                                    ? months[group.x]
                                    : 'Month';
                                return BarTooltipItem(
                                  '$monthLabel\n${rod.toY.toStringAsFixed(0)}',
                                  const TextStyle(color: Colors.white),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  List<String> months = [
                                    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                  ];
                                  if (value.toInt() >= 0 && value.toInt() < months.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        months[value.toInt()],
                                        style: const TextStyle(
                                          color: Colors.blueAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString(),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ));
                                },
                              ),
                            ),
                          ),
                          barGroups: List.generate(_monthlyRegistrations.length, (index) {
                            final yValue = _monthlyRegistrations[index] * _animation.value;
                            return _buildBarGroup(index, yValue);
                          }),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}