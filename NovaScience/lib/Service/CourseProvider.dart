import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../Modals/CourseAndSectionAndVideos.dart'; // Import your Course model

class CourseProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool hasError = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Assuming Firebase



  // Fetch courses from Firestore
  Future<void> fetchCourses() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('courses').get();
      // Removed _courses list functionality
      notifyListeners();
    } catch (e) {
      hasError = true;
      print('Error fetching courses: $e');
    }
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
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('course_images/$fileName');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Update the addCourse method to include image uploading
  Future<void> addCourse({String? title, String? description, double? price, DateTime? startDate, DateTime? endDate, String? instructor, String? duration, String? imageUrl, String? status}) async {
    // Create a new Course object
    Course newCourse = Course(
      courseTitle: title,
      description: description,
      price: price,
      startDate: startDate,
      endDate: endDate,
      instructor: instructor,
      duration: duration,
      imageUrl: imageUrl,
      status: status,
      sections: [],
    );

    // Add course to Firestore and get the document ID
    try {
      DocumentReference docRef = await FirebaseFirestore.instance.collection('courses').add(newCourse.toMap());
      // Removed _courses.add(newCourse) functionality
      notifyListeners();
    } catch (e) {
      print('Error adding course: $e');
    }
  }

  // Edit course method
  Future<void> editCourse(String id, String title, String description, double? price) async {
    try {
      await FirebaseFirestore.instance.collection('courses').doc(id).update({
        'courseTitle': title,
        'description': description,
        'price': price ,
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
      await FirebaseFirestore.instance.collection('courses').doc(courseId).update({
        'sections': FieldValue.arrayUnion([newSection.toMap()]), // Update Firestore directly
      });

      notifyListeners();
    } catch (e) {
      print('Error adding section: $e');
    }
  }

  // Edit section method
  Future<void> editSection(String courseId, int sectionIndex, String newTitle) async {
    try {
      // Logic for editing the section should also directly update Firestore
      await FirebaseFirestore.instance.collection('courses').doc(courseId).update({
        'sections.$sectionIndex.sectionTitle': newTitle, // Update Firestore directly
      });

      notifyListeners();
    } catch (e) {
      print('Error editing section: $e');
    }
  }

  // Delete section method
  Future<void> deleteSection(String courseId, int sectionIndex) async {
    try {
      // Logic for deleting the section should also directly update Firestore
      await FirebaseFirestore.instance.collection('courses').doc(courseId).update({
        'sections': FieldValue.arrayRemove([/* add the section to remove */]), // Implement the correct logic here
      });

      notifyListeners();
    } catch (e) {
      print('Error deleting section: $e');
    }
  }

  // Add video to section
  Future<void> addVideo(String courseId, int sectionIndex, String videoTitle, String videoUrl) async {
    try {
      Video newVideo = Video(title: videoTitle, videoUrl: videoUrl);

      await FirebaseFirestore.instance.collection('courses').doc(courseId).update({
        'sections.$sectionIndex.videos': FieldValue.arrayUnion([newVideo.toMap()]), // Update Firestore directly
      });

      notifyListeners();
    } catch (e) {
      print('Error adding video: $e');
    }
  }

  // Delete video from section
  Future<void> deleteVideo(String courseId, int sectionIndex, int videoIndex) async {
    try {
      await FirebaseFirestore.instance.collection('courses').doc(courseId).update({
        'sections.$sectionIndex.videos': FieldValue.arrayRemove([/* add the video to remove */]), // Implement the correct logic here
      });

      notifyListeners();
    } catch (e) {
      print('Error deleting video: $e');
    }
  }

  // Get course by ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      DocumentSnapshot docSnapshot =
      await FirebaseFirestore.instance.collection('courses').doc(courseId).get();

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
      await _firestore.collection('courses').doc(course.id).update(course.toMap()); // Assuming toMap method
      notifyListeners(); // Notify listeners of the change
    } catch (e) {
      print('Failed to update course: $e');
    }
  }
  Future<void> addVideoToSection(String courseId, String sectionTitle, Video video) async {
    try {
      // Fetch the course
      Course? course = await getCourseById(courseId);

      if (course != null) {
        // Find the section by its title
        Section? section = course.sections.firstWhere((sec) => sec.sectionTitle == sectionTitle);

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
}

