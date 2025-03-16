// NotificationService.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


import '../Modals/GroupMember.dart';
import 'GroupMemberService.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GroupMemberService _memberService = GroupMemberService();

  // For local notifications
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Navigation handler for notification taps
  Function(Map<String, dynamic>)? _notificationTapHandler;

  // Check if already initialized to prevent duplicate initializations
  bool _isInitialized = false;

  // Factory constructor to return the same instance
  factory NotificationService() {
    return _instance;
  }

  // Private constructor
  NotificationService._internal();

  // Set the notification tap handler
  void setNotificationTapHandler(Function(Map<String, dynamic>) handler) {
    _notificationTapHandler = handler;
  }

  // Initialize the notification services
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission for notifications
    await _requestPermissions();

    // Configure local notifications
    await _setupLocalNotifications();

    // Set up Firebase Messaging handlers
    _setupFirebaseMessaging();

    // Store FCM token in Firestore
    await _updateFCMToken();

    // Listen for token refresh
    _listenForTokenRefresh();

    _isInitialized = true;
    print('Notification service initialized');
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User notification permission status: ${settings.authorizationStatus}');
  }

  // Configure local notifications
  Future<void> _setupLocalNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings - fixed for latest version
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // Initialize settings
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  // Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'group_chat_channel', // Channel ID
      'Group Chat Notifications', // Channel name
      description: 'Notifications for group chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      print('Notification payload: $payload');
      // Parse the payload and navigate to the group chat
      _handleNotificationPayload(payload);
    }
  }

  // Parse and handle notification payload
  void _handleNotificationPayload(String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload) as Map<String, dynamic>;

      // Use the tap handler if available
      if (_notificationTapHandler != null) {
        _notificationTapHandler!(data);
      }
    } catch (e) {
      print('Error handling notification payload: $e');
    }
  }

  // Set up Firebase Messaging handlers
  void _setupFirebaseMessaging() {
    // Handle messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when user taps on notification from terminated state
    FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);

    // Handle when user taps on notification from background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // Handle a message when the app is in the foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also had a notification: ${message.notification}');

      // Display a local notification
      await showLocalNotification(
        title: message.notification!.title ?? 'New Message',
        body: message.notification!.body ?? 'You have a new message',
        payload: jsonEncode(message.data),
      );
    }
  }

  // Handle initial message (app opened from terminated state)
  Future<void> _handleInitialMessage(RemoteMessage? message) async {
    if (message != null) {
      print('Initial message: ${message.data}');

      // Use the tap handler if available
      if (_notificationTapHandler != null) {
        _notificationTapHandler!(message.data);
      }
    }
  }

  // Handle message opened app (app opened from background state)
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.data}');

    // Use the tap handler if available
    if (_notificationTapHandler != null) {
      _notificationTapHandler!(message.data);
    }
  }

  // Show a local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Android notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'group_chat_channel', // Channel ID
      'Group Chat Notifications', // Channel name
      channelDescription: 'Notifications for group chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Notification details
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Update FCM token in Firestore
  Future<void> _updateFCMToken() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        print('FCM token updated in Firestore: $token');
      }
    }
  }

  // Listen for token refresh
  void _listenForTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((String token) async {
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        print('FCM token refreshed and updated in Firestore: $token');
      }
    });
  }

  // Send a notification to a specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get the user's FCM token
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('User document does not exist: $userId');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final String? fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        print('User does not have an FCM token: $userId');
        return;
      }

      // In a real app, this would be sent from your backend server
      // Here we're showing the structure of what would be sent
      final message = {
        'to': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
      };

      print('Would send FCM notification: $message');

      // For testing, we'll show a local notification to the current user
      // This simulates receiving the notification
      if (userId == _auth.currentUser?.uid) {
        await showLocalNotification(
          title: title,
          body: body,
          payload: jsonEncode(data ?? {}),
        );
      }

      // Store notification in Firestore for in-app notification center
      await _storeNotificationInFirestore(userId, title, body, data);

    } catch (e) {
      print('Error sending notification to user: $e');
    }
  }

  // Store notification in Firestore for retrieval in notification center
  Future<void> _storeNotificationInFirestore(
      String userId,
      String title,
      String body,
      Map<String, dynamic>? data,
      ) async {
    try {
      await _firestore.collection('users').doc(userId).collection('notifications').add({
        'title': title,
        'body': body,
        'data': data,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error storing notification in Firestore: $e');
    }
  }

  // Send a notification to all members of a group
  Future<void> sendNotificationToGroup({
    required String groupId,
    required String groupName,
    required String senderName,
    required String messageText,
    String? messageType,
  }) async {
    try {
      // Get members who have notifications enabled
      final List<GroupMember> members =
      await _memberService.getMembersWithNotificationsEnabled(groupId);

      // Current user ID to exclude from notifications
      final String currentUserId = _auth.currentUser?.uid ?? '';

      // Prepare notification data
      final String title = '$senderName in $groupName';
      final String body = messageType != null && messageType.isNotEmpty
          ? 'Sent a ${messageType.toLowerCase()}'
          : messageText.isNotEmpty ? messageText : 'Sent a message';

      final Map<String, dynamic> data = {
        'groupId': groupId,
        'groupName': groupName,
        'senderId': currentUserId,
        'senderName': senderName,
        'messageType': messageType ?? 'text',
        'messageText': messageText,
        'notificationType': 'groupMessage',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // For each member in the group, send a notification
      for (final GroupMember member in members) {
        // Skip notification to the sender
        if (member.userId == currentUserId) {
          continue;
        }

        await sendNotificationToUser(
          userId: member.userId,
          title: title,
          body: body,
          data: data,
        );
      }

      // Also send a notification to users who are online in the app but not in this chat
      await _sendInAppNotificationToOnlineUsers(
        groupId: groupId,
        groupName: groupName,
        senderName: senderName,
        messageText: messageText,
        messageType: messageType,
      );

    } catch (e) {
      print('Error sending group notification: $e');
    }
  }

  // Send an in-app notification to users who are online
  Future<void> _sendInAppNotificationToOnlineUsers({
    required String groupId,
    required String groupName,
    required String senderName,
    required String messageText,
    String? messageType,
  }) async {
    try {
      // Get online users
      final QuerySnapshot onlineUsers = await _firestore
          .collection('online_users')
          .where('isOnline', isEqualTo: true)
          .get();

      // Current user ID to exclude
      final String currentUserId = _auth.currentUser?.uid ?? '';

      // Check if each online user is in the group and has notifications enabled
      for (final DocumentSnapshot userDoc in onlineUsers.docs) {
        final String userId = userDoc.id;

        // Skip the current user
        if (userId == currentUserId) {
          continue;
        }

        // Check if user is a member of the group
        final bool isMember = await _memberService.isUserMemberOfGroup(
          groupId: groupId,
          userId: userId,
        );

        if (isMember) {
          // Check if user has notifications enabled for this group
          final GroupMember? member = await _memberService.getGroupMember(
            groupId: groupId,
            userId: userId,
          );

          if (member != null && member.notifications) {
            // Add to the user's in-app notification center
            await _firestore.collection('users').doc(userId).collection('in_app_notifications').add({
              'groupId': groupId,
              'groupName': groupName,
              'senderName': senderName,
              'messageText': messageText,
              'messageType': messageType ?? 'text',
              'isRead': false,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      print('Error sending in-app notifications: $e');
    }
  }

  // Get unread notification count for the current user
  Stream<int> getUnreadNotificationCount() {
    final String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({
      'isRead': true,
    });
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    final QuerySnapshot notifications = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final WriteBatch batch = _firestore.batch();

    for (final DocumentSnapshot doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Get the user's notifications
  Stream<QuerySnapshot> getUserNotificationsStream() {
    final String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    final String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    final QuerySnapshot notifications = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .get();

    final WriteBatch batch = _firestore.batch();

    for (final DocumentSnapshot doc in notifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}