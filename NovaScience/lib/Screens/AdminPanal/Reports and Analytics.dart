import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';


class ReportsAnalyticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports & Analytics'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('User Registrations'),
              _buildUserRegistrationChart(),
              SizedBox(height: 20),
              _buildSectionTitle('Course Completion Rate'),
              _buildCourseCompletionChart(),
              SizedBox(height: 20),
              _buildSectionTitle('Revenue Trends'),
              _buildRevenueTrendsChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Sample User Registration Chart
  Widget _buildUserRegistrationChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blueAccent.withOpacity(0.5), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    switch (value.toInt()) {
                      case 0:
                        return Text('Jan');
                      case 1:
                        return Text('Feb');
                      case 2:
                        return Text('Mar');
                      case 3:
                        return Text('Apr');
                      case 4:
                        return Text('May');
                      case 5:
                        return Text('Jun');
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
              _buildBarGroup(0, 120),
              _buildBarGroup(1, 80),
              _buildBarGroup(2, 150),
              _buildBarGroup(3, 200),
              _buildBarGroup(4, 180),
              _buildBarGroup(5, 210),
            ],
          ),
        ),
      ),
    );
  }

  // Sample Course Completion Rate Chart
  Widget _buildCourseCompletionChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.greenAccent.withOpacity(0.5), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    switch (value.toInt()) {
                      case 0:
                        return Text('Q1');
                      case 1:
                        return Text('Q2');
                      case 2:
                        return Text('Q3');
                      case 3:
                        return Text('Q4');
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
            gridData: FlGridData(show: true),
            borderData: FlBorderData(show: true),
            minX: 0,
            maxX: 3,
            minY: 0,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: [
                  FlSpot(0, 75), // Q1
                  FlSpot(1, 85), // Q2
                  FlSpot(2, 90), // Q3
                  FlSpot(3, 95), // Q4
                ],
                isCurved: true,
                color: Colors.greenAccent,
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sample Revenue Trends Chart
  Widget _buildRevenueTrendsChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.orangeAccent.withOpacity(0.5), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                value: 30,
                title: 'Course Sales',
                color: Colors.blueAccent,
                radius: 40,
              ),
              PieChartSectionData(
                value: 20,
                title: 'Subscriptions',
                color: Colors.orange,
                radius: 40,
              ),
              PieChartSectionData(
                value: 25,
                title: 'Ads Revenue',
                color: Colors.green,
                radius: 40,
              ),
              PieChartSectionData(
                value: 25,
                title: 'Other',
                color: Colors.redAccent,
                radius: 40,
              ),
            ],
            borderData: FlBorderData(show: false),
            centerSpaceRadius: 40,
            sectionsSpace: 2,
          ),
        ),
      ),
    );
  }

  // Helper method to create a bar group
  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Colors.blueAccent,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
