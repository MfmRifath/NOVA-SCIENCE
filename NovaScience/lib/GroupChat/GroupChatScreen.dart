import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:nova_science/GroupChat/VideoPlayerScreen.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

import '../Screens/StartScreen/AppTheme.dart';
import '../Service/NotificationService.dart';
import 'AudioPalyer.dart';
import 'GroupInfoScreen.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupAvatar;

  const GroupChatScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
    this.groupAvatar,
  }) : super(key: key);

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // User and group state
  bool _isAdmin = false;
  bool _isLoading = false;
  bool _isUploading = false;
  String _currentUserId = '';
  String _currentUserName = '';

  // UI state
  bool _showEmojiPicker = false;
  bool _showScrollButton = false;
  bool _isTyping = false;
  int _unreadMessageCount = 0;
  double _uploadProgress = 0.0;

  // Media state
  File? _selectedMedia;
  String _mediaType = '';

  // Voice recording state
  VoiceRecordingManager? _voiceRecordingManager;
  bool _isRecording = false;
  bool _isVoiceRecordingLocked = false;
  bool _showVoiceRecording = false;

  // For recording button animation
  double _recordButtonScale = 1.0;

  // For recording progress indication
  int _maxRecordingDuration = 300; // 5 minutes in seconds

  // For visual feedback during recording
  Color _recordingColor = Colors.red.shade600;

  // Animation controllers
  late AnimationController _sendButtonController;
  late AnimationController _mediaUploadController;
  late AnimationController _fabController;
  late AnimationController _recordingAnimationController;

  // Message selection
  Map<String, dynamic>? _replyToMessage;
  final List<String> _selectedMessageIds = [];
  bool _isSelectMode = false;

  // Streams
  late Stream<QuerySnapshot> _messagesStream;
  Stream<QuerySnapshot>? _onlineUsersStream;
  Timestamp? _lastReadTimestamp;

  // Theme variables
  late ThemeData _theme;
  late Color _accentColor;
  late Color _backgroundColor;
  late Color _cardColor;
  late Color _textColor;
  late Color _secondaryTextColor;
  bool _isDarkMode = false;

  // Helper method for safe opacity values
  double _safeOpacity(double value) {
    return value.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid ?? '';
    _setupMessagesStream();
    _setupOnlineUsersStream();
    _getUserInfo();
    _updateUserOnlineStatus(true);
    _fetchLastReadTimestamp();
    _initVoiceRecordingManager();
    _setupScrollListener();

    // Initialize controllers
    _messageController.addListener(_handleTypingStatus);
    _messageFocusNode.addListener(_handleFocusChange);

    // Initialize animation controllers
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _mediaUploadController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _recordingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.offset > 500 && !_showScrollButton) {
        setState(() {
          _showScrollButton = true;
        });
      } else if (_scrollController.offset <= 500 && _showScrollButton) {
        setState(() {
          _showScrollButton = false;
        });
      }

      // Add logic for loading more messages when scrolling to top
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMoreMessages();
      }
    });
  }

  void _handleFocusChange() {
    if (_messageFocusNode.hasFocus) {
      setState(() {
        _showEmojiPicker = false;
      });
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  void _updateThemeSettings() {
    // Get system brightness
    final brightness = MediaQuery.of(context).platformBrightness;
    _isDarkMode = brightness == Brightness.dark;

    // Set theme colors based on mode
    if (_isDarkMode) {
      _backgroundColor = Color(0xFF121212);
      _cardColor = Color(0xFF1E1E1E);
      _accentColor = Color(0xFF4F78FF); // Vibrant blue
      _textColor = Colors.white;
      _secondaryTextColor = Colors.grey[400]!;
    } else {
      _backgroundColor = Colors.grey.shade50;
      _cardColor = Colors.white;
      _accentColor = Color(0xFF4F78FF); // Vibrant blue
      _textColor = Colors.black87;
      _secondaryTextColor = Colors.grey[600]!;
    }

    // Set theme
    _theme = Theme.of(context);
  }


  void _setupMessagesStream() {
    // Initial query with limit
    _messagesStream = _firestore
        .collection('discussion_groups')
        .doc(widget.groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_paginationLimit)
        .snapshots();
  }

  void _setupOnlineUsersStream() {
    _onlineUsersStream = _firestore
        .collection('discussion_groups')
        .doc(widget.groupId)
        .collection('online_users')
        .where('isOnline', isEqualTo: true)
        .snapshots();
  }

  DocumentSnapshot? _lastVisibleMessage;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  int _paginationLimit = 50; // Number of messages to load at a time
  void _loadMoreMessages() async {
    // Check if already loading or if there are no more messages
    if (_isLoadingMore || !_hasMoreMessages || _lastVisibleMessage == null) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Show loading indicator
      _showSnackBar('Loading older messages...');

      // Query the next batch of messages starting after the last visible message
      final querySnapshot = await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastVisibleMessage!)
          .limit(_paginationLimit)
          .get();

      // Check if we've reached the end
      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
          _isLoadingMore = false;
        });
        _showSnackBar('No more messages to load');
        return;
      }

      // Update the last visible message for the next pagination
      _lastVisibleMessage = querySnapshot.docs.last;

      // Here we need to merge the new messages with existing ones
      // This depends on how you're storing the current messages
      // One approach is to use a StreamController to merge streams

      // For a simpler approach, if you're using a StreamBuilder in your UI:
      // You can store loaded messages in a separate List<DocumentSnapshot>
      // and use that list in your build method instead of directly using the stream

      final List<DocumentSnapshot> newMessages = querySnapshot.docs;
      // Add newMessages to your existing messages list

      setState(() {
        _isLoadingMore = false;
      });

    } catch (e) {
      print('Error loading more messages: $e');
      setState(() {
        _isLoadingMore = false;
      });
      _showSnackBar('Failed to load more messages', isError: true);
    }
  }


  void _handleTypingStatus() {
    final isCurrentlyTyping = _messageController.text.isNotEmpty;

    if (_isTyping != isCurrentlyTyping) {
      setState(() {
        _isTyping = isCurrentlyTyping;
      });

      // Update typing status in Firestore
      _updateTypingStatus(isCurrentlyTyping);
    }
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    if (_currentUserId.isEmpty) return;

    try {
      await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('typing_users')
          .doc(_currentUserId)
          .set({
        'userId': _currentUserId,
        'name': _currentUserName,
        'isTyping': isTyping,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  Future<void> _fetchLastReadTimestamp() async {
    if (_currentUserId.isEmpty) return;

    try {
      final doc = await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('read_status')
          .doc(_currentUserId)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _lastReadTimestamp = doc.data()!['lastRead'] as Timestamp?;
        });
      }
    } catch (e) {
      print('Error fetching read status: $e');
    }
  }

  Future<void> _updateLastReadTimestamp() async {
    if (_currentUserId.isEmpty) return;

    try {
      await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('read_status')
          .doc(_currentUserId)
          .set({
        'userId': _currentUserId,
        'lastRead': FieldValue.serverTimestamp(),
      });

      // Reset unread count
      setState(() {
        _unreadMessageCount = 0;
      });
    } catch (e) {
      print('Error updating read status: $e');
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();

    // Update user status
    _updateUserOnlineStatus(false);
    _updateTypingStatus(false);

    // Dispose animation controllers
    _sendButtonController.dispose();
    _mediaUploadController.dispose();
    _fabController.dispose();
    _recordingAnimationController.dispose();

    // Dispose voice recording manager
    _voiceRecordingManager?.dispose();

    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _getUserInfo() async {
    if (_currentUserId.isEmpty) return;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();

      final groupDoc = await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .get();

      if (mounted) {
        setState(() {
          _currentUserName = userDoc.data()?['name'] ?? 'Anonymous';

          // Check if current user is an admin of the group
          List<dynamic> admins = groupDoc.data()?['admins'] ?? [];
          _isAdmin = admins.contains(_currentUserId) || userDoc.data()?['role'] == 'Admin';
        });
      }
    } catch (e) {
      print('Error getting user info: $e');
    }
  }

  Future<void> _updateUserOnlineStatus(bool isOnline) async {
    if (_currentUserId.isEmpty) return;

    try {
      await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('online_users')
          .doc(_currentUserId)
          .set({
        'userId': _currentUserId,
        'name': _currentUserName,
        'lastActive': FieldValue.serverTimestamp(),
        'isOnline': isOnline,
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }
  // Voice message handling
  // Replace the current _startRecordingVoiceMessage method with this improved version
  Future<void> _startRecordingVoiceMessage() async {
    try {
      // First check permissions - this is crucial
      final permissionGranted = await _checkMicrophonePermission();
      if (!permissionGranted) {
        _showSnackBar('Microphone permission is required to record voice messages', isError: true);
        return;
      }

      // If voice recording manager is null or had an error, reinitialize it
      if (_voiceRecordingManager == null) {
        _initVoiceRecordingManager();
        // Give it time to initialize
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Double-check it initialized properly
      if (_voiceRecordingManager == null || _voiceRecordingManager!.recorderController == null) {
        _showSnackBar('Could not initialize audio recorder. Please try again.', isError: true);
        return;
      }

      // Now start recording with proper error handling
      final success = await _voiceRecordingManager!.startRecording();
      if (!success) {
        _showSnackBar('Failed to start recording. Please try again.', isError: true);
      } else {
        // Provide feedback that recording started
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      print('Error in voice recording: $e');
      _showSnackBar('Recording error: $e', isError: true);

      // Reset recording state in case of error
      setState(() {
        _isVoiceRecordingLocked = false;
        _showVoiceRecording = false;
        _isRecording = false;
      });
    }
  }

  // Improved permission check method
  Future<bool> _checkMicrophonePermission() async {
    try {
      // Check current status
      var status = await Permission.microphone.status;

      // If permission is not determined yet or denied, request it
      if (status.isDenied || status.isRestricted || status.isLimited) {
        _showSnackBar('Requesting microphone permission...');
        status = await Permission.microphone.request();
      }

      // If still denied after request, show settings option
      if (status.isDenied || status.isPermanentlyDenied) {
        _showSnackBar('Microphone permission is required for voice messages', isError: true);

        // Show dialog to open settings if permanently denied
        if (status.isPermanentlyDenied) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Microphone Permission Required'),
              content: Text('Voice messages require microphone access. Please enable it in app settings.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return false;
      }

      return status.isGranted;
    } catch (e) {
      print('Error checking microphone permission: $e');
      return false;
    }
  }

  // Also update the initialization method for the voice recording manager
  void _initVoiceRecordingManager() {
    // Clean up previous instance if it exists
    _voiceRecordingManager?.dispose();

    _voiceRecordingManager = VoiceRecordingManager();

    // Set up callbacks
    _voiceRecordingManager!.onDurationChanged = (duration) {
      if (mounted) {
        setState(() {
          // Force UI refresh when duration changes
        });
      }
    };

    _voiceRecordingManager!.onRecordingStateChanged = (isRecording) {
      if (mounted) {
        setState(() {
          _showVoiceRecording = isRecording;
          _isRecording = isRecording;

          // If starting a recording, provide haptic feedback
          if (isRecording) {
            HapticFeedback.mediumImpact();
          }
        });
      }
    };

    _voiceRecordingManager!.onRecordingComplete = (audioFile) {
      // Only attempt to send if the file exists and is not empty
      if (audioFile != null && audioFile.existsSync() && audioFile.lengthSync() > 0) {
        _sendVoiceMessage(audioFile);
      } else {
        _showSnackBar('Recording was too short', isError: true);
      }
    };

    _voiceRecordingManager!.onError = (error) {
      _showSnackBar('Recording error: $error', isError: true);
    };
  }


  void _stopRecordingVoiceMessage() async {
    if (_voiceRecordingManager != null && _voiceRecordingManager!.isRecording) {
      try {
        await _voiceRecordingManager!.stopRecording();
      } catch (e) {
        print('Error stopping recording: $e');
        _showSnackBar('Error stopping recording', isError: true);
      }

      setState(() {
        _isVoiceRecordingLocked = false;
        _showVoiceRecording = false;
        _isRecording = false;
        _recordButtonScale = 1.0; // Reset button scale
      });
    }
  }

  void _cancelRecording() async {
    if (_voiceRecordingManager != null && _voiceRecordingManager!.isRecording) {
      try {
        await _voiceRecordingManager!.cancelRecording();
      } catch (e) {
        print('Error canceling recording: $e');
      }

      setState(() {
        _isVoiceRecordingLocked = false;
        _showVoiceRecording = false;
        _isRecording = false;
        _recordButtonScale = 1.0; // Reset button scale
      });
    }
  }

  Future<void> _sendVoiceMessage(File audioFile) async {
    setState(() {
      _isLoading = true;
    });

    // Show uploading feedback
    _showSnackBar('Sending voice message...');

    try {
      // Check if file exists and has content
      if (!audioFile.existsSync()) {
        throw Exception("Audio file doesn't exist");
      }

      if (audioFile.lengthSync() == 0) {
        throw Exception("Audio file is empty");
      }

      // Animate send button
      _sendButtonController.forward().then((_) => _sendButtonController.reverse());

      // Upload audio file
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_currentUserId}_voice.m4a';
      final storageRef = _storage.ref()
          .child('group_messages')
          .child(widget.groupId)
          .child(fileName);

      setState(() {
        _isUploading = true;
      });

      // Start upload animation
      _mediaUploadController.repeat(reverse: true);

      // Upload file with progress tracking
      final uploadTask = storageRef.putFile(audioFile);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      // Wait for the upload to complete
      await uploadTask.whenComplete(() {});

      // Get the download URL
      final mediaUrl = await storageRef.getDownloadURL();

      // Stop upload animation
      _mediaUploadController.stop();
      _mediaUploadController.reset();

      setState(() {
        _isUploading = false;
      });

      // Get the audio duration if possible
      int durationInSeconds = 0;
      try {
        final player = AudioPlayer();
        await player.setFilePath(audioFile.path);
        final duration = player.duration;
        if (duration != null) {
          durationInSeconds = duration.inSeconds;
        }
        await player.dispose();
      } catch (e) {
        print('Error getting audio duration: $e');
      }

      // Build the message data
      final messageData = {
        'text': '🎤 Voice message (${_formatDuration(durationInSeconds)})',
        'senderId': _currentUserId,
        'senderName': _currentUserName,
        'timestamp': FieldValue.serverTimestamp(),
        'mediaUrl': mediaUrl,
        'mediaThumbnailUrl': '',
        'mediaType': 'audio',
        'audioDuration': durationInSeconds,
      };

      // Add reply data if replying to a message
      if (_replyToMessage != null) {
        messageData['replyTo'] = {
          'messageId': _replyToMessage!['messageId'] ?? '',
          'text': _replyToMessage!['text'] ?? '',
          'senderName': _replyToMessage!['senderName'] ?? '',
          'mediaType': _replyToMessage!['mediaType'] ?? '',
        };
      }

      // Add message to Firestore
      final messageRef = await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('messages')
          .add(messageData);

      // Update last message in group document
      await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .update({
        'lastMessage': '🎤 Voice message',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUserId,
        'messageCount': FieldValue.increment(1),
      });

      // Reset states
      setState(() {
        _replyToMessage = null;
      });

      // Update read status
      _updateLastReadTimestamp();

      // Scroll to bottom to show the new message
      _scrollToBottom();

      // Show success message
      _showSnackBar('Voice message sent', isSuccess: true);
    } catch (e) {
      print('Error sending voice message: $e');
      _showSnackBar('Failed to send voice message', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if ((messageText.isEmpty && _selectedMedia == null) || _isUploading) return;

    // Check if message contains URLs or links
    if (_containsUrl(messageText)) {
      _showSnackBar('Links are not allowed in messages.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Animate send button
      _sendButtonController.forward().then((_) => _sendButtonController.reverse());

      String? mediaUrl;
      String? mediaThumbnailUrl;
      String finalMediaType = _mediaType;

      // Upload media if selected
      if (_selectedMedia != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_currentUserId}';
        final fileExtension = _selectedMedia!.path.split('.').last;
        final storageRef = _storage.ref()
            .child('group_messages')
            .child(widget.groupId)
            .child('$fileName.$fileExtension');

        setState(() {
          _isUploading = true;
        });

        // Start upload animation
        _mediaUploadController.repeat(reverse: true);

        // Upload file with progress tracking
        final uploadTask = storageRef.putFile(_selectedMedia!);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          setState(() {
            _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        });

        // Wait for the upload to complete
        await uploadTask.whenComplete(() {});

        // Get the download URL
        try {
          mediaUrl = await storageRef.getDownloadURL();

          // Test if URL is accessible
          final response = await http.head(Uri.parse(mediaUrl));
        } catch (urlError) {
          print('Error getting download URL: $urlError');
          // Fallback: try constructing URL manually if Firebase gives issues
          try {
            final fullPath = storageRef.fullPath;
            final bucket = _storage.bucket;
            // Construct Google Cloud Storage URL format
            final manualUrl = 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(fullPath)}?alt=media';
            mediaUrl = manualUrl;
          } catch (e) {
            print('Error constructing manual URL: $e');
          }
        }

        // Create thumbnail for video if needed
        if (finalMediaType == 'video') {
          // This would require a video thumbnail generator
          // For simplicity, we're using the same URL
          mediaThumbnailUrl = mediaUrl;
        }

        // Ensure media type is not empty
        if (mediaUrl != null && mediaUrl.isNotEmpty && finalMediaType.isEmpty) {
          // Determine type from file extension
          if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension.toLowerCase())) {
            finalMediaType = 'image';
          } else if (['mp4', 'mov', 'avi', 'mkv'].contains(fileExtension.toLowerCase())) {
            finalMediaType = 'video';
          } else if (['mp3', 'wav', 'ogg', 'm4a'].contains(fileExtension.toLowerCase())) {
            finalMediaType = 'audio';
          } else {
            finalMediaType = 'file';
          }
        }

        // Stop upload animation
        _mediaUploadController.stop();
        _mediaUploadController.reset();

        setState(() {
          _isUploading = false;
          _selectedMedia = null;
        });
      }

      // Build the message data
      final messageData = {
        'text': messageText,
        'senderId': _currentUserId,
        'senderName': _currentUserName,
        'timestamp': FieldValue.serverTimestamp(),
        'mediaUrl': mediaUrl ?? '',
        'mediaThumbnailUrl': mediaThumbnailUrl ?? '',
        'mediaType': finalMediaType,
        'isRead': {
          _currentUserId: true, // Mark as read by the sender
        },
      };

      // Add reply data if replying to a message
      if (_replyToMessage != null) {
        messageData['replyTo'] = {
          'messageId': _replyToMessage!['messageId'] ?? '',
          'text': _replyToMessage!['text'] ?? '',
          'senderName': _replyToMessage!['senderName'] ?? '',
          'mediaType': _replyToMessage!['mediaType'] ?? '',
        };
      }

      // Add message to Firestore
      final messageRef = await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('messages')
          .add(messageData);

      // Update last message in group document
      await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .update({
        'lastMessage': messageText.isEmpty ? 'Shared ${finalMediaType.toLowerCase()}' : messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUserId,
        'messageCount': FieldValue.increment(1),
      });

      // Clear input and reset states
      _messageController.clear();
      setState(() {
        _mediaType = '';
        _replyToMessage = null;
      });

      // Update typing status
      _updateTypingStatus(false);

      // Update read status
      _updateLastReadTimestamp();

      // Scroll to bottom to show the new message
      _scrollToBottom();

      // Send notification to all group members
      await NotificationService().sendNotificationToGroup(
        groupId: widget.groupId,
        groupName: widget.groupName,
        senderName: _currentUserName,
        messageText: messageText,
        messageType: finalMediaType,
      );

    } catch (e) {
      print('Error sending message: $e');
      _showSnackBar('Failed to send message', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  bool _containsUrl(String text) {
    // Simple regex to detect URLs
    final urlRegex = RegExp(
      r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(text);
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isError)
              Icon(Icons.error_outline, color: Colors.white)
            else if (isSuccess)
              Icon(Icons.check_circle_outline, color: Colors.white)
            else
              Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? Colors.red.shade700
            : (isSuccess ? Colors.green.shade600 : _accentColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        duration: Duration(seconds: isError ? 4 : 2),
        action: isError ? SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ) : null,
      ),
    );
  }

  // Media selection methods
  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedMedia = File(image.path);
        _mediaType = 'image';
      });

      // Since we added media, we should scroll to see the input field
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedMedia = File(image.path);
        _mediaType = 'image';
      });

      // Since we added media, we should scroll to see the input field
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: Duration(minutes: 5),
    );

    if (video != null) {
      setState(() {
        _selectedMedia = File(video.path);
        _mediaType = 'video';
      });

      // Since we added media, we should scroll to see the input field
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    }
  }

  Future<void> _recordVideo() async {
    final XFile? video = await _imagePicker.pickVideo(
      source: ImageSource.camera,
      maxDuration: Duration(minutes: 5),
    );

    if (video != null) {
      setState(() {
        _selectedMedia = File(video.path);
        _mediaType = 'video';
      });

      // Since we added media, we should scroll to see the input field
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    }
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        _selectedMedia = File(result.files.single.path!);
        _mediaType = 'audio';
      });

      // Since we added media, we should scroll to see the input field
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _selectedMedia = File(result.files.single.path!);
        _mediaType = 'file';
      });

      // Since we added media, we should scroll to see the input field
      Future.delayed(Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
    }
  }
  // UI Building Methods
  @override
  Widget build(BuildContext context) {
    // Update theme settings when rebuilt
    _updateThemeSettings();

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside input field
        FocusScope.of(context).unfocus();

        // Hide emoji picker too
        if (_showEmojiPicker) {
          setState(() {
            _showEmojiPicker = false;
          });
          _fabController.forward();
        }
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // Messages container
            Container(
              child: Column(
                children: [
                  // Show select mode header when active
                  if (_isSelectMode)
                    _buildSelectModeHeader(),

                  // Show reply preview if replying to a message
                  if (_replyToMessage != null)
                    _buildReplyPreview(),

                  // Show upload progress if uploading
                  if (_isUploading)
                    _buildUploadProgressIndicator(),

                  // Show selected media preview
                  if (_selectedMedia != null)
                    _buildSelectedMediaPreview(),

                  // Messages list
                  Expanded(
                    child: _buildMessagesList(),
                  ),

                  // Typing indicator
                  _buildTypingIndicator(),

                  // Input area (hide when recording)
                  if (!_showVoiceRecording || _isVoiceRecordingLocked)
                    _buildMessageInput(),

                  // Emoji picker
                  if (_showEmojiPicker && !_showVoiceRecording)
                    _buildEmojiPicker(),
                ],
              ),
            ),

            // Voice recording UI overlay
            if (_showVoiceRecording && _voiceRecordingManager != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: VoiceRecordingView(
                  onLockStateChanged: (isLocked) {
                    setState(() {
                      _isVoiceRecordingLocked = isLocked;
                    });
                  },
                  onCancelRecording: _cancelRecording,
                  onStopRecording: _stopRecordingVoiceMessage,
                  recordingDuration: _voiceRecordingManager!.recordingDuration,
                  isRecording: _voiceRecordingManager!.isRecording,
                  recorderController: _voiceRecordingManager!.recorderController!,
                  isDarkMode: _isDarkMode,
                  accentColor: _accentColor,
                ),
              ),

            // Scroll to bottom button
            _buildScrollToBottomButton(),

            // FAB for quick actions
            _buildQuickActionsFAB(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _cardColor,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: _textColor, size: 24),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: InkWell(
        onTap: () {
          // Navigate to group info screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupInfoScreen(
                groupId: widget.groupId,
                groupName: widget.groupName,
                isAdmin: _isAdmin,
              ),
            ),
          );
        },
        child: Row(
          children: [
            // Group avatar
            Hero(
              tag: 'group-avatar-${widget.groupId}',
              child: Container(
                width: 40,
                height: 40,
                margin: EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor.withOpacity(0.1),
                ),
                child: widget.groupAvatar != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: widget.groupAvatar!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: Text(
                        widget.groupName.isNotEmpty ? widget.groupName[0].toUpperCase() : '#',
                        style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Text(
                        widget.groupName.isNotEmpty ? widget.groupName[0].toUpperCase() : '#',
                        style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                )
                    : Center(
                  child: Text(
                    widget.groupName.isNotEmpty ? widget.groupName[0].toUpperCase() : '#',
                    style: TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Group name and online status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.groupName,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: _onlineUsersStream,
                    builder: (context, snapshot) {
                      int onlineCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: onlineCount > 0 ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            onlineCount > 0 ? '$onlineCount online' : 'No members online',
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Search button
        IconButton(
          icon: Icon(Icons.search, color: _textColor, size: 24),
          onPressed: () {
            _showSnackBar('Search feature coming soon');
          },
        ),

        // More options button
        IconButton(
          icon: Icon(Icons.more_vert, color: _textColor, size: 24),
          onPressed: () {
            _showGroupOptionsMenu();
          },
        ),
      ],
    );
  }

  Widget _buildSelectModeHeader() {
    return Container(
      color: _accentColor,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: _cancelSelectMode,
          ),
          Text(
            '${_selectedMessageIds.length} selected',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Spacer(),
          if (_selectedMessageIds.isNotEmpty) ...[
            IconButton(
              icon: Icon(Icons.forward, color: Colors.white),
              onPressed: _forwardSelectedMessages,
              tooltip: 'Forward',
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteSelectedMessages,
              tooltip: 'Delete',
            ),
          ],
        ],
      ),
    );
  }

  void _cancelSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedMessageIds.clear();
    });
  }

  Future<void> _deleteSelectedMessages() async {
    try {
      // Create a batch for efficient Firestore operations
      final batch = _firestore.batch();

      // Add delete operations to batch
      for (String messageId in _selectedMessageIds) {
        final messageRef = _firestore
            .collection('discussion_groups')
            .doc(widget.groupId)
            .collection('messages')
            .doc(messageId);

        batch.delete(messageRef);
      }

      // Commit the batch
      await batch.commit();

      // Show success message
      int count = _selectedMessageIds.length;
      _showSnackBar('$count message${count > 1 ? 's' : ''} deleted', isSuccess: true);

      // Exit select mode
      setState(() {
        _isSelectMode = false;
        _selectedMessageIds.clear();
      });
    } catch (e) {
      print('Error deleting selected messages: $e');
      _showSnackBar('Failed to delete messages', isError: true);
    }
  }

  Future<void> _forwardSelectedMessages() async {
    // In a real app, this would open a dialog to select recipients
    _showSnackBar('Forward feature coming soon');

    // For now, just exit select mode
    setState(() {
      _isSelectMode = false;
      _selectedMessageIds.clear();
    });
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF252525) : Colors.grey[100],
        border: Border(
          top: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[300]!),
          bottom: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reply to ${_replyToMessage!['senderName']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _accentColor,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                _replyToMessage!['mediaType'] != null && _replyToMessage!['mediaType'].isNotEmpty
                    ? Text(
                  '${_replyToMessage!['mediaType']} ${_replyToMessage!['text'] != null && _replyToMessage!['text'].isNotEmpty ? '• ${_replyToMessage!['text']}' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: _secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                    : Text(
                  _replyToMessage!['text'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: _secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: _secondaryTextColor),
            onPressed: () {
              setState(() {
                _replyToMessage = null;
              });
            },
            padding: EdgeInsets.all(4),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgressIndicator() {
    return AnimatedBuilder(
      animation: _mediaUploadController,
      builder: (context, child) {
        return Container(
          height: 4,
          child: LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _accentColor.withOpacity(_safeOpacity(0.5 + 0.5 * _mediaUploadController.value)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedMediaPreview() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF252525) : Colors.grey[100],
        border: Border(
          top: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 70,
              height: 70,
              child: _mediaType == 'image'
                  ? Image.file(
                _selectedMedia!,
                fit: BoxFit.cover,
              )
                  : Container(
                color: _getMediaTypeColor().withOpacity(_isDarkMode ? 0.3 : 0.2),
                child: Icon(
                  _getMediaTypeIcon(),
                  color: _getMediaTypeColor(),
                  size: 30,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected ${_mediaType.toLowerCase()}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap send to share',
                  style: TextStyle(
                    fontSize: 13,
                    color: _secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: _secondaryTextColor,
            ),
            onPressed: () {
              setState(() {
                _selectedMedia = null;
                _mediaType = '';
              });
            },
          ),
        ],
      ),
    );
  }

  Color _getMediaTypeColor() {
    switch (_mediaType) {
      case 'video':
        return Colors.red.shade500;
      case 'audio':
        return Colors.purple.shade500;
      case 'file':
        return Colors.blue.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  IconData _getMediaTypeIcon() {
    switch (_mediaType) {
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      case 'file':
        return Icons.insert_drive_file;
      default:
        return Icons.attachment;
    }
  }
  // Add this to the main MessageInput method for better visual cues
  Widget _buildMessageInput() {
    bool hasText = _messageController.text.isNotEmpty || _selectedMedia != null;

    return AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
    child: Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
    // Attachment button
    AnimatedContainer(
    duration: Duration(milliseconds: 200),
    width: 48,
    height: 48,
    margin: EdgeInsets.only(right: 8, bottom: 2),
    decoration: BoxDecoration(
    color: _accentColor.withOpacity(0.1),
    shape: BoxShape.circle,
    ),
    child: IconButton(
    icon: Icon(
    Icons.add_circle_outline,
    color: _accentColor,
    size: 24,
    ),
    onPressed: _showMediaOptions,
    padding: EdgeInsets.zero,
    splashRadius: 24,
    ),
    ),

    // Message input field
    Expanded(
    child: AnimatedContainer(
    duration: Duration(milliseconds: 200),
    margin: EdgeInsets.only(right: 8),
    decoration: BoxDecoration(
    color: _isDarkMode ? Color(0xFF252525) : Colors.grey.shade100,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
    color: _messageFocusNode.hasFocus
    ? _accentColor.withOpacity(0.5)
        : _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
    width: 1,
    ),
    ),
    child: Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
    // Emoji button
    IconButton(
    icon: Icon(
    _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
    color: _secondaryTextColor,
    size: 24,
    ),
    onPressed: _toggleEmojiPicker,
    padding: EdgeInsets.all(12),
    constraints: BoxConstraints(),
    visualDensity: VisualDensity.compact,
    ),

    // Text field
    Expanded(
    child: TextField(
    controller: _messageController,
    focusNode: _messageFocusNode,
    decoration: InputDecoration(
    hintText: _isRecording ? 'Recording audio...' : 'Type a message',
    hintStyle: TextStyle(
    color: _isRecording
    ? Colors.red.shade300
        : (_isDarkMode ? Colors.grey[500] : Colors.grey[400])
    ),
    border: InputBorder.none,
    contentPadding: EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 12,
    ),
    isDense: true,
    ),
    minLines: 1,
    maxLines: 5,
    textCapitalization: TextCapitalization.sentences,
    keyboardType: TextInputType.multiline,
    style: TextStyle(
    fontSize: 16,
    color: _textColor,
    ),
    enabled: !_isRecording, // Disable text input while recording
    ),
    ),

    // Camera shortcut button (when no text and not recording)
    if (!hasText && !_isRecording)
    IconButton(
    icon: Icon(
    Icons.camera_alt_outlined,
    color: _secondaryTextColor,
    size: 24,
    ),
    onPressed: _takePhoto,
    padding: EdgeInsets.all(12),
    constraints: BoxConstraints(),
    visualDensity: VisualDensity.compact,
    tooltip: 'Take a photo',
    ),

    // Recording indicator (when recording)
    if (_isRecording)
    Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    margin: EdgeInsets.only(right: 8),
    decoration: BoxDecoration(
    color: Colors.red.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(Icons.mic, color: Colors.red, size: 16),
    SizedBox(width: 4),
    Text(
    _formatDuration(_voiceRecordingManager?.recordingDuration ?? 0),
    style: TextStyle(
    color: Colors.red,
    fontWeight: FontWeight.bold,
    fontSize: 12,
    ),
    ),
    ],
    ),
    ),

    // Clear text button (when has text)
    if (_messageController.text.isNotEmpty && !_isRecording)
    IconButton(
    icon: Icon(
    Icons.clear,
    color: _secondaryTextColor,
    size: 20,
    ),
    onPressed: () {
    setState(() {
    _messageController.clear();
    });
    },
    padding: EdgeInsets.all(12),
    constraints: BoxConstraints(),
    visualDensity: VisualDensity.compact,
    tooltip: 'Clear text',
    ),
    ],
    ),
    ),
    ),

    // Send button or voice recording button
    AnimatedSwitcher(
    duration: Duration(milliseconds: 200),
    transitionBuilder: (Widget child, Animation<double> animation) {
    return ScaleTransition(scale: animation, child: child);
    },
    child: hasText
    ? GestureDetector(
    key: ValueKey<bool>(true),
    onTap: _isLoading ? null : _sendMessage,
    child: Container(
    width: 48,
    height: 48,
    margin: EdgeInsets.only(bottom: 2),
    decoration: BoxDecoration(
    color: _accentColor,
    shape: BoxShape.circle,
    boxShadow: [
    BoxShadow(
    color: _accentColor.withOpacity(0.3),
    blurRadius: 8,
    offset: Offset(0, 2),
    ),
    ],
    ),
    child: Icon(
    Icons.send,
    color: Colors.white,
    size: 22,
    ),
    ),
    )
        : // Use the improved voice recording button
    GestureDetector(
    key: ValueKey<bool>(false),
      onLongPress: () {
        print("Long press detected");
        HapticFeedback.heavyImpact();
        _startRecordingVoiceMessage();
      },
      onLongPressUp: () {
        print("Long press released");
        if (!_isVoiceRecordingLocked) {
          _stopRecordingVoiceMessage();
        }
      },
      onTap: () {
        // Quick tap provides feedback about how to use
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hold to record a voice message'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        width: 56,
        height: 56,
        margin: EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : _accentColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? Colors.red : _accentColor).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 28,
        ),
      ),
    )
    ),
    ],
    ),
        ),
        ),
    );
  }
