import 'package:cloud_firestore/cloud_firestore.dart';

// Video class
class Video {
  late final String title;
  final String videoUrl;
  final String? duration;

  Video({required this.title, required this.videoUrl, this.duration});

  // Factory constructor to create a Video from Firestore document
  factory Video.fromFirestore(Map<String, dynamic> data) {
    return Video(
      title: data['title'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      duration: data['duration']
    );
  }

  // Convert Video instance to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'videoUrl': videoUrl,
    };
  }
}

// Section class
class Section {
  late final String sectionTitle;
  final List<Video> videos;

  Section({required this.sectionTitle, required this.videos});

  // Factory constructor to create a Section from Firestore document
  factory Section.fromFirestore(Map<String, dynamic> data) {
    return Section(
      sectionTitle: data['sectionTitle'] ?? '',
      videos: (data['videos'] as List<dynamic>? ?? [])
          .map((videoData) => Video.fromFirestore(videoData))
          .toList(),
    );
  }

  // Convert Section instance to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'sectionTitle': sectionTitle,
      'videos': videos.map((video) => video.toMap()).toList(),
    };
  }
}

// Course class
class Course {
  late final String? id;
  late final String? courseTitle;
  late final String? description;
  final DateTime? startDate; // Start date of the course
  final DateTime? endDate; // End date of the course
  final int? enrolledStudents; // Number of students enrolled in the course
  // Duration of the course
  final String? instructor; // Instructor name
  final String? imageUrl; // URL of the course image (nullable)
  late final double? price;
  final List<Section>? sections;
  late final String? duration;

  Course({
    this.courseTitle,
    this.sections,
    this.id,
    this.duration,
    this.description,
    this.startDate,
    this.endDate,
    this.enrolledStudents = 0, // Default to 0 if not provided
    this.instructor,
    this.imageUrl, // Nullable image URL
    this.price,
  });

  // Factory constructor to create a Course from Firestore document
  factory Course.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id, // Get the document ID
      courseTitle: data['courseTitle'] ?? '',
      sections: (data['sections'] as List<dynamic>? ?? [])
          .map((section) => Section.fromFirestore(section))
          .toList(),
      description: data['description'] ??'',
      startDate: data['startDate'] ,
      endDate: data['endDate'] ,
      enrolledStudents: data['enrolledStudents'],
      instructor: data['instructor'] ?? '',
      price: data['price']
    );
  }

  // Convert Course instance to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'courseTitle': courseTitle,
      'sections': sections?.map((section) => section.toMap()).toList() ?? [],
      'description': description,
      'startDate':startDate,
      'endDate':endDate,
      'enrolledStudents': enrolledStudents,
      'instructor':instructor,
      'price':price
    };
  }
}
