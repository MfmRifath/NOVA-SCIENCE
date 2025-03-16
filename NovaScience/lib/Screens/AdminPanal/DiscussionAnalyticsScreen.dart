import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../StartScreen/AppTheme.dart';

class DiscussionAnalyticsScreen extends StatefulWidget {
  @override
  _DiscussionAnalyticsScreenState createState() => _DiscussionAnalyticsScreenState();
}

class _DiscussionAnalyticsScreenState extends State<DiscussionAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _timeRange = 'week'; // 'day', 'week', 'month', 'year'
  String _selectedCategory = 'All Categories';

  // Analytics data
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _dailyActivity = [];
  List<Map<String, dynamic>> _topGroups = [];
  List<Map<String, dynamic>> _categoryDistribution = [];
  List<Map<String, dynamic>> _userEngagement = [];

  final List<String> _categories = [
    'All Categories',
    'Science Stream',
    'Arts Stream',
    'Commerce Stream',
    'Technology Stream',
    'O/L',
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadSummary(),
        _loadDailyActivity(),
        _loadTopGroups(),
        _loadCategoryDistribution(),
        _loadUserEngagement(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSummary() async {
    try {
      // Get all groups
      Query groupsQuery = _firestore.collection('discussion_groups');

      if (_selectedCategory != 'All Categories') {
        groupsQuery = groupsQuery.where('category', isEqualTo: _selectedCategory);
      }

      QuerySnapshot groupsSnapshot = await groupsQuery.get();

      // Calculate total groups
      int totalGroups = groupsSnapshot.docs.length;

      // Calculate total members and messages
      int totalMembers = 0;
      int totalMessages = 0;
      Set<String> uniqueUsers = Set();

      for (var doc in groupsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalMembers += (data['memberCount'] as num?)?.toInt() ?? 0;
        totalMessages += (data['messageCount'] as num?)?.toInt() ?? 0;

        // Get member list for unique user count
        List<dynamic> members = data['members'] ?? [];
        uniqueUsers.addAll(members.cast<String>());
      }

      // Get date range based on selected time range
      DateTime now = DateTime.now();
      DateTime startDate;

      switch (_timeRange) {
        case 'day':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 1));
          break;
        case 'week':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 30));
          break;
        case 'year':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 365));
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 7));
      }

      // Get messages in date range
      int newMessages = 0;

      for (var groupDoc in groupsSnapshot.docs) {
        QuerySnapshot messagesSnapshot = await _firestore
            .collection('discussion_groups')
            .doc(groupDoc.id)
            .collection('messages')
            .where('timestamp', isGreaterThan: startDate)
            .get();

        newMessages += messagesSnapshot.docs.length;
      }

      // Get active users in date range
      QuerySnapshot activeUsersSnapshot = await _firestore
          .collection('users')
          .where('lastActiveTime', isGreaterThan: startDate)
          .get();

      int activeUsers = activeUsersSnapshot.docs.length;

      // Get number of new groups created in date range
      QuerySnapshot newGroupsSnapshot = await _firestore
          .collection('discussion_groups')
          .where('createdAt', isGreaterThan: startDate)
          .get();

      int newGroups = newGroupsSnapshot.docs.length;

      setState(() {
        _summary = {
          'totalGroups': totalGroups,
          'totalMembers': totalMembers,
          'totalMessages': totalMessages,
          'uniqueUsers': uniqueUsers.length,
          'newMessages': newMessages,
          'activeUsers': activeUsers,
          'newGroups': newGroups,
          'messagesPerDay': newMessages / _getDaysInRange(_timeRange),
          'timeRange': _getTimeRangeText(_timeRange),
        };
      });
    } catch (e) {
      print('Error loading summary: $e');
    }
  }

  Future<void> _loadDailyActivity() async {
    try {
      // Get date range based on selected time range
      DateTime now = DateTime.now();
      DateTime startDate;
      int days = _getDaysInRange(_timeRange);

      switch (_timeRange) {
        case 'day':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 1));
          break;
        case 'week':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 30));
          break;
        case 'year':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 365));
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 7));
      }

      // Create date bins
      List<DateTime> dateBins = [];
      for (int i = 0; i <= days; i++) {
        dateBins.add(startDate.add(Duration(days: i)));
      }

      // Initialize activity data
      List<Map<String, dynamic>> dailyActivity = [];
      for (int i = 0; i < dateBins.length; i++) {
        dailyActivity.add({
          'date': dateBins[i],
          'messages': 0,
          'activeUsers': 0,
        });
      }

      // Get all groups
      Query groupsQuery = _firestore.collection('discussion_groups');

      if (_selectedCategory != 'All Categories') {
        groupsQuery = groupsQuery.where('category', isEqualTo: _selectedCategory);
      }

      QuerySnapshot groupsSnapshot = await groupsQuery.get();

      // Get messages per day
      for (var groupDoc in groupsSnapshot.docs) {
        for (int i = 0; i < dateBins.length - 1; i++) {
          DateTime dayStart = dateBins[i];
          DateTime dayEnd = dateBins[i + 1];

          QuerySnapshot messagesSnapshot = await _firestore
              .collection('discussion_groups')
              .doc(groupDoc.id)
              .collection('messages')
              .where('timestamp', isGreaterThanOrEqualTo: dayStart)
              .where('timestamp', isLessThan: dayEnd)
              .get();

          dailyActivity[i]['messages'] += messagesSnapshot.docs.length;

          // Count unique users who sent messages on this day
          Set<String> usersOnDay = Set();
          for (var messageDoc in messagesSnapshot.docs) {
            Map<String, dynamic> messageData = messageDoc.data() as Map<String, dynamic>;
            String senderId = messageData['senderId'] ?? '';
            if (senderId.isNotEmpty) {
              usersOnDay.add(senderId);
            }
          }

          dailyActivity[i]['activeUsers'] += usersOnDay.length;
        }
      }

      setState(() {
        _dailyActivity = dailyActivity;
      });
    } catch (e) {
      print('Error loading daily activity: $e');
    }
  }

  Future<void> _loadTopGroups() async {
    try {
      // Get all groups
      Query groupsQuery = _firestore.collection('discussion_groups');

      if (_selectedCategory != 'All Categories') {
        groupsQuery = groupsQuery.where('category', isEqualTo: _selectedCategory);
      }

      groupsQuery = groupsQuery.orderBy('messageCount', descending: true).limit(5);

      QuerySnapshot groupsSnapshot = await groupsQuery.get();

      List<Map<String, dynamic>> topGroups = [];

      for (var doc in groupsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        topGroups.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Group',
          'category': data['category'] ?? '',
          'memberCount': data['memberCount'] ?? 0,
          'messageCount': data['messageCount'] ?? 0,
          'lastMessageTime': data['lastMessageTime'] != null
              ? (data['lastMessageTime'] as Timestamp).toDate()
              : null,
        });
      }

      setState(() {
        _topGroups = topGroups;
      });
    } catch (e) {
      print('Error loading top groups: $e');
    }
  }

  Future<void> _loadCategoryDistribution() async {
    try {
      // Count groups by category
      Map<String, int> categoryCounts = {};

      for (var category in _categories.where((c) => c != 'All Categories')) {
        QuerySnapshot snapshot = await _firestore
            .collection('discussion_groups')
            .where('category', isEqualTo: category)
            .get();

        categoryCounts[category] = snapshot.docs.length;
      }

      List<Map<String, dynamic>> categoryDistribution = [];

      categoryCounts.forEach((category, count) {
        categoryDistribution.add({
          'category': category,
          'count': count,
        });
      });

      setState(() {
        _categoryDistribution = categoryDistribution;
      });
    } catch (e) {
      print('Error loading category distribution: $e');
    }
  }

  Future<void> _loadUserEngagement() async {
    try {
      // Get date range based on selected time range
      DateTime now = DateTime.now();
      DateTime startDate;

      switch (_timeRange) {
        case 'day':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 1));
          break;
        case 'week':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 30));
          break;
        case 'year':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 365));
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 7));
      }

      // Get all users
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

      // Get all groups
      Query groupsQuery = _firestore.collection('discussion_groups');

      if (_selectedCategory != 'All Categories') {
        groupsQuery = groupsQuery.where('category', isEqualTo: _selectedCategory);
      }

      QuerySnapshot groupsSnapshot = await groupsQuery.get();

      // Count messages per user
      Map<String, int> userMessageCounts = {};
      Map<String, String> userNames = {};

      for (var userDoc in usersSnapshot.docs) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userNames[userDoc.id] = userData['name'] ?? 'Unknown';
        userMessageCounts[userDoc.id] = 0;
      }

      for (var groupDoc in groupsSnapshot.docs) {
        QuerySnapshot messagesSnapshot = await _firestore
            .collection('discussion_groups')
            .doc(groupDoc.id)
            .collection('messages')
            .where('timestamp', isGreaterThan: startDate)
            .get();

        for (var messageDoc in messagesSnapshot.docs) {
          Map<String, dynamic> messageData = messageDoc.data() as Map<String, dynamic>;
          String senderId = messageData['senderId'] ?? '';

          if (senderId.isNotEmpty && userMessageCounts.containsKey(senderId)) {
            userMessageCounts[senderId] = (userMessageCounts[senderId] ?? 0) + 1;
          }
        }
      }

      // Convert to list and sort by message count
      List<Map<String, dynamic>> userEngagement = [];

      userMessageCounts.forEach((userId, messageCount) {
        if (messageCount > 0) {
          userEngagement.add({
            'userId': userId,
            'name': userNames[userId] ?? 'Unknown',
            'messageCount': messageCount,
          });
        }
      });

      userEngagement.sort((a, b) => b['messageCount'].compareTo(a['messageCount']));

      // Take top 10
      if (userEngagement.length > 10) {
        userEngagement = userEngagement.sublist(0, 10);
      }

      setState(() {
        _userEngagement = userEngagement;
      });
    } catch (e) {
      print('Error loading user engagement: $e');
    }
  }

  int _getDaysInRange(String timeRange) {
    switch (timeRange) {
      case 'day':
        return 1;
      case 'week':
        return 7;
      case 'month':
        return 30;
      case 'year':
        return 365;
      default:
        return 7;
    }
  }

  String _getTimeRangeText(String timeRange) {
    switch (timeRange) {
      case 'day':
        return 'Past 24 Hours';
      case 'week':
        return 'Past Week';
      case 'month':
        return 'Past 30 Days';
      case 'year':
        return 'Past Year';
      default:
        return 'Past Week';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Determine layout based on available width
              bool isWideScreen = constraints.maxWidth > 900;
              bool isMediumScreen = constraints.maxWidth > 600 && constraints.maxWidth <= 900;

              // For summary cards, adjust column count based on screen width
              int summaryCardColumns = isWideScreen ? 4 : (isMediumScreen ? 2 : 1);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilters(),
                  SizedBox(height: 24),

                  // Make summary cards responsive
                  _buildSummaryCards(summaryCardColumns),

                  SizedBox(height: 24),
                  _buildActivityChart(),
                  SizedBox(height: 24),
                  _buildTopGroups(),
                  SizedBox(height: 24),

                  // Responsive layout for distribution and engagement
                  if (isWideScreen)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 300, // Fixed height for large screens
                            child: _buildCategoryDistribution(),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 300, // Fixed height for large screens
                            child: _buildUserEngagement(),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        SizedBox(
                          height: 250, // Smaller height for small screens
                          child: _buildCategoryDistribution(),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          height: 250, // Smaller height for small screens
                          child: _buildUserEngagement(),
                        ),
                      ],
                    ),
                  SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Analytics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 16),
          // Implement responsive layout for filters
          LayoutBuilder(
            builder: (context, constraints) {
              // Use vertical layout on smaller screens
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _buildTimeRangeDropdown(),
                    SizedBox(height: 16),
                    _buildCategoryDropdown(),
                  ],
                );
              } else {
                // Use horizontal layout on wider screens
                return Row(
                  children: [
                    Expanded(child: _buildTimeRangeDropdown()),
                    SizedBox(width: 16),
                    Expanded(child: _buildCategoryDropdown()),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Extract dropdowns to separate methods for cleaner code
  Widget _buildTimeRangeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Range:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true, // This fixes the overflow
          value: _timeRange,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: [
            DropdownMenuItem(value: 'day', child: Text('Last 24 Hours')),
            DropdownMenuItem(value: 'week', child: Text('Last Week')),
            DropdownMenuItem(value: 'month', child: Text('Last 30 Days')),
            DropdownMenuItem(value: 'year', child: Text('Last Year')),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _timeRange = newValue;
              });
              _loadAnalytics();
            }
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true, // This fixes the overflow
          value: _selectedCategory,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
              });
              _loadAnalytics();
            }
          },
        ),
      ],
    );
  }

  // Updated summary cards to take column count as parameter
  Widget _buildSummaryCards(int columnCount) {
    return GridView.count(
      crossAxisCount: columnCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      childAspectRatio: 1.5, // Make cards shorter and wider
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryCard(
          title: 'Total Groups',
          value: _summary['totalGroups']?.toString() ?? '0',
          subValue: '+${_summary['newGroups']?.toString() ?? '0'} in ${_summary['timeRange']}',
          icon: Icons.group_work_outlined,
          color: Colors.blue,
        ),
        _buildSummaryCard(
          title: 'Total Members',
          value: _summary['totalMembers']?.toString() ?? '0',
          subValue: '${_summary['uniqueUsers']?.toString() ?? '0'} unique users',
          icon: Icons.people_outline,
          color: Colors.green,
        ),
        _buildSummaryCard(
          title: 'Total Messages',
          value: _summary['totalMessages']?.toString() ?? '0',
          subValue: '+${_summary['newMessages']?.toString() ?? '0'} in ${_summary['timeRange']}',
          icon: Icons.message_outlined,
          color: Colors.purple,
        ),
        _buildSummaryCard(
          title: 'Active Users',
          value: _summary['activeUsers']?.toString() ?? '0',
          subValue: 'in ${_summary['timeRange']}',
          icon: Icons.person_outline,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Use minimum space
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subValue,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      height: 400,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Over Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Messages and active users in ${_summary['timeRange']}',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: _dailyActivity.isEmpty
                ? Center(
              child: Text(
                'No activity data available',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            )
                : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _dailyActivity.length) {
                          DateTime date = _dailyActivity[value.toInt()]['date'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 10,
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
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
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
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                minX: 0,
                maxX: _dailyActivity.length.toDouble() - 1,
                minY: 0,
                maxY: _getMaxValue(_dailyActivity),
                lineBarsData: [
                  _getMessagesLineChartBarData(),
                  _getActiveUsersLineChartBarData(),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        String label = touchedSpot.barIndex == 0 ? 'Messages' : 'Active Users';
                        return LineTooltipItem(
                          '$label: ${touchedSpot.y.toInt()}',
                          TextStyle(
                            color: touchedSpot.barIndex == 0 ? Colors.blue : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          // Fix: Wrap in SingleChildScrollView to prevent overflow
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegendItem('Messages', Colors.blue),
                SizedBox(width: 24),
                _buildChartLegendItem('Active Users', Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  double _getMaxValue(List<Map<String, dynamic>> data) {
    double maxMessages = 0;
    double maxUsers = 0;

    for (var item in data) {
      if (item['messages'] > maxMessages) {
        maxMessages = item['messages'].toDouble();
      }
      if (item['activeUsers'] > maxUsers) {
        maxUsers = item['activeUsers'].toDouble();
      }
    }

    return maxMessages > maxUsers ? maxMessages * 1.2 : maxUsers * 1.2;
  }

  LineChartBarData _getMessagesLineChartBarData() {
    List<FlSpot> spots = [];

    for (int i = 0; i < _dailyActivity.length; i++) {
      spots.add(FlSpot(i.toDouble(), _dailyActivity[i]['messages'].toDouble()));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.blue,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: Colors.blue.withOpacity(0.2),
      ),
    );
  }

  LineChartBarData _getActiveUsersLineChartBarData() {
    List<FlSpot> spots = [];

    for (int i = 0; i < _dailyActivity.length; i++) {
      spots.add(FlSpot(i.toDouble(), _dailyActivity[i]['activeUsers'].toDouble()));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.orange,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: Colors.orange.withOpacity(0.2),
      ),
    );
  }

  Widget _buildTopGroups() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Active Groups',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Groups with highest message count',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 16),
          _topGroups.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No groups found',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          )
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              columnWidths: {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(2),
              },
              border: TableBorder.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                  ),
                  children: [
                    _buildTableHeader('Group Name'),
                    _buildTableHeader('Category'),
                    _buildTableHeader('Members'),
                    _buildTableHeader('Messages'),
                    _buildTableHeader('Last Activity'),
                  ],
                ),
                ..._topGroups.map((group) {
                  return TableRow(
                    children: [
                      _buildTableCell(group['name']),
                      _buildTableCell(group['category']),
                      _buildTableCell(group['memberCount'].toString()),
                      _buildTableCell(group['messageCount'].toString()),
                      _buildTableCell(
                        group['lastMessageTime'] != null
                            ? _formatTimeAgo(group['lastMessageTime'])
                            : 'N/A',
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: AppTheme.textPrimaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondaryColor,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }

  Widget _buildCategoryDistribution() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Groups by category',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8), // Reduced from 16

          // Give the chart a flexible but constrained height
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate height based on available space
              double chartHeight = constraints.maxHeight > 300
                  ? 200
                  : constraints.maxHeight * 0.5;

              return SizedBox(
                height: chartHeight,
                child: _categoryDistribution.isEmpty
                    ? Center(
                  child: Text(
                    'No category data available',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                )
                    : PieChart(
                  PieChartData(
                    sections: _getCategoryPieChartSections(),
                    centerSpaceRadius: 30, // Reduced from 40
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                    pieTouchData: PieTouchData(),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 8), // Reduced from 16

          // Make the legend scrollable with constraints
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _categoryDistribution
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0), // Reduced padding
                    child: Row(
                      // Make sure the row items fit or wrap
                      mainAxisSize: MainAxisSize.min, // Use minimum space
                      children: [
                        Container(
                          width: 8, // Reduced from 12
                          height: 8, // Reduced from 12
                          decoration: BoxDecoration(
                            color: _getCategoryColor(entry.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4), // Reduced from 8
                        // Limit text width and add ellipsis for long category names
                        Expanded(
                          child: Text(
                            entry.value['category'],
                            style: TextStyle(
                              fontSize: 10, // Reduced from 12
                              color: AppTheme.textSecondaryColor,
                            ),
                            overflow: TextOverflow.ellipsis, // Add ellipsis
                            maxLines: 1, // Limit to one line
                          ),
                        ),
                        SizedBox(width: 4), // Added spacing
                        // Constrain count text
                        Text(
                          '${entry.value['count']}',
                          style: TextStyle(
                            fontSize: 10, // Reduced from 12
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getCategoryPieChartSections() {
    int total = _categoryDistribution.fold(0, (sum, item) => sum + (item['count'] as int));

    return _categoryDistribution.asMap().entries.map((entry) {
      final item = entry.value;
      final index = entry.key;
      final double percentage = total > 0 ? (item['count'] / total) * 100 : 0;

      return PieChartSectionData(
        color: _getCategoryColor(index),
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 80, // Reduced from 100
        titleStyle: TextStyle(
          fontSize: 10, // Reduced from 12
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(int index) {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    return colors[index % colors.length];
  }

  Widget _buildUserEngagement() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Contributors',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Users with most messages in ${_summary['timeRange']}',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8), // Reduced from 16

          _userEngagement.isEmpty
              ? Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No user engagement data available',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          )
              : Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _userEngagement
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0), // Reduced from 8.0
                    child: _buildUserEngagementItem(
                      entry.key + 1,
                      entry.value['name'],
                      entry.value['messageCount'],
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserEngagementItem(int rank, String name, int messageCount) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Use minimum space
        children: [
          Container(
            width: 20, // Reduced from 24
            height: 20, // Reduced from 24
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3 ? Colors.blue : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10, // Reduced from 12
              ),
            ),
          ),
          SizedBox(width: 8), // Reduced from 12
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12, // Reduced from 14
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              overflow: TextOverflow.ellipsis, // Add ellipsis
              maxLines: 1, // Limit to one line
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$messageCount msg',  // Shortened "messages" to "msg"
              style: TextStyle(
                fontSize: 10, // Reduced from 12
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}