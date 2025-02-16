// course_provider.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../Modals/CourseAndSectionAndVideos.dart';
import '../Modals/User.dart';

class CourseProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool hasError = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth? auth;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // ============================================================================
  // COURSE FETCHING METHODS
  // ============================================================================

  /// Fetch all courses from Firestore.
  Future<void> fetchCourses() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('courses').get();
      print('Courses fetched: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        print('Course: ${doc.data()}');
      }
      notifyListeners();
    } catch (e) {
      hasError = true;
      print('Error fetching courses: $e');
    }
  }

  /// Get courses in which a given user is enrolled.
  Future<List<QueryDocumentSnapshot<Object?>>> getEnrolledCourses(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null) {
          // Assuming 'enrolledCourses' is a list of objects containing a courseId field.
          final enrolledCourses = userData['enrolledCourses'] as List<dynamic>? ?? [];
          final enrolledCourseIds = enrolledCourses
              .map((courseObj) => (courseObj is Map<String, dynamic> ? courseObj['courseId'] as String : courseObj.toString()))
              .toList();

          if (enrolledCourseIds.isNotEmpty) {
            final coursesSnapshot = await _firestore
                .collection('courses')
                .where(FieldPath.documentId, whereIn: enrolledCourseIds)
                .get();
            return coursesSnapshot.docs;
          }
        }
      }
    } catch (e) {
      print('Error fetching enrolled courses: $e');
    }
    return [];
  }

  /// Get all free courses.
  Future<List<QueryDocumentSnapshot<Object?>>?> getFreeCourses() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('courses')
          .where('status', isEqualTo: 'free')
          .get();
      return snapshot.docs;
    } catch (e) {
      hasError = true;
      print('Error fetching free courses: $e');
      return null;
    }
  }

  /// Get all premium courses.
  Future<List<QueryDocumentSnapshot<Object?>>?> getMyCourses() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('courses')
          .where('status', isEqualTo: 'premium')
          .get();
      return snapshot.docs;
    } catch (e) {
      hasError = true;
      print('Error fetching premium courses: $e');
      return null;
    }
  }

  // ============================================================================
  // IMAGE & COURSE CREATION/UPDATE METHODS
  // ============================================================================

  /// Upload an image file to Firebase Storage and return its URL.
  Future<String?> uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('course_images/$fileName');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Add a new course to Firestore.
  Future<void> addCourse({
    String? title,
    String? description,
    double? price,
    DateTime? startDate,
    DateTime? endDate,
    String? instructor,
    String? duration,
    String? imageUrl,
    String? status,
    String? subject,
    String? instructorEmail,
    String? medium
  }) async {
    Course newCourse = Course(
      courseTitle: title,
      description: description,
      price: price,
      instructor: instructor,
      duration: duration,
      imageUrl: imageUrl,
      status: status,
      sections: [],
      subject: subject,
      instructorEmail: instructorEmail,
      medium: medium!
    );
    try {
      DocumentReference docRef = await _firestore.collection('courses').add(newCourse.toMap());
      print('Course added with ID: ${docRef.id}');
      notifyListeners();
    } catch (e) {
      print('Error adding course: $e');
    }
  }
  Future<List<QueryDocumentSnapshot<Object?>>?> getReviewCourses() async {
    // Fetch all courses and then filter to only include those not approved.
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('courses').get();
    List<QueryDocumentSnapshot> allCourses = querySnapshot.docs;
    List<QueryDocumentSnapshot> reviewCourses = allCourses.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // If isApproved is not true, consider it "in review"
      return data['isApproved'] != true;
    }).toList();
    return reviewCourses;
  }
  /// Edit an existing course.
  Future<void> editCourse(String id, String title, String description,
      double? price, String subject, String imageUrl,String medium) async {
    try {
      await _firestore.collection('courses').doc(id).update({
        'courseTitle': title,
        'description': description,
        'price': price,
        'subject': subject,
        'imageUrl': imageUrl,
        'medium': medium
      });
      notifyListeners();
    } catch (e) {
      print('Error editing course: $e');
    }
  }

  /// Delete a course.
  Future<void> deleteCourse(String? id) async {
    try {
      await _firestore.collection('courses').doc(id).delete();
      notifyListeners();
    } catch (e) {
      print('Error deleting course: $e');
    }
  }

  // ============================================================================
  // SECTION MANAGEMENT
  // ============================================================================

  /// Add a new section (with empty videos and PDFs) to a course.
  Future<void> addSection(String courseId, String title) async {
    try {
      Section newSection = Section(
        sectionTitle: title,
        videos: [],
        pdfs: [],
      );
      await _firestore.collection('courses').doc(courseId).update({
        'sections': FieldValue.arrayUnion([newSection.toMap()]),
      });
      notifyListeners();
    } catch (e) {
      print('Error adding section: $e');
    }
  }

  /// Edit the title of an existing section.
  Future<void> editSection(String courseId, String oldTitle, String newTitle) async {
    try {
      Course? course = await getCourseById(courseId);
      if (course != null) {
        int index = course.sections.indexWhere((sec) => sec.sectionTitle == oldTitle);
        if (index != -1) {
          course.sections[index].sectionTitle = newTitle;
          await updateCourse(course);
          notifyListeners();
        } else {
          print('Section not found');
        }
      } else {
        print('Course not found');
      }
    } catch (e) {
      print('Failed to edit section: $e');
    }
  }

  /// Delete a section from a course.
  Future<void> deleteSection(String courseId, String sectionTitle) async {
    try {
      Course? course = await getCourseById(courseId);
      if (course != null) {
        int initialLength = course.sections.length;
        course.sections.removeWhere((sec) => sec.sectionTitle == sectionTitle);
        if (course.sections.length < initialLength) {
          await updateCourse(course);
          notifyListeners();
        } else {
          print('Section "$sectionTitle" not found in course "$courseId".');
        }
      } else {
        print('Course with ID "$courseId" not found.');
      }
    } catch (e) {
      print('Failed to delete section: $e');
    }
  }

  // ============================================================================
  // VIDEO MANAGEMENT
  // ============================================================================

  /// Add a video to a section by using its array index.
  Future<void> addVideo(String courseId, int sectionIndex, String videoTitle, String videoUrl) async {
    try {
      Video newVideo = Video(title: videoTitle, videoUrl: videoUrl);
      await _firestore.collection('courses').doc(courseId).update({
        'sections.$sectionIndex.videos': FieldValue.arrayUnion([newVideo.toMap()]),
      });
      notifyListeners();
    } catch (e) {
      print('Error adding video: $e');
    }
  }

  /// Delete a video from a section by its title and video index.
  Future<void> deleteVideo(String courseId, String sectionTitle, int videoIndex) async {
    try {
      Course? course = await getCourseById(courseId);
      if (course != null) {
        Section? section = course.sections.firstWhere(
              (sec) => sec.sectionTitle == sectionTitle,
        );
        if (section != null && videoIndex >= 0 && videoIndex < section.videos.length) {
          section.videos.removeAt(videoIndex);
          await updateCourse(course);
          notifyListeners();
        } else {
          print('Invalid video index or section not found');
        }
      } else {
        print('Course not found');
      }
    } catch (e) {
      print('Failed to delete video: $e');
    }
  }

  /// Add a video to a section by its title.
  Future<void> addVideoToSection(String courseId, String sectionTitle, Video video) async {
    try {
      Course? course = await getCourseById(courseId);
      if (course != null) {
        Section? section = course.sections.firstWhere(
              (sec) => sec.sectionTitle == sectionTitle,
        );
        if (section != null) {
          section.videos.add(video);
          await updateCourse(course);
        } else {
          print('Section not found');
        }
      } else {
        print('Course not found');
      }
    } catch (e) {
      print('Failed to add video: $e');
    }
  }

  /// Edit an existing video's details.
  Future<void> editVideo(String courseId, String sectionTitle, int videoIndex, String newTitle, String newUrl) async {
    try {
      Course? course = await getCourseById(courseId);
      if (course != null) {
        Section? section = course.sections.firstWhere(
              (sec) => sec.sectionTitle == sectionTitle,
        );
        if (section != null && videoIndex >= 0 && videoIndex < section.videos.length) {
          section.videos[videoIndex].title = newTitle;
          section.videos[videoIndex].videoUrl = newUrl;
          await updateCourse(course);
          notifyListeners();
        } else {
          print('Invalid video index or section not found');
        }
      } else {
        print('Course not found');
      }
    } catch (e) {
      print('Failed to edit video: $e');
    }
  }

  // ============================================================================
  // PDF RESOURCE MANAGEMENT (NEW)
  // ============================================================================

  /// Add a PDF resource to a section.
  Future<void> addPdfToSection(String courseId, String sectionTitle, String pdfTitle, String pdfUrl) async {
    try {
      Course? course = await getCourseById(courseId);
      if (course != null) {
        Section? section = course.sections.firstWhere(
              (sec) => sec.sectionTitle == sectionTitle,
        );
        if (section != null) {
          PdfResource newPdf = PdfResource(title: pdfTitle, pdfUrl: pdfUrl);
          section.pdfs.add(newPdf);
          await updateCourse(course);
          notifyListeners();
        } else {
          print('Section not found');
        }
      } else {
        print('Course not found');
      }
    } catch (e) {
      print('Failed to add PDF: $e');
    }
  }

  /// Delete a PDF resource from a section.
  Future<void> deletePdfFromSection(String courseId, String sectionTitle, int pdfIndex) async {
    try {
      Course? course = await getCourseById(courseId);
      if (course != null) {
        Section? section = course.sections.firstWhere(
              (sec) => sec.sectionTitle == sectionTitle,
        );
        if (section != null && pdfIndex >= 0 && pdfIndex < section.pdfs.length) {
          section.pdfs.removeAt(pdfIndex);
          await updateCourse(course);
          notifyListeners();
        } else {
          print('Invalid PDF index or section not found');
        }
      } else {
        print('Course not found');
      }
    } catch (e) {
      print('Failed to delete PDF: $e');
    }
  }

  // ============================================================================
  // FEEDBACK MANAGEMENT
  // ============================================================================

  /// Add new feedback to a course and update the average rating.
  Future<void> addFeedback(
      String courseId,
      String userId,
      String feedbackText,
      String userName,
      double rating,
      ) async {
    try {
      FeedBack newFeedback = FeedBack(
        userId: userId,
        userName: userName,
        feedback: feedbackText,
        rating: rating,
        date: Timestamp.now(),
      );

      DocumentReference courseRef = _firestore.collection('courses').doc(courseId);
      DocumentSnapshot courseSnapshot = await courseRef.get();
      if (!courseSnapshot.exists) {
        throw Exception("Course not found");
      }

      Map<String, dynamic>? courseData = courseSnapshot.data() as Map<String, dynamic>?;
      double currentAverage = (courseData?['averageRating'] as num?)?.toDouble() ?? 0.0;
      List<dynamic> feedbacks = courseData?['feedbacks'] ?? [];
      int totalFeedbacks = feedbacks.length;
      double newAverage = ((currentAverage * totalFeedbacks) + rating) / (totalFeedbacks + 1);

      await courseRef.update({
        'feedbacks': FieldValue.arrayUnion([newFeedback.toMap()]),
        'averageRating': newAverage,
      });

      notifyListeners();
    } catch (e) {
      print("Failed to add feedback: $e");
      throw e;
    }
  }

  /// Update an existing feedback and recalculate the course’s average rating.
  Future<void> updateFeedback(
      String courseId,
      String userId,
      String newFeedbackText,
      double newRating,
      ) async {
    try {
      print("Starting feedback update for userId: $userId in courseId: $courseId");
      DocumentReference courseRef = _firestore.collection('courses').doc(courseId);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot courseSnapshot = await transaction.get(courseRef);
        if (!courseSnapshot.exists) {
          throw Exception("Course not found");
        }

        Map<String, dynamic>? courseData = courseSnapshot.data() as Map<String, dynamic>?;
        List<dynamic> feedbacks = courseData?['feedbacks'] ?? [];
        int feedbackIndex = feedbacks.indexWhere((fb) => fb['userId'] == userId);
        if (feedbackIndex == -1) {
          throw Exception("Feedback not found for user");
        }

        print("Feedback found at index: $feedbackIndex");

        // Update feedback fields and adjust rating.
        feedbacks[feedbackIndex]['feedback'] = newFeedbackText;
        feedbacks[feedbackIndex]['rating'] = newRating;
        feedbacks[feedbackIndex]['date'] = Timestamp.fromDate(DateTime.now());

        double totalRating = 0;
        for (var fb in feedbacks) {
          totalRating += (fb['rating'] ?? 0).toDouble();
        }
        double newAverage = feedbacks.isNotEmpty ? totalRating / feedbacks.length : 0;
        print("Recalculated average rating: $newAverage");

        transaction.update(courseRef, {
          'feedbacks': feedbacks,
          'averageRating': newAverage,
        });

        print("Transaction update committed.");
      });

      print("Feedback update transaction completed successfully.");
      notifyListeners();
    } on FirebaseException catch (e) {
      print("FirebaseException in updateFeedback: ${e.message}");
      throw e;
    } catch (e, stackTrace) {
      print("Error in updateFeedback: $e");
      print("StackTrace: $stackTrace");
      throw e;
    }
  }

  /// Delete feedback for a user from a course.
  Future<void> deleteFeedback(String courseId, String userId) async {
    try {
      DocumentReference courseRef = _firestore.collection('courses').doc(courseId);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot courseSnapshot = await transaction.get(courseRef);
        if (!courseSnapshot.exists) {
          throw Exception("Course does not exist!");
        }
        List<dynamic> feedbacks = courseSnapshot.get('feedbacks') ?? [];
        feedbacks.removeWhere((fb) => fb['userId'] == userId);
        transaction.update(courseRef, {'feedbacks': feedbacks});
      });
    } catch (e) {
      throw Exception('Failed to delete feedback: $e');
    }
  }

  /// Retrieve all feedbacks for a given course.
  Future<List<FeedBack>?> getFeedbackByCourse(String courseId) async {
    try {
      Course? course = await getCourseById(courseId);
      if (course != null) {
        return course.feedbacks;
      } else {
        print('Course not found');
        return null;
      }
    } catch (e) {
      print('Error fetching feedbacks: $e');
      return null;
    }
  }

  // ============================================================================
  // USER & ENROLLMENT METHODS
  // ============================================================================

  /// Get the current authenticated user from Firebase Auth and Firestore.
  Future<CustomUser?> getCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          CustomUser currentUser = CustomUser.fromMap(
              userDoc.data() as Map<String, dynamic>, userDoc.id);
          return currentUser;
        } else {
          print('User document does not exist in Firestore.');
          return null;
        }
      } else {
        print('No user is currently signed in.');
        return null;
      }
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }

  /// Get all premium courses.
  Future<List<QueryDocumentSnapshot<Object?>>> getPremiumCourses() async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .where('status', isEqualTo: 'Premium')
          .get();
      return snapshot.docs;
    } catch (error) {
      throw error;
    }
  }

  /// Enroll a user in a course.
  Future<bool> enrollInCourse(String courseId, String userId) async {
    try {
      DocumentReference courseRef = _firestore.collection('courses').doc(courseId);
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot courseSnapshot = await transaction.get(courseRef);
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        if (!courseSnapshot.exists) {
          throw Exception("Course does not exist!");
        }
        if (!userSnapshot.exists) {
          throw Exception("User does not exist!");
        }
        List<dynamic> enrolledUsers = courseSnapshot.get('enrolledUserIds') ?? [];
        if (!enrolledUsers.contains(userId)) {
          transaction.update(courseRef, {
            'enrolledUserIds': FieldValue.arrayUnion([userId])
          });
        }
        List<dynamic> enrolledCourses = userSnapshot.get('enrolledCourses') ?? [];
        if (!enrolledCourses.contains(courseId)) {
          transaction.update(userRef, {
            'enrolledCourses': FieldValue.arrayUnion([courseId])
          });
        }
      });
      notifyListeners();
      return true;
    } catch (e) {
      print("Error enrolling in course: $e");
      return false;
    }
  }

  /// Unenroll a user from a course.
  Future<bool> unenrollFromCourse(String courseId, String userId) async {
    try {
      DocumentReference courseRef = _firestore.collection('courses').doc(courseId);
      DocumentReference userRef = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot courseSnapshot = await transaction.get(courseRef);
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        if (!courseSnapshot.exists) {
          throw Exception("Course does not exist!");
        }
        if (!userSnapshot.exists) {
          throw Exception("User does not exist!");
        }
        List<dynamic> enrolledUsers = courseSnapshot.get('enrolledUserIds') ?? [];
        if (enrolledUsers.contains(userId)) {
          transaction.update(courseRef, {
            'enrolledUserIds': FieldValue.arrayRemove([userId])
          });
        }
        List<dynamic> enrolledCourses = userSnapshot.get('enrolledCourses') ?? [];
        if (enrolledCourses.contains(courseId)) {
          transaction.update(userRef, {
            'enrolledCourses': FieldValue.arrayRemove([courseId])
          });
        }
      });
      notifyListeners();
      return true;
    } catch (e) {
      print("Error unenrolling from course: $e");
      return false;
    }
  }

  // ============================================================================
  // OTHER METHODS
  // ============================================================================

  /// Retrieve a course by its ID.
  Future<Course?> getCourseById(String courseId) async {
    try {
      DocumentSnapshot docSnapshot = await _firestore.collection('courses').doc(courseId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?;
        if (data != null) {
          return Course.fromMap(data, courseId);
        } else {
          print('Course data is null for the given ID');
          return null;
        }
      } else {
        print('No course found with the given ID');
        return null;
      }
    } catch (e) {
      print('Error getting course: $e');
      return null;
    }
  }

  /// Update the entire course document.
  Future<void> updateCourse(Course course) async {
    try {
      await _firestore.collection('courses').doc(course.id).update(course.toMap());
      notifyListeners();
    } catch (e) {
      print('Failed to update course: $e');
    }
  }

  /// Update a video’s details stored in a subcollection (if using subcollections for sections/videos).
  Future<void> updateVideo(String courseId, String sectionTitle, int videoIndex, String newTitle, String newVideoUrl) async {
    try {
      CollectionReference sectionsRef = _firestore.collection('courses').doc(courseId).collection('sections');
      QuerySnapshot query = await sectionsRef.where('sectionTitle', isEqualTo: sectionTitle).get();
      if (query.docs.isNotEmpty) {
        DocumentReference sectionDoc = query.docs.first.reference;
        CollectionReference videosRef = sectionDoc.collection('videos');
        QuerySnapshot videos = await videosRef.get();
        if (videoIndex < videos.docs.length) {
          DocumentReference videoDoc = videos.docs[videoIndex].reference;
          await videoDoc.update({
            'title': newTitle,
            'videoUrl': newVideoUrl,
          });
        } else {
          throw Exception("Video index out of range.");
        }
      } else {
        throw Exception("Section not found: $sectionTitle");
      }
    } catch (e) {
      print("Error updating video: $e");
      rethrow;
    }
  }

  /// Send a push notification to all users and also store a notification document.
  Future<void> sendNotificationToAllUsers({required String title, required String body}) async {
    try {
      QuerySnapshot userSnapshot = await _firestore.collection('users').get();
      for (var doc in userSnapshot.docs) {
        Map<String, dynamic>? userData = doc.data() as Map<String, dynamic>?;
        if (userData != null && userData.containsKey('fcmToken')) {
          String? token = userData['fcmToken'];
          if (token != null) {
            await _sendPushNotification(token, title, body);
          }
        }
        await _firestore.collection('notifications').add({
          'title': title,
          'body': body,
          'userId': doc.id,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    } catch (e) {
      print("Error sending notifications: $e");
    }
  }

  /// Helper method to send a push notification using Firebase Messaging.
  Future<void> _sendPushNotification(String token, String title, String body) async {
    try {
      await _firebaseMessaging.sendMessage(
        to: token,
        data: {
          'title': title,
          'body': body,
        },
      );
    } catch (e) {
      print("Error sending push notification: $e");
    }
  }

  /// Calculate the total earnings for a teacher based on courses created and enrollments.
  Future<double> calculateTeacherEarnings(String instructorEmail) async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('courses')
          .where('instructorEmail', isEqualTo: instructorEmail)
          .get();
      double totalEarnings = 0;
      for (var doc in querySnapshot.docs) {
        Map? courseData = doc.data() as Map?;
        if (courseData != null) {
          String courseId = doc.id;
          double price = (courseData['price'] as num?)?.toDouble() ?? 0.0;
          int enrollmentCount = await _getEnrollmentCount(courseId);
          totalEarnings += price * enrollmentCount;
        }
      }
      return totalEarnings;
    } catch (e) {
      print('Error calculating teacher earnings: $e');
      return 0;
    }
  }

  /// Helper method to count how many users are enrolled in a given course.
  Future<int> _getEnrollmentCount(String courseId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      int count = 0;
      for (var doc in querySnapshot.docs) {
        Map userData = doc.data() as Map;
        List? enrolledCourses = userData['enrolledCourses'];
        if (enrolledCourses != null) {
          bool isEnrolled = enrolledCourses.any((course) {
            if (course is Map && course['courseId'] == courseId) {
              return true;
            }
            return false;
          });
          if (isEnrolled) count++;
        }
      }
      return count;
    } catch (e) {
      print('Error fetching enrollment count: $e');
      return 0;
    }
  }
  Future<int> getNumberOfLoggedInUsers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isLoggedin', isEqualTo: true) // Adjust this field if needed.
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error fetching logged-in users: $e');
      return 0;
    }
  }

// Inside your CourseProvider class:
  Future<String?> uploadPdf(File pdfFile) async {
    try {
      // Create a unique file name based on the current time
      String fileName = 'pdf_${DateTime.now().millisecondsSinceEpoch}';
      // Create a reference in Firebase Storage under a folder named "course_pdfs"
      Reference ref = FirebaseStorage.instance.ref().child('course_pdfs/$fileName');
      // Upload the file to Firebase Storage
      await ref.putFile(pdfFile);
      // Get the download URL
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading PDF: $e");
      return null;
    }
  }
}