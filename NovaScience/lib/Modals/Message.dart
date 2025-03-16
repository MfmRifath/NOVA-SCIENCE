import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final String? mediaType;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaType,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      mediaUrl: data['mediaUrl'],
      mediaThumbnailUrl: data['mediaThumbnailUrl'],
      mediaType: data['mediaType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'mediaUrl': mediaUrl,
      'mediaThumbnailUrl': mediaThumbnailUrl,
      'mediaType': mediaType,
    };
  }
}

class DiscussionGroup {
  final String id;
  final String name;
  final String description;
  final String category;
  final String createdBy;
  final String creatorName;
  final DateTime createdAt;
  final int memberCount;
  final List<String> members;
  final List<String> admins;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final int messageCount;

  DiscussionGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.createdBy,
    required this.creatorName,
    required this.createdAt,
    required this.memberCount,
    required this.members,
    required this.admins,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.messageCount = 0,
  });

  factory DiscussionGroup.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return DiscussionGroup(
      id: doc.id,
      name: data['name'] ?? 'Unknown Group',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      createdBy: data['createdBy'] ?? '',
      creatorName: data['creatorName'] ?? 'Unknown',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      memberCount: data['memberCount'] ?? 0,
      members: List<String>.from(data['members'] ?? []),
      admins: List<String>.from(data['admins'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: data['lastMessageSenderId'],
      messageCount: data['messageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'memberCount': memberCount,
      'members': members,
      'admins': admins,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastMessageSenderId': lastMessageSenderId,
      'messageCount': messageCount,
    };
  }
}

class OnlineUser {
  final String userId;
  final String name;
  final DateTime lastActive;
  final bool isOnline;

  OnlineUser({
    required this.userId,
    required this.name,
    required this.lastActive,
    required this.isOnline,
  });

  factory OnlineUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return OnlineUser(
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Anonymous',
      lastActive: data['lastActive'] != null
          ? (data['lastActive'] as Timestamp).toDate()
          : DateTime.now(),
      isOnline: data['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'lastActive': Timestamp.fromDate(lastActive),
      'isOnline': isOnline,
    };
  }
}