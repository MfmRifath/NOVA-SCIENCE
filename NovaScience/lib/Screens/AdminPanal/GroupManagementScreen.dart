import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../StartScreen/AppTheme.dart';
import 'MessageModerationScreen.dart';


class GroupManagementScreen extends StatefulWidget {
  final String category;

  const GroupManagementScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  _GroupManagementScreenState createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _groups = [];
  String _searchQuery = '';
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void didUpdateWidget(GroupManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _loadGroups();
    }
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Query query = _firestore.collection('discussion_groups');

      // Apply category filter
      if (widget.category != 'All Categories') {
        query = query.where('category', isEqualTo: widget.category);
      }

      // Apply search filter if present
      if (_searchQuery.isNotEmpty) {
        query = query.where('name', isGreaterThanOrEqualTo: _searchQuery)
            .where('name', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
      }

      // Apply sorting
      switch (_sortBy) {
        case 'newest':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'oldest':
          query = query.orderBy('createdAt', descending: false);
          break;
        case 'members':
          query = query.orderBy('memberCount', descending: true);
          break;
        case 'messages':
          query = query.orderBy('messageCount', descending: true);
          break;
        case 'activity':
          query = query.orderBy('lastMessageTime', descending: true);
          break;
      }

      QuerySnapshot snapshot = await query.get();

      List<Map<String, dynamic>> groups = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        groups.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown Group',
          'description': data['description'] ?? '',
          'category': data['category'] ?? '',
          'createdBy': data['createdBy'] ?? '',
          'creatorName': data['creatorName'] ?? '',
          'createdAt': data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          'memberCount': data['memberCount'] ?? 0,
          'messageCount': data['messageCount'] ?? 0,
          'lastMessageTime': data['lastMessageTime'] != null
              ? (data['lastMessageTime'] as Timestamp).toDate()
              : null,
          'lastMessage': data['lastMessage'] ?? '',
        });
      }

      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading groups: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteGroup(String groupId) async {
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

      // Refresh the list
      _loadGroups();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _groups.isEmpty
                ? _buildEmptyState()
                : _buildGroupList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        backgroundColor: AppTheme.tertiaryColor,
        child: Icon(Icons.add),
        tooltip: 'Create New Group',
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search groups...',
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                  _loadGroups();
                },
              )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              // Debounce search to avoid excessive queries
              Future.delayed(Duration(milliseconds: 300), () {
                if (value == _searchQuery) {
                  _loadGroups();
                }
              });
            },
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Sort by:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              SizedBox(width: 5),
              _buildSortButton('newest', 'Newest'),
              SizedBox(width: 5),
              _buildSortButton('oldest', 'Oldest'),
              SizedBox(width: 8),
              _buildSortButton('members', 'Members'),
              SizedBox(width: 8),
              _buildSortButton('messages', 'Messages'),
              SizedBox(width: 8),
              _buildSortButton('activity', 'Activity'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(String sortValue, String label) {
    final isSelected = _sortBy == sortValue;

    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = sortValue;
        });
        _loadGroups();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        final hasRecentActivity = group['lastMessageTime'] != null &&
            DateTime.now().difference(group['lastMessageTime']).inDays < 3;

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getColorForString(group['name']),
                      child: Text(
                        group['name'][0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                group['name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              SizedBox(width: 8),
                              if (hasRecentActivity)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Category: ${group['category']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Created on ${_formatDate(group['createdAt'])} by ${group['creatorName']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildGroupMenu(group),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  group['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                      label: 'Members',
                      value: group['memberCount'].toString(),
                      icon: Icons.people_outline,
                    ),
                    SizedBox(width: 12),
                    _buildStatCard(
                      label: 'Messages',
                      value: group['messageCount'].toString(),
                      icon: Icons.message_outlined,
                    ),
                    SizedBox(width: 12),
                    _buildStatCard(
                      label: 'Last Activity',
                      value: group['lastMessageTime'] != null
                          ? _formatTimeAgo(group['lastMessageTime'])
                          : 'N/A',
                      icon: Icons.access_time,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // Navigate to group details
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessageModerationScreen(
                              groupId: group['id'],
                              groupName: group['name'],
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.message_outlined, size: 18),
                      label: Text('Moderate'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupMenu(Map<String, dynamic> group) {
    return PopupMenuButton(
      icon: Icon(
        Icons.more_vert,
        color: AppTheme.textTertiaryColor,
      ),
      onSelected: (value) async {
        if (value == 'edit') {
          _showEditGroupDialog(group);
        } else if (value == 'delete') {
          bool confirm = await _showDeleteConfirmation(group['name']);
          if (confirm) {
            _deleteGroup(group['id']);
          }
        } else if (value == 'moderate') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MessageModerationScreen(
                groupId: group['id'],
                groupName: group['name'],
              ),
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: AppTheme.primaryColor, size: 18),
              SizedBox(width: 8),
              Text('Edit Group'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'moderate',
          child: Row(
            children: [
              Icon(Icons.message_outlined, color: AppTheme.primaryColor, size: 18),
              SizedBox(width: 8),
              Text('Moderate Messages'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Delete Group', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppTheme.textTertiaryColor,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No groups found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : widget.category != 'All Categories'
                ? 'No groups in this category'
                : 'Create a new group to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textTertiaryColor,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateGroupDialog,
            icon: Icon(Icons.add),
            label: Text('Create New Group'),
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

  void _showCreateGroupDialog() {
    String groupName = '';
    String groupDescription = '';
    String category = widget.category == 'All Categories'
        ? 'Science Stream'
        : widget.category;

    final List<String> categories = [
      'Science Stream',
      'Arts Stream',
      'Commerce Stream',
      'Technology Stream',
      'O/L',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Create New Group'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Group Name:'),
                    SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter group name',
                      ),
                      onChanged: (value) {
                        groupName = value;
                      },
                    ),
                    SizedBox(height: 16),
                    Text('Group Description:'),
                    SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter group description',
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        groupDescription = value;
                      },
                    ),
                    SizedBox(height: 16),
                    Text('Category:'),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          category = value!;
                        });
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
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (groupName.isNotEmpty && groupDescription.isNotEmpty) {
                      Navigator.of(context).pop();
                      await _createGroup(groupName, groupDescription, category);
                    }
                  },
                  child: Text('Create'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tertiaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditGroupDialog(Map<String, dynamic> group) {
    String groupName = group['name'];
    String groupDescription = group['description'];
    String category = group['category'];

    final List<String> categories = [
      'Science Stream',
      'Arts Stream',
      'Commerce Stream',
      'Technology Stream',
      'O/L',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Group'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Group Name:'),
                    SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter group name',
                      ),
                      controller: TextEditingController(text: groupName),
                      onChanged: (value) {
                        groupName = value;
                      },
                    ),
                    SizedBox(height: 16),
                    Text('Group Description:'),
                    SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter group description',
                      ),
                      controller: TextEditingController(text: groupDescription),
                      maxLines: 3,
                      onChanged: (value) {
                        groupDescription = value;
                      },
                    ),
                    SizedBox(height: 16),
                    Text('Category:'),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          category = value!;
                        });
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
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (groupName.isNotEmpty && groupDescription.isNotEmpty) {
                      Navigator.of(context).pop();
                      await _updateGroup(group['id'], groupName, groupDescription, category);
                    }
                  },
                  child: Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tertiaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmation(String groupName) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Group'),
          content: Text(
            'Are you sure you want to delete the group "$groupName"? '
                'This action cannot be undone and all messages will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  Future<void> _createGroup(String name, String description, String category) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadGroups();
    } catch (e) {
      print('Error creating group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateGroup(String groupId, String name, String description, String category) async {
    try {
      await _firestore.collection('discussion_groups').doc(groupId).update({
        'name': name,
        'description': description,
        'category': category,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadGroups();
    } catch (e) {
      print('Error updating group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update group: $e'),
          backgroundColor: Colors.red,
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

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}