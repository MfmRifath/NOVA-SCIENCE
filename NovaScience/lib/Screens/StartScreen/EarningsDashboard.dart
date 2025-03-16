import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Service/AuthService.dart';
import '../../Service/CourseProvider.dart';

class EarningsDashboard extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color textDarkColor;
  final Color textLightColor;
  final Color surfaceColor;
  final Color successColor;

  const EarningsDashboard({
    Key? key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.textDarkColor,
    required this.textLightColor,
    required this.surfaceColor,
    required this.successColor,
  }) : super(key: key);

  @override
  _EarningsDashboardState createState() => _EarningsDashboardState();
}

class _EarningsDashboardState extends State<EarningsDashboard> {
  String _selectedPeriod = 'Monthly';
  String _selectedYear = DateTime.now().year.toString();
  bool _isShowingData = false;
  Map<String, double> _periodData = {};

  // For filtering
  List<String> _years = [];
  List<String> _periods = ['Weekly', 'Monthly', 'Quarterly', 'Yearly'];

  double _totalEarnings = 0;
  double _averageMonthlyEarnings = 0;
  double _growthRate = 0;

  @override
  void initState() {
    super.initState();
    _initializeYears();
    Future.delayed(Duration.zero, () {
      _fetchEarningsData();
    });
  }

  void _initializeYears() {
    final currentYear = DateTime.now().year;
    _years = List.generate(3, (index) => (currentYear - index).toString());
  }

  Future<void> _fetchEarningsData() async {
    setState(() => _isShowingData = false);

    final authService = Provider.of<AuthService>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    String? teacherEmail = await authService.getCurrentUserEmail();
    if (teacherEmail == null) return;

    // Get earnings data based on selected period
    Map<String, double> earningsData;

    if (_selectedPeriod == 'Monthly') {
      earningsData = await _fetchMonthlyEarningsForTeacher(teacherEmail, int.parse(_selectedYear));
    } else if (_selectedPeriod == 'Weekly') {
      earningsData = await _fetchWeeklyEarningsForTeacher(teacherEmail, int.parse(_selectedYear));
    } else if (_selectedPeriod == 'Quarterly') {
      earningsData = await _fetchQuarterlyEarningsForTeacher(teacherEmail, int.parse(_selectedYear));
    } else {
      // Yearly
      earningsData = await _fetchYearlyEarningsForTeacher(teacherEmail);
    }

    // Calculate totals and averages
    _totalEarnings = earningsData.values.fold(0, (sum, value) => sum + value);
    _averageMonthlyEarnings = _selectedPeriod == 'Monthly'
        ? earningsData.values.isEmpty ? 0 : _totalEarnings / earningsData.length
        : _totalEarnings / 12;

    // Calculate growth rate based on first and last periods
    if (earningsData.length > 1) {
      final values = earningsData.values.toList();
      final firstValue = values.first;
      final lastValue = values.last;
      if (firstValue > 0) {
        _growthRate = ((lastValue - firstValue) / firstValue) * 100;
      }
    }

    setState(() {
      _periodData = earningsData;
      _isShowingData = true;
    });
  }

  Future<Map<String, double>> _fetchMonthlyEarningsForTeacher(String teacherEmail, int year) async {
    // This method would actually interact with your Firestore database
    // For demo, we're using a placeholder implementation

    // This would be replaced with a real Firestore query to get monthly earnings for this teacher
    // similar to your existing _fetchMonthlyEarningsForTeacher method but filtering by year

    Map<String, double> monthlyEarnings = {};

    // Get courses by this teacher
    final courseSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: teacherEmail)
        .get();

    final Map<String, double> teacherCourses = {};
    for (var doc in courseSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final priceValue = data['price'] ?? 0.0;
      final double coursePrice = double.tryParse(priceValue.toString()) ?? 0.0;
      teacherCourses[doc.id] = coursePrice;
    }

    // Get enrollments
    final userSnapshot = await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final List<dynamic>? enrolledCourses = userData['enrolledCourses'];
      if (enrolledCourses == null) continue;

