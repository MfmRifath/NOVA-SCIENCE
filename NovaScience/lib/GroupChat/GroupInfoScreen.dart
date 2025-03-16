import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../Screens/StartScreen/AppTheme.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isAdmin;
  final String? groupAvatar;

  const GroupInfoScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.isAdmin,
    this.groupAvatar,
  }) : super(key: key);

  @override
  _GroupInfoScreenState createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  late Stream<DocumentSnapshot> _groupStream;
  Stream<QuerySnapshot>? _membersStream;
  late Stream<QuerySnapshot> _onlineUsersStream;

  late TabController _tabController;
  File? _selectedGroupImage;
  bool _isUploading = false;

  String _currentUserId = '';
  bool _isLeaving = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid ?? '';
    _tabController = TabController(length: 2, vsync: this);

    _groupStream = _firestore
        .collection('discussion_groups')
        .doc(widget.groupId)
        .snapshots();

    _onlineUsersStream = _firestore
        .collection('discussion_groups')
        .doc(widget.groupId)
        .collection('online_users')
        .where('isOnline', isEqualTo: true)
        .snapshots();

    // Initialize members stream separately without awaiting
    _initializeMembersStream();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Separate method to handle the async initialization
  Future<void> _initializeMembersStream() async {
    try {
      List<String> memberIds = await _getMemberIds();

      if (mounted) {
        setState(() {
          _membersStream = _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: memberIds.isNotEmpty ? memberIds : ['placeholder'])
              .snapshots();
        });
      }
    } catch (e) {
      print('Error initializing members stream: $e');
    }
  }

  Future<List<String>> _getMemberIds() async {
    try {
      final groupDoc = await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .get();

      List<dynamic> members = groupDoc.data()?['members'] ?? [];
      return members.cast<String>().toList();
    } catch (e) {
      print('Error getting member IDs: $e');
      return [];
    }
  }

  Future<void> _pickGroupImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedGroupImage = File(image.path);
      });
      _uploadGroupImage();
    }
  }

  Future<void> _uploadGroupImage() async {
    if (_selectedGroupImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final storageRef = _storage.ref()
          .child('group_images')
          .child('${DateTime.now().millisecondsSinceEpoch}_${widget.groupId}.jpg');

      // Upload file with metadata
      final uploadTask = storageRef.putFile(
        _selectedGroupImage!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for upload to complete
      await uploadTask.whenComplete(() {});

      // Get download URL
      final imageUrl = await storageRef.getDownloadURL();

      // Update group document with new image URL
      await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .update({
        'groupImageUrl': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group image updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      print('Error uploading group image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update group image'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _selectedGroupImage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _groupStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildNotFoundState();
          }

          Map<String, dynamic> groupData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> admins = groupData['admins'] ?? [];
          bool isUserAdmin = admins.contains(_currentUserId) || widget.isAdmin;
          String? groupImageUrl = groupData['groupImageUrl'];

          return CustomScrollView(
            slivers: [
              _buildAppBar(groupData, isUserAdmin, groupImageUrl),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGroupStats(groupData),
                    _buildTabBar(),
                    SizedBox(height: 8),
                  ],
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // About tab
                    SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAboutGroup(groupData),
                          SizedBox(height: 24),
                          _buildOnlineUsers(),
                          SizedBox(height: 32),
                          if (isUserAdmin)
                            _buildAdminActions()
                          else
                            _buildLeaveButton(),
                          SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Members tab
                    SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchBar(),
                          SizedBox(height: 16),
                          _buildMembersList(isUserAdmin),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
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
            'We couldn\'t load the group information',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Go Back'),
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          SizedBox(height: 24),
          Text(
            'Loading group information...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Group not found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This group may have been deleted',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Go Back'),
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

  Widget _buildAppBar(Map<String, dynamic> groupData, bool isUserAdmin, String? groupImageUrl) {
    final timestamp = groupData['createdAt'] as Timestamp?;
    final creationDate = timestamp != null
        ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
        : 'Unknown';

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image or color
            if (groupImageUrl != null)
              CachedNetworkImage(
                imageUrl: groupImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: _getColorForString(widget.groupName).withOpacity(0.3),
                ),
                errorWidget: (context, url, error) => Container(
                  color: _getColorForString(widget.groupName).withOpacity(0.3),
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white.withOpacity(0.6),
                    size: 64,
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getColorForString(widget.groupName).withOpacity(0.8),
                      AppTheme.primaryColor.withOpacity(0.9),
                    ],
                  ),
                ),
              ),

            // Gradient overlay for better text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: [0.5, 1.0],
                ),
              ),
            ),

            // Group info content
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Group avatar and edit button
                  Row(
                    children: [
                      Hero(
                        tag: 'group-${widget.groupId}',
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _isUploading
                              ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: groupImageUrl != null
                                ? CachedNetworkImage(
                              imageUrl: groupImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: _getColorForString(widget.groupName),
                                child: Icon(
                                  Icons.groups,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: _getColorForString(widget.groupName),
                                child: Icon(
                                  Icons.groups,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            )
                                : Container(
                              color: _getColorForString(widget.groupName),
                              child: Icon(
                                Icons.groups,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (isUserAdmin)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _pickGroupImage,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: AppTheme.primaryColor,
                                size: 16,
                              ),
                            ),
                          ),
                        ),

                      Spacer(),

                      if (isUserAdmin)
                        ElevatedButton.icon(
                          onPressed: _showEditGroupDialog,
                          icon: Icon(Icons.edit, size: 16),
                          label: Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            elevation: 2,
                            shadowColor: Colors.black38,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Group name and creation info
                  Text(
                    widget.groupName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Created on $creationDate',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
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
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondaryColor,
        tabs: [
          Tab(
            icon: Icon(Icons.info_outline),
            text: 'About',
          ),
          Tab(
            icon: Icon(Icons.people_outline),
            text: 'Members',
          ),
        ],
      ),
    );
  }

  Widget _buildAboutGroup(Map<String, dynamic> groupData) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                'About this group',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            groupData['description'] ?? 'No description available',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStats(Map<String, dynamic> groupData) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.people_outline,
            value: '${groupData['memberCount'] ?? 0}',
            label: 'Members',
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            icon: Icons.message_outlined,
            value: '${groupData['messageCount'] ?? 0}',
            label: 'Messages',
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            icon: Icons.calendar_today_outlined,
            value: _getDaysActive(groupData['createdAt']),
            label: 'Days Active',
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 22,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  String _getDaysActive(Timestamp? createdAt) {
    if (createdAt == null) return '0';

    final now = DateTime.now();
    final created = createdAt.toDate();
    final difference = now.difference(created).inDays;

    return difference.toString();
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppTheme.textSecondaryColor,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search members',
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(
                  color: AppTheme.textTertiaryColor,
                  fontSize: 14,
                ),
              ),
              style: TextStyle(
                fontSize: 14,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: AppTheme.textSecondaryColor,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildOnlineUsers() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_pin_circle,
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Online Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _onlineUsersStream,
                      builder: (context, snapshot) {
                        int onlineCount = 0;
                        if (snapshot.hasData) {
                          onlineCount = snapshot.data!.docs.length;
                        }
                        return Text(
                          '$onlineCount ${onlineCount == 1 ? 'member' : 'members'} online',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            height: 100,
            child: StreamBuilder<QuerySnapshot>(
              stream: _onlineUsersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading online users'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            color: Colors.grey.shade400,
                            size: 24,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No members online right now',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Anonymous';

                    return Container(
                      width: 70,
                      margin: EdgeInsets.only(right: 16, bottom: 16),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Container(
                                    color: _getColorForString(name),
                                    child: Center(
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            name.isNotEmpty && name.length > 10
                                ? name.substring(0, 7) + '...'
                                : name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(bool isUserAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_membersStream == null)
          Center(
            child: CircularProgressIndicator(),
          )
        else
          StreamBuilder<QuerySnapshot>(
            stream: _membersStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade300,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error loading members',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.group_off,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No members found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This group doesn\'t have any members yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Filter members based on search query
              final docs = snapshot.data!.docs.where((doc) {
                if (_searchQuery.isEmpty) return true;

                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();

                return name.contains(_searchQuery.toLowerCase()) ||
                    email.contains(_searchQuery.toLowerCase());
              }).toList();

              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No members match your search for "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Build the member list
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Anonymous';
                  final email = data['email'] ?? '';
                  final role = data['role'] ?? 'User';
                  final userId = doc.id;
                  final profileImage = data['profileImageUrl'] as String?;

                  // Check if user is admin of the group
                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore
                        .collection('discussion_groups')
                        .doc(widget.groupId)
                        .get(),
                    builder: (context, groupSnapshot) {
                      bool isAdmin = false;
                      if (groupSnapshot.hasData && groupSnapshot.data!.exists) {
                        Map<String, dynamic> groupData = groupSnapshot.data!.data() as Map<String, dynamic>;
                        List<dynamic> admins = groupData['admins'] ?? [];
                        isAdmin = admins.contains(userId);
                      }

                      final bool isCurrentUser = userId == _currentUserId;

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentUser
                                ? AppTheme.primaryColor.withOpacity(0.3)
                                : Colors.grey.shade200,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isAdmin
                                    ? Colors.blue.shade300
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: profileImage != null && profileImage.isNotEmpty
                                  ? CachedNetworkImage(
                                imageUrl: profileImage,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: _getColorForString(name),
                                  child: Center(
                                    child: Text(
                                      name[0].toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: _getColorForString(name),
                                  child: Center(
                                    child: Text(
                                      name[0].toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                                  : Container(
                                color: _getColorForString(name),
                                child: Center(
                                  child: Text(
                                    name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (isCurrentUser)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'You',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 2),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  if (isAdmin)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'Group Admin',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                  SizedBox(width: isAdmin ? 8 : 0),

                                  if (role == 'Admin')
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.purple.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'Site Admin',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.purple.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: isUserAdmin && userId != _currentUserId
                              ? PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: AppTheme.textTertiaryColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onSelected: (String value) {
                              if (value == 'make_admin') {
                                _makeUserAdmin(userId);
                              } else if (value == 'remove_admin') {
                                _removeUserAdmin(userId);
                              } else if (value == 'remove') {
                                _removeUser(userId, name);
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              if (!isAdmin)
                                PopupMenuItem<String>(
                                  value: 'make_admin',
                                  child: Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings, size: 18, color: Colors.blue),
                                      SizedBox(width: 12),
                                      Text('Make Admin'),
                                    ],
                                  ),
                                ),
                              if (isAdmin)
                                PopupMenuItem<String>(
                                  value: 'remove_admin',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, size: 18, color: Colors.orange),
                                      SizedBox(width: 12),
                                      Text('Remove Admin'),
                                    ],
                                  ),
                                ),
                              PopupMenuItem<String>(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                    SizedBox(width: 12),
                                    Text('Remove from Group'),
                                  ],
                                ),
                              ),
                            ],
                          )
                              : null,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildAdminActions() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Admin Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildActionItem(
            icon: Icons.edit,
            color: Colors.blue,
            title: 'Edit Group Information',
            subtitle: 'Change name, description, and other details',
            onTap: _showEditGroupDialog,
          ),
          SizedBox(height: 12),
          _buildActionItem(
            icon: Icons.photo_library,
            color: Colors.green,
            title: 'Change Group Image',
            subtitle: 'Update the group\'s profile picture',
            onTap: _pickGroupImage,
          ),
          SizedBox(height: 12),
          _buildActionItem(
            icon: Icons.delete_forever,
            color: Colors.red,
            title: 'Delete Group',
            subtitle: 'Permanently delete this group and all its messages',
            onTap: _showDeleteGroupDialog,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.shade50
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? Colors.red.shade200
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : color,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDestructive ? Colors.red.shade700 : AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDestructive ? Colors.red.shade300 : Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.red.shade200,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.exit_to_app,
              color: Colors.red,
              size: 28,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Leave Group',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You will no longer receive messages from this group',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade700,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLeaving ? null : _showLeaveGroupDialog,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.logout),
                SizedBox(width: 8),
                Text(_isLeaving ? 'Leaving...' : 'Leave Group'),
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog() async {
    try {
      DocumentSnapshot groupDoc = await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .get();

      if (!groupDoc.exists) return;

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      String name = groupData['name'] ?? '';
      String description = groupData['description'] ?? '';

      showDialog(
        context: context,
        builder: (BuildContext context) {
          String newName = name;
          String newDescription = description;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.edit, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Edit Group Info'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    controller: TextEditingController(text: name),
                    onChanged: (value) {
                      newName = value;
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
                    controller: TextEditingController(text: description),
                    maxLines: 3,
                    onChanged: (value) {
                      newDescription = value;
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
                  if (newName.isNotEmpty && newDescription.isNotEmpty) {
                    _updateGroupInfo(newName, newDescription);
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error loading group data: $e');
    }
  }

  Future<void> _updateGroupInfo(String name, String description) async {
    try {
      // Generate search keywords for the group name
      List<String> searchKeywords = [];
      String nameLower = name.toLowerCase();
      for (int i = 1; i <= nameLower.length; i++) {
        searchKeywords.add(nameLower.substring(0, i));
      }

      await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .update({
        'name': name,
        'description': description,
        'nameSearch': searchKeywords,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group information updated'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Update the app bar title
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GroupInfoScreen(
            groupId: widget.groupId,
            groupName: name,
            isAdmin: widget.isAdmin,
            groupAvatar: widget.groupAvatar,
          ),
        ),
      );
    } catch (e) {
      print('Error updating group info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update group information'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showDeleteGroupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Group'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Permanent Action',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This action cannot be undone. All messages and data will be lost.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this group?',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
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
                Navigator.of(context).pop();
                _deleteGroup();
              },
              child: Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGroup() async {
    try {
      // Delete all messages in the group
      QuerySnapshot messagesSnapshot = await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('messages')
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete online users collection
      QuerySnapshot onlineUsersSnapshot = await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('online_users')
          .get();

      for (var doc in onlineUsersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete typing users collection
      QuerySnapshot typingUsersSnapshot = await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('typing_users')
          .get();

      for (var doc in typingUsersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete read status collection
      QuerySnapshot readStatusSnapshot = await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('read_status')
          .get();

      for (var doc in readStatusSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the group document
      batch.delete(_firestore.collection('discussion_groups').doc(widget.groupId));

      // Commit the batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group deleted successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Navigate back to the group list
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      print('Error deleting group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete group. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.orange),
              SizedBox(width: 8),
              Text('Leave Group'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will no longer receive messages from this group.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to leave this group?',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
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
                Navigator.of(context).pop();
                _leaveGroup();
              },
              child: Text('Leave Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _leaveGroup() async {
    if (_currentUserId.isEmpty) return;

    setState(() {
      _isLeaving = true;
    });

    try {
      // Update the group document atomically
      await _firestore.runTransaction((transaction) async {
        DocumentReference groupRef = _firestore.collection('discussion_groups').doc(widget.groupId);
        DocumentSnapshot groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) {
          throw Exception("Group does not exist!");
        }

        Map<String, dynamic> groupData = groupSnapshot.data() as Map<String, dynamic>;
        List<dynamic> members = List.from(groupData['members'] ?? []);
        List<dynamic> admins = List.from(groupData['admins'] ?? []);

        // Remove user from members and admins lists
        members.remove(_currentUserId);
        admins.remove(_currentUserId);

        transaction.update(groupRef, {
          'members': members,
          'admins': admins,
          'memberCount': members.length,
        });
      });

      // Remove user from online users
      await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('online_users')
          .doc(_currentUserId)
          .delete();

      // Remove user from typing users
      await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('typing_users')
          .doc(_currentUserId)
          .delete();

      // Remove user from read status
      await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('read_status')
          .doc(_currentUserId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have left the group'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Navigate back to the group list
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      print('Error leaving group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave group. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      setState(() {
        _isLeaving = false;
      });
    }
  }

  Future<void> _makeUserAdmin(String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference groupRef = _firestore.collection('discussion_groups').doc(widget.groupId);
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User is now an admin'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      print('Error making user admin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update admin status'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _removeUserAdmin(String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference groupRef = _firestore.collection('discussion_groups').doc(widget.groupId);
        DocumentSnapshot groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) {
          throw Exception("Group does not exist!");
        }

        Map<String, dynamic> groupData = groupSnapshot.data() as Map<String, dynamic>;
        List<dynamic> admins = List.from(groupData['admins'] ?? []);

        admins.remove(userId);
        transaction.update(groupRef, {'admins': admins});
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User is no longer an admin'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      print('Error removing user admin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update admin status'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _removeUser(String userId, String userName) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.person_remove, color: Colors.red),
              SizedBox(width: 8),
              Expanded(
                child: Text('Remove User'),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to remove $userName from this group?',
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
                Navigator.of(context).pop();
                _processUserRemoval(userId);
              },
              child: Text('Remove'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processUserRemoval(String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference groupRef = _firestore.collection('discussion_groups').doc(widget.groupId);
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
          .doc(widget.groupId)
          .collection('online_users')
          .doc(userId)
          .delete();

      // Remove user from typing users
      await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('typing_users')
          .doc(userId)
          .delete();

      // Remove user from read status
      await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('read_status')
          .doc(userId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User removed from group'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      print('Error removing user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove user'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
}