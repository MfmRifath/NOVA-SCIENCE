// CustomUser.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CustomUser {
  String? id;
  String? name;
  String? email;
  String? profileImageUrl;
  String? role; // 'Admin' or 'User'
  String? phoneNumber;
  String? location;
  Timestamp? birthday;
  String? bio;
  bool? isLoggedin;
  Timestamp? registeredDate;
  List<String>? enrolledCourses;

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
    this.enrolledCourses,
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
      birthday: data['birthday'],
      bio: data['bio'],
      isLoggedin: data['isLoggedin'],
      registeredDate: data['registeredDate'],
      enrolledCourses: List<String>.from(data['enrolledCourses'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'role': role,
      'phoneNumber': phoneNumber,
      'location': location,
      'birthday': birthday,
      'bio': bio,
      'isLoggedin': isLoggedin,
      'registeredDate': registeredDate,
      'enrolledCourses': enrolledCourses ?? [],
    };
  }
}