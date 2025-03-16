import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class DiscussionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get all discussion groups
  Stream<QuerySnapshot> getAllGroups() {
    return _firestore
        .collection('discussion_groups')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get groups by category
  Stream<QuerySnapshot> getGroupsByCategory(String category) {
    return _firestore
        .collection('discussion_groups')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get group details
  Stream<DocumentSnapshot> getGroupDetails(String groupId) {
    return _firestore
        .collection('discussion_groups')
        .doc(groupId)
        .snapshots();
  }

  // Get messages for a group
  Stream<QuerySnapshot> getGroupMessages(String groupId, {int limit = 50}) {
    return _firestore
        .collection('discussion_groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get online users in a group
  Stream<QuerySnapshot> getOnlineUsers(String groupId) {
    return _firestore
        .collection('discussion_groups')
        .doc(groupId)
        .collection('online_users')
        .where('isOnline', isEqualTo: true)
        .snapshots();
  }

  // Create a new group
  Future<void> createGroup({
    required String name,
    required String description,
    required String category,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      await _firestore.collection('discussion_groups').add({
        'name': name,
        'description': description,
        'category': category,
        'createdBy': user.uid,
        'creatorName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1,
        'members': [user.uid],
        'admins': [user.uid],
        'messageCount': 0,
      });
    } catch (e) {
      print('Error creating group: $e');
      rethrow;
    }
  }

  // Join a group
  Future<void> joinGroup(String groupId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get a reference to the group document
      DocumentReference groupRef = _firestore.collection('discussion_groups').doc(groupId);

      // Update the group document atomically
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot groupSnapshot = await transaction.get(groupRef);
        if (!groupSnapshot.exists) {
          throw Exception("Group does not exist!");
        }

        Map<String, dynamic> groupData = groupSnapshot.data() as Map<String, dynamic>;
        List<dynamic> members = List.from(groupData['members'] ?? []);

        // Check if user is already a member
        if (!members.contains(user.uid)) {
          members.add(user.uid);

          transaction.update(groupRef, {
            'members': members,
            'memberCount': members.length,
          });
        }
      });
    } catch (e) {
      print('Error joining group: $e');
      rethrow;
    }
  }

  // Leave a group
  Future<void> leaveGroup(String groupId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update the group document atomically
      await _firestore.runTransaction((transaction) async {
        DocumentReference groupRef = _firestore.collection('discussion_groups').doc(groupId);
        DocumentSnapshot groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) {
          throw Exception("Group does not exist!");
        }

        Map<String, dynamic> groupData = groupSnapshot.data() as Map<String, dynamic>;
        List<dynamic> members = List.from(groupData['members'] ?? []);
        List<dynamic> admins = List.from(groupData['admins'] ?? []);

        // Remove user from members and admins lists
        members.remove(user.uid);
        admins.remove(user.uid);

        transaction.update(groupRef, {
          'members': members,
          'admins': admins,
          'memberCount': members.length,
        });
      });

      // Remove user from online users
      await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('online_users')
          .doc(user.uid)
          .delete();
    } catch (e) {
      print('Error leaving group: $e');
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String groupId,
    required String text,
    File? mediaFile,
    String mediaType = '',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      String? mediaUrl;
      String? mediaThumbnailUrl;

      // Upload media if selected
      if (mediaFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.uid}';
        final fileExtension = mediaFile.path.split('.').last;
        final storageRef = _storage.ref()
            .child('group_messages')
            .child(groupId)
            .child('$fileName.$fileExtension');

        // Upload file
        final uploadTask = await storageRef.putFile(mediaFile);
        mediaUrl = await storageRef.getDownloadURL();

        // Create thumbnail for video if needed
        if (mediaType == 'video') {
          // This would require a video thumbnail generator
          // For simplicity, we're using the same URL
          mediaThumbnailUrl = mediaUrl;
        }
      }

      // Add message to Firestore
      DocumentReference messageRef = await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': user.uid,
        'senderName': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'mediaUrl': mediaUrl,
        'mediaThumbnailUrl': mediaThumbnailUrl,
        'mediaType': mediaType,
      });

      // Update group with last message info
      await _firestore.collection('discussion_groups').doc(groupId).update({
        'lastMessage': text.isEmpty ? 'Shared ${mediaType.toLowerCase()}' : text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': user.uid,
        'messageCount': FieldValue.increment(1),
      });

      return;
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Update user online status
  Future<void> updateUserOnlineStatus(String groupId, bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('online_users')
          .doc(user.uid)
          .set({
        'userId': user.uid,
        'name': userName,
        'lastActive': FieldValue.serverTimestamp(),
        'isOnline': isOnline,
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  // Delete a group (admin only)
  Future<void> deleteGroup(String groupId) async {
    try {
      // Delete all messages in the group
      final messagesSnapshot = await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('messages')
          .get();

      final onlineUsersSnapshot = await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('online_users')
          .get();

      // Create a batch operation
      WriteBatch batch = _firestore.batch();

      // Add message deletions to batch
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add online user deletions to batch
      for (var doc in onlineUsersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add group deletion to batch
      batch.delete(_firestore.collection('discussion_groups').doc(groupId));

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error deleting group: $e');
      rethrow;
    }
  }

  // Check if user is an admin of a group
  Future<bool> isGroupAdmin(String groupId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if user is a site admin
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.data()?['role'] == 'Admin') return true;

      // Check if user is a group admin
      final groupDoc = await _firestore.collection('discussion_groups').doc(groupId).get();
      List<dynamic> admins = groupDoc.data()?['admins'] ?? [];

      return admins.contains(user.uid);
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Update group information (admin only)
  Future<void> updateGroupInfo(String groupId, String name, String description) async {
    try {
      await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .update({
        'name': name,
        'description': description,
      });
    } catch (e) {
      print('Error updating group info: $e');
      rethrow;
    }
  }

  // Make a user an admin of a group
  Future<void> makeUserAdmin(String groupId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference groupRef = _firestore.collection('discussion_groups').doc(groupId);
        DocumentSnapshot groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) {
          throw Exception("Group does not exist!");
        }

        Map<String, dynamic> groupData = groupSnapshot.data() as Map<String, dynamic>;
        List<dynamic> admins = List.from(groupData['admins'] ?? []);

        if (!admins.contains(userId)) {
          admins.add(userId);
          transaction.update(groupRef, {'admins': admins});
        }
      });
    } catch (e) {
      print('Error making user admin: $e');
      rethrow;
    }
  }

  // Remove admin status from a user
  Future<void> removeUserAdmin(String groupId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference groupRef = _firestore.collection('discussion_groups').doc(groupId);
        DocumentSnapshot groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) {
          throw Exception("Group does not exist!");
        }

        Map<String, dynamic> groupData = groupSnapshot.data() as Map<String, dynamic>;
        List<dynamic> admins = List.from(groupData['admins'] ?? []);

        admins.remove(userId);
        transaction.update(groupRef, {'admins': admins});
      });
    } catch (e) {
      print('Error removing user admin: $e');
      rethrow;
    }
  }

  // Remove a user from a group (admin only)
  Future<void> removeUserFromGroup(String groupId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference groupRef = _firestore.collection('discussion_groups').doc(groupId);
        DocumentSnapshot groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) {
          throw Exception("Group does not exist!");
        }

        Map<String, dynamic> groupData = groupSnapshot.data() as Map<String, dynamic>;
        List<dynamic> members = List.from(groupData['members'] ?? []);
        List<dynamic> admins = List.from(groupData['admins'] ?? []);

        members.remove(userId);
        admins.remove(userId);

        transaction.update(groupRef, {
          'members': members,
          'admins': admins,
          'memberCount': members.length,
        });
      });

      // Remove user from online users
      await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('online_users')
          .doc(userId)
          .delete();
    } catch (e) {
      print('Error removing user: $e');
      rethrow;
    }
  }

  // Get all categories
  List<Map<String, dynamic>> getCategories() {
    return [
      {
        'name': 'Science Stream',
        'icon': Icons.science_outlined,
        'color': Color(0xFF4CAF50),
        'description': 'Physics, Chemistry, Biology and more'
      },
      {
        'name': 'Arts Stream',
        'icon': Icons.color_lens_outlined,
        'color': Color(0xFFE91E63),
        'description': 'Literature, History, Geography and more'
      },
      {
        'name': 'Commerce Stream',
        'icon': Icons.attach_money_outlined,
        'color': Color(0xFF2196F3),
        'description': 'Business, Economics, Accounting and more'
      },
      {
        'name': 'Technology Stream',
        'icon': Icons.computer_outlined,
        'color': Color(0xFF673AB7),
        'description': 'Programming, Engineering, Design and more'
      },
      {
        'name': 'O/L',
        'icon': Icons.menu_book_outlined,
        'color': Color(0xFFFF9800),
        'description': 'General education and foundation subjects'
      },
    ];
  }

  // Search groups by name
  Stream<QuerySnapshot> searchGroups(String query) {
    return _firestore
        .collection('discussion_groups')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots();
  }

  // Check if text contains URLs
  bool containsUrl(String text) {
    // Simple regex to detect URLs
    final urlRegex = RegExp(
      r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(text);
  }
}