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
    // Debug print: log the raw data retrieved from Firestore.
    print('Creating CustomUser from data: $data with id: $documentId');

    return CustomUser(
      id: documentId,
      // Explicitly cast the value to String?
      name: data['name'] as String?,
      email: data['email'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      role: data['role'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      location: data['location'] as String?,
      birthday: data['birthday'] != null ? (data['birthday'] as Timestamp).toDate() : null,
      bio: data['bio'] as String?,
      isLoggedin: data['isLoggedin'] as bool?,
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
      'name': name ,
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
      courseId: data['courseId'] as String,
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