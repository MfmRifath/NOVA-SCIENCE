import 'package:cloud_firestore/cloud_firestore.dart';




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
// Define the Section class
// Define the FeedBack class
class FeedBack {
  String userId;
  String userName;
  String feedback;
  Timestamp? date;

  FeedBack({required this.userName, required this.feedback, this.date, required this.userId});

  // Method to create FeedBack from a map
  factory FeedBack.fromMap(Map<String, dynamic> data) {
    return FeedBack(
      userName: data['userName'] ?? '',
      feedback: data['feedback'] ?? '',
      date: data['date'] ?? '',
      userId: data['userId']

    );
  }

  // Convert FeedBack to a map
  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'feedback': feedback,
      'date':date,
      'userId':userId
    };
  }
}

// Updated Course class
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
  List<FeedBack> feedbacks; // Feedback list
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
    this.feedbacks = const [], // Initialize feedbacks
  });

  // Method to create a Course from a map
  factory Course.fromMap(Map<String, dynamic> data, String? documentId) {
    // Parse sections
    List<Section> sectionList = [];
    if (data['sections'] is List) {
      sectionList = (data['sections'] as List).map((sectionData) {
        if (sectionData is Map<String, dynamic>) {
          return Section.fromMap(sectionData);
        }
        return null;
      }).whereType<Section>().toList();
    }

    // Parse feedbacks
    List<FeedBack> feedbackList = [];
    if (data['feedbacks'] is List) {
      feedbackList = (data['feedbacks'] as List).map((feedbackData) {
        if (feedbackData is Map<String, dynamic>) {
          return FeedBack.fromMap(feedbackData);
        }
        return null;
      }).whereType<FeedBack>().toList();
    }

    return Course(
      id: documentId,
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
      feedbacks: feedbackList, // Assign parsed feedbacks
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
      'feedbacks': feedbacks.map((feedback) => feedback.toMap()).toList(), // Map feedbacks
      'subject': subject,
    };
  }
}
