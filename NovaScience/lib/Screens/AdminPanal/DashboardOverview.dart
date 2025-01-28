import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Chart data (e.g., for the last 6 months).
  // This will store the registration count per month in an array.
  List<double> _monthlyRegistrations = [0, 0, 0, 0, 0, 0];

  // For bar chart animation
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isLoading = true; // For indicating data is still loading

  @override
  void initState() {
    super.initState();

    // Initialize your animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // Fetch data from Firestore (async)
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // 1) Fetch total users
      // Assume you have a "users" collection. The size of the snapshot is the total user count.
      final usersSnapshot =
      await FirebaseFirestore.instance.collection('users').get();
      final totalUsersCount = usersSnapshot.size;

      // 2) Fetch total courses
      // Assume you have a "courses" collection
      final coursesSnapshot =
      await FirebaseFirestore.instance.collection('courses').get();
      final coursesCount = coursesSnapshot.size;

      // 3) Fetch active students
      // Suppose "active" is a boolean field on the "students" collection
      final activeStudentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('active', isEqualTo: true)
          .get();
      final activeStudentsCount = activeStudentsSnapshot.size;

      // 4) Fetch monthly revenue (this could be a single doc or aggregated from multiple docs)
      // Let's assume it's a single doc in a "stats" collection with a "monthlyRevenue" field
      final revenueDoc = await FirebaseFirestore.instance
          .collection('stats')
          .doc('revenue')
          .get();
      final monthlyRevenue =
          revenueDoc.data()?['monthlyRevenue']?.toDouble() ?? 0.0;

      // 5) Fetch monthly registrations for the last 6 months
      // We will assume you have a "registrations" collection with a "month" field (0 to 11),
      // or a timestamp to derive the month. Here we demonstrate a simplified approach.
      // For the last 6 months:  (4=April, 5=May, 6=June, 7=July, 8=August, 9=September)
      List<double> monthlyRegs = [0, 0, 0, 0, 0, 0];
      final registrationsSnapshot = await FirebaseFirestore.instance
          .collection('registrations')
      // Only fetch the months we care about (Apr=4, ..., Sep=9 in example)
          .where('month', whereIn: [4, 5, 6, 7, 8, 9])
          .get();

      // Count how many documents belong to each month
      for (var doc in registrationsSnapshot.docs) {
        int month = doc.data()['month'] ?? 0; // e.g. 4 for April
        // Put them in an index: April=0, May=1, June=2, July=3, August=4, September=5
        int index = month - 4; // So that 4 -> 0, 5 -> 1, ...
        if (index >= 0 && index < 6) {
          monthlyRegs[index]++;
        }
      }

      // Once all is fetched, update the state
      setState(() {
        _totalUsers = totalUsersCount;
        _coursesAvailable = coursesCount;
        _activeStudents = activeStudentsCount;
        _monthlyRevenue = monthlyRevenue;
        _monthlyRegistrations = monthlyRegs;
        _isLoading = false;
      });

      // Start the chart animation
      _controller.forward();
    } catch (e) {
      print('Error fetching data: $e');
      // Handle any errors or show a message accordingly
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
                    '\$${_monthlyRevenue.toStringAsFixed(2)}', Icons.attach_money, Colors.redAccent),
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