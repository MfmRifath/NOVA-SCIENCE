// GroupChatNotificationHelper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart'; // Import rxdart for switchMap
import 'package:nova_science/GroupChat/GroupChatScreen.dart';

import 'NotificationService.dart';


class GroupChatNotificationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final NotificationService _notificationService = NotificationService();

  // Call this method when the app starts
  static Future<void> initialize(BuildContext context) async {
    // Initialize notifications
    await _notificationService.initialize();

    // Set up navigation handler for notification taps
    _setupNotificationNavigation(context);
  }

  // Set up handler for navigating when notifications are tapped
  static void _setupNotificationNavigation(BuildContext context) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(context, message.data);
    });
  }

  // Handle notification tap navigation
  static void _handleNotificationTap(BuildContext context, Map<String, dynamic> data) {
    // Extract group information from notification data
    final String? groupId = data['groupId'];
    final String? groupName = data['groupName'];
    final String? groupAvatar = data['groupAvatar'];

    if (groupId != null && groupName != null) {
      // Navigate to the GroupChatScreen
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

  // Mark a message as read
  static Future<void> markMessageAsRead({
    required String groupId,
    required String messageId,
  }) async {
    try {
      final String currentUserId = _auth.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) return;

      // Update the isRead map for this message
      await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({
        'isRead.$currentUserId': true,
      });
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  // Track read status for all messages
  static Future<void> markAllMessagesAsRead(String groupId) async {
    try {
      final String currentUserId = _auth.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) return;

      // Get recent unread messages
      final QuerySnapshot messageSnapshot = await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(50) // Only mark the most recent messages
          .get();

      // Create a batch to update multiple messages
      final WriteBatch batch = _firestore.batch();

      for (final DocumentSnapshot doc in messageSnapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final Map<String, dynamic> isRead = (data['isRead'] as Map<String, dynamic>?) ?? {};

        // Only update if this user hasn't read this message
        if (isRead[currentUserId] != true) {
          batch.update(doc.reference, {
            'isRead.$currentUserId': true,
          });
        }
      }

      // Commit the batch
      await batch.commit();

      // Also update last read timestamp
      await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('read_status')
          .doc(currentUserId)
          .set({
        'userId': currentUserId,
        'lastRead': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking all messages as read: $e');
    }
  }

  // Count unread messages for a group
  // Count unread messages for a group
  static Stream<int> unreadMessageCountStream(String groupId) {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      return Stream.value(0);
    }

    // Get the user's last read timestamp
    return _firestore
        .collection('discussion_groups')
        .doc(groupId)
        .collection('read_status')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((docSnapshot) async {
      // Get the last read timestamp - fixed the syntax error here
      final Timestamp? lastRead;
      if (docSnapshot.exists && docSnapshot.data() != null) {
        lastRead = docSnapshot.data()!['lastRead'] as Timestamp?;
      } else {
        lastRead = null;
      }

      // If no last read timestamp, count all messages
      if (lastRead == null) {
        final QuerySnapshot querySnapshot = await _firestore
            .collection('discussion_groups')
            .doc(groupId)
            .collection('messages')
            .where('senderId', isNotEqualTo: currentUserId) // Don't count own messages
            .get();
        return querySnapshot.docs.length;
      }

      // Count messages newer than last read
      final QuerySnapshot querySnapshot = await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('messages')
          .where('timestamp', isGreaterThan: lastRead)
          .where('senderId', isNotEqualTo: currentUserId) // Don't count own messages
          .get();
      return querySnapshot.docs.length;
    });
  }
  // Listen for new messages in a group
  static void listenForNewMessages(String groupId) {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    // Get a reference to the latest document in the messages collection
    _firestore
        .collection('discussion_groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((querySnapshot) async {
      if (querySnapshot.docs.isEmpty) return;

      final DocumentSnapshot latestMessage = querySnapshot.docs.first;
      final Map<String, dynamic> data = latestMessage.data() as Map<String, dynamic>;

      // Check if this is a new message and not from the current user
      if (data['senderId'] != currentUserId) {
        // Mark it as read if the user is currently viewing this chat
        // This can be determined by a global state variable or other means
        if (GroupChatState.currentlyViewingGroupId == groupId) {
          await markMessageAsRead(
            groupId: groupId,
            messageId: latestMessage.id,
          );
        } else {
          // If not viewing, show a notification
          final String senderName = data['senderName'] ?? 'Someone';
          final String messageText = data['text'] ?? '';
          final String mediaType = data['mediaType'] ?? '';

          // Get group information
          final DocumentSnapshot groupDoc = await _firestore
              .collection('discussion_groups')
              .doc(groupId)
              .get();

          final Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
          final String groupName = groupData['name'] ?? 'Group Chat';

          // Show a local notification
          _notificationService.showLocalNotification(
            title: '$senderName in $groupName',
            body: messageText.isNotEmpty
                ? messageText
                : 'Sent a ${mediaType.isEmpty ? 'message' : mediaType.toLowerCase()}',
            payload: '{"groupId":"$groupId","groupName":"$groupName"}',
          );
        }
      }
    });
  }
}

// Add this to your GroupChatScreen.dart
class GroupChatState {
  static String? currentlyViewingGroupId;
}

// Note: The following code should be added to your GroupChatScreen class
// and not included as part of this file. It's shown here as a reference.
/*
class _GroupChatScreenState extends State<GroupChatScreen> with TickerProviderStateMixin {
  // Add this field:
  late Stream<int> _unreadMessageCountStream;
  int _unreadMessageCount = 0; // Add this field to track the count

  // Add to your initState method:
  @override
  void initState() {
    super.initState();
    // ... existing code ...

    // Set currently viewing group for notification handling
    GroupChatState.currentlyViewingGroupId = widget.groupId;

    // Mark all messages as read when entering the chat
    GroupChatNotificationHelper.markAllMessagesAsRead(widget.groupId);

    // Get unread count
    _unreadMessageCountStream = GroupChatNotificationHelper.unreadMessageCountStream(widget.groupId);
    _unreadMessageCountStream.listen((count) {
      setState(() {
        _unreadMessageCount = count;
      });
    });
  }

  // Add to your dispose method:
  @override
  void dispose() {
    // ... existing code ...

    // Clear currently viewing group when leaving
    if (GroupChatState.currentlyViewingGroupId == widget.groupId) {
      GroupChatState.currentlyViewingGroupId = null;
    }

    super.dispose();
  }
}
*/