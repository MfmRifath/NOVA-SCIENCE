import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Import the json package

// Define the Video class
class Video {
  String title;
  String videoUrl;

  Video({required this.title, required this.videoUrl});

  // Method to create a Video from a map
  factory Video.fromMap(Map<String, dynamic> data) {
    return Video(
      title: data['title'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
    );
  }

  // Convert Video to a map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'videoUrl': videoUrl,
    };
  }
}

// Define the Section class
class Section {
  String sectionTitle;
  List<Video> videos;

  Section({required this.sectionTitle, required this.videos});

  factory Section.fromMap(Map<String, dynamic> data) {
    var videosData = data['videos'] ?? [];
    List<Video> videoList = List<Video>.from(
      videosData.map((videoData) => Video.fromMap(videoData)),
    );

    return Section(
      sectionTitle: data['sectionTitle'] ?? '',
      videos: videoList,
    );
  }

  // Convert Section to a map
  Map<String, dynamic> toMap() {
    return {
      'sectionTitle': sectionTitle,
      'videos': videos.map((video) => video.toMap()).toList(),
    };
  }
}

class Course {
  String? id; // Document ID
  String? courseTitle;
  String? description;
  double? price;
  DateTime? startDate;
  DateTime? endDate;
  String? instructor;
  String? duration;
  String? imageUrl;
  List<Section> sections;
  String? status;
  String? subject;

  Course({
    this.id,
    this.courseTitle,
    this.description,
    this.price,
    this.startDate,
    this.endDate,
    this.instructor,
    this.duration,
    this.imageUrl,
    this.sections = const [],
    this.status,
    this.subject,
  });

  // Method to create a Course from a map
  factory Course.fromMap(Map<String, dynamic> data, String? documentId) {
    // Ensure sections is parsed correctly as a list of Section objects
    List<Section> sectionList = [];

    if (data['sections'] is List) {
      sectionList = (data['sections'] as List).map((sectionData) {
        // Ensure sectionData is a Map
        if (sectionData is Map<String, dynamic>) {
          return Section.fromMap(sectionData);
        }
        return null; // or throw an exception if invalid data
      }).whereType<Section>().toList(); // Filter out any null values
    }

    return Course(
      id: documentId, // Set the document ID here
      courseTitle: data['courseTitle'] as String?,
      description: data['description'] as String?,
      price: (data['price'] as num?)?.toDouble(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      instructor: data['instructor'] as String?,
      duration: data['duration'] as String?,
      imageUrl: data['imageUrl'] as String?,
      status: data['status'] as String?,
      subject: data['subject'] as String?,
      sections: sectionList,
    );
  }
  // Convert Course to a map
  Map<String, dynamic> toMap() {
    return {
      'courseTitle': courseTitle,
      'description': description,
      'price': price,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'instructor': instructor,
      'duration': duration,
      'imageUrl': imageUrl,
      'status': status,
      'sections': sections.map((section) => section.toMap()).toList(),
      'subject': subject,
    };
  }
}