// This is the implementation of _buildMessageItem method from GroupChatScreen
// Add this to your GroupChatScreen class

  Widget _buildMessageItem(DocumentSnapshot doc, bool isCurrentUser, String messageId) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;
    final String timeString = timestamp != null
        ? DateFormat('h:mm a').format(timestamp.toDate())
        : '';

    final String mediaUrl = data['mediaUrl'] ?? '';
    final String mediaType = data['mediaType'] ?? '';
    final String text = data['text'] ?? '';
    final String senderName = data['senderName'] ?? 'Unknown';

    // Check if this is a reply to another message
    final Map<String, dynamic>? replyData = data['replyTo'] as Map<String, dynamic>?;

    // Check if this message has been read
    bool isRead = false;
    if (timestamp != null && _lastReadTimestamp != null) {
      isRead = timestamp.compareTo(_lastReadTimestamp!) <= 0;
    }

    // Check if this message is selected in multi-select mode
    bool isSelected = _isSelectMode && _selectedMessageIds.contains(messageId);

    return Slidable(
      enabled: !_isSelectMode && isCurrentUser,
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) {
              _deleteMessage(messageId);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) {
              setState(() {
                _replyToMessage = {
                  ...data,
                  'messageId': messageId,
                };
              });
              _messageFocusNode.requestFocus();
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.reply,
            label: 'Reply',
            borderRadius: BorderRadius.circular(16),
          ),
          SlidableAction(
            onPressed: (_) {
              _showSnackBar('Forward feature coming soon');
            },
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.forward,
            label: 'Forward',
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: () {
          // Start multi-select mode or show message options
          if (_isSelectMode) {
            _toggleSelection(messageId);
          } else {
            _showMessageOptions(data, messageId);
          }

          // Provide haptic feedback
          HapticFeedback.mediumImpact();
        },
        onTap: () {
          // In select mode, toggle selection
          if (_isSelectMode) {
            _toggleSelection(messageId);
          } else if (mediaUrl.isNotEmpty) {
            // Otherwise if message has media, preview it
            _showMediaPreview(mediaUrl, mediaType);
          }
        },
        child: Container(
          margin: EdgeInsets.only(
            bottom: 4,
            top: 4,
            left: isCurrentUser ? 64 : 8,
            right: isCurrentUser ? 8 : 64,
          ),
          child: Row(
            mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar for other users' messages
              if (!isCurrentUser)
                _buildMessageAvatar(senderName),

              // Selected message indicator
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isDarkMode ? Colors.grey[900]! : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),

              // The message bubble
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: _getMessageBubbleColor(isCurrentUser, isSelected),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                      bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sender name for group messages (only for other users)
                      if (!isCurrentUser)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
                          child: Text(
                            senderName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _accentColor,
                            ),
                          ),
                        ),

                      // Reply preview if this is a reply
                      if (replyData != null && replyData.isNotEmpty)
                        _buildReplyContent(replyData),

                      // Media content
                      if (mediaUrl.isNotEmpty)
                        _buildMediaContent(mediaUrl, mediaType, data),

                      // Message text
                      if (text.isNotEmpty && !text.startsWith('🎤 Voice message'))
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 15,
                              color: _getMessageTextColor(isCurrentUser),
                            ),
                          ),
                        ),

                      // Time and read status
                      Padding(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 8,
                          top: text.isEmpty && mediaUrl.isEmpty ? 8 : 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              timeString,
                              style: TextStyle(
                                fontSize: 11,
                                color: _secondaryTextColor,
                              ),
                            ),
                            if (isCurrentUser)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: MessageStatusIndicator(
                                  isRead: isRead,
                                  isSent: true,
                                  isDelivered: true,
                                  isDarkMode: _isDarkMode,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMessageBubbleColor(bool isCurrentUser, bool isSelected) {
    if (isSelected) {
      return isCurrentUser
          ? _accentColor.withOpacity(0.3)
          : (_isDarkMode ? Colors.grey[700]! : Colors.grey[300]!);
    }

    return isCurrentUser
        ? (_isDarkMode ? Color(0xFF2C5282) : Color(0xFFE3F2FD)) // Customized color for user's messages
        : (_isDarkMode ? Color(0xFF2D3748) : Colors.white);
  }

  Color _getMessageTextColor(bool isCurrentUser) {
    return isCurrentUser
        ? (_isDarkMode ? Colors.white : Colors.black87)
        : (_isDarkMode ? Colors.white : Colors.black87);
  }

  Widget _buildMessageAvatar(String senderName) {
    return Container(
      width: 32,
      height: 32,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
          style: TextStyle(
            color: _accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildReplyContent(Map<String, dynamic> replyData) {
    final String replyText = replyData['text'] ?? '';
    final String replySenderName = replyData['senderName'] ?? 'Someone';
    final String replyMediaType = replyData['mediaType'] ?? '';

    return Container(
      margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.reply,
                size: 12,
                color: _accentColor,
              ),
              SizedBox(width: 6),
              Text(
                replySenderName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: _accentColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          if (replyMediaType.isNotEmpty)
            Row(
              children: [
                Icon(
                  _getReplyMediaTypeIcon(replyMediaType),
                  size: 12,
                  color: _secondaryTextColor,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    replyText.isEmpty ? _getReplyMediaTypeLabel(replyMediaType) : replyText,
                    style: TextStyle(
                      fontSize: 12,
                      color: _secondaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else if (replyText.isNotEmpty)
            Text(
              replyText,
              style: TextStyle(
                fontSize: 12,
                color: _secondaryTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  IconData _getReplyMediaTypeIcon(String mediaType) {
    switch (mediaType.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.mic;
      case 'file':
        return Icons.insert_drive_file;
      default:
        return Icons.attachment;
    }
  }

  String _getReplyMediaTypeLabel(String mediaType) {
    switch (mediaType.toLowerCase()) {
      case 'image':
        return 'Photo';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Voice Message';
      case 'file':
        return 'File';
      default:
        return 'Attachment';
    }
  }

  Widget _buildMediaContent(String mediaUrl, String mediaType, Map<String, dynamic> data) {
    // If mediaUrl exists but mediaType is empty, try to determine the type from URL
    if (mediaUrl.isNotEmpty && mediaType.isEmpty) {
      // Most image URLs end with image extensions
      if (mediaUrl.toLowerCase().endsWith('.jpg') ||
          mediaUrl.toLowerCase().endsWith('.jpeg') ||
          mediaUrl.toLowerCase().endsWith('.png') ||
          mediaUrl.toLowerCase().endsWith('.gif') ||
          mediaUrl.toLowerCase().endsWith('.webp')) {
        mediaType = 'image';
      } else if (mediaUrl.toLowerCase().endsWith('.mp4') ||
          mediaUrl.toLowerCase().endsWith('.mov') ||
          mediaUrl.toLowerCase().endsWith('.avi')) {
        mediaType = 'video';
      } else if (mediaUrl.toLowerCase().endsWith('.mp3') ||
          mediaUrl.toLowerCase().endsWith('.wav') ||
          mediaUrl.toLowerCase().endsWith('.ogg')) {
        mediaType = 'audio';
      }
    }

    if (mediaType == 'image') {
      return GestureDetector(
        onTap: () => _showFullScreenImage(mediaUrl),
        child: _buildImageContent(mediaUrl),
      );
    } else if (mediaType == 'video') {
      return GestureDetector(
        onTap: () => _showVideoPlayer(mediaUrl),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video thumbnail placeholder with gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey[800]!,
                      Colors.grey[900]!,
                    ],
                  ),
                ),
              ),
              // Play button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showVideoPlayer(mediaUrl),
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // File name at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Text(
                    _getFilenameFromUrl(mediaUrl),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (mediaType == 'audio') {
      // Voice message bubble
      try {
        final timestamp = data['timestamp'] as Timestamp?;
        final DateTime messageTime = timestamp?.toDate() ?? DateTime.now();
        final int audioDuration = data['audioDuration'] as int? ?? 0;

        return VoiceMessageBubble(
          audioUrl: mediaUrl,
          isCurrentUser: data['senderId'] == _currentUserId,
          senderName: data['senderName'] ?? 'Unknown',
          timestamp: messageTime,
          isRead: true, // Adapt this based on your read status logic
          audioDuration: audioDuration,
          isDarkMode: _isDarkMode,
          accentColor: _accentColor,
          onPlay: () => _showAudioPlayer(mediaUrl),
        );
      } catch (e) {
        print('Error building voice message: $e');
        // Fallback to a simpler implementation
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Row(
              children: [
          Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(_isDarkMode ? 0.2 : 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.music_note,
            color: Colors.purple,
            size: 24,
          ),
        ),
    SizedBox(width: 12),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Voice Message",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _textColor,  // This line was split incorrectly
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      SizedBox(height: 4),
      Text(
        data['audioDuration'] != null ? _formatDuration(data['audioDuration']) : '0:00',
        style: TextStyle(
          fontSize: 12,
          color: _secondaryTextColor,
        ),
      ),
    ],
    ),
    ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(_isDarkMode ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 24,
                    icon: Icon(
                      Icons.play_arrow,
                      color: Colors.purple,
                    ),
                    onPressed: () => _showAudioPlayer(mediaUrl),
                  ),
                ),
              ],
          ),
        );
      }
    } else if (mediaUrl.isNotEmpty) {
      // Generic file attachment
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.shade50,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getFileTypeColor(_getFileTypeFromUrl(mediaUrl)).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getFileTypeIcon(_getFileTypeFromUrl(mediaUrl)),
                color: _getFileTypeColor(_getFileTypeFromUrl(mediaUrl)),
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getFileTypeFromUrl(mediaUrl),
                    style: TextStyle(
                      fontSize: 12,
                      color: _secondaryTextColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getFilenameFromUrl(mediaUrl),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.download_outlined,
                  color: _accentColor,
                  size: 20,
                ),
                onPressed: () => _downloadFile(mediaUrl),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink(); // Fallback for empty mediaUrl
  }

  Widget _buildImageContent(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
      child: Hero(
        tag: imageUrl,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 300,
          placeholder: (context, url) => _buildImagePlaceholder(),
          errorWidget: (context, url, error) => _buildImageErrorWidget(),
          fadeInDuration: Duration(milliseconds: 300),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildImageErrorWidget() {
    return Container(
      height: 200,
      color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
              size: 36,
            ),
            SizedBox(height: 8),
            Text(
              'Image couldn\'t load',
              style: TextStyle(
                color: _secondaryTextColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTypingIndicator() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('typing_users')
          .where('isTyping', isEqualTo: true)
          .where('userId', isNotEqualTo: _currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SizedBox.shrink();
        }

        final typingUsers = snapshot.data!.docs;
        if (typingUsers.isEmpty) return SizedBox.shrink();

        // Extract names of typing users
        final List<String> names = typingUsers
            .map((doc) => doc['name'] as String? ?? 'Someone')
            .toList();

        return TypingIndicator(
          typingUsers: names,
          isDarkMode: _isDarkMode,
          accentColor: _accentColor,
        );
      },
    );
  }

  Widget _buildMessagesList() {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                strokeWidth: 2,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Update read status when new messages arrive
          if (snapshot.data!.docs.isNotEmpty) {
            _updateLastReadTimestamp();
          }

          return AnimatedMessageList(
            messages: snapshot.data!.docs,
            shouldShowDate: (doc, index) {
              // Determine if we should show date divider
              if (index < snapshot.data!.docs.length - 1) {
                DocumentSnapshot nextDoc = snapshot.data!.docs[index + 1];
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                Map<String, dynamic> nextData = nextDoc.data() as Map<String, dynamic>;

                final thisTimestamp = data['timestamp'] as Timestamp?;
                final nextTimestamp = nextData['timestamp'] as Timestamp?;

                if (thisTimestamp != null && nextTimestamp != null) {
                  final thisDate = thisTimestamp.toDate();
                  final nextDate = nextTimestamp.toDate();

                  return thisDate.day != nextDate.day ||
                      thisDate.month != nextDate.month ||
                      thisDate.year != nextDate.year;
                }
              } else if (index == snapshot.data!.docs.length - 1) {
                // Last message in the list
                return true;
              }
              return false;
            },
            buildMessageItem: (doc, isCurrentUser, messageId) =>
                _buildMessageItem(doc, isCurrentUser, messageId),
            buildDateDivider: _buildDateDivider,
            scrollController: _scrollController,
            isSelectMode: _isSelectMode,
            selectedMessageIds: _selectedMessageIds,
            isDarkMode: _isDarkMode,
            toggleSelection: _toggleSelection,
            showMessageOptions: _showMessageOptions,
            showMediaPreview: _showMediaPreview,
          );
        },
      ),
    );
  }

  void _toggleSelection(String messageId) {
    if (!_isSelectMode) {
      setState(() {
        _isSelectMode = true;
        _selectedMessageIds.add(messageId);
      });
    } else {
      // If already in select mode, toggle selection of this message
      setState(() {
        if (_selectedMessageIds.contains(messageId)) {
          _selectedMessageIds.remove(messageId);

          // If no messages left selected, exit select mode
          if (_selectedMessageIds.isEmpty) {
            _isSelectMode = false;
          }
        } else {
          _selectedMessageIds.add(messageId);
        }
      });
    }
  }

  void _showMediaPreview(String mediaUrl, String mediaType) {
    // Implementation for showing media previews
    if (mediaType == 'image') {
      _showFullScreenImage(mediaUrl);
    } else if (mediaType == 'video') {
      _showVideoPlayer(mediaUrl);
    } else if (mediaType == 'audio') {
      _showAudioPlayer(mediaUrl);
    } else {
      // For other file types, attempt to download
      _downloadFile(mediaUrl);
    }
  }

  void _showMessageOptions(Map<String, dynamic> message, String messageId) {
    final bool isCurrentUserMessage = message['senderId'] == _currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                ListTile(
                  leading: Icon(Icons.reply, color: _accentColor),
                  title: Text('Reply', style: TextStyle(color: _textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _replyToMessage = {
                        ...message,
                        'messageId': messageId,
                      };
                    });
                    _messageFocusNode.requestFocus();
                  },
                ),

                ListTile(
                  leading: Icon(Icons.content_copy, color: _accentColor),
                  title: Text('Copy', style: TextStyle(color: _textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    // Copy message text to clipboard
                    final text = message['text'] ?? '';
                    if (text.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: text));
                      _showSnackBar('Message copied to clipboard', isSuccess: true);
                    }
                  },
                ),

                if (isCurrentUserMessage)
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: _textColor)),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteMessage(messageId);
                    },
                  ),

                ListTile(
                  leading: Icon(Icons.select_all, color: _accentColor),
                  title: Text('Select', style: TextStyle(color: _textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleSelection(messageId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          setState(() {
            _messageController.text = _messageController.text + emoji.emoji;
          });
        },
        onBackspacePressed: () {
          if (_messageController.text.isNotEmpty) {
            setState(() {
              final text = _messageController.text;
              _messageController.text = text.substring(0, text.length - 1);
            });
          }
        },
        textEditingController: _messageController,
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Share Content',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),

                // Grid of options
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 24,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      _buildMediaOption(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage();
                        },
                      ),
                      _buildMediaOption(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.purple.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _takePhoto();
                        },
                      ),
                      _buildMediaOption(
                        icon: Icons.videocam,
                        label: 'Video',
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _pickVideo();
                        },
                      ),
                      _buildMediaOption(
                        icon: Icons.mic,
                        label: 'Audio',
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.orange.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _pickAudio();
                        },
                      ),
                      _buildMediaOption(
                        icon: Icons.insert_drive_file,
                        label: 'Document',
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.teal.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _pickDocument();
                        },
                      ),
                      _buildMediaOption(
                        icon: Icons.location_on,
                        label: 'Location',
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // Implement location sharing
                          _showSnackBar('Location sharing coming soon');
                        },
                      ),
                      _buildMediaOption(
                        icon: Icons.person,
                        label: 'Contact',
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // Implement contact sharing
                          _showSnackBar('Contact sharing coming soon');
                        },
                      ),
                      _buildMediaOption(
                        icon: Icons.poll,
                        label: 'Poll',
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade400, Colors.amber.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // Implement poll creation
                          _showSnackBar('Poll creation coming soon');
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 50,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _isDarkMode ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });

    if (_showEmojiPicker) {
      _messageFocusNode.unfocus();
      _fabController.reverse();
    } else {
      _messageFocusNode.requestFocus();
      _fabController.forward();
    }
  }

  void _showGroupOptionsMenu() {
    // Implementation for showing group options menu
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                ListTile(
                  leading: Icon(Icons.info_outline, color: _accentColor),
                  title: Text('Group Info', style: TextStyle(color: _textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupInfoScreen(
                          groupId: widget.groupId,
                          groupName: widget.groupName,
                          isAdmin: _isAdmin,
                        ),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: Icon(Icons.search, color: _accentColor),
                  title: Text('Search Messages', style: TextStyle(color: _textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Search feature coming soon');
                  },
                ),

                ListTile(
                  leading: Icon(Icons.volume_off, color: _accentColor),
                  title: Text('Mute Notifications', style: TextStyle(color: _textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Notification muting coming soon');
                  },
                ),

                if (_isAdmin)
                  ListTile(
                    leading: Icon(Icons.edit, color: _accentColor),
                    title: Text('Edit Group', style: TextStyle(color: _textColor)),
                    onTap: () {
                      Navigator.pop(context);
                      _showSnackBar('Group editing coming soon');
                    },
                  ),

                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Leave Group', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Leave group feature coming soon');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We couldn\'t load your messages',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryTextColor,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _setupMessagesStream();
              });
            },
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final List<String> quickMessages = [
      '👋 Hello everyone!',
      "I'm new here",
      'How is everyone doing?',
      'Looking forward to chatting!',
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Fun illustration
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 72,
              color: _accentColor,
            ),
          ),
          SizedBox(height: 32),

          // Title
          Text(
            'Start the conversation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),

          SizedBox(height: 16),

          // Subtitle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text('Be the first to send a message in this group!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: _secondaryTextColor,
              ),
            ),
          ),

          SizedBox(height: 40),

          // Suggestion cards
          Container(
            height: 140,
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: quickMessages.length,
              itemBuilder: (context, index) {
                return _buildSuggestionCard(
                  message: quickMessages[index],
                  index: index,
                  onTap: () {
                    setState(() {
                      _messageController.text = quickMessages[index];
                    });
                    _sendMessage();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard({
    required String message,
    required int index,
    required VoidCallback onTap,
  }) {
    final colors = [
      [Colors.blue.shade400, Colors.blue.shade700],
      [Colors.purple.shade400, Colors.purple.shade700],
      [Colors.teal.shade400, Colors.teal.shade700],
      [Colors.orange.shade400, Colors.orange.shade700],
      [Colors.pink.shade400, Colors.pink.shade700],
    ];

    final colorPair = colors[index % colors.length];

    return Container(
      width: 180,
      margin: EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colorPair,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.chat,
                  color: Colors.white,
                  size: 28,
                ),
                Spacer(),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateDivider(Timestamp? timestamp) {
    if (timestamp == null) return SizedBox.shrink();

    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: _isDarkMode ? Colors.grey[800] : Colors.grey[300])),
          SizedBox(width: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isDarkMode ? Color(0xFF252525) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _secondaryTextColor,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(child: Divider(color: _isDarkMode ? Colors.grey[800] : Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    return AnimatedPositioned(
      right: 16,
      bottom: 80,
      duration: Duration(milliseconds: 200),
      child: AnimatedOpacity(
        opacity: _showScrollButton ? 1.0 : 0.0,
        duration: Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: _scrollToBottom,
          child: Container(
            height: 42,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _isDarkMode ? Color(0xFF252525) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_unreadMessageCount > 0)
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _unreadMessageCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Icon(
                  Icons.arrow_downward,
                  color: _accentColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsFAB() {
    return AnimatedBuilder(
        animation: _fabController,
        builder: (context, child) {
      return Positioned(
          right: 16,
          bottom: 80 + (1 - _fabController.value) * 80, // Slides up when input is focused
    child: Opacity(
    opacity: _fabController.value,
    child: IgnorePointer(
    ignoring: _fabController.value < 0.5,
    child: FloatingActionButton(
    backgroundColor: _accentColor,
    elevation: 4,
      // Continuing from previous part
      onPressed: () {
        // Show quick actions menu
        _showQuickActionsMenu();
      },
      child: Icon(Icons.bolt, color: Colors.white),
    ),
    ),
    ),
      );
        },
    );
  }

  void _showQuickActionsMenu() {
    // Implementation for showing quick action menu
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Color(0xFF252525) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                ListTile(
                  leading: Icon(Icons.camera_alt, color: _accentColor),
                  title: Text('Take Photo', style: TextStyle(color: _textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),

                ListTile(
                  leading: Icon(Icons.photo_library, color: _accentColor),
                  title: Text('Share Media', style: TextStyle(color: _textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _showMediaOptions();
                  },
                ),

                ListTile(
                  leading: Icon(Icons.search, color: _accentColor),
                  title: Text('Search in Chat', style: TextStyle(color: _textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _showSnackBar('Search feature coming soon');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Download file from URL
  Future<void> _downloadFile(String fileUrl) async {
    try {
      // Show initial download notification
      _showSnackBar('Starting download: ${_getFilenameFromUrl(fileUrl)}...');

      // Get the external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        _showSnackBar('Storage access error', isError: true);
        return;
      }

      // Create the downloads folder if it doesn't exist
      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Generate the local file path
      final fileName = _getFilenameFromUrl(fileUrl);
      final savePath = '${downloadsDir.path}/$fileName';

      // Check if permission is granted for storage
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          _showSnackBar('Storage permission denied', isError: true);
          return;
        }
      }

      // Initialize Dio
      final dio = Dio();

      // Show progress notification
      int progress = 0;

      // Start the download
      await dio.download(
        fileUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final newProgress = (received / total * 100).floor();
            if (newProgress != progress && newProgress % 10 == 0) {
              progress = newProgress;
              _showSnackBar('Downloading: $progress%');
            }
          }
        },
      );

      // Show completion notification
      _showSnackBar('File downloaded to Downloads folder', isSuccess: true);

      // Open the file (optional)
      final file = File(savePath);
      if (await file.exists()) {
        try {
          final mimeType = _getMimeType(fileName);
          final result = await OpenFile.open(savePath, type: mimeType);
          if (result.type != ResultType.done) {
            _showSnackBar('Could not open file: ${result.message}', isError: true);
          }
        } catch (e) {
          print('Error opening file: $e');
          _showSnackBar('File saved, but could not be opened automatically', isError: false);
        }
      }
    } catch (e) {
      print('Download error: $e');
      _showSnackBar('Download failed: ${e.toString()}', isError: true);
    }
  }

  // Helper function to determine MIME type based on file extension
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp3':
        return 'audio/mpeg';
      case 'mp4':
        return 'video/mp4';
      case 'zip':
        return 'application/zip';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream'; // Generic binary data
    }
  }

  Color _getFileTypeColor(String fileType) {
    switch (fileType) {
      case 'PDF Document':
        return Colors.red;
      case 'Word Document':
        return Colors.blue;
      case 'Excel Spreadsheet':
        return Colors.green;
      case 'PowerPoint':
        return Colors.orange;
      case 'Archive':
        return Colors.amber;
      case 'Text File':
        return Colors.grey;
      default:
        return _accentColor;
    }
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType) {
      case 'PDF Document':
        return Icons.picture_as_pdf;
      case 'Word Document':
        return Icons.description;
      case 'Excel Spreadsheet':
        return Icons.table_chart;
      case 'PowerPoint':
        return Icons.slideshow;
      case 'Archive':
        return Icons.folder_zip;
      case 'Text File':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      String filename = uri.pathSegments.last;

      // Remove query parameters if present
      if (filename.contains('?')) {
        filename = filename.split('?').first;
      }

      // Decode URL encoding
      return Uri.decodeComponent(filename);
    } catch (e) {
      return 'attachment';
    }
  }

  String _getFileTypeFromUrl(String url) {
    try {
      final String filename = _getFilenameFromUrl(url);
      final String extension = filename.split('.').last.toLowerCase();

      switch (extension) {
        case 'pdf':
          return 'PDF Document';
        case 'doc':
        case 'docx':
          return 'Word Document';
        case 'xls':
        case 'xlsx':
          return 'Excel Spreadsheet';
        case 'ppt':
        case 'pptx':
          return 'PowerPoint';
        case 'zip':
        case 'rar':
        case '7z':
          return 'Archive';
        case 'txt':
        case 'rtf':
          return 'Text File';
        default:
          return 'Document';
      }
    } catch (e) {
      return 'File';
    }
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FullScreenImageViewer(
          imageUrl: imageUrl,
          isDarkMode: _isDarkMode,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void _showVideoPlayer(String videoUrl) {
    // Validate URL format
    if (!videoUrl.startsWith('http')) {
      _showSnackBar('Invalid video URL format', isError: true);
      return;
    }

    // Try to show the player screen
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
        ),
      );
    } catch (e) {
      print('Error navigating to video player: $e');
      // Fallback to external player
      launchUrl(Uri.parse(videoUrl), mode: LaunchMode.externalApplication);
    }
  }

  void _showAudioPlayer(String audioUrl) {
    // Validate URL format
    if (!audioUrl.startsWith('http')) {
      _showSnackBar('Invalid audio URL format', isError: true);
      return;
    }

    // Extract filename from URL to use as a title
    String audioTitle = _getFilenameFromUrl(audioUrl);

    // Try to show the player screen
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerScreen(
            audioUrl: audioUrl,
            audioTitle: audioTitle,
          ),
        ),
      );
    } catch (e) {
      print('Error navigating to audio player: $e');
      // Fallback to external player
      launchUrl(Uri.parse(audioUrl), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('discussion_groups')
          .doc(widget.groupId)
          .collection('messages')
          .doc(messageId)
          .delete();

      _showSnackBar('Message deleted', isSuccess: true);
    } catch (e) {
      print('Error deleting message: $e');
      _showSnackBar('Failed to delete message', isError: true);
    }
  }
}
class VoiceRecordingManager {
  RecorderController? recorderController;
  bool isRecording = false;
  String? recordingFilePath;
  Timer? _durationTimer;
  int recordingDuration = 0;

  // Callbacks
  Function(int)? onDurationChanged;
  Function(bool)? onRecordingStateChanged;
  Function(File?)? onRecordingComplete;
  Function(String)? onError;

  VoiceRecordingManager() {
    // Initialize recorder right away
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      // Clean up previous controller if it exists
      if (recorderController != null) {
        try {
          recorderController!.dispose();
        } catch (e) {
          print('Error disposing previous recorder: $e');
        }
      }

      // Create a new controller with better audio quality
      recorderController = RecorderController()
        ..androidEncoder = AndroidEncoder.aac
        ..androidOutputFormat = AndroidOutputFormat.mpeg4
        ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
        ..sampleRate = 44100
        ..bitRate = 128000;

      // Wait for recorder to initialize
      await Future.delayed(Duration(milliseconds: 200));

    } catch (e) {
      print('Error initializing recorder: $e');
      onError?.call('Failed to initialize recorder: $e');
      recorderController = null;
    }
  }

  Future<bool> startRecording() async {
    // Make sure we have an initialized recorder
    if (recorderController == null) {
      await _initRecorder();
      // Give it a moment to initialize
      await Future.delayed(Duration(milliseconds: 300));
    }

    if (recorderController == null) {
      onError?.call('Cannot initialize recorder');
      return false;
    }

    if (isRecording) {
      return true; // Already recording
    }

    try {
      // Create a unique file path for this recording
      final Directory tempDir = await getTemporaryDirectory();
      recordingFilePath = '${tempDir.path}/voice_msg_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Make sure the path exists
      if (!await Directory(tempDir.path).exists()) {
        await Directory(tempDir.path).create(recursive: true);
      }

      // Verify file can be created
      final file = File(recordingFilePath!);
      if (await file.exists()) {
        await file.delete();
      }

      // Start recording - this is a void method, so we can't await it
      print('Starting recording to: $recordingFilePath');
      recorderController!.record(path: recordingFilePath);

      // Set recording state
      isRecording = true;
      recordingDuration = 0;
      onRecordingStateChanged?.call(true);

      // Setup timer to track duration
      _durationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        recordingDuration++;
        onDurationChanged?.call(recordingDuration);

        // Safety timeout - stop recording after 5 minutes
        if (recordingDuration >= 300) {
          stopRecording();
        }
      });

      return true;
    } catch (e) {
      print('Error starting recording: $e');
      isRecording = false;
      onError?.call('Failed to start recording: $e');

      // Try to reinitialize for next attempt
      _initRecorder();
      return false;
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording || recorderController == null) {
      return;
    }

    try {
      // Cancel duration timer
      if (_durationTimer != null) {
        _durationTimer!.cancel();
        _durationTimer = null;
      }

      // Stop recording (this returns void)
      recorderController!.stop();

      // Update state
      isRecording = false;
      onRecordingStateChanged?.call(false);

      // Process recording file
      if (recordingFilePath != null) {
        // Give a slight delay to ensure the file is properly closed
        await Future.delayed(Duration(milliseconds: 500));

        final file = File(recordingFilePath!);

        // Only return the file if it exists and has content
        if (await file.exists() && file.lengthSync() > 0) {
          print('Recording successful, file size: ${file.lengthSync()} bytes');
          onRecordingComplete?.call(file);
        } else {
          print('Recording file is empty or does not exist: $recordingFilePath');
          onError?.call('Recording file is empty or does not exist');
          onRecordingComplete?.call(null);
        }
      } else {
        onError?.call('Recording file path is null');
        onRecordingComplete?.call(null);
      }
    } catch (e) {
      print('Error stopping recording: $e');
      onError?.call('Failed to stop recording: $e');

      isRecording = false;
      onRecordingStateChanged?.call(false);

      // Try to reinitialize for next attempt
      _initRecorder();
    }
  }

  Future<void> cancelRecording() async {
    if (!isRecording || recorderController == null) {
      return;
    }

    try {
      // Cancel timer
      if (_durationTimer != null) {
        _durationTimer!.cancel();
        _durationTimer = null;
      }

      // Stop recording
      recorderController!.stop();

      // Delete the file
      if (recordingFilePath != null) {
        // Give a slight delay to ensure the file is properly closed
        await Future.delayed(Duration(milliseconds: 300));

        final file = File(recordingFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Update state
      isRecording = false;
      onRecordingStateChanged?.call(false);
      onRecordingComplete?.call(null);
    } catch (e) {
      print('Error canceling recording: $e');
      onError?.call('Failed to cancel recording: $e');

      isRecording = false;
      onRecordingStateChanged?.call(false);

      // Try to reinitialize for next attempt
      _initRecorder();
    }
  }

  void dispose() {
    if (_durationTimer != null) {
      _durationTimer!.cancel();
      _durationTimer = null;
    }

    // Stop recording if still active
    if (isRecording && recorderController != null) {
      try {
        recorderController!.stop();
      } catch (e) {
        print('Error stopping recording during dispose: $e');
      }
    }

    if (recorderController != null) {
      try {
        recorderController!.dispose();
      } catch (e) {
        print('Error disposing recorder controller: $e');
      }
      recorderController = null;
    }

    isRecording = false;
  }
}
class VoiceRecordingView extends StatefulWidget {
  final Function(bool) onLockStateChanged;
  final VoidCallback onCancelRecording;
  final VoidCallback onStopRecording;
  final int recordingDuration;
  final bool isRecording;
  final RecorderController recorderController;
  final bool isDarkMode;
  final Color accentColor;

  const VoiceRecordingView({
    Key? key,
    required this.onLockStateChanged,
    required this.onCancelRecording,
    required this.onStopRecording,
    required this.recordingDuration,
    required this.isRecording,
    required this.recorderController,
    required this.isDarkMode,
    required this.accentColor,
  }) : super(key: key);

  @override
  _VoiceRecordingViewState createState() => _VoiceRecordingViewState();
}

class _VoiceRecordingViewState extends State<VoiceRecordingView> with SingleTickerProviderStateMixin {
  bool _isLocked = false;
  double _dragOffset = 0;
  final double _lockThreshold = 100.0;
  double _horizontalDragOffset = 0;
  final double _cancelThreshold = 100.0;

  // Pulse animation for the recording indicator
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Provide haptic feedback on init to indicate recording has started
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = widget.isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final Color secondaryTextColor = widget.isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    // Calculate remaining time warning color
    final int remainingSeconds = 300 - widget.recordingDuration; // 5 minute max
    final Color timeColor = remainingSeconds < 30
        ? Colors.red
        : (remainingSeconds < 60 ? Colors.orange : Colors.red);

    return Container(
      color: cardColor,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recording progress indicator with fixed opacity values
            if (widget.isRecording)
              LinearProgressIndicator(
                value: widget.recordingDuration / 300, // 5 minute max
                backgroundColor: widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(timeColor),
              ),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: _isLocked
                  ? _buildLockedRecordingUI(textColor, secondaryTextColor, timeColor)
                  : _buildDraggableRecordingUI(textColor, secondaryTextColor, timeColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedRecordingUI(Color textColor, Color secondaryTextColor, Color timeColor) {
    return Column(
      children: [
        // Recording status indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: timeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Recording: ${_formatDuration(widget.recordingDuration)} / Max 5:00',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: timeColor,
            ),
          ),
        ),

        Row(
          children: [
            // Recording indicator dot
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 16),

            // Recording duration
            Text(
              _formatDuration(widget.recordingDuration),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

            // Audio waveform visualization
            Expanded(
              child: Container(
                height: 60,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: AudioWaveforms(
                  recorderController: widget.recorderController,
                  waveStyle: WaveStyle(
                    showMiddleLine: false,
                    extendWaveform: true,
                    waveColor: Colors.red.shade300,
                    spacing: 5,
                    waveThickness: 3,
                  ),
                  size: Size(MediaQuery.of(context).size.width * 0.5, 60),
                  padding: EdgeInsets.only(right: 16),
                ),
              ),
            ),

            // Stop recording button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onStopRecording,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 20),

        // Cancel recording button with better styling
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onCancelRecording,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Cancel Recording',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableRecordingUI(Color textColor, Color secondaryTextColor, Color timeColor) {
    return GestureDetector(
        // Handle vertical drag to lock
        onVerticalDragUpdate: (details) {
      setState(() {
        _dragOffset -= details.delta.dy;
        _dragOffset = _dragOffset.clamp(0, _lockThreshold);
        _horizontalDragOffset = 0; // Reset horizontal drag when dragging vertically

        // Lock the recording if we pass the threshold
        if (_dragOffset >= _lockThreshold && !_isLocked) {
          _isLocked = true;
          widget.onLockStateChanged(true);
          HapticFeedback.mediumImpact();
        }
      });
    },
    onVerticalDragEnd: (_) {
    if (!_isLocked) {
    setState(() {
    _dragOffset = 0;
    });
    }
    },

    // Handle horizontal drag to cancel
    onHorizontalDragUpdate: (details) {
    setState(() {
    _horizontalDragOffset += details.delta.dx;

    // Constrain to only allow dragging left (negative values)
    if (_horizontalDragOffset > 0) _horizontalDragOffset = 0;

    // Clamp the max drag distance
    if (_horizontalDragOffset < -_cancelThreshold) {
    widget.onCancelRecording();
    }
    });
    },
    onHorizontalDragEnd: (_) {
    if (_horizontalDragOffset > -_cancelThreshold) {
    setState(() {
    _horizontalDragOffset = 0;
    });
    }
    },

    child: Container(
    height: 160, // Taller container for better visibility
    child: Stack(
    alignment: Alignment.center,
    children: [
    // "Slide up to lock" indicator
    Positioned(
    top: 10,
    child: Column(
    children: [
    Icon(
    Icons.lock_outline,
    color: widget.accentColor,
    size: 24,
    ),
    SizedBox(height: 4),
    Text(
    'Slide up to lock recording',
    style: TextStyle(
    color: widget.accentColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    ),
    ),
    ],
    ),
    ),

    // Left side - "Slide left to cancel"
    Positioned(
    left: 20,
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(
    Icons.arrow_back,
    color: Colors.red,
    size: 24,
    ),
    SizedBox(height: 4),
    Text(
    'Slide left to cancel',
    style: TextStyle(
    color: Colors.red,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    ),
    ),
    ],
    ),
    ),

    // Recording info at the bottom
    Positioned(
    bottom: 10,
    child: Container(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
    color: timeColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
    color: timeColor,
    shape: BoxShape.circle,
    ),
    ),
    SizedBox(width: 10),
    Text(
    _formatDuration(widget.recordingDuration),
    style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: timeColor,
    ),
    ),
    ],
    ),
    ),
    ),

    // Drag indicator that moves as user drags vertically or horizontally
    Transform.translate(
    offset: Offset(_horizontalDragOffset, -_dragOffset),
    child: Container(
    width: 70,
    height: 70,
    decoration: BoxDecoration(
    color: Colors.red,
    shape: BoxShape.circle,
    boxShadow: [
    BoxShadow(
    color: Colors.red.withOpacity(0.3),
    blurRadius: 8,
    offset: Offset(0, 2),),
    ]),
      child: Icon(
        Icons.mic,
        color: Colors.white,
        size: 36,
      ),
    ),
    ),

    // Audio waveform visualization
    Positioned(
    right: 20,
    child: Container(
    width: 120,
    height: 60,
    child: AudioWaveforms(
    recorderController: widget.recorderController,
    waveStyle: WaveStyle(
    showMiddleLine: false,
    extendWaveform: true,
    waveColor: Colors.red.shade300,
    spacing: 3,
    waveThickness: 2,
    ),
    size: Size(120, 60),
    ),
    ),
    ),
    ],
    ),
    ),
    );
  }
}
// TypingIndicator widget
class TypingIndicator extends StatefulWidget {
  final List<String> typingUsers;
  final bool isDarkMode;
  final Color accentColor;

