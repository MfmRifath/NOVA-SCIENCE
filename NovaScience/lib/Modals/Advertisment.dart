// models/advertisement.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum AdvertisementType { image, video }

class Advertisement {
  final String id;
  final AdvertisementType type;
  final String imageUrl;
  final String videoUrl;
  final String link; // Optional: URL to navigate when ad is tapped

  Advertisement({
    required this.id,
    required this.type,
    required this.imageUrl,
    required this.videoUrl,
    required this.link,
  });

  factory Advertisement.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Advertisement(
      id: doc.id,
      type: data['type'] == 'video' ? AdvertisementType.video : AdvertisementType.image,
      imageUrl: data['imageUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      link: data['link'] ?? '',
    );
  }
}