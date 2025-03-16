import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../Screens/StartScreen/AppTheme.dart';
import 'GroupChatScreen.dart';

class GroupListScreen extends StatefulWidget {
  final String category;

  const GroupListScreen({Key? key, required this.category}) : super(key: key);

  @override
  _GroupListScreenState createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  late Stream<QuerySnapshot> _groupsStream;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isAdmin = false;
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupGroupsStream();
    _checkUserRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setupGroupsStream() {
    _groupsStream = _firestore
        .collection('discussion_groups')
        .where('category', isEqualTo: widget.category)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          _isAdmin = userDoc.data()?['role'] == 'Admin';
        });
      }
    } catch (e) {
      print('Error checking user role: $e');
    }
  }

  void _searchGroups(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        // Reset to original stream
        _setupGroupsStream();
      } else {
        _groupsStream = _firestore
            .collection('discussion_groups')
            .where('category', isEqualTo: widget.category)
            .where('nameSearch', arrayContains: query.toLowerCase())
            .snapshots();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
              ],
            ),
          ),
        ),
        elevation: 0,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              onPressed: () => _showCreateGroupDialog(),
              tooltip: 'Create Group',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildGroupList(),
          ),
        ],
      ),
      floatingActionButton: _isAdmin ? FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        child: Icon(Icons.add),
        backgroundColor: AppTheme.tertiaryColor,
      ) : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search groups',
          prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: _searchQuery.isNotEmpty ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              _searchGroups('');
            },
          ) : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: _searchGroups,
      ),
    );
  }

  Widget _buildGroupList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _groupsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isUserMember = (data['members'] as List).contains(_auth.currentUser?.uid);

            return _buildGroupCard(doc.id, data, isUserMember);
          },
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _setupGroupsStream();
              });
            },
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_off,
              size: 64,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No groups found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _searchQuery.isEmpty
                  ? 'There are no discussion groups in this category yet'
                  : 'No groups match your search "$_searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          SizedBox(height: 32),
          if (_isAdmin)
            ElevatedButton.icon(
              onPressed: _showCreateGroupDialog,
              icon: Icon(Icons.add),
              label: Text('Create a group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tertiaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(String groupId, Map<String, dynamic> data, bool isUserMember) {
    final String groupName = data['name'] ?? 'Unnamed Group';
    final String groupDesc = data['description'] ?? 'No description available';
    final int memberCount = data['memberCount'] ?? 0;
    final String creatorName = data['creatorName'] ?? 'Unknown';
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;
    final String? groupImageUrl = data['groupImageUrl'];

    // Format creation date
    String creationDate = 'Recently';
    if (createdAt != null) {
      final now = DateTime.now();
      final created = createdAt.toDate();
      final difference = now.difference(created);

      if (difference.inDays > 365) {
        creationDate = '${(difference.inDays / 365).floor()} years ago';
      } else if (difference.inDays > 30) {
        creationDate = '${(difference.inDays / 30).floor()} months ago';
      } else if (difference.inDays > 0) {
        creationDate = '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        creationDate = '${difference.inHours} hours ago';
      } else {
        creationDate = 'Just now';
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (isUserMember) {
            _navigateToGroupChat(groupId, groupName, groupImageUrl);
          } else {
            _showJoinGroupDialog(groupId, groupName);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group header with image
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                color: AppTheme.primaryColor.withOpacity(0.05),
              ),
              child: Stack(
                children: [
                  // Group cover image or gradient
                  if (groupImageUrl != null && groupImageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: groupImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: _getColorForString(groupName).withOpacity(0.3),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getColorForString(groupName).withOpacity(0.3),
                                  _getColorForString(groupName).withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.groups,
                              size: 40,
                              color: _getColorForString(groupName).withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getColorForString(groupName).withOpacity(0.3),
                            _getColorForString(groupName).withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.groups,
                          size: 40,
                          color: _getColorForString(groupName).withOpacity(0.5),
                        ),
                      ),
                    ),

                  // Overlay gradient for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.4),
                        ],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),

                  // Group info overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Group avatar
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              color: _getColorForString(groupName),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: groupImageUrl != null && groupImageUrl.isNotEmpty
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: CachedNetworkImage(
                                imageUrl: groupImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: Text(
                                    groupName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Text(
                                    groupName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                              ),
                            )
                                : Center(
                              child: Text(
                                groupName[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),

                          // Group title and status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  groupName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '$memberCount members',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Membership status chip
                          _buildStatusChip(isUserMember),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Group details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    groupDesc,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16),

                  // Creator info and actions
                  Row(
                    children: [
                      // Creation info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Created by $creatorName',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              creationDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textTertiaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action button
                      if (!isUserMember)
                        ElevatedButton(
                          onPressed: () => _joinGroup(groupId, groupName),
                          child: Text('Join Group'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.tertiaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _navigateToGroupChat(groupId, groupName, groupImageUrl),
                          icon: Icon(Icons.chat, size: 16),
                          label: Text('Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForString(String input) {
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    int hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }

  Widget _buildStatusChip(bool isUserMember) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isUserMember ? Colors.green.withOpacity(0.8) : Colors.grey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        isUserMember ? 'Member' : 'Join',
        style: TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _navigateToGroupChat(String groupId, String groupName, String? groupImageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(
          groupId: groupId,
          groupName: groupName,
          groupAvatar: groupImageUrl,
        ),
      ),
    );
  }

  void _showJoinGroupDialog(String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Join Group'),
          content: Text('Would you like to join the "$groupName" group?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _joinGroup(groupId, groupName);
              },
              child: Text('Join'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tertiaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinGroup(String groupId, String groupName) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _auth.currentUser;
      if (user == null) return;

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

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have joined the "$groupName" group!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Navigate to group chat
      final groupDoc = await groupRef.get();
      final groupData = groupDoc.data() as Map<String, dynamic>?;
      final String? groupImageUrl = groupData?['groupImageUrl'];

      _navigateToGroupChat(groupId, groupName, groupImageUrl);
    } catch (e) {
      print('Error joining group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join group. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateGroupDialog() {
    String groupName = '';
    String groupDescription = '';
    File? selectedImage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text('Create New Group'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group image selector
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final ImagePicker _picker = ImagePicker();
                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            setState(() {
                              selectedImage = File(image.path);
                            });
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: selectedImage != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            ),
                          )
                              : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                color: Colors.grey[500],
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    Text(
                      'Group Name:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        hintText: 'Enter group name',
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        groupName = value;
                      },
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Group Description:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        hintText: 'Enter group description',
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        groupDescription = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (groupName.isNotEmpty && groupDescription.isNotEmpty) {
                      Navigator.of(context).pop();
                      _createNewGroup(groupName, groupDescription, selectedImage);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill in all fields'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Text('Create'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tertiaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createNewGroup(String name, String description, File? image) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      // Generate search keywords for the group name (for better search functionality)
      List<String> searchKeywords = [];
      String nameLower = name.toLowerCase();
      for (int i = 1; i <= nameLower.length; i++) {
        searchKeywords.add(nameLower.substring(0, i));
      }

      // Upload image if selected
      String? imageUrl;
      if (image != null) {
        final storageRef = _storage.ref()
            .child('group_images')
            .child('${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg');

        // Upload file with metadata
        final uploadTask = storageRef.putFile(
          image,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // Wait for upload to complete
        await uploadTask.whenComplete(() {});

        // Get download URL
        imageUrl = await storageRef.getDownloadURL();
      }

      // Create the group document
      final groupRef = await _firestore.collection('discussion_groups').add({
        'name': name,
        'description': description,
        'category': widget.category,
        'createdBy': user.uid,
        'creatorName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1,
        'members': [user.uid],
        'admins': [user.uid],
        'groupImageUrl': imageUrl,
        'nameSearch': searchKeywords,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Navigate to the newly created group
      _navigateToGroupChat(groupRef.id, name, imageUrl);
    } catch (e) {
      print('Error creating group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create group. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}