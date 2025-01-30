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
  // Metrics
  int _totalUsers = 0;
  int _coursesAvailable = 0;
  int _activeStudents = 0;
  double _monthlyRevenue = 0.0;
  List<double> _monthlyRegistrations = [0, 0, 0, 0, 0, 0];

  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);

      final allUsers = await authService.getAllUsers();
      await courseProvider.fetchCourses();  // Just call it without assignment
      final loggedInUsers = await courseProvider.getNumberOfLoggedInUsers();

      // Fetch courses count correctly
      final coursesSnapshot = await FirebaseFirestore.instance.collection('courses').get();
      final coursesCount = coursesSnapshot.size;

      double totalRevenue = 0.0;
      for (var userDoc in allUsers) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final enrolledCourses = userData?['enrolledCourses'] ?? [];
        for (var courseId in enrolledCourses) {
          final courseDoc = await FirebaseFirestore.instance.collection('courses').doc(courseId).get();
          final coursePrice = courseDoc.data()?['price']?.toDouble() ?? 0.0;
          totalRevenue += coursePrice;
        }
      }

      setState(() {
        _totalUsers = allUsers.length;
        _coursesAvailable = coursesCount;
        _activeStudents = loggedInUsers;
        _monthlyRevenue = totalRevenue;
        _isLoading = false;
      });

      _controller.forward();
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Helper to build a metric card
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build a BarChartGroupData
  BarChartGroupData _buildBarGroup(int x, double y) {
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
            toY: 100, // Adjust max Y if necessary
            color: Colors.blueAccent.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show a loading indicator while data is being fetched
      return Scaffold(
        appBar: AppBar(
          title: Text('Dashboard Overview'),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Once data is loaded, show the dashboard
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Overview'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Metrics',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Key metrics in a GridView
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard('Total Users',
                    '$_totalUsers', Icons.people, Colors.blue),
                _buildMetricCard('Courses Available',
                    '$_coursesAvailable', Icons.book, Colors.orange),
                _buildMetricCard('Active Students',
                    '$_activeStudents', Icons.school, Colors.green),
                _buildMetricCard('Monthly Revenue',
                    '\RS: ${_monthlyRevenue.toStringAsFixed(2)}', Icons.attach_money, Colors.redAccent),
              ],
            ),

            SizedBox(height: 16),

            Text(
              'User Registrations (Last 6 Months)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Bar Chart
            Container(
              height: 200,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100, // Adjust based on your data's maximum
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            // You can map group.x to actual months
                            // e.g. 0 -> April, 1 -> May, etc.
                            List<String> months = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'];
                            String monthLabel = (group.x >= 0 && group.x < months.length)
                                ? months[group.x]
                                : 'Month';
                            return BarTooltipItem(
                              '$monthLabel\n${rod.toY.toStringAsFixed(0)}',
                              TextStyle(color: Colors.white),
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
                              List<String> months = ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'];
                              if (value.toInt() >= 0 && value.toInt() < months.length) {
                                return Text(
                                  months[value.toInt()],
                                  style: TextStyle(color: Colors.blueAccent),
                                );
                              }
                              return Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
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
          ],
        ),
      ),
    );
  }
}