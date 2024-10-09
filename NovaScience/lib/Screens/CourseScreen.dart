import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:nova_science/Modals/User.dart';
import 'package:nova_science/Service/AuthService.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../Modals/CourseAndSectionAndVideos.dart';
import '../Service/CourseProvider.dart';

class CourseScreen extends StatefulWidget {
  final String courseId;

  CourseScreen({required this.courseId});

  @override
  _CourseScreenState createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen>
    with TickerProviderStateMixin {
  YoutubePlayerController? _youtubeController;
  late TabController _tabController;
  FirebaseAuth? _auth;
  Course? _course;
  bool isLoading = true;
  bool isActionLoading = false;

  // For indicating loading in dialog actions

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCourseData();
  }

  void _initializeYoutubePlayer(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) return;

    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          isLive: false,
        ),
      );
    } else {
      print("Invalid video URL");
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _playVideo(String videoUrl) {
    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId != null) {
      _youtubeController!.load(videoId);
    } else {
      print("Invalid video URL");
    }
  }

  Future<void> _fetchCourseData() async {
    try {
      final courseProvider =
          Provider.of<CourseProvider>(context, listen: false);
      _course = await courseProvider.getCourseById(widget.courseId);

      setState(() {
        isLoading = false;
      });

      if (_course != null &&
          _course!.sections.isNotEmpty &&
          _course!.sections.first.videos.isNotEmpty) {
        _initializeYoutubePlayer(_course!.sections.first.videos.first.videoUrl);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load course data: $e'),
        duration: Duration(seconds: 3),
      ));
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addVideoToSection(String courseId, String sectionTitle,
      String videoTitle, String videoUrl, BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    courseProvider.addVideoToSection(
        courseId, sectionTitle, Video(title: videoTitle, videoUrl: videoUrl));
  }

  void _deleteVideo(String courseId, String sectionTitle, int videoIndex) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    courseProvider.deleteVideo(widget.courseId, sectionTitle, videoIndex);
  }

  void _deleteSection(int sectionIndex, Section section) async {
    try {
      final courseProvider =
          Provider.of<CourseProvider>(context, listen: false);
      await courseProvider.deleteSection(widget.courseId, section.sectionTitle);
    } catch (e) {
      // Handle the error, e.g., show a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting section: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: Center(
            child: SpinKitDoubleBounce(
          color: Colors.white,
        )),
      );
    }

    if (!(_youtubeController is YoutubePlayerController)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: Column(
          children: [
            Center(child: Text('Video player not initialized')),
            _buildSectionsList(_course!)
          ],
        ),
      );
    }

    return SafeArea(
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          onReady: () => print("Player is ready"),
          onEnded: (metaData) => print("Video has ended"),
        ),
        builder: (context, player) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_course!.courseTitle ?? 'Course Details'),
              backgroundColor: Colors.blueAccent,
              actions: [
                IconButton(
                  icon: Icon(Icons.edit, semanticLabel: 'Edit Course'),
                  onPressed: () => _showEditCourseDialog(context, _course!),
                ),
                IconButton(
                  icon: Icon(Icons.delete, semanticLabel: 'Delete Course'),
                  onPressed: () {
                    Provider.of<CourseProvider>(context, listen: false)
                        .deleteCourse(_course!.id);
                    Navigator.pop(context);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add, semanticLabel: 'Add Section'),
                  onPressed: () => _showAddSectionDialog(context),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'videoHero',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: player,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF3F51B5),
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: "Overview"),
                        Tab(text: "Lessons"),
                        Tab(text: "Feedback"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 500, // Fixed height to avoid scrolling issues
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverview(_course!),
                          _buildSectionsList(_course!),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            // Proper padding around the feedback section
                            child: _buildFeedbackTab(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverview(Course course) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Course Title
          Text(
            'Course Overview',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple[900],
            ),
          ),
          const SizedBox(height: 16),

          // Course Card with Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple[300]!, Colors.deepPurple[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructor Name
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Instructor: ${course.instructor ?? "Instructor Name"}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description Header
                  const Text(
                    'Course Description',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Adjusted Description for Overflow Management
                  Text(
                    course.description ?? 'No description available.',
                    style: TextStyle(fontSize: 16, height: 1.5, color: Colors.white70),
                    maxLines: 5, // Limit to 5 lines
                    overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                  ),
                  const SizedBox(height: 20),

                  // Price and Duration Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${course.price}',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${course.duration ?? "Duration not specified"}',
                            style: TextStyle(fontSize: 18, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10), // Space between Price and Button

                      // Using Flexible to prevent overflow
                      Flexible(
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Enrollment coming soon!'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.blueAccent,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            backgroundColor: Colors.greenAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            elevation: 6,
                          ),
                          child: const Text(
                            'Enroll Now',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30), // Space after the card
          // Additional Resources Section (leave space for this section)
          // Placeholder for additional resources
        ],
      ),
    );
  }


  Widget _buildSectionsList(Course course) {
    if (course.sections.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () => _showAddSectionDialog(context),
          child: Text('Add Sections'),
        ),
      );
    }

    return SizedBox(
      height: 500.0,
      child: ListView.builder(
        itemCount: course.sections.length,
        itemBuilder: (context, index) {
          final section = course.sections[index];
          return _buildSectionCard(section, index);
        },
      ),
    );
  }

  Widget _buildSectionCard(Section section, int sectionIndex) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              section.sectionTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () =>
                      _showEditSectionDialog(section, sectionIndex),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _confirmDeleteSection(sectionIndex, section),
                ),
              ],
            ),
          ],
        ),
        children: [
          if (section.videos.isNotEmpty)
            ...section.videos.asMap().entries.map((entry) {
              int videoIndex = entry.key;
              Video video = entry.value;

              return ListTile(
                leading: Icon(Icons.play_circle_outline),
                title: Text(video.title),
                subtitle: Text('Click to play'),
                onTap: () => _playVideo(video.videoUrl),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showEditVideoDialog(
                          section.sectionTitle, video, videoIndex),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteVideo(
                          widget.courseId, section.sectionTitle, videoIndex),
                    ),
                  ],
                ),
              );
            }).toList()
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text('No videos available')),
            ),
          TextButton(
            onPressed: () =>
                _showAddVideoDialog(widget.courseId, section.sectionTitle),
            child: Text('Add Video'),
          ),
        ],
      ),
    );
  }

  void _showEditCourseDialog(BuildContext context, Course course) {
    final TextEditingController titleController =
        TextEditingController(text: course.courseTitle);
    final TextEditingController descriptionController =
        TextEditingController(text: course.description);
    final TextEditingController priceController =
        TextEditingController(text: course.price.toString());
    final TextEditingController subjectController =
        TextEditingController(text: course.subject);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Course Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Course Description'),
                  maxLines: 3,
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Course Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(labelText: 'subject'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Validate and save course details
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    priceController.text.isNotEmpty) ;
                // Update the course object with new values
                Provider.of<CourseProvider>(context, listen: false).editCourse(
                  course.id!,
                  titleController.text,
                  descriptionController.text,
                  double.parse(priceController.text),
                  subjectController.text,
                );

                // Dismiss the dialog
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddSectionDialog(BuildContext context) {
    final _sectionTitleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Section'),
          content: TextField(
            controller: _sectionTitleController,
            decoration: InputDecoration(
                labelText: 'Section Title', hintText: 'Enter section title'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (_sectionTitleController.text.isNotEmpty) {
                  setState(() => isActionLoading = true); // Start loading
                  final courseProvider =
                      Provider.of<CourseProvider>(context, listen: false);
                  await courseProvider.addSection(
                      widget.courseId, _sectionTitleController.text);
                  setState(() => isActionLoading = false); // End loading
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a section title')));
                }
              },
              child: isActionLoading
                  ? CircularProgressIndicator() // Show loader during the action
                  : Text('Add Section'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVideoDialog(String courseId, String sectionTitle) {
    final _videoTitleController = TextEditingController();
    final _videoUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Video to $sectionTitle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _videoTitleController,
                decoration: InputDecoration(
                    labelText: 'Video Title', hintText: 'Enter video title'),
              ),
              TextField(
                controller: _videoUrlController,
                decoration: InputDecoration(
                    labelText: 'Video URL',
                    hintText: 'Enter valid YouTube URL'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (_videoTitleController.text.isNotEmpty &&
                    _videoUrlController.text.isNotEmpty) {
                  setState(() => isActionLoading = true); // Start loading
                  _addVideoToSection(
                      courseId,
                      sectionTitle,
                      _videoTitleController.text,
                      _videoUrlController.text,
                      context);
                  setState(() => isActionLoading = false); // End loading
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill out all fields')));
                }
              },
              child: isActionLoading
                  ? SpinKitDoubleBounce(
                      color: Colors.white,
                    ) // Show loader during the action
                  : Text('Add Video'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSectionDialog(Section section, int sectionIndex) {
    final _sectionTitleController =
        TextEditingController(text: section.sectionTitle);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Section'),
          content: TextField(
            controller: _sectionTitleController,
            decoration: InputDecoration(
                labelText: 'Section Title',
                hintText: 'Enter new section title'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (_sectionTitleController.text.isNotEmpty) {
                  setState(() => isActionLoading = true); // Start loading
                  final courseProvider =
                      Provider.of<CourseProvider>(context, listen: false);
                  await courseProvider.editSection(widget.courseId,
                      section.sectionTitle, _sectionTitleController.text);
                  setState(() => isActionLoading = false); // End loading
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a section title')));
                }
              },
              child: isActionLoading
                  ? SpinKitDoubleBounce(
                      color: Colors.white,
                    ) // Show loader during the action
                  : Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditVideoDialog(String sectionTitle, Video video, int videoIndex) {
    final _videoTitleController = TextEditingController(text: video.title);
    final _videoUrlController = TextEditingController(text: video.videoUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _videoTitleController,
              decoration: InputDecoration(
                  labelText: 'Video Title', hintText: 'Enter new video title'),
            ),
            TextField(
              controller: _videoUrlController,
              decoration: InputDecoration(
                  labelText: 'Video URL', hintText: 'Enter new YouTube URL'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              if (_videoTitleController.text.isNotEmpty &&
                  _videoUrlController.text.isNotEmpty) {
                final courseProvider =
                    Provider.of<CourseProvider>(context, listen: false);
                courseProvider.editVideo(
                    widget.courseId,
                    sectionTitle,
                    videoIndex,
                    _videoTitleController.text,
                    _videoUrlController.text);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill out all fields')));
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSection(int sectionIndex, Section section) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Delete Section'),
            content: Text('Are you sure you want to delete this section?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                // Close the dialog
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  setState(() => isActionLoading = true); // Start loading
                  _deleteSection(
                      sectionIndex, section); // Proceed to delete the section
                  setState(() => isActionLoading = false); // End loading
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: isActionLoading
                    ? SpinKitDoubleBounce(
                        color: Colors.white,
                      ) // Show loader during the action
                    : Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackTab(BuildContext context) {
    return FutureBuilder<CustomUser?>(
      future: Provider.of<CourseProvider>(context, listen: false).getCurrentUser(), // Get the current user asynchronously
      builder: (BuildContext context, AsyncSnapshot<CustomUser?> snapshot) {
        // Handle different states based on the snapshot status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitDoubleBounce(color: Colors.blueAccent), // While loading
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}')); // Error state
        } else if (!snapshot.hasData) {
          return Center(child: Text('No user data available')); // No user available
        } else {
          final currentUser = snapshot.data; // Get the user data from snapshot
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFeedbackForm(currentUser!),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildFeedbackList(currentUser),
                ),
              ),
            ],
          );
        }
      },
    );
  }


  bool _isSubmitting =
      false; // Add this state variable to track submission status

  Widget _buildFeedbackForm(CustomUser user) {
    final TextEditingController _feedbackController = TextEditingController();

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Wrap the content in SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We value your feedback!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _feedbackController,
                decoration: InputDecoration(
                  labelText: 'Your Feedback',
                  hintText: 'Enter your thoughts...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.feedback, color: Colors.blueAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                  ),
                ),
                maxLength: 150,
                maxLines: 2,
              ),
              SizedBox(height: 8),
              // Display character limit below the text field
              Text(
                '${_feedbackController.text.length}/150 characters',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                  if (_feedbackController.text.isNotEmpty) {
                    setState(() {
                      _isSubmitting = true;
                    });

                    final result = await _addFeedback(
                      _course!.id!,
                      user.name!,
                      _feedbackController.text,
                      user.id!,
                    );
                    _feedbackController.clear();

                    // Show success or error message based on result
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result // Assuming _addFeedback returns a success message
                              ? 'Feedback submitted successfully!'
                              : 'Failed to submit feedback. Please try again.',
                        ),
                        duration: Duration(seconds: 2),
                        backgroundColor:
                        result ? Colors.green : Colors.red,
                      ),
                    );

                    setState(() {
                      _isSubmitting = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  backgroundColor:
                  _isSubmitting ? Colors.grey : Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 3,
                ),
                child: _isSubmitting
                    ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.send, color: Colors.white),
                    // Icon for submit button
                    SizedBox(width: 8),
                    // Space between icon and text
                    Text(
                      'Submit Feedback',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildFeedbackList(CustomUser currentUser) {
    return ListView.builder(
      itemCount: _course!.feedbacks.length,
      itemBuilder: (context, index) {
        final feedback = _course!.feedbacks[index];

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(feedback.userId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error fetching user'));
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('User data not available'));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>?;

            final userName = userData?['name'] ?? 'Unknown User';
            final isOwnerOrAdmin = feedback.userId == currentUser.id ||
                currentUser.role == 'Admin';

            // Format date
            final formattedDate =
                DateFormat('yMMMd').format(feedback.date!.toDate());

            // Highlight current user feedback
            final isCurrentUserFeedback = feedback.userId == currentUser.id;

            return Card(
              margin: const EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0)),
              elevation: 3,
              color: isCurrentUserFeedback
                  ? Colors.lightBlue.shade50
                  : Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(userData?['profileImageUrl'] ??
                          "https://via.placeholder.com/150"), // Replace with your placeholder URL
                    ),
                    title: Text(feedback.feedback,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Posted by $userName on $formattedDate'),
                    trailing: isOwnerOrAdmin
                        ? PopupMenuButton(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditFeedbackDialog(feedback, index);
                              } else if (value == 'delete') {
                                _deleteFeedback(_course!.id!, index);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: ElevatedButton(
                                  onPressed: () {
                                    _showEditFeedbackDialog(feedback, index);
                                  },
                                  child: Text('Edit'),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: ElevatedButton(
                                  onPressed: () {
                                    _deleteFeedback(_course!.id!, index);
                                  },
                                  child: Text('Delete'),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                  Divider(), // Add a divider for visual separation
                ],
              ),
            );
          },
        );
      },
    );
  }


  Future<bool> _addFeedback(String courseId, String userName, String feedbackText, String userId) async {
    try {
      // Add feedback to the Firestore collection (or wherever you're storing it)
      final newFeedback = FeedBack(
        userId: userId,
        userName: userName,
        feedback: feedbackText,
      );

      setState(() {
        Provider.of<CourseProvider>(context, listen: false)
            .addFeedback(courseId, userId, feedbackText, userName);
      });
      return true; // Return true on success
    } catch (error) {
      print("Failed to add feedback: $error");
      return false; // Return false on error
    }
  }

  void _showEditFeedbackDialog(FeedBack feedback, int index) {
    final TextEditingController _feedbackController =
        TextEditingController(text: feedback.feedback);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Feedback'),
          content: TextField(
            controller: _feedbackController,
            maxLines: 2,
            decoration: InputDecoration(labelText: 'Your Feedback'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                setState(() {
                  _course!.feedbacks[index].feedback = _feedbackController.text;
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteFeedback(String courseId, int index) async {
    // Show a confirmation dialog before deletion
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this feedback?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    // If the user confirms deletion, proceed with deletion
    if (shouldDelete == true) {
      setState(() {
        // Call the provider method to delete feedback
        Provider.of<CourseProvider>(context, listen: false)
            .deleteFeedback(courseId, index);
      });
    }
  }

}
