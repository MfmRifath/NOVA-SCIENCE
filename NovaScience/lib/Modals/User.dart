// CustomUser.dart
// Update your User model with these fields to fix the errors

import 'package:cloud_firestore/cloud_firestore.dart';

class CustomUser {
  final String? id;
  final String? name;
  final String? email;
  final String? role;
  final String? phoneNumber;
  final String? location;
  final DateTime? birthday;
  final String? bio;
  final String? profileImageUrl;
  final bool? isLoggedIn;
  final DateTime? registrationDate; // Changed from registeredDate to match usage
  final DateTime? lastActiveTime;   // Added this field
  final List<Enrollment>? enrollments;

  CustomUser({
    this.id,
    this.name,
    this.email,
    this.role,
    this.phoneNumber,
    this.location,
    this.birthday,
    this.bio,
    this.profileImageUrl,
    this.isLoggedIn = false,
    DateTime? registrationDate, // Allow both naming conventions
    DateTime? registeredDate,   // Allow both naming conventions
    this.lastActiveTime,
    this.enrollments,
  }) : this.registrationDate = registrationDate ?? registeredDate; // Use either name

  // Create a factory constructor to convert from Firestore
  factory CustomUser.fromMap(Map<String, dynamic> data, String documentId) {
    return CustomUser(
      id: documentId,
      name: data['name'],
      email: data['email'],
      role: data['role'],
      phoneNumber: data['phoneNumber'],
      location: data['location'],
      birthday: data['birthday'] != null ?
      (data['birthday'] as Timestamp).toDate() : null,
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      isLoggedIn: data['isLoggedin'] ?? false, // Note: matches Firestore field
      registrationDate: data['registeredDate'] != null ?
      (data['registeredDate'] as Timestamp).toDate() : null,
      lastActiveTime: data['lastActiveTime'] != null ?
      (data['lastActiveTime'] as Timestamp).toDate() :
      (data['lastLogin'] != null ? (data['lastLogin'] as Timestamp).toDate() : null),
      enrollments: convertEnrollments(data['enrolledCourses']),
    );
  }

  // Utility method to convert enrollments
  static List<Enrollment>? convertEnrollments(dynamic enrolledCourses) {
    if (enrolledCourses == null) return [];

    try {
      return (enrolledCourses as List).map((course) {
        if (course is Map<String, dynamic>) {
          return Enrollment.fromMap(course);
        }
        return Enrollment(courseId: 'unknown', enrollmentDate: DateTime.now());
      }).toList();
    } catch (e) {
      print('Error converting enrollments: $e');
      return [];
    }
  }

  // Create a copy with method to easily update user properties
  CustomUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phoneNumber,
    String? location,
    DateTime? birthday,
    String? bio,
    String? profileImageUrl,
    bool? isLoggedIn,
    DateTime? registrationDate,
    DateTime? lastActiveTime,
    List<Enrollment>? enrollments,
  }) {
    return CustomUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      birthday: birthday ?? this.birthday,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      registrationDate: registrationDate ?? this.registrationDate,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
      enrollments: enrollments ?? this.enrollments,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'location': location,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'isLoggedin': isLoggedIn,
      'registeredDate': registrationDate != null ?
      Timestamp.fromDate(registrationDate!) : null,
      'lastActiveTime': lastActiveTime != null ?
      Timestamp.fromDate(lastActiveTime!) : null,
      'enrolledCourses': enrollments?.map((e) => e.toMap()).toList(),
    };
  }
}

// Enrollment class for user's course enrollments
class Enrollment {
  final String courseId;
  final DateTime enrollmentDate;
  final DateTime? enrollmentEndDate;
  final String? status;

  Enrollment({
    required this.courseId,
    required this.enrollmentDate,
    this.enrollmentEndDate,
    this.status,
  });

  factory Enrollment.fromMap(Map<String, dynamic> map) {
    return Enrollment(
      courseId: map['courseId'] ?? '',
      enrollmentDate: map['enrollmentDate'] != null ?
      (map['enrollmentDate'] as Timestamp).toDate() : DateTime.now(),
      enrollmentEndDate: map['enrollmentEndDate'] != null ?
      (map['enrollmentEndDate'] as Timestamp).toDate() : null,
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'enrollmentDate': Timestamp.fromDate(enrollmentDate),
      'enrollmentEndDate': enrollmentEndDate != null ?
      Timestamp.fromDate(enrollmentEndDate!) : null,
      'status': status,
    };
  }
}