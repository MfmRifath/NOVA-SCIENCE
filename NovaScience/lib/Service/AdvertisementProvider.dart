
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import '../Modals/Advertisment.dart';


class AdvertisementProvider with ChangeNotifier {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final FirebaseStorage _storage = FirebaseStorage.instance;
List<Advertisement> _advertisements = [];
bool _isLoading = true;

List<Advertisement> get advertisements => _activeAndCurrentAdvertisements;
List<Advertisement> get allAdvertisements => _advertisements;
bool get isLoading => _isLoading;

// Get only active and current advertisements (within date range)
List<Advertisement> get _activeAndCurrentAdvertisements {
final now = DateTime.now();
return _advertisements.where((ad) =>
ad.isActive &&
ad.startDate.isBefore(now) &&
ad.endDate.isAfter(now)
).toList();
}

// Initialize and load advertisements from Firestore
Future<void> loadAdvertisements() async {
_isLoading = true;
notifyListeners();

try {
final snapshot = await _firestore.collection('advertisements').get();
_advertisements = snapshot.docs
    .map((doc) => Advertisement.fromMap(doc.data(), doc.id))
    .toList();
_isLoading = false;
notifyListeners();
} catch (e) {
_isLoading = false;
print('Error loading advertisements: $e');
notifyListeners();
rethrow;
}
}

// Upload image to Firebase Storage
Future<String> uploadImage(String imagePath) async {
final File imageFile = File(imagePath);
final fileName = path.basename(imageFile.path);
final timestamp = DateTime.now().millisecondsSinceEpoch;
final storagePath = 'advertisements/$timestamp-$fileName';

try {
final uploadTask = _storage.ref(storagePath).putFile(imageFile);
final snapshot = await uploadTask;
return await snapshot.ref.getDownloadURL();
} catch (e) {
print('Error uploading image: $e');
rethrow;
}
}

// Add new advertisement
Future<void> addAdvertisement(
Advertisement advertisement, {
String? localImagePath,
}) async {
try {
String adId = _firestore.collection('advertisements').doc().id;
String imageUrl = advertisement.imageUrl;

// Upload local image if provided
if (localImagePath != null && advertisement.type == AdvertisementType.image) {
imageUrl = await uploadImage(localImagePath);
}

final newAdvertisement = advertisement.copyWith(
id: adId,
imageUrl: imageUrl,
);

await _firestore
    .collection('advertisements')
    .doc(adId)
    .set(newAdvertisement.toMap());

_advertisements.add(newAdvertisement);
notifyListeners();
} catch (e) {
print('Error adding advertisement: $e');
rethrow;
}
}

// Update existing advertisement
Future<void> updateAdvertisement(
Advertisement advertisement, {
String? localImagePath,
}) async {
try {
String imageUrl = advertisement.imageUrl;

// Upload local image if provided
if (localImagePath != null && advertisement.type == AdvertisementType.image) {
imageUrl = await uploadImage(localImagePath);
}

final updatedAdvertisement = advertisement.copyWith(
imageUrl: imageUrl,
);

await _firestore
    .collection('advertisements')
    .doc(updatedAdvertisement.id)
    .update(updatedAdvertisement.toMap());

final index = _advertisements.indexWhere((ad) => ad.id == updatedAdvertisement.id);
if (index != -1) {
_advertisements[index] = updatedAdvertisement;
}
notifyListeners();
} catch (e) {
print('Error updating advertisement: $e');
rethrow;
}
}

// Delete advertisement
Future<void> deleteAdvertisement(String id) async {
try {
// Get the advertisement to check if we need to delete from storage
final adIndex = _advertisements.indexWhere((ad) => ad.id == id);
if (adIndex != -1) {
final ad = _advertisements[adIndex];

// Delete from Firestore
await _firestore.collection('advertisements').doc(id).delete();

// If it's an image ad, delete the image from Storage
if (ad.type == AdvertisementType.image && ad.imageUrl.isNotEmpty) {
try {
// Check if the URL is from Firebase Storage
if (ad.imageUrl.contains('firebasestorage.googleapis.com')) {
final ref = _storage.refFromURL(ad.imageUrl);
await ref.delete();
}
} catch (e) {
print('Warning: Could not delete image from storage: $e');
// Continue with the deletion anyway
}
}

// Update the local list
_advertisements.removeAt(adIndex);
notifyListeners();
}
} catch (e) {
print('Error deleting advertisement: $e');
rethrow;
}
}

// Toggle advertisement active status
Future<void> toggleAdvertisementStatus(String id) async {
try {
final adIndex = _advertisements.indexWhere((ad) => ad.id == id);
if (adIndex != -1) {
final ad = _advertisements[adIndex];
final updatedAd = ad.copyWith(isActive: !ad.isActive);

await _firestore
    .collection('advertisements')
    .doc(id)
    .update({'isActive': updatedAd.isActive});

_advertisements[adIndex] = updatedAd;
notifyListeners();
}
} catch (e) {
print('Error toggling advertisement status: $e');
rethrow;
}
}
}
