// NotificationCenterScreen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nova_science/GroupChat/GroupChatScreen.dart';

import 'NotificationService.dart';


class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  _NotificationCenterScreenState createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep),
            tooltip: 'Clear all notifications',
            onPressed: _showClearConfirmation,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getUserNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading notifications',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return Stack(
            children: [
              ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final data = notification.data() as Map<String, dynamic>;

                  return _buildNotificationItem(
                    context,
                    notification.id,
                    data,
                  );
                },
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 72,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'When you receive new messages, they\'ll appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context,
      String notificationId,
      Map<String, dynamic> data,
      ) {
    final String title = data['title'] ?? 'New notification';
    final String body = data['body'] ?? '';
    final bool isRead = data['isRead'] ?? false;
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;
    final Map<String, dynamic>? notificationData =
    data['data'] as Map<String, dynamic>?;

    // Format the timestamp
    final String timeString = timestamp != null
        ? _formatTimestamp(timestamp.toDate())
        : '';

    // Determine notification type and icon
    IconData icon = Icons.notifications;
    Color iconColor = Colors.blue;

    if (notificationData != null) {
      final String notificationType = notificationData['notificationType'] ?? '';
      final String messageType = notificationData['messageType'] ?? '';

      if (notificationType == 'groupMessage') {
        icon = Icons.chat;
        iconColor = Colors.green;

        if (messageType == 'image') {
          icon = Icons.image;
          iconColor = Colors.purple;
        } else if (messageType == 'video') {
          icon = Icons.videocam;
          iconColor = Colors.red;
        } else if (messageType == 'audio') {
          icon = Icons.mic;
          iconColor = Colors.orange;
        } else if (messageType == 'file') {
          icon = Icons.insert_drive_file;
          iconColor = Colors.blue;
        }
      }
    }

    return Dismissible(
      key: Key(notificationId),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notificationId);
      },
      child: Container(
        color: isRead ? null : Colors.blue.withOpacity(0.05),
        child: ListTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (body.isNotEmpty)
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: 4),
              Text(
                timeString,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: isRead
              ? null
              : Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          onTap: () {
            _handleNotificationTap(notificationId, notificationData);
          },
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  void _handleNotificationTap(
      String notificationId,
      Map<String, dynamic>? notificationData,
      ) async {
    // Mark notification as read
    await _notificationService.markNotificationAsRead(notificationId);

    // Navigate based on notification type
    if (notificationData != null) {
      final String notificationType = notificationData['notificationType'] ?? '';

      if (notificationType == 'groupMessage') {
        final String? groupId = notificationData['groupId'];
        final String? groupName = notificationData['groupName'];
        final String? groupAvatar = notificationData['groupAvatar'];

        if (groupId != null && groupName != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupChatScreen(
                groupId: groupId,
                groupName: groupName,
                groupAvatar: groupAvatar,
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.markAllNotificationsAsRead();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear all notifications?'),
        content: Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllNotifications();
            },
            child: Text(
              'CLEAR',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.clearAllNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All notifications cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}