import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../Modals/CourseAndSectionAndVideos.dart';
import '../Modals/User.dart'; // Import your Course model

class CourseProvider with ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool hasError = false;
  final FirebaseFirestore _firestore = FirebaseFirestore
      .instance; // Assuming Firebase
  FirebaseAuth? auth;


  // Fetch courses from Firestore
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
  Future<List<QueryDocumentSnapshot<Object?>>?> getEnrolledCourses(String userId) async {
    try {
      // Fetch the user's document
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final enrolledCourseIds = List<String>.from(userData['enrolledCourses'] ?? []);

        if (enrolledCourseIds.isNotEmpty) {
          // Fetch courses matching the enrolled course IDs
          QuerySnapshot coursesSnapshot = await FirebaseFirestore.instance
              .collection('courses')
              .where(FieldPath.documentId, whereIn: enrolledCourseIds)
              .get();

          return coursesSnapshot.docs;
        }
      }
    } catch (e) {
      print('Error fetching enrolled courses: $e');
    }
    return [];
  }
  // Fetch free courses from Firestore
  Future<List<QueryDocumentSnapshot<Object?>>?> getFreeCourses() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('status', isEqualTo: 'free') // Filtering by status
          .get();
      return snapshot.docs;
      notifyListeners();
    } catch (e) {
      hasError = true;
      print('Error fetching free courses: $e');
    }
  }

  // Fetch my premium courses from Firestore
  Future<List<QueryDocumentSnapshot<Object?>>?> getMyCourses() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('status', isEqualTo: 'premium') // Filtering by status
          .get();
      return snapshot.docs;
      notifyListeners();
    } catch (e) {
      hasError = true;
      print('Error fetching premium courses: $e');
    }
  }

  // Upload image to Firebase Storage
  Future<String?> uploadImage(File imageFile) async {
    try {
      String fileName = DateTime
          .now()
          .millisecondsSinceEpoch
          .toString();
      Reference ref = FirebaseStorage.instance.ref().child(
          'course_images/$fileName');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Update the addCourse method to include image uploading
  Future<void> addCourse(
      {String? title, String? description, double? price, DateTime? startDate, DateTime? endDate, String? instructor, String? duration, String? imageUrl, String? status, String? subject}) async {
    // Create a new Course object
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
    );

    // Add course to Firestore and get the document ID
    try {
      DocumentReference docRef = await FirebaseFirestore.instance.collection(
          'courses').add(newCourse.toMap());
      // Removed _courses.add(newCourse) functionality
      notifyListeners();
    } catch (e) {
      print('Error adding course: $e');
    }
  }

  // Edit course method
  Future<void> editCourse(String id, String title, String description,
      double? price, String subject) async {
    try {
      await FirebaseFirestore.instance.collection('courses').doc(id).update({
        'courseTitle': title,
        'description': description,
        'price': price,
        'subject': subject,
      });

      // Removed local course update
      notifyListeners();
    } catch (e) {
      print('Error editing course: $e');
    }
  }

  // Delete course method
  Future<void> deleteCourse(String? id) async {
    try {
      await FirebaseFirestore.instance.collection('courses').doc(id).delete();
      // Removed local course deletion
      notifyListeners();
    } catch (e) {
      print('Error deleting course: $e');
    }
  }

  // Add section to a course
  Future<void> addSection(String courseId, String title) async {
    try {
      // Removed local course retrieval
      Section newSection = Section(sectionTitle: title, videos: []);
      // Assume that you will retrieve course sections here directly from Firestore instead
      await FirebaseFirestore.instance.collection('courses')
          .doc(courseId)
          .update({
        'sections': FieldValue.arrayUnion([newSection.toMap()]),
        // Update Firestore directly
      });

      notifyListeners();
    } catch (e) {
      print('Error adding section: $e');
    }
  }

  // Edit section method
  // Edit section method
  Future<void> editSection(String courseId, String oldTitle,
      String newTitle) async {
    try {
      // Fetch the course
      Course? course = await getCourseById(courseId);

      if (course != null) {
        // Find the section to edit
        Section? section = course.sections.firstWhere((sec) =>
        sec.sectionTitle == oldTitle);

        if (section != null) {
          // Update the section title
          section.sectionTitle = newTitle;

          // Update Firestore with the modified course data
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

  // Delete section method
  // Delete section method
  Future<void> deleteSection(String courseId, String sectionTitle) async {
    try {
      // Fetch the course
      Course? course = await getCourseById(courseId);

      if (course != null) {
        // Find the section to delete, handle the case where it might not be found
        Section? section = course.sections.firstWhere(
              (sec) =>
          sec.sectionTitle == sectionTitle, // Use orElse to avoid an exception
        );

        if (section != null) {
          // Remove the section from the course
          course.sections.remove(section);

          // Update Firestore with the new sections array
          await updateCourse(course);

          // Notify listeners to update the UI
          notifyListeners();
        } else {
          print('Section "$sectionTitle" not found in course "$courseId".');
        }
      } else {
        print('Course with ID "$courseId" not found.');
      }
    } catch (e) {
      print('Failed to delete section: $e');
      // Optionally, you could rethrow the error or handle it in another way
      // throw e; // Uncomment this line if you want to propagate the error
    }
  }


  // Add video to section
  Future<void> addVideo(String courseId, int sectionIndex, String videoTitle,
      String videoUrl) async {
    try {
      Video newVideo = Video(title: videoTitle, videoUrl: videoUrl);

      await FirebaseFirestore.instance.collection('courses')
          .doc(courseId)
          .update({
        'sections.$sectionIndex.videos': FieldValue.arrayUnion(
            [newVideo.toMap()]), // Update Firestore directly
      });

      notifyListeners();
    } catch (e) {
      print('Error adding video: $e');
    }
  }

  // Delete video from section
  // Delete video method
  Future<void> deleteVideo(String courseId, String sectionTitle,
      int videoIndex) async {
    try {
      // Fetch the course
      Course? course = await getCourseById(courseId);

      if (course != null) {
        // Find the section
        Section? section = course.sections.firstWhere((sec) =>
        sec.sectionTitle == sectionTitle);

        if (section != null && videoIndex >= 0 &&
            videoIndex < section.videos.length) {
          // Remove the video from the section
          section.videos.removeAt(videoIndex);

          // Update Firestore with the modified course data
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
    // In CourseProvider


  }

  Future<int> getNumberOfLoggedInUsers() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('isOnline', isEqualTo: true) // or however you track presence
          .get();

      return query.docs.length;
    } catch (e) {
      print('Error fetching logged-in users: $e');
      return 0;
    }
  }
  // Get course by ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      DocumentSnapshot docSnapshot =
      await FirebaseFirestore.instance.collection('courses')
          .doc(courseId)
          .get();

      if (docSnapshot.exists) {
        // Ensure the data is properly cast to Map<String, dynamic>
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

  Future<void> updateCourse(Course course) async {
    try {
      await _firestore.collection('courses').doc(course.id).update(
          course.toMap()); // Assuming toMap method
      notifyListeners(); // Notify listeners of the change
    } catch (e) {
      print('Failed to update course: $e');
    }
  }

  Future<void> addVideoToSection(String courseId, String sectionTitle,
      Video video) async {
    try {
      // Fetch the course
      Course? course = await getCourseById(courseId);

      if (course != null) {
        // Find the section by its title
        Section? section = course.sections.firstWhere((sec) =>
        sec.sectionTitle == sectionTitle);

        if (section != null) {
          // Add the video to the section
          section.videos.add(video);

          // Update the course with the new video added to the section
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

  // Edit video method
  // Edit video method
  Future<void> editVideo(String courseId, String sectionTitle, int videoIndex,
      String newTitle, String newUrl) async {
    try {
      // Fetch the course
      Course? course = await getCourseById(courseId);

      if (course != null) {
        // Find the section
        Section? section = course.sections.firstWhere((sec) =>
        sec.sectionTitle == sectionTitle);

        if (section != null && videoIndex >= 0 &&
            videoIndex < section.videos.length) {
          // Update the video details
          section.videos[videoIndex].title = newTitle;
          section.videos[videoIndex].videoUrl = newUrl;

          // Update Firestore with the modified course data
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

// Add feedback to a course
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

      // Fetch current average rating and number of feedbacks
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
      throw e; // Rethrow to allow upstream handling
    }
  }


// Delete feedback method
  Future<void> deleteFeedback(String courseId, int feedbackIndex) async {
    try {
      // Fetch the course
      Course? course = await getCourseById(courseId);

      if (course != null && feedbackIndex >= 0 &&
          feedbackIndex < course.feedbacks.length) {
        // Remove the feedback from the course
        course.feedbacks.removeAt(feedbackIndex);

        // Update Firestore with the modified course data
        await updateCourse(course);
        notifyListeners();
      } else {
        print('Invalid feedback index or course not found');
      }
    } catch (e) {
      print('Failed to delete feedback: $e');
    }
  }

// Fetch feedbacks for a specific course
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

  Future<CustomUser?> getCurrentUser() async {
    try {
      // Fetch the current user from Firebase Authentication
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Check if user exists in Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          // Pass both the user data and document ID to the CustomUser.fromMap method
          CustomUser currentUser = CustomUser.fromMap(
              userDoc.data() as Map<String, dynamic>, userDoc.id);  // Pass both arguments
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
  Future<List<QueryDocumentSnapshot<Object?>>> getPremiumCourses() async {
    try {
      // Query Firestore for courses where the status is "Premium"
      final snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('status', isEqualTo: 'Premium')
          .get();
      return snapshot.docs;
    } catch (error) {
      throw error;
    }
  }
  // Enroll User in a Course
  // Enroll User in a Course
  Future<bool> enrollInCourse(String courseId, String userId) async {
    try {
      DocumentReference courseRef = _firestore.collection('courses').doc(courseId);
      DocumentReference userRef = _firestore.collection('users').doc(userId);

      // Use a transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot courseSnapshot = await transaction.get(courseRef);
        DocumentSnapshot userSnapshot = await transaction.get(userRef);

        if (!courseSnapshot.exists) {
          throw Exception("Course does not exist!");
        }

        if (!userSnapshot.exists) {
          throw Exception("User does not exist!");
        }

        // Update enrolledUserIds in Course
        List<dynamic> enrolledUsers = courseSnapshot.get('enrolledUserIds') ?? [];
        if (!enrolledUsers.contains(userId)) {
          transaction.update(courseRef, {
            'enrolledUserIds': FieldValue.arrayUnion([userId])
          });
        }

        // Update enrolledCourses in User
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

  // Unenroll User from a Course
  Future<bool> unenrollFromCourse(String courseId, String userId) async {
    try {
      DocumentReference courseRef = _firestore.collection('courses').doc(courseId);
      DocumentReference userRef = _firestore.collection('users').doc(userId);

      // Use a transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot courseSnapshot = await transaction.get(courseRef);
        DocumentSnapshot userSnapshot = await transaction.get(userRef);

        if (!courseSnapshot.exists) {
          throw Exception("Course does not exist!");
        }

        if (!userSnapshot.exists) {
          throw Exception("User does not exist!");
        }

        // Update enrolledUserIds in Course
        List<dynamic> enrolledUsers = courseSnapshot.get('enrolledUserIds') ?? [];
        if (enrolledUsers.contains(userId)) {
          transaction.update(courseRef, {
            'enrolledUserIds': FieldValue.arrayRemove([userId])
          });
        }

        // Update enrolledCourses in User
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
  /// Updates existing feedback for a user.
  Future<void> updateFeedback(String courseId, String userId, String feedbackText, double rating) async {
    try {
      CollectionReference feedbacksRef =
      _firestore.collection('courses').doc(courseId).collection('feedbacks');

      QuerySnapshot query = await feedbacksRef.where('userId', isEqualTo: userId).get();

      if (query.docs.isNotEmpty) {
        DocumentReference feedbackDoc = query.docs.first.reference;
        await feedbackDoc.update({
          'feedback': feedbackText,
          'rating': rating,
          'date': FieldValue.serverTimestamp(),
        });

        // Optionally, update the course's average rating here
        await _updateAverageRating(courseId);
      } else {
        throw Exception("Feedback not found for user ID: $userId");
      }
    } catch (e) {
      print("Error updating feedback: $e");
      rethrow;
    }
  }
  /// Updates the average rating of a course based on all feedbacks.
  Future<void> _updateAverageRating(String courseId) async {
    try {
      CollectionReference feedbacksRef =
      _firestore.collection('courses').doc(courseId).collection('feedbacks');

      QuerySnapshot feedbacks = await feedbacksRef.get();

      if (feedbacks.docs.isNotEmpty) {
        double totalRating = 0.0;
        feedbacks.docs.forEach((doc) {
          totalRating += doc['rating'] ?? 0.0;
        });

        double averageRating = totalRating / feedbacks.docs.length;

        await _firestore.collection('courses').doc(courseId).update({
          'averageRating': averageRating,
        });
      } else {
        // If no feedbacks, set averageRating to 0
        await _firestore.collection('courses').doc(courseId).update({
          'averageRating': 0.0,
        });
      }
    } catch (e) {
      print("Error updating average rating: $e");
    }
  }
  /// Updates a video's details in a specific section.
  Future<void> updateVideo(String courseId, String sectionTitle,
      int videoIndex, String newTitle, String newVideoUrl) async {
    try {
      CollectionReference sectionsRef =
      _firestore.collection('courses').doc(courseId).collection('sections');

      QuerySnapshot query =
      await sectionsRef.where('sectionTitle', isEqualTo: sectionTitle).get();

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

}

