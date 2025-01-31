import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart';
import '../../Service/AuthService.dart';
import '../../Modals/User.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart'; // For launching URLs
import 'VideoPlayerScreen.dart';
import 'package:cached_network_image/cached_network_image.dart'; // For image caching

class CourseDetailScreen extends StatelessWidget {
  final Course course;

  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  /// Helper method to validate YouTube URLs
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
      floating: false,
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
            course.imageUrl != null && course.imageUrl!.isNotEmpty
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
            // Gradient overlay for better text visibility
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
  Widget _buildAppBarActions(BuildContext context, Course course) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

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
              Navigator.pop(context); // Navigate back after deletion
            }
            break;
          default:
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Text('Edit Course'),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete Course'),
        ),
      ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
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

  /// Builds the course title and description.
  Widget _buildCourseTitleAndDescription(Course course, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.courseTitle ?? '',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          course.description ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  /// Builds the course price and status chips.
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

  /// Displays the number of currently logged-in users.
  Widget _buildLoggedInUsers(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    return FutureBuilder<int>(
      future: courseProvider.getNumberOfLoggedInUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text(
            'Unable to load user count',
            style: TextStyle(color: Colors.red),
          );
        }
        return Text(
          '${snapshot.data ?? 0} user(s) currently online.',
          style: Theme.of(context).textTheme.titleMedium,
        );
      },
    );
  }

  Widget _buildEnrolledStudents(BuildContext context, AuthService authService, String courseId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Enrolled Students',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<CustomUser>>(
            future: authService.getUsersEnrolledInCourse(courseId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
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
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final student = students[index];

                  // Get enrollment details for the specific course
                  final enrollment = student.enrollments?.firstWhere(
                        (enrollment) => enrollment.courseId == courseId,
                  );

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(
                        student.profileImageUrl != null && student.profileImageUrl!.isNotEmpty
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
                    onTap: () {
                      if (enrollment != null) {
                        _showEnrollmentDetails(
                          context,
                          student.name ?? 'Unnamed Student',
                          enrollment.enrollmentDate,
                          enrollment.endDate,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Enrollment details not available.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEnrollmentDetails(
      BuildContext context,
      String studentName,
      DateTime enrollmentDate,
      DateTime endDate,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enrollment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: $studentName'),
            const SizedBox(height: 8),
            Text('Enrollment Date: ${DateFormat.yMMMd().format(enrollmentDate)}'),
            Text('End Date: ${DateFormat.yMMMd().format(endDate)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  /// Extracts initials from a name string.
  String _getInitials(String name) {
    List<String> names = name.trim().split(' ');
    String initials = '';
    for (var part in names) {
      if (part.isNotEmpty) {
        initials += part[0].toUpperCase();
      }
    }
    return initials;
  }

  /// Shows a confirmation dialog to unenroll a student.
  void _showUnenrollConfirmationDialog(
      BuildContext context, String userId, String courseId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Unenroll Student'),
          content: Text(
              'Are you sure you want to unenroll this student from the course?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                // Use the root context for showing SnackBar
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
  Future<void> _unenrollStudent(BuildContext rootContext, String userId, String courseId) async {
    try {
      // Fetch the user's enrolledCourses
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      List<dynamic> enrolledCourses = userData['enrolledCourses'] ?? [];

      // Find the course object to remove
      Map<String, dynamic>? courseToRemove;
      for (var course in enrolledCourses) {
        if (course['courseId'] == courseId) {
          courseToRemove = course as Map<String, dynamic>;
          break;
        }
      }

      // If the course was found, remove it
      if (courseToRemove != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'enrolledCourses': FieldValue.arrayRemove([courseToRemove]),
        });

        // Show success SnackBar
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
  /// Builds the sections of the course.
  Widget _buildSections(BuildContext context, Course course) {
    if (course.sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No sections available.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                  section.sectionTitle!,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: section.videos.isNotEmpty
                    ? section.videos
                    .map(
                      (video) => ListTile(
                    leading: Icon(Icons.video_library, color: Colors.redAccent),
                    title: Text(video.title!),
                    trailing: Icon(Icons.play_circle_fill, color: Colors.green),
                    onTap: () {
                      if (video.videoUrl != null &&
                          _isValidYouTubeUrl(video.videoUrl!)) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VideoPlayerScreen(videoUrl: video.videoUrl!),
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
                    },
                  ),
                )
                    .toList()
                    : [
                  ListTile(
                    title: Text('No videos available.'),
                  )
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
        child: Text(
          'No feedbacks yet.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
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
                  itemBuilder: (context, _) =>
                      Icon(Icons.star, color: Colors.amber),
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
                // Replace with actual user details
                final CustomUser? currentUser =
                Provider.of<AuthService>(context, listen: false)
                    .currentUser as CustomUser?;

                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                      Text('You must be logged in to submit feedback.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Submit feedback
                final result = await Provider.of<CourseProvider>(context,
                    listen: false)
                    .addFeedback(
                  courseId,
                  currentUser.name ?? 'Anonymous',
                  _feedbackController.text,
                  currentUser.id ?? 'Unknown',
                  _currentRating,
                );


              }
            },
            child: Text('Submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                // Update course details
                final updatedCourse = Course(
                  id: course.id,
                  courseTitle: _titleController.text,
                  description: _descriptionController.text,
                  price: double.parse(_priceController.text),
                  status: _statusController.text,
                  imageUrl: course.imageUrl,
                  sections: course.sections,
                  feedbacks: course.feedbacks,
                );

                // Update in the provider
                await Provider.of<CourseProvider>(context, listen: false)
                    .updateCourse(updatedCourse);

                Navigator.pop(context);

                // Show a success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Course updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }


}