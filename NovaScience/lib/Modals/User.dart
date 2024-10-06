import 'package:cloud_firestore/cloud_firestore.dart';

class CustomUser {
  final String? id;
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
    this.id,
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
  DateTime? get registeredDateTime => registeredDate?.toDate();
}