// GroupMember.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMember {
  final String userId;
  final String name;
  final String? role; // 'admin', 'member', etc.
  final bool notifications;
  final DateTime joinedAt;
  final String? profileImageUrl;
  final Map<String, dynamic>? preferences;

  GroupMember({
    required this.userId,
    required this.name,
    this.role = 'member',
    this.notifications = true,
    required this.joinedAt,
    this.profileImageUrl,
    this.preferences,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'role': role,
      'notifications': notifications,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'profileImageUrl': profileImageUrl,
      'preferences': preferences ?? {},
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Unknown',
      role: map['role'] ?? 'member',
      notifications: map['notifications'] ?? true,
      joinedAt: map['joinedAt'] != null
          ? (map['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
      profileImageUrl: map['profileImageUrl'],
      preferences: map['preferences'],
    );
  }

  // Create a copy with method to easily update member properties
  GroupMember copyWith({
    String? userId,
    String? name,
    String? role,
    bool? notifications,
    DateTime? joinedAt,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      role: role ?? this.role,
      notifications: notifications ?? this.notifications,
      joinedAt: joinedAt ?? this.joinedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      preferences: preferences ?? this.preferences,
    );
  }
}