      for (var enrolled in enrolledCourses) {
        if (enrolled is Map<String, dynamic>) {
          final String? cId = enrolled['courseId'];
          if (cId != null && teacherCourses.containsKey(cId)) {
            final Timestamp? ts = enrolled['enrollmentDate'];
            if (ts == null) continue;
            final date = ts.toDate();

            // Only include enrollments from the selected year
            if (date.year != year) continue;

            final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            final double price = teacherCourses[cId] ?? 0.0;
            monthlyEarnings.update(
              monthKey,
                  (existing) => existing + price,
              ifAbsent: () => price,
            );
          }
        }
      }
    }

    // Sort by month
    final sortedKeys = monthlyEarnings.keys.toList()..sort();
    final sortedMap = Map<String, double>.fromEntries(
        sortedKeys.map((key) => MapEntry(key, monthlyEarnings[key]!))
    );

    return sortedMap;
  }

  Future<Map<String, double>> _fetchWeeklyEarningsForTeacher(String teacherEmail, int year) async {
    // Simplified implementation for weekly earnings
    // In a real app, you would group by week number
    Map<String, double> weeklyData = {};
    // ... implement actual Firestore logic similar to monthly but grouped by week

    // Placeholder data for demo
    for (int i = 1; i <= 52; i++) {
      final weekKey = 'Week $i';
      weeklyData[weekKey] = 2000 + (i * 50) + (Random().nextDouble() * 1000);
    }

    return weeklyData;
  }

  Future<Map<String, double>> _fetchQuarterlyEarningsForTeacher(String teacherEmail, int year) async {
    // Get monthly data and aggregate by quarter
    final monthlyData = await _fetchMonthlyEarningsForTeacher(teacherEmail, year);

    Map<String, double> quarterlyData = {
      'Q1': 0.0,
      'Q2': 0.0,
      'Q3': 0.0,
      'Q4': 0.0,
    };

    monthlyData.forEach((month, value) {
      final monthNum = int.parse(month.split('-')[1]);
      if (monthNum <= 3) {
        quarterlyData['Q1'] = (quarterlyData['Q1'] ?? 0) + value;
      } else if (monthNum <= 6) {
        quarterlyData['Q2'] = (quarterlyData['Q2'] ?? 0) + value;
      } else if (monthNum <= 9) {
        quarterlyData['Q3'] = (quarterlyData['Q3'] ?? 0) + value;
      } else {
        quarterlyData['Q4'] = (quarterlyData['Q4'] ?? 0) + value;
      }
    });

    return quarterlyData;
  }

  Future<Map<String, double>> _fetchYearlyEarningsForTeacher(String teacherEmail) async {
    Map<String, double> yearlyData = {};

    // Get courses by this teacher
    final courseSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: teacherEmail)
        .get();

    final Map<String, double> teacherCourses = {};
    for (var doc in courseSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final priceValue = data['price'] ?? 0.0;
      final double coursePrice = double.tryParse(priceValue.toString()) ?? 0.0;
      teacherCourses[doc.id] = coursePrice;
    }

    // Get enrollments
    final userSnapshot = await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final List<dynamic>? enrolledCourses = userData['enrolledCourses'];
      if (enrolledCourses == null) continue;

      for (var enrolled in enrolledCourses) {
        if (enrolled is Map<String, dynamic>) {
          final String? cId = enrolled['courseId'];
          if (cId != null && teacherCourses.containsKey(cId)) {
            final Timestamp? ts = enrolled['enrollmentDate'];
            if (ts == null) continue;
            final date = ts.toDate();

            final yearKey = date.year.toString();
            final double price = teacherCourses[cId] ?? 0.0;
            yearlyData.update(
              yearKey,
                  (existing) => existing + price,
              ifAbsent: () => price,
            );
          }
        }
      }
    }

    // Sort by year
    final sortedKeys = yearlyData.keys.toList()..sort();
    final sortedMap = Map<String, double>.fromEntries(
        sortedKeys.map((key) => MapEntry(key, yearlyData[key]!))
    );

    return sortedMap;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: widget.secondaryColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEarningsHeader(),
            SizedBox(height: 20),
            _buildEarningsFilter(),
            SizedBox(height: 20),
            _buildEarningsStats(),
            SizedBox(height: 20),
            _buildEarningsChart(),
            SizedBox(height: 20),
            _buildEarningsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: widget.accentColor,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Earnings Analytics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: widget.primaryColor,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Export earnings data functionality
          },
          icon: Icon(Icons.download_outlined, size: 16),
          label: Text(
            'Export',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.surfaceColor,
            foregroundColor: widget.secondaryColor,
            elevation: 0,
            side: BorderSide(color: widget.secondaryColor.withOpacity(0.3)),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.secondaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Time period selector
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time Period',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.textDarkColor.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.secondaryColor, width: 1.5),
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: widget.textDarkColor,
                  ),
                  items: _periods.map((period) {
                    return DropdownMenuItem<String>(
                      value: period,
                      child: Text(period),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                      _fetchEarningsData();
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          // Year selector
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Year',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.textDarkColor.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedYear,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: widget.secondaryColor, width: 1.5),
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: widget.textDarkColor,
                  ),
                  items: _years.map((year) {
                    return DropdownMenuItem<String>(
                      value: year,
                      child: Text(year),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedYear = value;
                      });
                      _fetchEarningsData();
                    }
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          // Apply button
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: ElevatedButton(
              onPressed: _fetchEarningsData,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: widget.textLightColor,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Apply',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsStats() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.secondaryColor.withOpacity(0.05),
            widget.accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.accentColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            title: 'Total Earnings',
            value: 'Rs. ${_totalEarnings.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet_outlined,
            color: widget.successColor,
          ),
          _buildStatItem(
            title: 'Avg. Monthly',
            value: 'Rs. ${_averageMonthlyEarnings.toStringAsFixed(2)}',
            icon: Icons.trending_up_outlined,
            color: widget.secondaryColor,
          ),
          _buildStatItem(
            title: 'Growth',
            value: '${_growthRate.toStringAsFixed(1)}%',
            icon: _growthRate >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            color: _growthRate >= 0 ? widget.successColor : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: widget.textDarkColor,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: widget.textDarkColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsChart() {
    if (!_isShowingData) {
      return Container(
        height: 250,
        child: Center(
          child: CircularProgressIndicator(
            color: widget.secondaryColor,
          ),
        ),
      );
    }

    if (_periodData.isEmpty) {
      return Container(
        height: 250,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 48,
                color: widget.textDarkColor.withOpacity(0.3),
              ),
              SizedBox(height: 16),
              Text(
                'No earnings data available for this period',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: widget.textDarkColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0, top: 16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _periodData.values.isEmpty ? 100 : _periodData.values.reduce((a, b) => a > b ? a : b) * 1.2,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        'Rs.${value.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: widget.textDarkColor.withOpacity(0.6),
                        ),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < _periodData.length) {
                      final label = _getFormattedLabel(_periodData.keys.elementAt(value.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: widget.textDarkColor.withOpacity(0.6),
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                  reservedSize: 30,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              horizontalInterval: _periodData.values.isEmpty ? 20 : _periodData.values.reduce((a, b) => a > b ? a : b) / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.15),
                  strokeWidth: 1,
                );
              },
            ),
            barGroups: List.generate(
              _periodData.length,
                  (index) {
                final value = _periodData.values.elementAt(index);
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      color: widget.secondaryColor,
                      width: 12,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: _periodData.values.isEmpty ? 100 : _periodData.values.reduce((a, b) => a > b ? a : b) * 1.2,
                        color: widget.surfaceColor,
                      ),
                    ),
                  ],
                );
              },
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final key = _periodData.keys.elementAt(group.x.toInt());
                  final value = _periodData.values.elementAt(group.x.toInt());
                  return BarTooltipItem(
                    '$key\nRs. ${value.toStringAsFixed(2)}',
                    GoogleFonts.poppins(
                      color: widget.textLightColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getFormattedLabel(String key) {
    if (_selectedPeriod == 'Monthly') {
      final parts = key.split('-');
      if (parts.length == 2) {
        final month = int.tryParse(parts[1]);
        if (month != null) {
          return DateFormat('MMM').format(DateTime(2021, month, 1));
        }
      }
      return key;
    } else if (_selectedPeriod == 'Weekly') {
      return key.replaceAll('Week ', 'W');
    }
    return key;
  }

  Widget _buildEarningsTable() {
    if (!_isShowingData || _periodData.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.secondaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Period',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Revenue',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Enrollments',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Change',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table rows
          Container(
            height: 250,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: _periodData.length,
              separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final period = _periodData.keys.elementAt(index);
                final value = _periodData.values.elementAt(index);

                // Calculate enrollment estimate based on average course price
                final avgCoursePrice = 1000.0; // This would be calculated in real app
                final estEnrollments = (value / avgCoursePrice).round();

                // Calculate change percentage from previous period
                double changePercent = 0;
                if (index > 0) {
                  final prevValue = _periodData.values.elementAt(index - 1);
                  if (prevValue > 0) {
                    changePercent = ((value - prevValue) / prevValue) * 100;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _getFormattedTableLabel(period),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: widget.textDarkColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Rs. ${value.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: widget.textDarkColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          estEnrollments.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: widget.textDarkColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              changePercent >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 12,
                              color: changePercent >= 0
                                  ? widget.successColor
                                  : Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${changePercent.abs().toStringAsFixed(1)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: changePercent >= 0
                                    ? widget.successColor
                                    : Colors.red,
                              ),
                            ),
                          ],
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
    );
  }

  String _getFormattedTableLabel(String period) {
    if (_selectedPeriod == 'Monthly') {
      final parts = period.split('-');
      if (parts.length == 2) {
        final month = int.tryParse(parts[1]);
        if (month != null) {
          return DateFormat('MMMM').format(DateTime(2021, month, 1));
        }
      }
    }
    return period;
  }
}

// You can add this to your TeacherScreen by adding the EarningsDashboard widget in the dashboard tab
// Example usage:
// EarningsDashboard(
//   primaryColor: primaryColor,
//   secondaryColor: secondaryColor,
//   accentColor: accentColor,
//   textDarkColor: textDarkColor,
//   textLightColor: textLightColor,
//   surfaceColor: surfaceColor,
//   successColor: successColor,
// ),