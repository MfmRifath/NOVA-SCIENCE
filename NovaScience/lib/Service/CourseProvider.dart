import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Modals/CourseAndSectionAndVideos.dart'; // Import your Course model

class CourseProvider with ChangeNotifier {
  List<Course> _courses = []; // Holds all courses

  List<Course> get courses => _courses; // Getter for courses

  // Fetch courses from Firestore
  Future<void> fetchCourses() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('courses').get();
      _courses = snapshot.docs.map((doc) {
        return Course.fromFirestore(doc.data() as DocumentSnapshot<Object?>)..id = doc.id;
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching courses: $e');
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
  Future<void> addCourse({String? title, String? description, double? price, DateTime? startDate, DateTime? endDate, String? instructor, String? duration, String? imageUrl}) async {
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
      sections: [],
    );

    // Add course to Firestore and get the document ID
    try {
      DocumentReference docRef = await FirebaseFirestore.instance.collection('courses').add(newCourse.toMap());
      newCourse.id = docRef.id;
      _courses.add(newCourse);
      notifyListeners();
    } catch (e) {
      print('Error adding course: $e');
    }
  }
  // Edit course method
  Future<void> editCourse(String id, String title, String description, double price) async {
    try {
      await FirebaseFirestore.instance.collection('courses').doc(id).update({
        'courseTitle': title,
        'description': description,
        'price': price,
      });

      // Update locally
      final course = _courses.firstWhere((course) => course.id == id);
      course.courseTitle = title;
      course.description = description;
      course.price = price;
      notifyListeners();
    } catch (e) {
      print('Error editing course: $e');
    }
  }

  // Delete course method
  Future<void> deleteCourse(String? id) async {
    try {
      await FirebaseFirestore.instance.collection('courses').doc(id).delete();
      _courses.removeWhere((course) => course.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting course: $e');
    }
  }

  // Add section to a course
  Future<void> addSection(String courseId, String title) async {
    try {
      final course = _courses.firstWhere((course) => course.id == courseId);
      Section newSection = Section(sectionTitle: title, videos: []);
      course.sections!.add(newSection);

      await FirebaseFirestore.instance.collection('courses').doc(course.id).update({
        'sections': course.sections!.map((s) => s.toMap()).toList(),
      });

      notifyListeners();
    } catch (e) {
      print('Error adding section: $e');
    }
  }

  // Edit section method
  Future<void> editSection(int courseIndex, int sectionIndex, String newTitle) async {
    try {
      final course = _courses[courseIndex];
      course.sections![sectionIndex].sectionTitle = newTitle;

      await FirebaseFirestore.instance.collection('courses').doc(course.id).update({
        'sections': course.sections!.map((s) => s.toMap()).toList(),
      });

      notifyListeners();
    } catch (e) {
      print('Error editing section: $e');
    }
  }

  // Delete section method
  Future<void> deleteSection(int courseIndex, int sectionIndex) async {
    try {
      final course = _courses[courseIndex];
      course.sections!.removeAt(sectionIndex);

      await FirebaseFirestore.instance.collection('courses').doc(course.id).update({
        'sections': course.sections!.map((s) => s.toMap()).toList(),
      });

      notifyListeners();
    } catch (e) {
      print('Error deleting section: $e');
    }
  }

  // Add video to section
  Future<void> addVideo(int courseIndex, int sectionIndex, String videoTitle, String videoUrl) async {
    try {
      final course = _courses[courseIndex];

      if (sectionIndex < 0 || sectionIndex >= course.sections!.length) {
        print('Invalid section index');
        return;
      }

      Video newVideo = Video(title: videoTitle, videoUrl: videoUrl);
      course.sections![sectionIndex].videos.add(newVideo);

      await FirebaseFirestore.instance.collection('courses').doc(course.id).update({
        'sections': course.sections!.map((s) => s.toMap()).toList(),
      });

      notifyListeners();
    } catch (e) {
      print('Error adding video: $e');
    }
  }

  // Delete video from section
  Future<void> deleteVideo(int courseIndex, int sectionIndex, int videoIndex) async {
    try {
      final course = _courses[courseIndex];

      if (sectionIndex < 0 || sectionIndex >= course.sections!.length) {
        print('Invalid section index');
        return;
      }

      course.sections![sectionIndex].videos.removeAt(videoIndex);

      await FirebaseFirestore.instance.collection('courses').doc(course.id).update({
        'sections': course.sections!.map((s) => s.toMap()).toList(),
      });

      notifyListeners();
    } catch (e) {
      print('Error deleting video: $e');
    }
  }

  // Get course by ID
  Course? getCourseById(String id) {
    try {
      return _courses.firstWhere((course) => course.id == id);
    } catch (e) {
      print('Course with ID $id not found.');
      return null;
    }
  }
}
