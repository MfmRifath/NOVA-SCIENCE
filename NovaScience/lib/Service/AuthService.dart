import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

import '../Modals/User.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CustomUser? _user;
  CustomUser? get user => _user;

  // Public getter for the current Firebase user
  User? get currentUser => _auth.currentUser;

  // Check if the current user is an admin
  Future<bool> isAdmin() async {
    if (currentUser != null) {
      final userData = await getUserData(currentUser!.uid);
      if (userData != null && userData['role'] == 'Admin') {
        return true;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Sign up method with additional fields
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    String? location,
    Timestamp? birthday,
    String? bio,
    File? profileImage,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = CustomUser(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        role: 'User',
        profileImageUrl: '',
        phoneNumber: phoneNumber,
        location: location,
        birthday: birthday,
        bio: bio,
        isLoggedin: true,
        registeredDate: Timestamp.now(),
      );

      // Upload profile image to Firebase Storage
      String? profileImageUrl;
      if (profileImage != null) {
        TaskSnapshot uploadTask = await _storage
            .ref('profile_images/${_user!.id}')
            .putFile(profileImage);
        profileImageUrl = await uploadTask.ref.getDownloadURL();
      }

      // Save user data in Firestore
      await _firestore.collection('users').doc(_user!.id).set({
        'name': name,
        'email': email,
        'role': 'User',
        'profileImageUrl': profileImageUrl ?? "https://via.placeholder.com/150",
        'phoneNumber': phoneNumber,
        'location': location,
        'birthday': birthday,
        'bio': bio,
        'isLoggedin': true,
        'registeredDate': Timestamp.now(),
      });

      notifyListeners(); // Notify after user is created
    } catch (e) {
      print('Error signing up: $e');
    }
  }

  Future<void> addUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
    String? location,
    Timestamp? birthday,
    String? bio,
    File? profileImage,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = CustomUser(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        role: role,
        profileImageUrl: '',
        phoneNumber: phoneNumber,
        location: location,
        birthday: birthday,
        bio: bio,
        isLoggedin: true,
        registeredDate: Timestamp.now(),
      );

      // Upload profile image to Firebase Storage
      String? profileImageUrl;
      if (profileImage != null) {
        TaskSnapshot uploadTask = await _storage
            .ref('profile_images/${_user!.id}')
            .putFile(profileImage);
        profileImageUrl = await uploadTask.ref.getDownloadURL();
      }

      // Save user data in Firestore
      await _firestore.collection('users').doc(_user!.id).set({
        'name': name,
        'email': email,
        'role': role,
        'profileImageUrl': profileImageUrl ?? "https://via.placeholder.com/150",
        'phoneNumber': phoneNumber,
        'location': location,
        'birthday': birthday,
        'bio': bio,
        'isLoggedin': true,
        'registeredDate': Timestamp.now(),
      });

      notifyListeners(); // Notify after user is created
    } catch (e) {
      print('Error adding user: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      notifyListeners(); // Notify listeners after fetching user data
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<void> updateUser({
    required Map<String, dynamic> updatedData,
    required File? newProfileImage,
  }) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update(updatedData);

      if (newProfileImage != null) {
        TaskSnapshot uploadTask = await _storage
            .ref('profile_images/${user.uid}')
            .putFile(newProfileImage);
        String newProfileImageUrl = await uploadTask.ref.getDownloadURL();
        await _firestore.collection('users').doc(user.uid).update({
          'profileImageUrl': newProfileImageUrl,
        });
      }

      notifyListeners(); // Notify after updating user
    }
  }

  Future<void> deleteUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        var profileImageUrl = (await _firestore.collection('users').doc(user.uid).get())
            .data()?['profileImageUrl'];
        if (profileImageUrl != null) {
          await _storage.refFromURL(profileImageUrl).delete();
        }

        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();

        _user = null; // Clear current user
        notifyListeners(); // Notify after deleting user
      } catch (e) {
        print('Error deleting user: $e');
      }
    }
  }

  Future<void> signOut() async {
    try {
      User? user = currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isLoggedin': false,
        });
      }

      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  Future<String?> getCurrentUserEmail() async {
    User? user = _auth.currentUser;
    notifyListeners(); // Notify after fetching current user's email
    return user?.email;
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      notifyListeners(); // Notify after fetching user data
      return doc;
    } catch (e) {
      print('Error fetching user: $e');
      rethrow;
    }
  }

  Future<List<DocumentSnapshot>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      notifyListeners(); // Notify after fetching all users
      return querySnapshot.docs;
    } catch (e) {
      print('Error fetching users: $e');
      rethrow;
    }
  }

  Future<List<DocumentSnapshot>> searchUsersByName(String name) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('name', isEqualTo: name)
          .get();
      notifyListeners(); // Notify after searching users
      return querySnapshot.docs;
    } catch (e) {
      print('Error searching users by name: $e');
      rethrow;
    }
  }

  Future<void> deleteUserByEmail(String email) async {
    try {
      final userQuery = await _firestore.collection('users').where('email', isEqualTo: email).get();

      if (userQuery.docs.isEmpty) {
        print('No user found with this email.');
        return;
      }

      final userDoc = userQuery.docs.first;
      final uid = userDoc.id;

      final profileImageUrl = userDoc.data()['profileImageUrl'];
      if (profileImageUrl != null) {
        await _storage.refFromURL(profileImageUrl).delete();
      }

      await _firestore.collection('users').doc(uid).delete();

      User? user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        await user.delete();
      } else {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: email, password: 'userPassword');
        await userCredential.user!.delete();
      }

      notifyListeners(); // Notify after deleting user by email
    } catch (e) {
      print('Error deleting user by email: $e');
    }
  }

  Future<void> deleteUserById(String userId) async {
    try {
      var profileImageUrl = (await _firestore.collection('users').doc(userId).get())
          .data()?['profileImageUrl'];
      if (profileImageUrl != null) {
        await _storage.refFromURL(profileImageUrl).delete();
      }

      await _firestore.collection('users').doc(userId).delete();
      notifyListeners(); // Notify after deleting user by ID
    } catch (e) {
      print('Error deleting user by ID: $e');
    }
  }

  Future<List<CustomUser>> fetchAllUsers() async {
    List<CustomUser> users = [];
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        users.add(CustomUser(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? '',
          profileImageUrl: data['profileImageUrl'] ?? '',
          phoneNumber: data['phoneNumber'],
          location: data['location'],
          birthday: data['birthday'],
          bio: data['bio'],
          isLoggedin: data['isLoggedin'],
          registeredDate: data['registeredDate'],
        ));
      }
      notifyListeners(); // Notify after fetching all users
    } catch (e) {
      print('Error fetching all users: $e');
    }
    return users;
  }

  Future<void> deleteFileByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
      notifyListeners(); // Notify after deleting a file
    } catch (e) {
      print('Error deleting file by URL: $e');
    }
  }

  Future<void> updateUserByEmail({
    String? email,
    Map<String, dynamic>? updatedData,
  }) async {
    try {
      final userQuery = await _firestore.collection('users').where('email', isEqualTo: email).get();

      if (userQuery.docs.isEmpty) {
        print('No user found with this email.');
        return;
      }

      final userDoc = userQuery.docs.first;
      await _firestore.collection('users').doc(userDoc.id).update(updatedData!);
      notifyListeners(); // Notify after updating user by email
    } catch (e) {
      print('Error updating user by email: $e');
    }
  }
}
