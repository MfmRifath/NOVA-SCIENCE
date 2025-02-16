import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart';
import '../../Service/AuthService.dart';
import '../../Modals/User.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'VideoPlayerScreen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

class YoutubePlayerBuilder extends StatefulWidget {
  final YoutubePlayer player;
  final Widget Function(BuildContext, Widget) builder;
  final VoidCallback? onEnterFullScreen;
  final VoidCallback? onExitFullScreen;

  const YoutubePlayerBuilder({
    Key? key,
    required this.player,
    required this.builder,
    this.onEnterFullScreen,
    this.onExitFullScreen,
  }) : super(key: key);

  @override
  State<YoutubePlayerBuilder> createState() => _YoutubePlayerBuilderState();
}

class _YoutubePlayerBuilderState extends State<YoutubePlayerBuilder>
    with WidgetsBindingObserver {
  final GlobalKey playerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Retrieve the list of views and check if it is empty.
    final views = PlatformDispatcher.instance.views;
    if (views.isEmpty) return; // Prevents calling `.first` on an empty list.

    final physicalSize = views.first.physicalSize;
    final controller = widget.player.controller;
    if (physicalSize.width > physicalSize.height) {
      controller.updateValue(controller.value.copyWith(isFullScreen: true));
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      widget.onEnterFullScreen?.call();
    } else {
      controller.updateValue(controller.value.copyWith(isFullScreen: false));
      SystemChrome.restoreSystemUIOverlays();
      widget.onExitFullScreen?.call();
    }
    super.didChangeMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final height = MediaQuery.of(context).size.height;
    final player = SizedBox(
      key: playerKey,
      height: orientation == Orientation.landscape ? height : null,
      child: widget.player,
    );
    final child = widget.builder(context, player);
    return OrientationBuilder(
      builder: (context, orientation) {
        return orientation == Orientation.portrait ? child : player;
      },
    );
  }
}
class CourseDetailScreen extends StatelessWidget {
  final Course course;

  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  /// Helper method to validate YouTube URLs.
  bool _isValidYouTubeUrl(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host.contains('youtube.com') || uri.host.contains('youtu.be');
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(course, context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildCourseDetails(context, course),
                Divider(thickness: 1.5),
                _buildEnrolledStudents(context, authService, course.id ?? ''),
                Divider(thickness: 1.5),
                _buildSections(context, course),
                Divider(thickness: 1.5),
                _buildFeedbacks(context, course.feedbacks),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddFeedbackDialog(context, course.id ?? '');
        },
        icon: Icon(Icons.feedback),
        label: Text('Add Feedback'),
        backgroundColor: Colors.teal,
        tooltip: 'Add Feedback',
      ),
    );
  }

  /// Builds the SliverAppBar with a background image and title.
  Widget _buildSliverAppBar(Course course, BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          course.courseTitle ?? 'Course Detail',
          style: TextStyle(
            color: Colors.white,
            shadows: [Shadow(blurRadius: 2, color: Colors.black)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            (course.imageUrl != null && course.imageUrl!.isNotEmpty)
                ? CachedNetworkImage(
              imageUrl: course.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade300,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
                : Container(
              color: Colors.grey.shade300,
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            ),
            // Gradient overlay for better text visibility.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  stops: [0.5, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        _buildAppBarActions(context, course),
      ],
    );
  }

  /// Builds action buttons in the AppBar.
  /// Builds action buttons in the AppBar.
  Widget _buildAppBarActions(BuildContext context, Course course) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            _showEditCourseDialog(context, course);
            break;
          case 'delete':
            bool confirm = await _showDeleteConfirmation(context);
            if (confirm) {
              await courseProvider.deleteCourse(course.id ?? '');
              Navigator.pop(context); // Navigate back after deletion.
            }
            break;
          case 'approve':
            {
              // Create an updated course instance with isApproved set to true.
              final updatedCourse = Course(
                id: course.id,
                courseTitle: course.courseTitle,
                description: course.description,
                price: course.price,
                subject: course.subject,
                imageUrl: course.imageUrl,
                status: course.status,
                duration: course.duration,
                instructor: course.instructor,
                averageRating: course.averageRating,
                enrolledUserIds: course.enrolledUserIds,
                sections: course.sections,
                feedbacks: course.feedbacks,
                instructorEmail: course.instructorEmail,
                medium: course.medium,
                isApproved: true,
              );
              await courseProvider.updateCourse(updatedCourse);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Course approved successfully!'))
              );
            }
            break;
          case 'disapprove':
            {
              // Create an updated course instance with isApproved set to false.
              final updatedCourse = Course(
                id: course.id,
                courseTitle: course.courseTitle,
                description: course.description,
                price: course.price,
                subject: course.subject,
                imageUrl: course.imageUrl,
                status: course.status,
                duration: course.duration,
                instructor: course.instructor,
                averageRating: course.averageRating,
                enrolledUserIds: course.enrolledUserIds,
                sections: course.sections,
                feedbacks: course.feedbacks,
                instructorEmail: course.instructorEmail,
                medium: course.medium,
                isApproved: false,
              );
              await courseProvider.updateCourse(updatedCourse);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Course disapproved successfully!'))
              );
            }
            break;
          default:
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        // Build a list of menu items.
        final List<PopupMenuEntry<String>> items = [
          const PopupMenuItem<String>(
            value: 'edit',
            child: Text('Edit Course'),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Text('Delete Course'),
          ),
        ];
          items.add(
            PopupMenuItem<String>(
              value: course.isApproved == true ? 'disapprove' : 'approve',
              child: Text(course.isApproved == true ? 'Disapprove Course' : 'Approve Course'),
            ),
          );
        return items;
      },
    );
  }

  /// Shows a confirmation dialog before deleting the course.
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Course'),
        content: Text(
            'Are you sure you want to delete this course? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    ) ??
        false;
  }

  /// Builds the course details section.
  Widget _buildCourseDetails(BuildContext context, Course course) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildCourseTitleAndDescription(course, context),
          SizedBox(height: 16),
          _buildCoursePriceAndStatus(course),
          SizedBox(height: 16),
          _buildLoggedInUsers(context),
        ],
      ),
    );
  }

  /// Displays the course title and description.
  Widget _buildCourseTitleAndDescription(Course course, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.courseTitle ?? '',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          course.description ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  /// Displays the course price and status as chips.
  Widget _buildCoursePriceAndStatus(Course course) {
    return Row(
      children: [
        if (course.price != null)
          Chip(
            label: Text('\$${course.price}'),
            backgroundColor: Colors.green.shade100,
          ),
        SizedBox(width: 8),
        Chip(
          label: Text('Status: ${course.status ?? 'N/A'}'),
          backgroundColor: Colors.blue.shade100,
        ),
      ],
    );
  }

  /// Shows the number of currently logged-in users.
  Widget _buildLoggedInUsers(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    return FutureBuilder<int>(
      future: courseProvider.getNumberOfLoggedInUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Unable to load user count', style: TextStyle(color: Colors.red));
        }
        return Text(
          '${snapshot.data ?? 0} user(s) currently online.',
          style: Theme.of(context).textTheme.titleMedium,
        );
      },
    );
  }

  /// Displays the list of enrolled students.
  Widget _buildEnrolledStudents(BuildContext context, AuthService authService, String courseId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Enrolled Students',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<CustomUser>>(
            future: authService.getUsersEnrolledInCourse(courseId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Unable to load students', style: TextStyle(color: Colors.red));
              }
              final students = snapshot.data ?? [];
              if (students.isEmpty) {
                return Text('No students enrolled yet.');
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: students.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  final student = students[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(
                        (student.profileImageUrl != null && student.profileImageUrl!.isNotEmpty)
                            ? student.profileImageUrl!
                            : 'https://via.placeholder.com/150',
                      ),
                    ),
                    title: Text(student.name ?? 'Unnamed Student'),
                    subtitle: Text(student.email ?? 'No Email'),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      tooltip: 'Unenroll Student',
                      onPressed: () {
                        _showUnenrollConfirmationDialog(context, student.id ?? '', courseId);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Shows a dialog to confirm unenrolling a student.
  void _showUnenrollConfirmationDialog(BuildContext context, String userId, String courseId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Unenroll Student'),
          content: Text('Are you sure you want to unenroll this student from the course?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _unenrollStudent(context, userId, courseId);
              },
              child: Text('Yes, Unenroll'),
            ),
          ],
        );
      },
    );
  }

  /// Unenrolls a student by updating Firestore.
  Future<void> _unenrollStudent(BuildContext rootContext, String userId, String courseId) async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      List<dynamic> enrolledCourses = userData['enrolledCourses'] ?? [];
      Map<String, dynamic>? courseToRemove;
      for (var course in enrolledCourses) {
        if (course['courseId'] == courseId) {
          courseToRemove = course as Map<String, dynamic>;
          break;
        }
      }
      if (courseToRemove != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'enrolledCourses': FieldValue.arrayRemove([courseToRemove]),
        });
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(
            content: Text('Student successfully unenrolled.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(
            content: Text('Course not found for this student.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error unenrolling student: $e');
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(
          content: Text('Failed to unenroll student.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Builds the sections list, including both videos and PDFs.
  Widget _buildSections(BuildContext context, Course course) {
    if (course.sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('No sections available.', style: Theme.of(context).textTheme.titleMedium),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sections',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: course.sections.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              final section = course.sections[index];
              return ExpansionTile(
                leading: Icon(Icons.folder_open, color: Colors.blueAccent),
                title: Text(
                  section.sectionTitle ?? "Untitled Section",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  // List Videos (if any)
                  if (section.videos.isNotEmpty)
                    ...section.videos.map((video) {
                      return ListTile(
                        leading: Icon(Icons.video_library, color: Colors.redAccent),
                        title: Text(video.title ?? "Untitled Video"),
                        trailing: Icon(Icons.play_circle_fill, color: Colors.green),
                        onTap: () {
                          if (video.videoUrl != null && _isValidYouTubeUrl(video.videoUrl!)) {
                            final String? videoId = YoutubePlayer.convertUrlToId(video.videoUrl!);
                            if (video.videoUrl != null && _isValidYouTubeUrl(video.videoUrl!)) {
                              // Extract the videoId if needed (for logging or other purposes) but pass videoUrl.
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerScreen(videoUrl: video.videoUrl!),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Invalid YouTube video URL.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invalid YouTube video URL.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    }).toList()
                  else
                    ...[ListTile(title: Text('No videos available.'))],
                  // List PDFs (if any)
                  if (section.pdfs.isNotEmpty)
                    ...section.pdfs.map((pdf) {
                      return ListTile(
                        leading: Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                        title: Text(pdf.title ?? "Untitled PDF"),
                        subtitle: Text(pdf.pdfUrl ?? "No URL"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PdfPreviewScreen(
                                pdfUrl: pdf.pdfUrl!,
                                title: pdf.title ?? "PDF Preview",
                              ),
                            ),
                          );
                        },
                      );
                    }).toList()
                  else
                    ...[ListTile(title: Text('No PDFs available.'))],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds the feedbacks section.
  Widget _buildFeedbacks(BuildContext context, List<FeedBack> feedbacks) {
    if (feedbacks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('No feedbacks yet.', style: Theme.of(context).textTheme.titleMedium),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Feedbacks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: feedbacks.length,
            separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              final feedback = feedbacks[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(feedback.userName ?? 'Anonymous'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(feedback.feedback ?? ''),
                      SizedBox(height: 4),
                      RatingBarIndicator(
                        rating: feedback.rating ?? 0.0,
                        itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 16.0,
                        direction: Axis.horizontal,
                      ),
                      SizedBox(height: 4),
                      Text(
                        feedback.date != null
                            ? DateFormat.yMMMd().format(feedback.date!.toDate())
                            : '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Shows a dialog to add feedback.
  void _showAddFeedbackDialog(BuildContext context, String courseId) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _feedbackController = TextEditingController();
    double _currentRating = 3.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Feedback'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Feedback Text
                TextFormField(
                  controller: _feedbackController,
                  decoration: InputDecoration(
                    labelText: 'Your Feedback',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 150,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your feedback.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                // Rating Bar
                Text(
                  'Rate this course:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                RatingBar.builder(
                  initialRating: _currentRating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) {
                    _currentRating = rating;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final CustomUser? currentUser =
                Provider.of<AuthService>(context, listen: false).currentUser as CustomUser?;
                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You must be logged in to submit feedback.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                await Provider.of<CourseProvider>(context, listen: false).addFeedback(
                  courseId,
                  currentUser.name ?? 'Anonymous',
                  _feedbackController.text,
                  currentUser.id ?? 'Unknown',
                  _currentRating,
                );
                Navigator.pop(context);
              }
            },
            child: Text('Submit'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog to edit the course details.
  void _showEditCourseDialog(BuildContext context, Course course) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _titleController =
    TextEditingController(text: course.courseTitle);
    final TextEditingController _descriptionController =
    TextEditingController(text: course.description);
    final TextEditingController _priceController =
    TextEditingController(text: course.price?.toString());
    final TextEditingController _statusController =
    TextEditingController(text: course.status);
    // Remove the medium controller

    // Define the list of allowed mediums
    final List<String> mediums = ['Tamil', 'English', 'Sinhala'];
    // Initialize selectedMedium using the course's medium or default to the first option
    String? selectedMedium = course.medium != null && mediums.contains(course.medium)
        ? course.medium
        : mediums.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Course'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Course Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Course Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the course title.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      // Course Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Course Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the course description.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      // Medium Dropdown instead of a text field
                      DropdownButtonFormField<String>(
                        value: selectedMedium,
                        decoration: InputDecoration(
                          labelText: 'Medium',
                          border: OutlineInputBorder(),
                        ),
                        items: mediums
                            .map((medium) => DropdownMenuItem(
                          value: medium,
                          child: Text(medium),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMedium = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a medium';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      // Course Price
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Course Price',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the course price.';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      // Course Status
                      TextFormField(
                        controller: _statusController,
                        decoration: InputDecoration(
                          labelText: 'Course Status',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final updatedCourse = Course(
                        id: course.id,
                        courseTitle: _titleController.text,
                        description: _descriptionController.text,
                        price: double.parse(_priceController.text),
                        status: _statusController.text,
                        imageUrl: course.imageUrl,
                        sections: course.sections,
                        feedbacks: course.feedbacks,
                        medium: selectedMedium, // Save the selected medium
                      );
                      await Provider.of<CourseProvider>(context, listen: false)
                          .updateCourse(updatedCourse);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Course updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: Text('Save'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// PDF Preview Screen to display PDFs within the app.
class PdfPreviewScreen extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const PdfPreviewScreen({Key? key, required this.pdfUrl, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blueAccent,
      ),
      body: PDF().cachedFromUrl(
        pdfUrl,
        placeholder: (progress) => Center(child: Text('$progress %')),
        errorWidget: (error) => Center(child: Text('Error: $error')),
      ),
    );
  }
}