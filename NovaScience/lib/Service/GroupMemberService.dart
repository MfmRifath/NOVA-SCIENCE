// GroupMemberService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Modals/GroupMember.dart';
import '../Modals/User.dart';

class GroupMemberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a user to a group
  Future<void> addMemberToGroup({
    required String groupId,
    required String userId,
    required String name,
    String? role,
    String? profileImageUrl,
  }) async {
    try {
      // Create a group member object
      final GroupMember member = GroupMember(
        userId: userId,
        name: name,
        role: role ?? 'member',
        joinedAt: DateTime.now(),
        profileImageUrl: profileImageUrl,
        notifications: true, // Enable notifications by default
      );

      // Add to the members collection in the group document
      await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .set(member.toMap());

      // Also update the members count in the group document
      await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .update({
        'memberCount': FieldValue.increment(1),
      });

      print('User $userId added to group $groupId');
    } catch (e) {
      print('Error adding member to group: $e');
      rethrow;
    }
  }

  // Remove a user from a group
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      // Remove from the members collection
      await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .delete();

      // Update the members count in the group document
      await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .update({
        'memberCount': FieldValue.increment(-1),
      });

      print('User $userId removed from group $groupId');
    } catch (e) {
      print('Error removing member from group: $e');
      rethrow;
    }
  }

  // Update member notification preferences
  Future<void> updateMemberNotificationSettings({
    required String groupId,
    required String userId,
    required bool notifications,
  }) async {
    try {
      await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .update({
        'notifications': notifications,
      });

      print('Updated notification settings for user $userId in group $groupId: $notifications');
    } catch (e) {
      print('Error updating member notification settings: $e');
      rethrow;
    }
  }

  // Get all members of a group
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('members')
          .get();

      return snapshot.docs
          .map((doc) => GroupMember.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting group members: $e');
      return [];
    }
  }

  // Check if a user is a member of a group
  Future<bool> isUserMemberOfGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking group membership: $e');
      return false;
    }
  }

  // Get a specific member
  Future<GroupMember?> getGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .get();

      if (doc.exists) {
        return GroupMember.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting group member: $e');
      return null;
    }
  }

  // Update member role
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required String role,
  }) async {
    try {
      await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .update({
        'role': role,
      });

      // If role is admin, also update the admins array in the group document
      if (role == 'admin') {
        await _firestore
            .collection('discussion_groups')
            .doc(groupId)
            .update({
          'admins': FieldValue.arrayUnion([userId]),
        });
      } else {
        // If role is not admin and user was an admin before, remove from admins array
        await _firestore
            .collection('discussion_groups')
            .doc(groupId)
            .update({
          'admins': FieldValue.arrayRemove([userId]),
        });
      }

      print('Updated role for user $userId in group $groupId: $role');
    } catch (e) {
      print('Error updating member role: $e');
      rethrow;
    }
  }

  // Get members who have notifications enabled
  Future<List<GroupMember>> getMembersWithNotificationsEnabled(String groupId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('members')
          .where('notifications', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => GroupMember.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting members with notifications enabled: $e');
      return [];
    }
  }

  // Initialize members collection when creating a new group
  Future<void> initializeGroupMembers({
    required String groupId,
    required List<String> memberIds,
    required Map<String, String> memberNames,
    required List<String> adminIds,
  }) async {
    try {
      // Create a batch to handle multiple writes
      final WriteBatch batch = _firestore.batch();

      for (final String userId in memberIds) {
        final String name = memberNames[userId] ?? 'Unknown';
        final String role = adminIds.contains(userId) ? 'admin' : 'member';

        final GroupMember member = GroupMember(
          userId: userId,
          name: name,
          role: role,
          joinedAt: DateTime.now(),
          notifications: true,
        );

        final DocumentReference memberRef = _firestore
            .collection('discussion_groups')
            .doc(groupId)
            .collection('members')
            .doc(userId);

        batch.set(memberRef, member.toMap());
      }

      // Commit the batch
      await batch.commit();

      print('Initialized members collection for group $groupId');
    } catch (e) {
      print('Error initializing group members: $e');
      rethrow;
    }
  }

  // Check if the current user has notifications enabled for this group
  Future<bool> hasCurrentUserNotificationsEnabled(String groupId) async {
    try {
      final String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) return false;

      final DocumentSnapshot doc = await _firestore
          .collection('discussion_groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['notifications'] ?? true;
      }
      return true; // Default to true if no document exists
    } catch (e) {
      print('Error checking notification status: $e');
      return true; // Default to true on error
    }
  }

  // Toggle notifications for the current user
  Future<bool> toggleCurrentUserNotifications(String groupId) async {
    try {
      final String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) return false;

      // Get the current status
      final bool currentStatus = await hasCurrentUserNotificationsEnabled(groupId);

      // Toggle it
      await updateMemberNotificationSettings(
        groupId: groupId,
        userId: userId,
        notifications: !currentStatus,
      );

      return !currentStatus;
    } catch (e) {
      print('Error toggling notifications: $e');
      rethrow;
    }
  }
}