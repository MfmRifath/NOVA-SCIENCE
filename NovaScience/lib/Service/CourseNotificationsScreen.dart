// CourseNotificationsScreen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart';
import '../Screens/AdminPanal/CMSDesignSystem.dart';
import '../Screens/AdminPanal/CourseDetailScreen.dart';


class CourseNotificationsScreen extends StatefulWidget {
  const CourseNotificationsScreen({Key? key}) : super(key: key);

  @override
  _CourseNotificationsScreenState createState() => _CourseNotificationsScreenState();
}

class _CourseNotificationsScreenState extends State<CourseNotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _showOnlyUnread = false;
  String? _filterType;

  final List<String> _filterOptions = [
    'All',
    'New Courses',
    'Approved Courses',
    'Course Updates',
    'New Content'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Course Notifications'),
        backgroundColor: CMSDesignSystem.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Mark all as read button
          IconButton(
            icon: Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),

          // Filter popup menu
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list_rounded),
            tooltip: 'Filter notifications',
            onSelected: (value) {
              setState(() {
                if (value == 'All') {
                  _filterType = null;
                } else if (value == 'New Courses') {
                  _filterType = 'newCourse';
                } else if (value == 'Approved Courses') {
                  _filterType = 'courseApproved';
                } else if (value == 'Course Updates') {
                  _filterType = 'courseUpdate';
                } else if (value == 'New Content') {
                  _filterType = 'newContent';
                }
              });
            },
            itemBuilder: (context) {
              return _filterOptions.map((option) {
                bool isSelected = false;
                if (option == 'All' && _filterType == null) {
                  isSelected = true;
                } else if (option == 'New Courses' && _filterType == 'newCourse') {
                  isSelected = true;
                } else if (option == 'Approved Courses' && _filterType == 'courseApproved') {
                  isSelected = true;
                } else if (option == 'Course Updates' && _filterType == 'courseUpdate') {
                  isSelected = true;
                } else if (option == 'New Content' && _filterType == 'newContent') {
                  isSelected = true;
                }

                return PopupMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      if (isSelected)
                        Icon(Icons.check, color: CMSDesignSystem.primaryBlue, size: 18)
                      else
                        SizedBox(width: 18),
                      SizedBox(width: 8),
                      Text(option),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chip for unread only
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text('Unread only'),
                  selected: _showOnlyUnread,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyUnread = selected;
                    });
                  },
                  selectedColor: CMSDesignSystem.primaryBlue.withOpacity(0.2),
                  checkmarkColor: CMSDesignSystem.primaryBlue,
                  avatar: _showOnlyUnread
                      ? Icon(Icons.visibility_off_rounded, size: 16, color: CMSDesignSystem.primaryBlue)
                      : Icon(Icons.visibility_rounded, size: 16, color: Colors.grey),
                ),
                SizedBox(width: 8),
                if (_filterType != null)
                  FilterChip(
                    label: Text(_getFilterName(_filterType!)),
                    selected: true,
                    onSelected: (selected) {
                      if (!selected) {
                        setState(() {
                          _filterType = null;
                        });
                      }
                    },
                    selectedColor: CMSDesignSystem.primaryGreen.withOpacity(0.2),
                    checkmarkColor: CMSDesignSystem.primaryGreen,
                    avatar: Icon(
                      _getFilterIcon(_filterType!),
                      size: 16,
                      color: CMSDesignSystem.primaryGreen,
                    ),
                  ),
              ],
            ),
          ),

          // Notifications list
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _getNotificationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(CMSDesignSystem.primaryBlue),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => setState(() {}),
                              child: Text('Refresh'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CMSDesignSystem.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                            )
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_rounded,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No notifications found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_filterType != null || _showOnlyUnread)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _filterType = null;
                                      _showOnlyUnread = false;
                                    });
                                  },
                                  child: Text('Clear filters'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: CMSDesignSystem.primaryBlue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.only(bottom: 16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final notification = snapshot.data!.docs[index];
                        final data = notification.data() as Map<String, dynamic>;

                        final String type = data['type'] ?? 'unknown';
                        final String courseId = data['courseId'] ?? '';
                        final String courseName = data['courseName'] ?? 'Unknown Course';
                        final bool isRead = data['isRead'] ?? false;
                        final Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
                        final String message = data['message'] ?? 'No message';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Card(
                            elevation: isRead ? 0 : 2,
                            color: isRead ? Colors.white : CMSDesignSystem.primaryBlue.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isRead ? Colors.grey.withOpacity(0.2) : CMSDesignSystem.primaryBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _handleNotificationTap(notification, data),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: _getTypeColor(type).withOpacity(0.2),
                                          foregroundColor: _getTypeColor(type),
                                          radius: 20,
                                          child: Icon(_getTypeIcon(type)),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      courseName,
                                                      style: TextStyle(
                                                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (!isRead)
                                                    Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration: BoxDecoration(
                                                        color: CMSDesignSystem.primaryBlue,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                _getTypeDescription(type),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                message,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatTimestamp(timestamp),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              if (!isRead)
                                                IconButton(
                                                  icon: Icon(Icons.mark_email_read_rounded, size: 18),
                                                  color: CMSDesignSystem.primaryBlue,
                                                  tooltip: 'Mark as read',
                                                  padding: EdgeInsets.zero,
                                                  constraints: BoxConstraints(),
                                                  onPressed: () => _markAsRead(notification.id),
                                                ),
                                              SizedBox(width: 16),
                                              IconButton(
                                                icon: Icon(Icons.delete_outline_rounded, size: 18),
                                                color: Colors.red[400],
                                                tooltip: 'Delete notification',
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(),
                                                onPressed: () => _deleteNotification(notification.id),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(CMSDesignSystem.primaryBlue),
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

  // Get notifications stream from Firestore
  Stream<QuerySnapshot> _getNotificationsStream() {
    String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return Stream.empty();

    Query query = _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    if (_showOnlyUnread) {
      query = query.where('isRead', isEqualTo: false);
    }

    if (_filterType != null) {
      query = query.where('type', isEqualTo: _filterType);
    }

    return query.snapshots();
  }

  // Handle notification tap
  Future<void> _handleNotificationTap(
      DocumentSnapshot notification, Map<String, dynamic> data) async {
    final String courseId = data['courseId'] ?? '';

    // Mark as read
    await _markAsRead(notification.id);

    // Navigate to course detail if courseId is available
    if (courseId.isNotEmpty) {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      setState(() {
        _isLoading = true;
      });

      try {

        Course? course = await courseProvider.getCourseById(courseId);

        if (course != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Course not found or no longer available'),
              backgroundColor: Colors.red[400],
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load course details'),
            backgroundColor: Colors.red[400],
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Mark notification as read
  Future<void> _markAsRead(String notificationId) async {
    String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark all notifications as read
  Future<void> _markAllAsRead() async {
    String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get all unread notifications
      final unreadNotifications = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      // Create a batch to update all documents
      final batch = _firestore.batch();
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Commit the batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: CMSDesignSystem.primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark notifications as read'),
          backgroundColor: Colors.red[400],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Delete a notification
  Future<void> _deleteNotification(String notificationId) async {
    String uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification deleted'),
        backgroundColor: Colors.grey[700],
      ),
    );
  }

  // Format timestamp to readable date
  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        } else {
          return '${difference.inMinutes} min ago';
        }
      } else {
        return '${difference.inHours} hr ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  // Get notification type description
  String _getTypeDescription(String type) {
    switch (type) {
      case 'newCourse':
        return 'New Course Added';
      case 'courseApproved':
        return 'Course Approved';
      case 'courseUpdate':
        return 'Course Updated';
      case 'newContent':
        return 'New Content Available';
      default:
        return 'Notification';
    }
  }

  // Get notification type color
  Color _getTypeColor(String type) {
    switch (type) {
      case 'newCourse':
        return Colors.purple;
      case 'courseApproved':
        return CMSDesignSystem.primaryGreen;
      case 'courseUpdate':
        return Colors.amber[700]!;
      case 'newContent':
        return CMSDesignSystem.primaryBlue;
      default:
        return Colors.grey;
    }
  }

  // Get notification type icon
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'newCourse':
        return Icons.school_rounded;
      case 'courseApproved':
        return Icons.verified_rounded;
      case 'courseUpdate':
        return Icons.update_rounded;
      case 'newContent':
        return Icons.video_library_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  // Get filter name from filter type
  String _getFilterName(String filterType) {
    switch (filterType) {
      case 'newCourse':
        return 'New Courses';
      case 'courseApproved':
        return 'Approved Courses';
      case 'courseUpdate':
        return 'Course Updates';
      case 'newContent':
        return 'New Content';
      default:
        return 'Unknown';
    }
  }

  // Get filter icon from filter type
  IconData _getFilterIcon(String filterType) {
    switch (filterType) {
      case 'newCourse':
        return Icons.school_rounded;
      case 'courseApproved':
        return Icons.verified_rounded;
      case 'courseUpdate':
        return Icons.update_rounded;
      case 'newContent':
        return Icons.video_library_rounded;
      default:
        return Icons.filter_list_rounded;
    }
  }
}