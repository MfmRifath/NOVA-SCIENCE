// providers/advertisement_provider.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../Modals/Advertisment.dart';


class AdvertisementProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Advertisement> _advertisements = [];
  bool _isLoading = false;
  String? _error;

  List<Advertisement> get advertisements => _advertisements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdvertisementProvider() {
    fetchAdvertisements();
  }

  Future<void> fetchAdvertisements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore.collection('advertisements').get();
      _advertisements = snapshot.docs
          .map((doc) => Advertisement.fromFirestore(doc))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> uploadImage(String filePath) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('advertisements').child(fileName);
      UploadTask uploadTask = ref.putFile(File(filePath));
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw e;
    }
  }

  Future<void> addAdvertisement(Advertisement ad, {String? localImagePath}) async {
    try {
      String imageUrl = '';
      if (ad.type == AdvertisementType.image && localImagePath != null) {
        imageUrl = await uploadImage(localImagePath);
      } else {
        imageUrl = ad.imageUrl;
      }

      DocumentReference docRef = await _firestore.collection('advertisements').add({
        'type': ad.type == AdvertisementType.image ? 'image' : 'video',
        'imageUrl': imageUrl,
        'videoUrl': ad.videoUrl,
        'link': ad.link,
      });
      Advertisement newAd = Advertisement(
        id: docRef.id,
        type: ad.type,
        imageUrl: imageUrl,
        videoUrl: ad.videoUrl,
        link: ad.link,
      );
      _advertisements.add(newAd);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> updateAdvertisement(Advertisement ad, {String? localImagePath}) async {
    try {
      String imageUrl = ad.imageUrl;
      if (ad.type == AdvertisementType.image && localImagePath != null) {
        imageUrl = await uploadImage(localImagePath);
      }

      await _firestore.collection('advertisements').doc(ad.id).update({
        'type': ad.type == AdvertisementType.image ? 'image' : 'video',
        'imageUrl': imageUrl,
        'videoUrl': ad.videoUrl,
        'link': ad.link,
      });

      int index = _advertisements.indexWhere((element) => element.id == ad.id);
      if (index != -1) {
        _advertisements[index] = Advertisement(
          id: ad.id,
          type: ad.type,
          imageUrl: imageUrl,
          videoUrl: ad.videoUrl,
          link: ad.link,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> deleteAdvertisement(String id) async {
    try {
      await _firestore.collection('advertisements').doc(id).delete();
      _advertisements.removeWhere((ad) => ad.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }
}