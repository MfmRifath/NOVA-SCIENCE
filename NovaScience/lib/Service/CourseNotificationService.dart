// CourseNotificationService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../Modals/CourseAndSectionAndVideos.dart';

/// A service class to handle all course-related notifications
class CourseNotificationService {
  static final CourseNotificationService _instance = CourseNotificationService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Factory constructor
  factory CourseNotificationService() {
    return _instance;
  }

  // Private constructor
  CourseNotificationService._internal();

  /// Sends notifications to all users when a course is created
  Future<void> sendCourseCreationNotifications({
    required String courseId,
    required String courseTitle,
    required String instructorName,
    required String instructorEmail,
    required String subject,
    required String medium,
  }) async {
    try {
      await _sendNotificationsToUsers(
        courseId: courseId,
        courseTitle: courseTitle,
        instructorName: instructorName,
        instructorEmail: instructorEmail,
        subject: subject,
        medium: medium,
        notificationType: 'newCourse',
        title: 'New Course Created',
        body: '$courseTitle by $instructorName has been created and is pending approval.',
        activityType: 'newCourse',
        activityTitle: 'New Course Created',
        activityDescription: '$courseTitle has been created and is awaiting approval',
      );
    } catch (e) {
      print('Error sending course creation notifications: $e');
    }
  }

  /// Sends notifications to all users when a course is approved
  Future<void> sendCourseApprovalNotifications({
    required String courseId,
    required String courseTitle,
    required String instructorName,
    required String instructorEmail,
    required String subject,
    required String medium,
  }) async {
    try {
      await _sendNotificationsToUsers(
        courseId: courseId,
        courseTitle: courseTitle,
        instructorName: instructorName,
        instructorEmail: instructorEmail,
        subject: subject,
        medium: medium,
        notificationType: 'courseApproved',
        title: 'New Course Available',
        body: '$courseTitle by $instructorName is now available!',
        activityType: 'courseApproved',
        activityTitle: 'Course Approved',
        activityDescription: '$courseTitle has been approved and is now available',
      );
    } catch (e) {
      print('Error sending course approval notifications: $e');
    }
  }

  /// Sends notifications to all users when a course is updated
  Future<void> sendCourseUpdateNotifications({
    required String courseId,
    required String courseTitle,
    required String instructorName,
    required String instructorEmail,
    required String subject,
    required String medium,
    required String updateDetails,
  }) async {
    try {
      await _sendNotificationsToUsers(
        courseId: courseId,
        courseTitle: courseTitle,
        instructorName: instructorName,
        instructorEmail: instructorEmail,
        subject: subject,
        medium: medium,
        notificationType: 'courseUpdate',
        title: 'Course Updated',
        body: '$courseTitle has been updated: $updateDetails',
        activityType: 'courseUpdate',
        activityTitle: 'Course Updated',
        activityDescription: '$courseTitle has been updated: $updateDetails',
        additionalData: {'updateDetails': updateDetails},
      );
    } catch (e) {
      print('Error sending course update notifications: $e');
    }
  }

