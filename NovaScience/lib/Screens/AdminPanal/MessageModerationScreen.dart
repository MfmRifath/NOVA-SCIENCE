import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../StartScreen/AppTheme.dart';


class MessageModerationScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const MessageModerationScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  _MessageModerationScreenState createState() => _MessageModerationScreenState();
}

class _MessageModerationScreenState extends State<MessageModerationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _messages = [];
  List<String> _selectedMessages = [];
  String _searchQuery = '';
  String _filterByType = 'all';
  String _filterByUser = 'all';

  List<Map<String, dynamic>> _uniqueUsers = [];
  bool _showDeleteOption = false;

  ScrollController _scrollController = ScrollController();
  bool _hasMoreMessages = true;
  bool _isLoadingMore = false;

  final int _messagesPerPage = 50;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadMessages();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMoreMessages();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _messages = [];
      _lastDocument = null;
    });

    try {
      Query query = _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('messages')
          .orderBy('timestamp', descending: true);

      if (_searchQuery.isNotEmpty) {
        query = query.where('text', isGreaterThanOrEqualTo: _searchQuery)
            .where('text', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
      }

      if (_filterByType != 'all') {
        query = query.where('mediaType', isEqualTo: _filterByType);
      }

      if (_filterByUser != 'all') {
        query = query.where('senderId', isEqualTo: _filterByUser);
      }

      QuerySnapshot snapshot = await query.limit(_messagesPerPage).get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      await _processMessagesSnapshot(snapshot);
      await _loadUniqueUsers();

      setState(() {
        _isLoading = false;
        _hasMoreMessages = snapshot.docs.length == _messagesPerPage;
      });
    } catch (e) {
      print('Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (!_hasMoreMessages || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      Query query = _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('messages')
          .orderBy('timestamp', descending: true);

      if (_searchQuery.isNotEmpty) {
        query = query.where('text', isGreaterThanOrEqualTo: _searchQuery)
            .where('text', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
      }

      if (_filterByType != 'all') {
        query = query.where('mediaType', isEqualTo: _filterByType);
      }

      if (_filterByUser != 'all') {
        query = query.where('senderId', isEqualTo: _filterByUser);
      }

      query = query.startAfterDocument(_lastDocument!).limit(_messagesPerPage);

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      await _processMessagesSnapshot(snapshot);

      setState(() {
        _isLoadingMore = false;
        _hasMoreMessages = snapshot.docs.length == _messagesPerPage;
      });
    } catch (e) {
      print('Error loading more messages: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _processMessagesSnapshot(QuerySnapshot snapshot) async {
    List<Map<String, dynamic>> newMessages = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      newMessages.add({
        'id': doc.id,
        'text': data['text'] ?? '',
        'senderId': data['senderId'] ?? '',
        'senderName': data['senderName'] ?? 'Unknown',
        'timestamp': data['timestamp'] != null
            ? (data['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
        'mediaUrl': data['mediaUrl'],
        'mediaThumbnailUrl': data['mediaThumbnailUrl'],
        'mediaType': data['mediaType'] ?? '',
      });
    }

    setState(() {
      _messages.addAll(newMessages);
    });
  }

  Future<void> _loadUniqueUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();

      Set<String> uniqueUserIds = Set();
      List<Map<String, dynamic>> users = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String senderId = data['senderId'] ?? '';
        String senderName = data['senderName'] ?? 'Unknown';

        if (senderId.isNotEmpty && !uniqueUserIds.contains(senderId)) {
          uniqueUserIds.add(senderId);
          users.add({
            'id': senderId,
            'name': senderName,
          });
        }
      }

      setState(() {
        _uniqueUsers = users;
      });
    } catch (e) {
      print('Error loading unique users: $e');
    }
  }

  Future<void> _deleteSelectedMessages() async {
    if (_selectedMessages.isEmpty) return;

    try {
      // Create a batch operation
      WriteBatch batch = _firestore.batch();

      // Get messages with media to delete from storage
      List<String> messagesToDelete = List.from(_selectedMessages);
      List<String> mediaUrlsToDelete = [];

      for (var message in _messages) {
        if (_selectedMessages.contains(message['id']) && message['mediaUrl'] != null) {
          mediaUrlsToDelete.add(message['mediaUrl']);
        }
      }

      // Delete messages from Firestore
      for (var messageId in messagesToDelete) {
        DocumentReference messageRef = _firestore
            .collection('discussion_groups')
            .doc(widget.groupId)
            .collection('messages')
            .doc(messageId);

        batch.delete(messageRef);
      }

      // Commit the batch
      await batch.commit();

      // Delete media files from Storage
      for (var mediaUrl in mediaUrlsToDelete) {
        try {
          await _storage.refFromURL(mediaUrl).delete();
        } catch (e) {
          print('Error deleting media file: $e');
        }
      }

      // Update message count in group document
      await _firestore.collection('discussion_groups').doc(widget.groupId).update({
        'messageCount': FieldValue.increment(-messagesToDelete.length),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${messagesToDelete.length} messages deleted'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset selection and reload messages
      setState(() {
        _selectedMessages = [];
        _showDeleteOption = false;
      });

      _loadMessages();
    } catch (e) {
      print('Error deleting messages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete messages: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reportContent(Map<String, dynamic> message) async {
    try {
      await _firestore.collection('reported_content').add({
        'contentType': message['mediaUrl'] != null ? message['mediaType'] : 'message',
        'contentId': message['id'],
        'groupId': widget.groupId,
        'groupName': widget.groupName,
        'senderId': message['senderId'],
        'senderName': message['senderName'],
        'messageText': message['text'],
        'mediaUrl': message['mediaUrl'],
        'reportedAt': FieldValue.serverTimestamp(),
        'reportedBy': 'Admin',
        'reason': 'Flagged by admin for review',
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Content reported for review'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Error reporting content: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to report content: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _banUser(String userId, String userName) async {
    try {
      // Add user to banned users collection
      await _firestore.collection('banned_users').add({
        'userId': userId,
        'userName': userName,
        'groupId': widget.groupId,
        'groupName': widget.groupName,
        'bannedAt': FieldValue.serverTimestamp(),
        'bannedBy': 'Admin',
        'reason': 'Inappropriate content',
      });

      // Remove user from group
      await _firestore.runTransaction((transaction) async {
        DocumentReference groupRef = _firestore.collection('discussion_groups').doc(widget.groupId);
        DocumentSnapshot groupSnapshot = await transaction.get(groupRef);

        if (groupSnapshot.exists) {
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
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User $userName has been banned from the group'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload messages to update UI
      _loadMessages();
    } catch (e) {
      print('Error banning user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ban user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Message Moderation: ${widget.groupName}',
          style: TextStyle(color: Colors.white),
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
        actions: [
          if (_showDeleteOption && _selectedMessages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmationDialog();
              },
              tooltip: 'Delete Selected Messages',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
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
              hintText: 'Search messages...',
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                  _loadMessages();
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
                  _loadMessages();
                }
              });
            },
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by type:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _filterByType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(value: 'all', child: Text('All Types')),
                        DropdownMenuItem(value: 'image', child: Text('Images')),
                        DropdownMenuItem(value: 'video', child: Text('Videos')),
                        DropdownMenuItem(value: 'audio', child: Text('Audio')),
                        DropdownMenuItem(value: '', child: Text('Text Only')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterByType = value!;
                        });
                        _loadMessages();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by user:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _filterByUser,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),

                          items: [
                          DropdownMenuItem<String>(value: 'all', child: Text('All Types')),
                          DropdownMenuItem<String>(value: 'image', child: Text('Images')),
                          DropdownMenuItem<String>(value: 'video', child: Text('Videos')),
                          DropdownMenuItem<String>(value: 'audio', child: Text('Audio')),
                          DropdownMenuItem<String>(value: '', child: Text('Text Only')),
                          ],
                      onChanged: (value) {
                        setState(() {
                          _filterByUser = value!;
                        });
                        _loadMessages();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _showDeleteOption,
                onChanged: (value) {
                  setState(() {
                    _showDeleteOption = value!;
                    if (!_showDeleteOption) {
                      _selectedMessages = [];
                    }
                  });
                },
              ),
              Text(
                'Select messages to delete',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Spacer(),
              if (_showDeleteOption && _selectedMessages.isNotEmpty)
                Text(
                  '${_selectedMessages.length} selected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.tertiaryColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(8),
      itemCount: _messages.length + (_hasMoreMessages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildLoadingMoreIndicator();
        }

        final message = _messages[index];
        final isSelected = _selectedMessages.contains(message['id']);

        return Card(
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: isSelected ? Colors.blue.shade50 : null,
          child: InkWell(
            onLongPress: () {
              if (_showDeleteOption) {
                setState(() {
                  if (isSelected) {
                    _selectedMessages.remove(message['id']);
                  } else {
                    _selectedMessages.add(message['id']);
                  }
                });
              }
            },
            onTap: () {
              if (_showDeleteOption) {
                setState(() {
                  if (isSelected) {
                    _selectedMessages.remove(message['id']);
                  } else {
                    _selectedMessages.add(message['id']);
                  }
                });
              }
            },
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showDeleteOption)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value!) {
                              _selectedMessages.add(message['id']);
                            } else {
                              _selectedMessages.remove(message['id']);
                            }
                          });
                        },
                      ),
                    ),
                  CircleAvatar(
                    backgroundColor: _getColorForString(message['senderName']),
                    radius: 20,
                    child: Text(
                      message['senderName'][0].toUpperCase(),
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
                              message['senderName'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              _formatDateTime(message['timestamp']),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textTertiaryColor,
                              ),
                            ),
                            Spacer(),
                            _buildMessageMenu(message),
                          ],
                        ),
                        SizedBox(height: 8),
                        if (message['mediaUrl'] != null)
                          _buildMediaPreview(message),
                        if (message['text'].isNotEmpty) ...[
                          SizedBox(height: message['mediaUrl'] != null ? 8 : 0),
                          Text(
                            message['text'],
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaPreview(Map<String, dynamic> message) {
    final mediaType = message['mediaType'] ?? '';
    final mediaUrl = message['mediaUrl'];

    if (mediaUrl == null) return Container();

    if (mediaType == 'image') {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            mediaUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else if (mediaType == 'video') {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (message['mediaThumbnailUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message['mediaThumbnailUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade800,
                    );
                  },
                ),
              )
            else
              Container(
                color: Colors.grey.shade800,
              ),
            Icon(
              Icons.play_circle_fill,
              size: 48,
              color: Colors.white.withOpacity(0.8),
            ),
          ],
        ),
      );
    } else if (mediaType == 'audio') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.audiotrack,
              color: AppTheme.secondaryColor,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Audio Message',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
            Icon(
              Icons.play_arrow,
              color: AppTheme.tertiaryColor,
              size: 24,
            ),
          ],
        ),
      );
    }

    return Container();
  }

  Widget _buildMessageMenu(Map<String, dynamic> message) {
    return PopupMenuButton(
      icon: Icon(
        Icons.more_vert,
        color: AppTheme.textTertiaryColor,
        size: 16,
      ),
      onSelected: (value) async {
        if (value == 'delete') {
          setState(() {
            _selectedMessages = [message['id']];
          });
          _showDeleteConfirmationDialog();
        } else if (value == 'report') {
          _reportContent(message);
        } else if (value == 'ban_user') {
          _showBanUserConfirmation(message['senderId'], message['senderName']);
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Delete Message'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Text('Report Content'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'ban_user',
          child: Row(
            children: [
              Icon(Icons.person_off_outlined, color: Colors.red, size: 18),
              SizedBox(width: 8),
              Text('Ban User'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? CircularProgressIndicator()
          : TextButton(
        onPressed: _loadMoreMessages,
        child: Text('Load More'),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'No messages found';
    if (_searchQuery.isNotEmpty) {
      message = 'No messages matching "$_searchQuery"';
    } else if (_filterByType != 'all') {
      message = 'No ${_filterByType.isNotEmpty ? _filterByType : "text"} messages found';
    } else if (_filterByUser != 'all') {
      String userName = _uniqueUsers.firstWhere((u) => u['id'] == _filterByUser, orElse: () => {'name': 'selected user'})['name'];
      message = 'No messages from $userName';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          SizedBox(height: 8),
          if (_searchQuery.isNotEmpty || _filterByType != 'all' || _filterByUser != 'all')
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _filterByType = 'all';
                  _filterByUser = 'all';
                });
                _loadMessages();
              },
              child: Text('Clear Filters'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Messages'),
          content: Text(
            'Are you sure you want to delete ${_selectedMessages.length} selected message(s)? '
                'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSelectedMessages();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showBanUserConfirmation(String userId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ban User'),
          content: Text(
            'Are you sure you want to ban $userName from this group? '
                'They will be removed from the group and prevented from rejoining.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _banUser(userId, userName);
              },
              child: Text('Ban User', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today, ${DateFormat('h:mm a').format(dateTime)}';
    } else if (date == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }
}