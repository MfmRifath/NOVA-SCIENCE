import 'package:flutter/material.dart';

enum AdvertisementType { image, video, whatsapp, telegram }

class Advertisement {
  final String id;
  final AdvertisementType type;
  final String imageUrl;
  final String videoUrl;
  final String link;
  final String title;       // Added title field
  final String description; // Added description field
  final DateTime startDate; // Added date range for scheduling
  final DateTime endDate;
  final bool isActive;      // Added active status

  Advertisement({
    required this.id,
    required this.type,
    this.imageUrl = '',
    this.videoUrl = '',
    this.link = '',
    this.title = '',
    this.description = '',
    DateTime? startDate,
    DateTime? endDate,
    this.isActive = true,
  }) :
        this.startDate = startDate ?? DateTime.now(),
        this.endDate = endDate ?? DateTime.now().add(Duration(days: 30));

  // Create a copy of advertisement with updated fields
  Advertisement copyWith({
    String? id,
    AdvertisementType? type,
    String? imageUrl,
    String? videoUrl,
    String? link,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Advertisement(
      id: id ?? this.id,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      link: link ?? this.link,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  // Create a map for storing in database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'link': link,
      'title': title,
      'description': description,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'isActive': isActive,
    };
  }

  // Create advertisement from map
  factory Advertisement.fromMap(Map<String, dynamic> map, String documentId) {
    return Advertisement(
      id: documentId,
      type: AdvertisementType.values[map['type'] ?? 0],
      imageUrl: map['imageUrl'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      link: map['link'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'])
          : null,
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
          : null,
      isActive: map['isActive'] ?? true,
    );
  }
}
