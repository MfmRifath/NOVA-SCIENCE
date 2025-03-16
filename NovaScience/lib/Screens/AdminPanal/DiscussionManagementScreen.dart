import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../StartScreen/AppTheme.dart';
import 'DiscussionAnalyticsScreen.dart';
import 'GroupManagementScreen.dart';
import 'MessageModerationScreen.dart';
import 'ReportedContentScreen.dart';


class DiscussionManagementScreen extends StatefulWidget {
  @override
  _DiscussionManagementScreenState createState() => _DiscussionManagementScreenState();
}

class _DiscussionManagementScreenState extends State<DiscussionManagementScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedCategory = 'All Categories';
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentGroups = [];
  List<Map<String, dynamic>> _reportedContent = [];
  List<Map<String, dynamic>> _activeUsers = [];

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
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load dashboard stats
      await _loadStats();

      // Load recent groups
      await _loadRecentGroups();

      // Load reported content
      await _loadReportedContent();

      // Load active users
      await _loadActiveUsers();
    } catch (e) {
      print('Error loading management data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    // Get all groups count
    QuerySnapshot groupsSnapshot;

    if (_selectedCategory == 'All Categories') {
      groupsSnapshot = await _firestore
          .collection('discussion_groups')
          .get();
    } else {
      groupsSnapshot = await _firestore
          .collection('discussion_groups')
          .where('category', isEqualTo: _selectedCategory)
          .get();
    }

    int totalGroups = groupsSnapshot.docs.length;

    // Calculate total members and messages
    int totalMembers = 0;
    int totalMessages = 0;

    for (var doc in groupsSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      totalMembers += (data['memberCount'] as num?)?.toInt() ?? 0;
      totalMessages += (data['messageCount'] as num?)?.toInt() ?? 0;
    }

    // Get active users in the last 24 hours
    final yesterday = DateTime.now().subtract(Duration(hours: 24));

    QuerySnapshot activeUsersSnapshot = await _firestore
        .collection('users')
        .where('lastActiveTime', isGreaterThan: yesterday)
        .get();

    // Get reported content count
    QuerySnapshot reportedContentSnapshot = await _firestore
        .collection('reported_content')
        .where('status', isEqualTo: 'pending')
        .get();

    setState(() {
      _stats = {
        'totalGroups': totalGroups,
        'totalMembers': totalMembers,
        'totalMessages': totalMessages,
        'activeUsers': activeUsersSnapshot.docs.length,
        'reportedContent': reportedContentSnapshot.docs.length,
      };
    });
  }

  Future<void> _loadRecentGroups() async {
    QuerySnapshot snapshot;

    if (_selectedCategory == 'All Categories') {
      snapshot = await _firestore
          .collection('discussion_groups')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
    } else {
      snapshot = await _firestore
          .collection('discussion_groups')
          .where('category', isEqualTo: _selectedCategory)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
    }

    List<Map<String, dynamic>> groups = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      groups.add({
        'id': doc.id,
        'name': data['name'] ?? 'Unknown Group',
        'category': data['category'] ?? 'Uncategorized',
        'memberCount': data['memberCount'] ?? 0,
        'messageCount': data['messageCount'] ?? 0,
        'createdAt': data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        'creatorName': data['creatorName'] ?? 'Unknown',
      });
    }

    setState(() {
      _recentGroups = groups;
    });
  }

  Future<void> _loadReportedContent() async {
    QuerySnapshot snapshot = await _firestore
        .collection('reported_content')
        .where('status', isEqualTo: 'pending')
        .orderBy('reportedAt', descending: true)
        .limit(5)
        .get();

    List<Map<String, dynamic>> reports = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      reports.add({
        'id': doc.id,
        'contentType': data['contentType'] ?? 'Unknown',
        'contentId': data['contentId'] ?? '',
        'groupId': data['groupId'] ?? '',
        'groupName': data['groupName'] ?? 'Unknown Group',
        'reportedAt': data['reportedAt'] != null
            ? (data['reportedAt'] as Timestamp).toDate()
            : DateTime.now(),
        'reportedBy': data['reportedBy'] ?? 'Unknown',
        'reason': data['reason'] ?? 'No reason provided',
      });
    }

    setState(() {
      _reportedContent = reports;
    });
  }

  Future<void> _loadActiveUsers() async {
    final yesterday = DateTime.now().subtract(Duration(hours: 24));

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('lastActiveTime', isGreaterThan: yesterday)
        .orderBy('lastActiveTime', descending: true)
        .limit(8)
        .get();

    List<Map<String, dynamic>> users = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      users.add({
        'id': doc.id,
        'name': data['name'] ?? 'Anonymous',
        'email': data['email'] ?? 'No email',
        'lastActiveTime': data['lastActiveTime'] != null
            ? (data['lastActiveTime'] as Timestamp).toDate()
            : DateTime.now(),
        'isLoggedIn': data['isLoggedIn'] ?? false,
        'role': data['role'] ?? 'User',
      });
    }

    setState(() {
      _activeUsers = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discussion Management',
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Dashboard'),
            Tab(text: 'Groups'),
            Tab(text: 'Reports'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(),
          GroupManagementScreen(category: _selectedCategory),
          ReportedContentScreen(),
          DiscussionAnalyticsScreen(),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategorySelector(),
          SizedBox(height: 16),
          _buildStatCards(),
          SizedBox(height: 24),
          _buildSectionHeader('Recent Groups', Icons.group),
          SizedBox(height: 8),
          _buildRecentGroupsList(),
          SizedBox(height: 24),
          _buildSectionHeader('Reported Content', Icons.report_problem_outlined),
          SizedBox(height: 8),
          _buildReportedContentList(),
          SizedBox(height: 24),
          _buildSectionHeader('Active Users', Icons.people_outline),
          SizedBox(height: 8),
          _buildActiveUsersList(),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Filter by category:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              underline: Container(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                  _loadData();
                }
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Total Groups',
          value: _stats['totalGroups']?.toString() ?? '0',
          icon: Icons.group_work_outlined,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Total Members',
          value: _stats['totalMembers']?.toString() ?? '0',
          icon: Icons.people_outline,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Total Messages',
          value: _formatNumber(_stats['totalMessages'] ?? 0),
          icon: Icons.message_outlined,
          color: Colors.purple,
        ),
        _buildStatCard(
          title: 'Active Users (24h)',
          value: _stats['activeUsers']?.toString() ?? '0',
          icon: Icons.person_outline,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Pending Reports',
          value: _stats['reportedContent']?.toString() ?? '0',
          icon: Icons.report_problem_outlined,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
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
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentGroupsList() {
    if (_recentGroups.isEmpty) {
      return _buildEmptyState('No groups found');
    }

    return Column(
      children: _recentGroups.map((group) {
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _getColorForString(group['name']),
              child: Text(
                group['name'][0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              group['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  '${group['category']} • ${group['memberCount']} members • ${group['messageCount']} messages',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Created ${_formatDate(group['createdAt'])} by ${group['creatorName']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textTertiaryColor,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessageModerationScreen(
                      groupId: group['id'],
                      groupName: group['name'],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportedContentList() {
    if (_reportedContent.isEmpty) {
      return _buildEmptyState('No pending reports');
    }

    return Column(
      children: _reportedContent.map((report) {
        IconData contentIcon;
        String contentTypeText;

        switch (report['contentType']) {
          case 'message':
            contentIcon = Icons.message_outlined;
            contentTypeText = 'Message';
            break;
          case 'image':
            contentIcon = Icons.image_outlined;
            contentTypeText = 'Image';
            break;
          case 'video':
            contentIcon = Icons.videocam_outlined;
            contentTypeText = 'Video';
            break;
          case 'audio':
            contentIcon = Icons.audiotrack_outlined;
            contentTypeText = 'Audio';
            break;
          default:
            contentIcon = Icons.error_outline;
            contentTypeText = 'Unknown';
        }

        return Card(
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Icon(
                contentIcon,
                color: Colors.red,
              ),
            ),
            title: Row(
              children: [
                Text(
                  contentTypeText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Reported',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  'In group: ${report['groupName']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Reason: ${report['reason']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Reported ${_formatDate(report['reportedAt'])} by ${report['reportedBy']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textTertiaryColor,
              ),
              onPressed: () {
                // Navigate to detailed report view
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportedContentScreen(
                      initialReportId: report['id'],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveUsersList() {
    if (_activeUsers.isEmpty) {
      return _buildEmptyState('No active users in the last 24 hours');
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _activeUsers.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final user = _activeUsers[index];
        final isOnline = user['isLoggedIn'] ?? false;

        return Container(
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
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _getColorForString(user['name']),
                    child: Text(
                      user['name'][0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                user['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              if (user['role'] != 'User')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user['role'],
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              SizedBox(height: 4),
              Text(
                _formatTimeAgo(user['lastActiveTime']),
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textTertiaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForString(String input) {
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

    int hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}