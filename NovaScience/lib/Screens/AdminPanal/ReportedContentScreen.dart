import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../StartScreen/AppTheme.dart';

class ReportedContentScreen extends StatefulWidget {
  final String? initialReportId;

  const ReportedContentScreen({
    Key? key,
    this.initialReportId,
  }) : super(key: key);

  @override
  _ReportedContentScreenState createState() => _ReportedContentScreenState();
}

class _ReportedContentScreenState extends State<ReportedContentScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingReports = [];
  List<Map<String, dynamic>> _resolvedReports = [];
  String _searchQuery = '';

  Map<String, dynamic>? _selectedReport;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();

    if (widget.initialReportId != null) {
      _loadInitialReport();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialReport() async {
    try {
      DocumentSnapshot reportDoc = await _firestore
          .collection('reported_content')
          .doc(widget.initialReportId)
          .get();

      if (reportDoc.exists) {
        Map<String, dynamic> data = reportDoc.data() as Map<String, dynamic>;
        data['id'] = reportDoc.id;

        setState(() {
          _selectedReport = data;
        });
      }
    } catch (e) {
      print('Error loading initial report: $e');
    }
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load pending reports
      Query pendingQuery = _firestore
          .collection('reported_content')
          .where('status', isEqualTo: 'pending')
          .orderBy('reportedAt', descending: true);

      // Apply search filter if present
      if (_searchQuery.isNotEmpty) {
        pendingQuery = pendingQuery.where('groupName', isGreaterThanOrEqualTo: _searchQuery)
            .where('groupName', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
      }

      QuerySnapshot pendingSnapshot = await pendingQuery.get();

      // Load resolved reports
      Query resolvedQuery = _firestore
          .collection('reported_content')
          .where('status', isNotEqualTo: 'pending')
          .orderBy('status')
          .orderBy('resolvedAt', descending: true);

      // Apply search filter if present
      if (_searchQuery.isNotEmpty) {
        resolvedQuery = resolvedQuery.where('groupName', isGreaterThanOrEqualTo: _searchQuery)
            .where('groupName', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
      }

      QuerySnapshot resolvedSnapshot = await resolvedQuery.get();

      List<Map<String, dynamic>> pendingReports = [];
      List<Map<String, dynamic>> resolvedReports = [];

      for (var doc in pendingSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        pendingReports.add(data);
      }

      for (var doc in resolvedSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        resolvedReports.add(data);
      }

      setState(() {
        _pendingReports = pendingReports;
        _resolvedReports = resolvedReports;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reports: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resolveReport(String reportId, String resolution) async {
    try {
      await _firestore.collection('reported_content').doc(reportId).update({
        'status': resolution,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': 'Admin',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report marked as $resolution'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedReport = null;
      });

      _loadReports();
    } catch (e) {
      print('Error resolving report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resolve report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteContent(Map<String, dynamic> report) async {
    try {
      // Delete the reported content
      await _firestore
          .collection('discussion_groups')
          .doc(report['groupId'])
          .collection('messages')
          .doc(report['contentId'])
          .delete();

      // Update report status
      await _firestore
          .collection('reported_content')
          .doc(report['id'])
          .update({
        'status': 'removed',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': 'Admin',
        'resolution': 'Content was deleted',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Content deleted and report resolved'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedReport = null;
      });

      _loadReports();
    } catch (e) {
      print('Error deleting content: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete content: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _banUser(Map<String, dynamic> report) async {
    try {
      // Add user to banned users collection
      await _firestore.collection('banned_users').add({
        'userId': report['senderId'],
        'userName': report['senderName'],
        'groupId': report['groupId'],
        'groupName': report['groupName'],
        'bannedAt': FieldValue.serverTimestamp(),
        'bannedBy': 'Admin',
        'reason': 'Violating community guidelines',
        'reportId': report['id'],
      });

      // Remove user from group
      await _firestore.runTransaction((transaction) async {
        DocumentReference groupRef = _firestore.collection('discussion_groups').doc(report['groupId']);
        DocumentSnapshot groupSnapshot = await transaction.get(groupRef);

        if (groupSnapshot.exists) {
          Map<String, dynamic> groupData = groupSnapshot.data() as Map<String, dynamic>;
          List<dynamic> members = List.from(groupData['members'] ?? []);
          List<dynamic> admins = List.from(groupData['admins'] ?? []);

          members.remove(report['senderId']);
          admins.remove(report['senderId']);

          transaction.update(groupRef, {
            'members': members,
            'admins': admins,
            'memberCount': members.length,
          });
        }
      });

      // Update report status
      await _firestore
          .collection('reported_content')
          .doc(report['id'])
          .update({
        'status': 'banned',
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': 'Admin',
        'resolution': 'User was banned from the group',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User banned and report resolved'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedReport = null;
      });

      _loadReports();
    } catch (e) {
      print('Error banning user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ban user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedReport == null
          ? AppBar(
        title: Text(
          'Reported Content',
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
          tabs: [
            Tab(text: 'Pending (${_pendingReports.length})'),
            Tab(text: 'Resolved (${_resolvedReports.length})'),
          ],
        ),
      )
          : AppBar(
        title: Text(
          'Report Details',
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedReport = null;
            });
          },
        ),
      ),
      body: _selectedReport != null
          ? _buildReportDetails()
          : Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                _pendingReports.isEmpty
                    ? _buildEmptyState('No pending reports')
                    : _buildReportsList(_pendingReports),
                _resolvedReports.isEmpty
                    ? _buildEmptyState('No resolved reports')
                    : _buildReportsList(_resolvedReports, isResolved: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by group name...',
          prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              _loadReports();
            },
          )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          // Debounce search to avoid excessive queries
          Future.delayed(Duration(milliseconds: 300), () {
            if (value == _searchQuery) {
              _loadReports();
            }
          });
        },
      ),
    );
  }

  Widget _buildReportsList(List<Map<String, dynamic>> reports, {bool isResolved = false}) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];

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

        Color statusColor;
        String statusText;

        if (isResolved) {
          switch (report['status']) {
            case 'approved':
              statusColor = Colors.green;
              statusText = 'Approved';
              break;
            case 'rejected':
              statusColor = Colors.orange;
              statusText = 'Rejected';
              break;
            case 'removed':
              statusColor = Colors.red;
              statusText = 'Removed';
              break;
            case 'banned':
              statusColor = Colors.purple;
              statusText = 'User Banned';
              break;
            default:
              statusColor = Colors.grey;
              statusText = 'Unknown';
          }
        } else {
          statusColor = Colors.red;
          statusText = 'Reported';
        }

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedReport = report;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Icon(
                          contentIcon,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  contentTypeText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'In group: ${report['groupName'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppTheme.textTertiaryColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (report['messageText'] != null && report['messageText'].toString().isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                      ),
                      child: Text(
                        '"${report['messageText']}"',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From: ${report['senderName'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Reported by: ${report['reportedBy'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatDateTime(report['reportedAt'] != null
                            ? (report['reportedAt'] as Timestamp).toDate()
                            : DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTertiaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (isResolved && report['resolvedAt'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Resolved: ${_formatDateTime((report['resolvedAt'] as Timestamp).toDate())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTertiaryColor,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportDetails() {
    final report = _selectedReport!;

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

    Color statusColor;
    String statusText;

    switch (report['status']) {
      case 'pending':
        statusColor = Colors.red;
        statusText = 'Reported';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.orange;
        statusText = 'Rejected';
        break;
      case 'removed':
        statusColor = Colors.red;
        statusText = 'Removed';
        break;
      case 'banned':
        statusColor = Colors.purple;
        statusText = 'User Banned';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        radius: 24,
                        child: Icon(
                          contentIcon,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  contentTypeText,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'In group: ${report['groupName'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Report Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildDetailRow('Reported On', _formatDateTime(report['reportedAt'] != null
                      ? (report['reportedAt'] as Timestamp).toDate()
                      : DateTime.now())),
                  _buildDetailRow('Reported By', report['reportedBy'] ?? 'Unknown'),
                  _buildDetailRow('Reason', report['reason'] ?? 'No reason provided'),
                  if (report['resolvedAt'] != null)
                    _buildDetailRow('Resolved On', _formatDateTime((report['resolvedAt'] as Timestamp).toDate())),
                  if (report['resolvedBy'] != null)
                    _buildDetailRow('Resolved By', report['resolvedBy']),
                  if (report['resolution'] != null)
                    _buildDetailRow('Resolution', report['resolution']),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildDetailRow('Content Type', contentTypeText),
                  _buildDetailRow('Content ID', report['contentId'] ?? 'Unknown'),
                  SizedBox(height: 16),
                  if (report['messageText'] != null && report['messageText'].toString().isNotEmpty) ...[
                    Text(
                      'Message Content:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                      ),
                      child: Text(
                        report['messageText'],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                  if (report['mediaUrl'] != null) ...[
                    SizedBox(height: 16),
                    Text(
                      'Media:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildMediaPreview(report),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildDetailRow('Sender Name', report['senderName'] ?? 'Unknown'),
                  _buildDetailRow('Sender ID', report['senderId'] ?? 'Unknown'),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          if (report['status'] == 'pending')
            _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label + ':',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(Map<String, dynamic> report) {
    final mediaType = report['contentType'] ?? '';
    final mediaUrl = report['mediaUrl'];

    if (mediaUrl == null) return Container();

    if (mediaType == 'image') {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            mediaUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else if (mediaType == 'video') {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (report['mediaThumbnailUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  report['mediaThumbnailUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade800,
                    );
                  },
                ),
              )
            else
              Container(
                color: Colors.grey.shade800,
              ),
            Icon(
              Icons.play_circle_fill,
              size: 64,
              color: Colors.white.withOpacity(0.8),
            ),
            Text(
              'Video Content',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (mediaType == 'audio') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.audiotrack,
              color: AppTheme.secondaryColor,
              size: 32,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Audio Content',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.play_arrow,
              color: AppTheme.tertiaryColor,
              size: 32,
            ),
          ],
        ),
      );
    }

    return Container();
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _resolveReport(_selectedReport!['id'], 'approved'),
                icon: Icon(Icons.check_circle_outline),
                label: Text('Approve Content'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _resolveReport(_selectedReport!['id'], 'rejected'),
                icon: Icon(Icons.cancel_outlined),
                label: Text('Reject Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _deleteContent(_selectedReport!),
                icon: Icon(Icons.delete_outline),
                label: Text('Delete Content'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _banUser(_selectedReport!),
                icon: Icon(Icons.person_off_outlined),
                label: Text('Ban User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8),
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
                _loadReports();
              },
              child: Text('Clear Search'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today, ${DateFormat('h:mm a').format(dateTime)}';
    } else if (date == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
    }
  }
}