  const TypingIndicator({
    Key? key,
    required this.typingUsers,
    required this.isDarkMode,
    required this.accentColor,
  }) : super(key: key);

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Create staggered animations for dots
    _dotAnimations = List.generate(3, (index) {
      final delay = index * 0.2;
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: 1)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1, end: 0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(0),
          weight: 60,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _bounceController,
          curve: Interval(delay, delay + 0.4, curve: Curves.linear),
        ),
      );
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  String _buildTypingMessage() {
    if (widget.typingUsers.isEmpty) return '';

    if (widget.typingUsers.length == 1) {
      return '${widget.typingUsers[0]} is typing';
    } else if (widget.typingUsers.length == 2) {
      return '${widget.typingUsers[0]} and ${widget.typingUsers[1]} are typing';
    } else {
      return 'Several people are typing';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++)
            AnimatedBuilder(
              animation: _dotAnimations[i],
              builder: (context, child) {
                // Use safeOpacity to prevent invalid values
                final safeOpacity = (0.4 + (_dotAnimations[i].value * 0.6)).clamp(0.0, 1.0);

                return Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(safeOpacity),
                    shape: BoxShape.circle,
                  ),
                  transform: Matrix4.translationValues(
                    0,
                    -4 * _dotAnimations[i].value,
                    0,
                  ),
                );
              },
            ),
          SizedBox(width: 8),
          Text(
            _buildTypingMessage(),
            style: TextStyle(
              color: widget.accentColor,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// Message Status Indicator
class MessageStatusIndicator extends StatelessWidget {
  final bool isRead;
  final bool isSent;
  final bool isDelivered;
  final bool isFailed;
  final bool isDarkMode;

  const MessageStatusIndicator({
    Key? key,
    this.isRead = false,
    this.isSent = true,
    this.isDelivered = false,
    this.isFailed = false,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isFailed) {
      return Icon(
        Icons.error_outline,
        size: 14,
        color: Colors.red,
      );
    }

    if (isRead) {
      return Icon(
        Icons.done_all,
        size: 14,
        color: Colors.blue,
      );
    }

    if (isDelivered) {
      return Icon(
        Icons.done_all,
        size: 14,
        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
      );
    }

    if (isSent) {
      return Icon(
        Icons.done,
        size: 14,
        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
      );
    }

    return Icon(
      Icons.schedule,
      size: 14,
      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
    );
  }
}

// Animated Message List
class AnimatedMessageList extends StatelessWidget {
  final List<DocumentSnapshot> messages;
  final bool Function(DocumentSnapshot, int) shouldShowDate;
  final Widget Function(DocumentSnapshot, bool, String) buildMessageItem;
  final Widget Function(Timestamp?) buildDateDivider;
  final ScrollController scrollController;
  final bool isSelectMode;
  final List<String> selectedMessageIds;
  final bool isDarkMode;
  final Function(String) toggleSelection;
  final Function(Map<String, dynamic>, String) showMessageOptions;
  final Function(String, String) showMediaPreview;

  const AnimatedMessageList({
    Key? key,
    required this.messages,
    required this.shouldShowDate,
    required this.buildMessageItem,
    required this.buildDateDivider,
    required this.scrollController,
    required this.isSelectMode,
    required this.selectedMessageIds,
    required this.isDarkMode,
    required this.toggleSelection,
    required this.showMessageOptions,
    required this.showMediaPreview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        DocumentSnapshot doc = messages[index];
        String messageId = doc.id;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        bool isCurrentUser = data['senderId'] == FirebaseAuth.instance.currentUser?.uid;

        // Determine if we should show a date divider
        bool showDate = shouldShowDate(doc, index);

        return AnimatedMessageItem(
          index: index,
          child: Column(
            children: [
              if (showDate)
                buildDateDivider(data['timestamp'] as Timestamp?),
              buildMessageItem(doc, isCurrentUser, messageId),
            ],
          ),
        );
      },
    );
  }
}

class AnimatedMessageItem extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedMessageItem({
    Key? key,
    required this.child,
    required this.index,
  }) : super(key: key);

  @override
  _AnimatedMessageItemState createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<AnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuad,
    );

    // Stagger animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 20), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}