  /// Sends notifications to enrolled students about a new section or content
  Future<void> sendNewContentNotifications({
    required String courseId,
    required String courseTitle,
    required String instructorName,
    required String contentType,
    required String contentTitle,
  }) async {
    try {
      // Find users enrolled in this specific course
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

      // Create a batch for efficient writes
      WriteBatch batch = _firestore.batch();

      // Notification data
      final notificationData = {
        'title': 'New $contentType Added',
        'body': 'New $contentType "$contentTitle" added to $courseTitle',
        'data': {
          'courseId': courseId,
          'courseTitle': courseTitle,
          'instructorName': instructorName,
          'contentType': contentType,
          'contentTitle': contentTitle,
          'notificationType': 'newContent',
          'timestamp': FieldValue.serverTimestamp(),
        },
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      int enrolledCount = 0;

      // Add notification to enrolled users only
      for (var userDoc in usersSnapshot.docs) {
        if (userDoc.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          List<dynamic> enrolledCourses = userData['enrolledCourses'] ?? [];

          // Check if user is enrolled in this course
          bool isEnrolled = enrolledCourses.any((enrollment) {
            if (enrollment is Map<String, dynamic>) {
              return enrollment['courseId'] == courseId;
            }
            return false;
          });

          if (isEnrolled) {
            enrolledCount++;

            // Create notification document reference
            DocumentReference notificationRef = _firestore
                .collection('users')
                .doc(userDoc.id)
                .collection('notifications')
                .doc(); // Auto-generate ID

            // Add to batch
            batch.set(notificationRef, notificationData);
          }
        }
      }

      // Only commit if there were enrolled users
      if (enrolledCount > 0) {
        // Add to activities collection
        DocumentReference activityRef = _firestore.collection('activities').doc();
        batch.set(activityRef, {
          'type': 'newContent',
          'title': 'New Content Added',
          'description': 'New $contentType "$contentTitle" added to $courseTitle',
          'courseId': courseId,
          'courseTitle': courseTitle,
          'contentType': contentType,
          'contentTitle': contentTitle,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Commit the batch
        await batch.commit();

        print('New content notifications sent to $enrolledCount enrolled users');
      } else {
        print('No enrolled users found for course $courseTitle');
      }
    } catch (e) {
      print('Error sending new content notifications: $e');
    }
  }

  /// Common method to send notifications to all users
  Future<void> _sendNotificationsToUsers({
    required String courseId,
    required String courseTitle,
    required String instructorName,
    required String instructorEmail,
    required String subject,
    required String medium,
    required String notificationType,
    required String title,
    required String body,
    required String activityType,
    required String activityTitle,
    required String activityDescription,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // 1. Get all users
      QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

      // 2. Create a batch for efficient writes
      WriteBatch batch = _firestore.batch();

      // 3. Prepare the notification data
      final Map<String, dynamic> baseData = {
        'courseId': courseId,
        'courseTitle': courseTitle,
        'instructorName': instructorName,
        'subject': subject,
        'medium': medium,
        'notificationType': notificationType,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add any additional data
      if (additionalData != null) {
        baseData.addAll(additionalData);
      }

      final notificationData = {
        'title': title,
        'body': body,
        'data': baseData,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // 4. Add notification to each user's notifications collection
      int notificationCount = 0;

      for (var userDoc in usersSnapshot.docs) {
        // Skip sending notification to the course creator
        if (userDoc.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          if (userData['email'] == instructorEmail) {
            continue;
          }
        }

        notificationCount++;

        // Create notification document reference
        DocumentReference notificationRef = _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc(); // Auto-generate ID

        // Add to batch
        batch.set(notificationRef, notificationData);
      }

      // 5. Add to activities collection
      DocumentReference activityRef = _firestore.collection('activities').doc();
      batch.set(activityRef, {
        'type': activityType,
        'teacherId': instructorEmail,
        'title': activityTitle,
        'description': activityDescription,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 6. Commit the batch
      if (notificationCount > 0) {
        await batch.commit();
        print('Sent $notificationCount notifications for course: $courseTitle');
      } else {
        print('No users to notify for course: $courseTitle');
      }

      // 7. Also send push notifications via FCM (would normally be done server-side)
      _sendPushNotificationsIfPossible(title, body, baseData);

    } catch (e) {
      print('Error sending notifications: $e');
      // We don't throw the error to avoid disrupting the main functionality
    }
  }

  /// Send push notifications using FCM (simplified version)
  /// In a real app, this would be handled by a server
  void _sendPushNotificationsIfPossible(
      String title,
      String body,
      Map<String, dynamic> data
      ) {
    // This is a stub for demonstration
    // In a real app, you would use a server-side function to trigger FCM
    print('Would send push notifications with title: $title, body: $body');

    // Note: Client-side apps cannot directly send to FCM topics or multiple tokens
    // This requires a server component (Firebase Cloud Functions, custom API, etc.)
  }

  /// Get count of unread course notifications for the current user
  Stream<int> getUnreadCourseNotificationsCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .where('data.notificationType', whereIn: [
      'newCourse',
      'courseApproved',
      'courseUpdate',
      'newContent'
    ])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}