import 'package:cloud_firestore/cloud_firestore.dart';

class CustomUser {
  String? id;
  String? name;
  String? email;
  String? profileImageUrl;
  String? role; // 'Admin' or 'User'
  String? phoneNumber;
  String? location;
  DateTime? birthday;
  String? bio;
  bool? isLoggedin;
  DateTime? registeredDate;
  late final List<Enrollment>? enrollments;

  CustomUser({
    this.id,
    this.name,
    this.email,
    this.profileImageUrl,
    this.role,
    this.phoneNumber,
    this.location,
    this.birthday,
    this.bio,
    this.isLoggedin,
    this.registeredDate,
    this.enrollments,
  });

  factory CustomUser.fromMap(Map<String, dynamic> data, String documentId) {
    return CustomUser(
      id: documentId,
      name: data['name'],
      email: data['email'],
      profileImageUrl: data['profileImageUrl'],
      role: data['role'],
      phoneNumber: data['phoneNumber'],
      location: data['location'],
      birthday: data['birthday'] != null ? (data['birthday'] as Timestamp).toDate() : null,
      bio: data['bio'],
      isLoggedin: data['isLoggedin'],
      registeredDate: data['registeredDate'] != null ? (data['registeredDate'] as Timestamp).toDate() : null,
      enrollments: convertEnrollments(data['enrolledCourses']),
    );
  }

  static List<Enrollment>? convertEnrollments(dynamic firestoreData) {
    if (firestoreData == null) return null;

    return (firestoreData as List<dynamic>).map((e) {
      if (e is Map<String, dynamic>) {
        return Enrollment.fromMap(e);
      } else {
        throw Exception('Invalid enrollment format in Firestore');
      }
    }).toList();
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'phoneNumber': phoneNumber,
      'location': location,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'bio': bio,
      'isLoggedin': isLoggedin,
      'registeredDate': registeredDate != null ? Timestamp.fromDate(registeredDate!) : null,
      'enrolledCourses': enrollments?.map((e) => e.toMap()).toList() ?? [],
    };
  }

  /// **Public method to convert Firestore enrollments**

}

class Enrollment {
  final String courseId;
  final DateTime enrollmentDate;
  final DateTime endDate;

  Enrollment({
    required this.courseId,
    required this.enrollmentDate,
    required this.endDate,
  });

  factory Enrollment.fromMap(Map<String, dynamic> data) {
    return Enrollment(
      courseId: data['courseId'],
      enrollmentDate: (data['enrollmentDate'] as Timestamp).toDate(),
      endDate: (data['enrollmentEndDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'enrollmentDate': Timestamp.fromDate(enrollmentDate),
      'enrollmentEndDate': Timestamp.fromDate(endDate),
    };
  }
}