// AuthService.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import '../Modals/User.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CustomUser? _user;

  CustomUser? get user => _user;

  // Public getter for the current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Checks if the current user has an Admin role.
  Future<bool> isAdmin() async {
    if (currentUser != null) {
      final userData = await getUserData(currentUser!.uid);
      if (userData != null && userData['role'] == 'Admin') {
        return true;
      }
    }
    return false;
  }

  /// Retrieves user data from Firestore based on UID.
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print(e);
      return null;
    }
  }

  /// Signs up a new user with email and password, including additional profile details.
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
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = CustomUser(
        id: userCredential.user!.uid,
        name: name as String?,
        email: email,
        role: 'User',
        profileImageUrl: '',
        phoneNumber: phoneNumber,
        location: location,
        birthday: birthday?.toDate(),
        bio: bio,
        isLoggedin: true,
        registeredDate: DateTime.now(),
        enrollments: [],
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
        'profileImageUrl':
        profileImageUrl ?? "https://via.placeholder.com/150",
        'phoneNumber': phoneNumber,
        'location': location,
        'birthday': birthday,
        'bio': bio,
        'isLoggedin': true,
        'registeredDate': Timestamp.now(),
        'enrolledCourses': [], // Initialize enrolledCourses as empty list
      });

      notifyListeners(); // Notify listeners after user is created
    } catch (e) {
      print('Error signing up: $e');
      // Optionally, handle errors by rethrowing or using another mechanism
    }
  }

  /// Adds a user with specified role. Typically used by Admins.
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
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
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
        birthday: birthday?.toDate(),
        bio: bio,
        isLoggedin: true,
        registeredDate: DateTime.now(),
        enrollments: [],
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
        'profileImageUrl':
        profileImageUrl ?? "https://via.placeholder.com/150",
        'phoneNumber': phoneNumber,
        'location': location,
        'birthday': birthday,
        'bio': bio,
        'isLoggedin': true,
        'registeredDate': Timestamp.now(),
        'enrolledCourses': [],
      });

      notifyListeners(); // Notify listeners after user is created
    } catch (e) {
      print('Error adding user: $e');
      // Optionally, handle errors by rethrowing or using another mechanism
    }
  }

  Future<CustomUser?> getCurrentUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        print('Fetched document: ${doc.data()}'); // Debug output
        if (doc.exists) {
          _user = CustomUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          notifyListeners();
          return _user;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }
  /// Updates the user's profile with new data and optionally a new profile image.
  Future<void> updateUser({
    required Map<String, dynamic> updatedData,
    File? newProfileImage,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get a reference to the user's document.
      DocumentReference userDoc = _firestore.collection('users').doc(user.uid);

      // Create a write batch to commit multiple updates atomically.
      WriteBatch batch = _firestore.batch();

      // Add the updated profile data to the batch.
      batch.update(userDoc, updatedData);

      // If there is a new profile image, upload it and add its URL update to the batch.
      if (newProfileImage != null) {
        TaskSnapshot uploadTask = await _storage.ref('profile_images/${user.uid}').putFile(newProfileImage);
        String newProfileImageUrl = await uploadTask.ref.getDownloadURL();
        batch.update(userDoc, {'profileImageUrl': newProfileImageUrl});
      }

      // Commit the batch.
      await batch.commit();

      // Refresh local user data after update.
      await getCurrentUser();

      // Notify any listeners of the change.
      notifyListeners();
    } catch (e) {
      print('Error updating user: $e');
      // Rethrow the error so the caller can handle it if needed.
      rethrow;
    }
  }

  /// Deletes the currently authenticated user's account.


  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      User? user = currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isLoggedin': false,
        });
      }

      await _auth.signOut();
      _user = null; // Clear local user data
      notifyListeners(); // Notify after signing out
    } catch (e) {
      print("Error signing out: $e");
      // Optionally, handle errors by rethrowing or using another mechanism
    }
  }
  /// Retrieves the current user's email.
  Future<String?> getCurrentUserEmail() async {
    User? user = _auth.currentUser;
    return user?.email;
  }

  /// Fetches a user's document by UID.
  Future<DocumentSnapshot> getUser(String uid) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('users').doc(uid).get();
      return doc;
    } catch (e) {
      print('Error fetching user: $e');
      rethrow;
    }
  }

  /// Fetches all users from Firestore.
  Future<List<DocumentSnapshot>> getAllUsers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs;
    } catch (e) {
      print('Error fetching users: $e');
      rethrow;
    }
  }

  /// Searches users by their name.
  Future<List<DocumentSnapshot>> searchUsersByName(String name) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('name', isEqualTo: name)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      print('Error searching users by name: $e');
      rethrow;
    }
  }

  /// Deletes a user by their email.
  Future<void> deleteUserByEmail(String email) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        print('No user found with this email.');
        return;
      }

      final userDoc = userQuery.docs.first;
      final uid = userDoc.id;

      final profileImageUrl = userDoc.data()['profileImageUrl'];
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        await _storage.refFromURL(profileImageUrl).delete();
      }

      await _firestore.collection('users').doc(uid).delete();

      User? user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        await user.delete();
      } else {
        // If the user to delete is not the current user, you might need Admin privileges
        // This part requires additional implementation based on your authentication flow
      }

      notifyListeners(); // Notify after deleting user by email
    } catch (e) {
      print('Error deleting user by email: $e');
      // Optionally, handle errors by rethrowing or using another mechanism
    }
  }

  /// Deletes a user by their UID.
  Future<void> deleteUserById(String userId) async {
    try {
      var userDoc = await _firestore.collection('users').doc(userId).get();
      var profileImageUrl = userDoc.data()?['profileImageUrl'];
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        await _storage.refFromURL(profileImageUrl).delete();
      }

      await _firestore.collection('users').doc(userId).delete();

      // If the deleted user is the current user, sign them out
      User? user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        await _auth.signOut();
        _user = null;
      }

      notifyListeners(); // Notify after deleting user by ID
    } catch (e) {
      print('Error deleting user by ID: $e');
      // Optionally, handle errors by rethrowing or using another mechanism
    }
  }

  Future<void> deleteUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Delete user's profile image from Firebase Storage (if exists)
        var userDoc = await _firestore.collection('users').doc(user.uid).get();
        var profileImageUrl = userDoc.data()?['profileImageUrl'];
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          await _storage.refFromURL(profileImageUrl).delete();
        }

        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        notifyListeners(); // Notify listeners that user is deleted
      } catch (e) {
        print('Error deleting user from Firestore: $e');
        throw e; // Rethrow error to handle it in ProfileScreen
      }
    }
  }

  /// Updates a user's data by their email.
  Future<void> updateUserByEmail({
    required String email,
    required Map<String, dynamic> updatedData,
  }) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        print('No user found with this email.');
        return;
      }

      final userDoc = userQuery.docs.first;
      await _firestore.collection('users').doc(userDoc.id).update(updatedData);
      notifyListeners(); // Notify after updating user by email
    } catch (e) {
      print('Error updating user by email: $e');
      // Optionally, handle errors by rethrowing or using another mechanism
    }
  }

  /// Fetches a user with their enrolled courses based on UID.
  Future<CustomUser?> fetchUserWithCourses(String userId) async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return CustomUser.fromMap(
          userDoc.data() as Map<String, dynamic>,
          userDoc.id,
        );
      } else {
        print('User not found');
        return null;
      }
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }


  Future<void> storeFCMToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await FirebaseFirestore.instance.collection('users')
              .doc(user.uid)
              .set(
            {'fcmToken': token},
            SetOptions(merge: true), // Merge with existing data
          );
        }
      } catch (e) {
        print("Error storing FCM token: $e");
      }
    }
  }

  /// Fetches all users from Firestore and converts them to CustomUser objects.
  Future<List<CustomUser>> fetchAllUsers() async {
    List<CustomUser> users = [];
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        users.add(CustomUser.fromMap(data, doc.id));
      }
    } catch (e) {
      print('Error fetching all users: $e');
    }
    return users;
  }
  Future<int> getEnrollmentCount(String courseId) async {
    try {
      // Fetch all users
      QuerySnapshot query = await FirebaseFirestore.instance.collection('users').get();

      int count = 0;

      // Loop through each user and check their enrolled courses
      for (var doc in query.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        List<dynamic>? enrolledCourses = userData['enrolledCourses'];

        if (enrolledCourses != null) {
          // Check if the user is enrolled in the specific course
          bool isEnrolled = enrolledCourses.any((course) {
            if (course is Map<String, dynamic> && course['courseId'] == courseId) {
              return true;
            }
            return false;
          });

          if (isEnrolled) count++;
        }
      }

      return count; // Return the total count of enrolled users
    } catch (e) {
      print('Error fetching enrollment count: $e');
      return 0; // Default to 0 in case of an error
    }
  }
  void listenForTokenChanges() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'fcmToken': newToken},
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<List<CustomUser>> getUsersEnrolledInCourse(String courseId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').get();

      List<CustomUser> enrolledUsers = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // Parse the user's enrollments
        List<Enrollment>? enrollments = CustomUser.convertEnrollments(userData['enrolledCourses']);

        // Check if the user is enrolled in the course
        bool isEnrolled = enrollments?.any((enrollment) => enrollment.courseId == courseId) ?? false;

        if (isEnrolled) {
          enrolledUsers.add(CustomUser.fromMap(userData, doc.id));
        }
      }

      return enrolledUsers;
    } catch (e) {
      print('Error fetching enrolled users: $e');
      return [];
    }
  }
  Future<void> checkAndUnenrollExpiredCourses(String userId) async {
    try {
      // Fetch the user's enrolled courses
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      List<dynamic> enrolledCourses = userData['enrolledCourses'] ?? [];

      // Filter out expired courses
      List<dynamic> updatedCourses = enrolledCourses.where((course) {
        if (course is Map<String, dynamic>) {
          DateTime endDate =
          (course['enrollmentEndDate'] as Timestamp).toDate();
          return endDate.isAfter(DateTime.now()); // Keep valid courses
        }
        return false;
      }).toList();

      // Update Firestore only if changes are needed
      if (enrolledCourses.length != updatedCourses.length) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'enrolledCourses': updatedCourses,
        });
        print('Removed expired courses for user: $userId');
      }
    } catch (e) {
      print('Error checking expired courses: $e');
    }
  }
  }