// CourseAndSectionAndVideos.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  String? id;
  String? courseTitle;
  String? description;
  double? price;
  String? subject;
  String? imageUrl;
  String? status;
  String? duration;
  String? instructor;
  double? averageRating;
  List<String>? enrolledUserIds;
  List<Section> sections;
  List<FeedBack> feedbacks;

  Course({
    this.id,
    this.courseTitle,
    this.description,
    this.price,
    this.subject,
    this.duration,
    this.imageUrl,
    this.instructor,
    this.averageRating = 0.0,
    this.enrolledUserIds,
    this.status,
    this.sections = const [],
    this.feedbacks = const [],
  });

  factory Course.fromMap(Map<String, dynamic> data, String documentId) {
    return Course(
      id: documentId,
      courseTitle: data['courseTitle'],
      description: data['description'],
      price: data['price']?.toDouble(),
      imageUrl: data['imageUrl'],
      subject: data['subject'],
      duration: data['duration'],
      status: data['status'],
      instructor: data['instructor'],
      averageRating: data['averageRating']?.toDouble() ?? 0.0,
      enrolledUserIds: List<String>.from(data['enrolledUserIds'] ?? []),
      sections: (data['sections'] as List<dynamic>?)
          ?.map((section) => Section.fromMap(section))
          .toList() ??
          [],
      feedbacks: (data['feedbacks'] as List<dynamic>?)
          ?.map((fb) => FeedBack.fromMap(fb))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseTitle': courseTitle,
      'description': description,
      'price': price,
      'subject': subject,
      'duration': duration,
      'instructor': instructor,
      'averageRating': averageRating,
      'status':status,
      'imageUrl': imageUrl,
      'enrolledUserIds': enrolledUserIds ?? [],
      'sections': sections.map((s) => s.toMap()).toList(),
      'feedbacks': feedbacks.map((fb) => fb.toMap()).toList(),
    };
  }
}

class Section {
  String? sectionTitle;
  List<Video> videos;

  Section({this.sectionTitle, this.videos = const []});

  factory Section.fromMap(Map<String, dynamic> data) {
    return Section(
      sectionTitle: data['sectionTitle'],
      videos: (data['videos'] as List<dynamic>?)
          ?.map((video) => Video.fromMap(video))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sectionTitle': sectionTitle,
      'videos': videos.map((v) => v.toMap()).toList(),
    };
  }
}

class Video {
  String? title;
  String? videoUrl;

  Video({this.title, this.videoUrl});

  factory Video.fromMap(Map<String, dynamic> data) {
    return Video(
      title: data['title'],
      videoUrl: data['videoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'videoUrl': videoUrl,
    };
  }
}

class FeedBack {
  String? userId;
  String? userName;
  String? feedback;
  double? rating;
  Timestamp? date;

  FeedBack({
    this.userId,
    this.userName,
    this.feedback,
    this.rating,
    this.date,
  });

  factory FeedBack.fromMap(Map<String, dynamic> data) {
    return FeedBack(
      userId: data['userId'],
      userName: data['userName'],
      feedback: data['feedback'],
      rating: data['rating']?.toDouble(),
      date: data['date'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'feedback': feedback,
      'rating': rating,
      'date': date,
    };
  }
}