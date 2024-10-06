import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts

class DashboardOverviewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Overview'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        // Wrap the content in SingleChildScrollView
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
              crossAxisCount: 2, // 2 columns in the grid
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true, // Add shrinkWrap to handle height inside ScrollView
              physics: NeverScrollableScrollPhysics(), // Prevents GridView from scrolling
              children: [
                _buildMetricCard('Total Users', '1,234', Icons.people, Colors.blue),
                _buildMetricCard('Courses Available', '56', Icons.book, Colors.orange),
                _buildMetricCard('Active Students', '789', Icons.school, Colors.green),
                _buildMetricCard('Monthly Revenue', '\$12,345', Icons.attach_money, Colors.redAccent),
              ],
            ),
            SizedBox(height: 16),

            // Bar Chart section
            Text(
              'User Registrations (Last 6 Months)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Bar Chart
            Container(
              height: 200, // Specify a height to prevent overflow
              child: BarChartSample(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create a metric card
  Card _buildMetricCard(String title, String value, IconData icon, Color color) {
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

// Sample Bar Chart using fl_chart package
class BarChartSample extends StatefulWidget {
  @override
  _BarChartSampleState createState() => _BarChartSampleState();
}

class _BarChartSampleState extends State<BarChartSample> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${group.x + 1} Month\n${rod.toY}',
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
                    switch (value.toInt()) {
                      case 0:
                        return Text('Apr', style: TextStyle(color: Colors.blueAccent));
                      case 1:
                        return Text('May', style: TextStyle(color: Colors.blueAccent));
                      case 2:
                        return Text('Jun', style: TextStyle(color: Colors.blueAccent));
                      case 3:
                        return Text('Jul', style: TextStyle(color: Colors.blueAccent));
                      case 4:
                        return Text('Aug', style: TextStyle(color: Colors.blueAccent));
                      case 5:
                        return Text('Sep', style: TextStyle(color: Colors.blueAccent));
                      default:
                        return Text('');
                    }
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true),
              ),
            ),
            barGroups: [
              _buildBarGroup(0, 70 * _animation.value),
              _buildBarGroup(1, 50 * _animation.value),
              _buildBarGroup(2, 80 * _animation.value),
              _buildBarGroup(3, 60 * _animation.value),
              _buildBarGroup(4, 90 * _animation.value),
              _buildBarGroup(5, 75 * _animation.value),
            ],
          ),
        );
      },
    );
  }

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
            toY: 100,
            color: Colors.blueAccent.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
