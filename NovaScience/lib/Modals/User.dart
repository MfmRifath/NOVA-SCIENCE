import 'package:cloud_firestore/cloud_firestore.dart';

class CustomUser {
  final String? id; // The user id will now hold the document ID
  final String? name;
  final String? email;
  final String? role;
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? location;
  final Timestamp? birthday;
  final String? bio;
  final bool? isLoggedin;
  final Timestamp? registeredDate;

  CustomUser({
    this.id, // The user id will be assigned the document ID
    this.name,
    this.email,
    this.role,
    this.profileImageUrl,
    this.phoneNumber,
    this.location,
    this.birthday,
    this.bio,
    this.isLoggedin,
    this.registeredDate,
  });

  // Method to convert a map into a CustomUser object
  factory CustomUser.fromMap(Map<String, dynamic> map, String documentId) {
    return CustomUser(
      id: documentId, // Set the user id to be the Firestore document ID
      name: map['name'] as String?,
      email: map['email'] as String?,
      role: map['role'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      location: map['location'] as String?,
      birthday: map['birthday'] as Timestamp?,
      bio: map['bio'] as String?,
      isLoggedin: map['isLoggedin'] as bool?,
      registeredDate: map['registeredDate'] as Timestamp?,
    );
  }

  // Method to convert the registeredDate to DateTime
  DateTime? get registeredDateTime => registeredDate?.toDate();
}
