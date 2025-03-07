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
  bool? isLoggedIn;
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
    this.isLoggedIn,
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
      isLoggedIn: data['isLoggedin'] as bool?,
      registeredDate: data['registeredDate'] != null ? (data['registeredDate'] as Timestamp).toDate() : null,
      enrollments: convertEnrollments(data['enrolledCourses']),
    );
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
      'isLoggedin': isLoggedIn,
      'registeredDate': registeredDate != null ? Timestamp.fromDate(registeredDate!) : null,
      'enrolledCourses': enrollments?.map((e) => e.toMap()).toList() ?? [],
    };
  }
  static List<Enrollment>? convertEnrollments(dynamic firestoreData) {
    if (firestoreData == null) return [];

    try {
      List<Enrollment> enrollments = [];

      for (var item in firestoreData) {
        // Handle simple string IDs
        if (item is String) {
          enrollments.add(Enrollment(
            courseId: item,
            enrollmentDate: DateTime.now(),
            endDate: DateTime.now().add(Duration(days: 365)),
          ));
        }
        // Handle map format
        else if (item is Map<String, dynamic>) {
          enrollments.add(Enrollment.fromMap(item));
        }
      }

      return enrollments;
    } catch (e) {
      print('Error converting enrollments: $e');
      // Return empty list instead of null to prevent further errors
      return [];
    }
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