// Full Screen Image Viewer
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final bool isDarkMode;

  const FullScreenImageViewer({
    Key? key,
    required this.imageUrl,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing image...')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading image...')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: imageUrl,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              errorWidget: (context, url, error) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Image could not be loaded',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final bool isCurrentUser;
  final String senderName;
  final DateTime timestamp;
  final bool isRead;
  final int audioDuration;
  final bool isDarkMode;
  final Color accentColor;
  final VoidCallback onPlay;

  const VoiceMessageBubble({
    Key? key,
    required this.audioUrl,
    required this.isCurrentUser,
    required this.senderName,
    required this.timestamp,
    required this.isRead,
    this.audioDuration = 0,
    required this.isDarkMode,
    required this.accentColor,
    required this.onPlay,
  }) : super(key: key);

  @override
  _VoiceMessageBubbleState createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> with SingleTickerProviderStateMixin {
  bool isPlaying = false;
  double progress = 0.0;
  late AnimationController _waveformAnimation;

  @override
  void initState() {
    super.initState();
    _waveformAnimation = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveformAnimation.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Helper method for safe opacity values
  double _safeOpacity(double value) {
    return value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final Color secondaryTextColor = widget.isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color waveColor = widget.isCurrentUser
        ? (widget.isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600)
        : widget.accentColor;
    final Color backgroundColor = widget.isCurrentUser
        ? (widget.isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50)
        : (widget.isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voice message header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Icon(
                  Icons.mic,
                  size: 16,
                  color: waveColor,
                ),
                SizedBox(width: 8),
                Text(
                  'Voice Message',
                  style: TextStyle(
                    fontSize: 13,
                    color: waveColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.audioDuration > 0)
                  Text(
                    ' • ${_formatDuration(widget.audioDuration)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryTextColor,
                    ),
                  ),
                Spacer(),
                // Show timestamp in corner
                Text(
                  DateFormat('h:mm a').format(widget.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Player UI
          Row(
            children: [
              SizedBox(width: 8),
              // Play button with animated background
              GestureDetector(
                onTap: () {
                  setState(() {
                    isPlaying = !isPlaying;
                  });
                  widget.onPlay();
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? waveColor
                        : waveColor.withOpacity(_safeOpacity(widget.isDarkMode ? 0.3 : 0.2)),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: waveColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        key: ValueKey<bool>(isPlaying),
                        color: isPlaying ? Colors.white : waveColor,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Waveform visualization with progress indicator
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Waveform visualization (simplified)
                    Container(
                      height: 40,
                      child: _buildStylizedWaveform(
                        color: waveColor.withOpacity(0.3),
                        isActive: isPlaying,
                      ),
                    ),

                    SizedBox(height: 8),

                    // Progress slider
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: waveColor,
                        inactiveTrackColor: waveColor.withOpacity(0.2),
                        thumbColor: waveColor,
                        overlayColor: waveColor.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: (value) {
                          setState(() {
                            progress = value;
                          });
                          // In a real implementation, seek to this position
                        },
                      ),
                    ),

                    // Time indicators
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Current position
                          Text(
                            _formatDuration((widget.audioDuration * progress).round()),
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),

                          // Total duration
                          Text(
                            _formatDuration(widget.audioDuration),
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStylizedWaveform({required Color color, required bool isActive}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        30,
            (index) {
          // Create a pattern with variable heights
          double heightFactor;

          // Pattern for wave heights
          if (index % 5 == 0) {
            heightFactor = 0.9;
          } else if (index % 3 == 0) {
            heightFactor = 0.7;
          } else if (index % 2 == 0) {
            heightFactor = 0.5;
          } else {
            heightFactor = 0.3;
          }

          return Container(
            width: 2,
            height: 32 * heightFactor,
            decoration: BoxDecoration(
              color: index < (progress * 30) ? color.withOpacity(0.8) : color,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        },
      ),
    );
  }
}