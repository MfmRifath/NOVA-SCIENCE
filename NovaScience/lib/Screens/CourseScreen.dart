// CourseScreen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:nova_science/Service/AuthService.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../Modals/CourseAndSectionAndVideos.dart';
import '../Modals/User.dart';
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
  Course? _course;
  bool isLoading = true;
  bool isActionLoading = false;
  final TextEditingController _feedbackController = TextEditingController();
  double _currentRating = 3.0;
  bool _isSubmitting = false;

  // Enrollment and Admin related variables
  bool isEnrolled = false;
  bool isAdmin = false; // New variable to track Admin status
  bool isCheckingEnrollment = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeCourse();
  }

  Future<void> _initializeCourse() async {
    try {
      final authProvider = Provider.of<AuthService>(context, listen: false);
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);

      // Fetch Course Details
      _course = await courseProvider.getCourseById(widget.courseId);

      // Fetch Current User
      CustomUser? currentUser = await authProvider.getCurrentUser();
      if (_course != null && currentUser != null) {
        // Check Enrollment (assuming enrollments is a list of objects with courseId)
        isEnrolled = (currentUser.enrollments as List?)?.any((enrollment) {
          return enrollment.courseId == _course!.id;
        }) ??
            false;

        // Check Admin Status
        isAdmin = currentUser.role == 'Admin';
      }

      // Update TabController based on access level
      _tabController = TabController(
        length: (isEnrolled || isAdmin) ? 3 : 2,
        vsync: this,
      );

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load course data: $e')),
      );
    }
  }
  void _showAddResourceDialog(String courseId, String sectionTitle) {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _urlController = TextEditingController();
    String resourceType = "Video"; // Default type is Video
    // Variable to hold the picked PDF file (if any)
    PlatformFile? pickedPdf;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add Resource to "$sectionTitle"'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle between Video and PDF using radio buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<String>(
                        value: "Video",
                        groupValue: resourceType,
                        onChanged: (value) {
                          setState(() {
                            resourceType = value!;
                            // Clear PDF selection when switching to Video
                            pickedPdf = null;
                            _urlController.clear();
                          });
                        },
                      ),
                      const Text("Video"),
                      const SizedBox(width: 20),
                      Radio<String>(
                        value: "PDF",
                        groupValue: resourceType,
                        onChanged: (value) {
                          setState(() {
                            resourceType = value!;
                            // Clear URL when switching to PDF
                            _urlController.clear();
                          });
                        },
                      ),
                      const Text("PDF"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Common: Resource title text field
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: resourceType == "Video"
                          ? 'Video Title'
                          : 'PDF Title',
                      hintText: 'Enter ${resourceType.toLowerCase()} title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: resourceType == "Video"
                          ? Icon(Icons.video_library)
                          : Icon(Icons.picture_as_pdf),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // For Video, show a text field to enter URL.
                  // For PDF, show a button to pick the file.
                  if (resourceType == "Video")
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'Video URL',
                        hintText: 'Enter valid YouTube URL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.link),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Use file_picker to pick a PDF file.
                            FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                            );
                            if (result != null && result.files.isNotEmpty) {
                              setState(() {
                                pickedPdf = result.files.first;
                                // Optionally, update the URL field to show the file name.
                                _urlController.text = pickedPdf!.name;
                              });
                            }
                          },
                          icon: Icon(Icons.folder),
                          label: Text('Pick PDF from Gallery'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                        ),
                        if (pickedPdf != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Selected File: ${pickedPdf!.name}',
                              style: TextStyle(
                                  fontSize: 14, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
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
                onPressed: () async {
                  String title = _titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a resource title'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (resourceType == "Video") {
                    String url = _urlController.text.trim();
                    if (url.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a video URL'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    // Validate YouTube URL.
                    String? videoId = YoutubePlayer.convertUrlToId(url);
                    if (videoId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid YouTube video URL'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    await Provider.of<CourseProvider>(context, listen: false)
                        .addVideoToSection(
                        courseId, sectionTitle, Video(title: title, videoUrl: url));
                  } else {
                    // For PDF, ensure a file was picked.
                    if (pickedPdf == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please pick a PDF file'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    // Create a File instance from the picked file's path.
                    File pdfFile = File(pickedPdf!.path!);
                    // Upload the PDF using the provider's uploadPdf method.
                    String? uploadedPdfUrl =
                    await Provider.of<CourseProvider>(context, listen: false)
                        .uploadPdf(pdfFile);
                    if (uploadedPdfUrl != null) {
                      await Provider.of<CourseProvider>(context, listen: false)
                          .addPdfToSection(courseId, sectionTitle, title, uploadedPdfUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to upload PDF'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  }
                  Navigator.pop(context);
                  await _initializeCourse();
                },
                child: const Text('Add Resource'),
              ),
            ],
          );
        },
      ),
    );
  }
  /// NEW: Shows a dialog to edit a section's title.
  void _showEditSectionDialog(Section section, int sectionIndex) {
    final TextEditingController _sectionTitleController =
    TextEditingController(text: section.sectionTitle);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Section'),
          content: TextField(
            controller: _sectionTitleController,
            decoration: const InputDecoration(
                labelText: 'Section Title',
                hintText: 'Enter new section title'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (_sectionTitleController.text.isNotEmpty) {
                  setState(() => isActionLoading = true); // Start loading
                  final courseProvider =
                  Provider.of<CourseProvider>(context, listen: false);
                  await courseProvider.editSection(
                      widget.courseId,
                      section.sectionTitle ?? '',
                      _sectionTitleController.text);
                  setState(() => isActionLoading = false); // End loading
                  Navigator.pop(context);

                  // Refresh course data
                  await _initializeCourse();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please enter a section title')));
                }
              },
              child: isActionLoading
                  ? SpinKitDoubleBounce(color: Colors.white)
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// NEW: Shows a confirmation dialog before deleting a section.
  void _confirmDeleteSection(int sectionIndex, Section section) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Section'),
          content:
          const Text('Are you sure you want to delete this section?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                setState(() => isActionLoading = true); // Start loading
                await Provider.of<CourseProvider>(context, listen: false)
                    .deleteSection(widget.courseId, section.sectionTitle ?? '');
                setState(() => isActionLoading = false); // End loading
                Navigator.of(context).pop(); // Close the dialog

                // Refresh course data
                await _initializeCourse();
              },
              child: isActionLoading
                  ? SpinKitDoubleBounce(color: Colors.white, size: 20)
                  : const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  /// Deletes a specific video from a course section.
  void _deleteVideo(String courseId, String sectionTitle, int videoIndex) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Video'),
          content: const Text('Are you sure you want to delete this video?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        isActionLoading = true;
      });

      try {
        final courseProvider =
        Provider.of<CourseProvider>(context, listen: false);
        await courseProvider.deleteVideo(courseId, sectionTitle, videoIndex);

        setState(() {
          isActionLoading = false;
        });

        await _initializeCourse();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Video deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print("Error deleting video: $e");
        setState(() {
          isActionLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete video. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Shows a dialog to edit a video's details.
  void _showEditVideoDialog(String sectionTitle, Video video, int videoIndex) {
    final TextEditingController _titleController =
    TextEditingController(text: video.title);
    final TextEditingController _urlController =
    TextEditingController(text: video.videoUrl);
    bool _isUpdating = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Video'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Video Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Video URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: _isUpdating
                  ? null
                  : () async {
                String newTitle = _titleController.text.trim();
                String newUrl = _urlController.text.trim();

                if (newTitle.isEmpty || newUrl.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please fill out both title and URL.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Validate YouTube URL
                String? videoId =
                YoutubePlayer.convertUrlToId(newUrl);
                if (videoId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please enter a valid YouTube video URL.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                setState(() {
                  _isUpdating = true;
                });

                try {
                  final courseProvider =
                  Provider.of<CourseProvider>(context, listen: false);
                  await courseProvider.updateVideo(
                      _course!.id!,
                      sectionTitle,
                      videoIndex,
                      newTitle,
                      newUrl);

                  setState(() {
                    _isUpdating = false;
                  });

                  Navigator.pop(context);
                  await _initializeCourse();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print("Error updating video: $e");
                  setState(() {
                    _isUpdating = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update video. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: _isUpdating
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.blueAccent,
                  strokeWidth: 2.0,
                ),
              )
                  : const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Initializes the YouTube player with the given video URL.
  void _initializeYoutubePlayer(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) return;

    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId != null && _youtubeController == null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          isLive: false,
        ),
      );
    } else if (videoId != null && _youtubeController != null) {
      _youtubeController!.load(videoId);
    } else {
      print("Invalid video URL");
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _tabController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  /// Enrolls the current user in the course.
  Future<void> _enrollUser() async {
    final courseProvider =
    Provider.of<CourseProvider>(context, listen: false);
    final authProvider =
    Provider.of<AuthService>(context, listen: false);
    final CustomUser? currentUser = await authProvider.getCurrentUser();

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must be logged in to enroll.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isActionLoading = true;
    });

    bool success =
    await courseProvider.enrollInCourse(_course!.id!, currentUser.id!);

    setState(() {
      isActionLoading = false;
      if (success) {
        isEnrolled = true;
        _tabController.dispose();
        _tabController = TabController(
          length: (isEnrolled || isAdmin) ? 3 : 2,
          vsync: this,
        );
      }
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully enrolled in the course!'),
          backgroundColor: Colors.green,
        ),
      );

      if (_course!.sections.isNotEmpty &&
          _course!.sections.first.videos.isNotEmpty) {
        _initializeYoutubePlayer(
            _course!.sections.first.videos.first.videoUrl);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to enroll. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Unenrolls the current user from the course.
  Future<void> _unenrollUser() async {
    final courseProvider =
    Provider.of<CourseProvider>(context, listen: false);
    final authProvider =
    Provider.of<AuthService>(context, listen: false);
    final CustomUser? currentUser = await authProvider.getCurrentUser();

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must be logged in to unenroll.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isActionLoading = true;
    });

    bool success =
    await courseProvider.unenrollFromCourse(_course!.id!, currentUser.id!);

    setState(() {
      isActionLoading = false;
      if (success) {
        isEnrolled = false;
        _tabController.dispose();
        _tabController = TabController(
          length: (isEnrolled || isAdmin) ? 3 : 2,
          vsync: this,
        );
      }
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully unenrolled from the course.'),
          backgroundColor: Colors.green,
        ),
      );
      _youtubeController?.dispose();
      _youtubeController = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unenroll. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Shows a confirmation dialog before enrolling.
  void _confirmEnroll() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enroll in Course'),
          content: Text('Are you sure you want to enroll in this course?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _enrollUser();
              },
              child: isActionLoading
                  ? SpinKitDoubleBounce(color: Colors.white, size: 20)
                  : Text('Enroll'),
            ),
          ],
        );
      },
    );
  }

  /// Shows a confirmation dialog before unenrolling.
  void _confirmUnenroll() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unenroll from Course'),
          content: Text('Are you sure you want to unenroll from this course?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _unenrollUser();
              },
              child: isActionLoading
                  ? SpinKitDoubleBounce(color: Colors.white, size: 20)
                  : Text('Unenroll'),
            ),
          ],
        );
      },
    );
  }

  /// Shows a confirmation dialog before deleting a course.
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text(
            'Are you sure you want to delete this course? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    ) ??
        false;
  }

  /// Shows a dialog to add a new section.
  void _showAddSectionDialog(BuildContext context) {
    final _sectionTitleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Section'),
          content: TextField(
            controller: _sectionTitleController,
            decoration: const InputDecoration(
                labelText: 'Section Title',
                hintText: 'Enter section title'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (_sectionTitleController.text.isNotEmpty) {
                  setState(() => isActionLoading = true);
                  final courseProvider =
                  Provider.of<CourseProvider>(context, listen: false);
                  await courseProvider.addSection(
                      widget.courseId, _sectionTitleController.text);
                  setState(() => isActionLoading = false);
                  Navigator.pop(context);
                  await _initializeCourse();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Please enter a section title')));
                }
              },
              child: isActionLoading
                  ? SpinKitDoubleBounce(color: Colors.white)
                  : const Text('Add Section'),
            ),
          ],
        ),
      ),
    );
  }

  /// NEW: Shows a dialog to add a resource (Video or PDF) to a section.

  /// Builds the Overview tab content.
  Widget _buildOverview(Course course) {
    final String adminPhoneNumber = course.medium == 'Tamil'?
        "+94757439885" : "+94766224999"; // Replace with the actual admin phone number

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Course Overview',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple[800],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple[300]!, Colors.deepPurple[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Instructor: ${course.instructor ?? "N/A"}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Course Description',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    course.description ?? 'No description available.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: Colors.white70,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Course Medium',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    course.medium ?? 'No medium specified',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: Colors.white70,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\RS:${course.price} per month',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            course.duration ?? 'Duration not specified',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rating: ${course.averageRating?.toStringAsFixed(1) ?? 'N/A'} / 5',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (course.averageRating != null)
                            RatingBarIndicator(
                              rating: course.averageRating!,
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 18.0,
                              direction: Axis.horizontal,
                            )
                          else
                            const Text(
                              'No Ratings Yet',
                              style: TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Request Admin for Enrollment',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple[50],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Contact',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple[800],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.deepPurple),
                    const SizedBox(width: 12),
                    Text(
                      adminPhoneNumber,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.deepPurple[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final Uri phoneUri =
                          Uri(scheme: 'tel', path: adminPhoneNumber);
                          if (await canLaunchUrl(phoneUri)) {
                            await launchUrl(phoneUri);
                          } else {
                            _showErrorSnackbar('Could not launch phone dialer.');
                          }
                        },
                        icon: const Icon(Icons.call),
                        label: const Text('Call Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Remove the '+' from the admin phone number for WhatsApp URL formatting.
                          final String whatsappNumber = adminPhoneNumber.replaceAll('+', '');
                          final String message =
                              'I want to enroll in the course ${_course!.courseTitle ?? 'Unknown'}. The Instructor Of the Course is ${_course!.instructor ?? "Unknown"}';
                          final Uri whatsappUrl = Uri.parse(
                              "https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}");
                          if (await canLaunchUrl(whatsappUrl)) {
                            await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                          } else {
                            _showErrorSnackbar('Could not launch WhatsApp.');
                          }
                        },
                        icon: const Icon(Icons.message),
                        label: const Text('Message Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// Helper method to show error SnackBar.
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Builds the Lessons (Sections) tab content.
  Widget _buildSectionsList(Course course) {
    if (course.sections.isEmpty) {
      return Center(
        child: isAdmin
            ? TextButton(
          onPressed: () => _showAddSectionDialog(context),
          child: Text('Add Sections'),
        )
            : Text('No sections available.'),
      );
    }

    return ListView.builder(
      itemCount: course.sections.length,
      itemBuilder: (context, index) {
        final section = course.sections[index];
        return _buildSectionCard(section, index, course.id!);
      },
    );
  }

  /// Builds individual section cards with expandable content.
  Widget _buildSectionCard(Section section, int sectionIndex, String courseId) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0)),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              section.sectionTitle ?? 'Untitled Section',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (isAdmin)
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () =>
                        _showEditSectionDialog(section, sectionIndex),
                    tooltip: 'Edit Section',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () =>
                        _confirmDeleteSection(sectionIndex, section),
                    tooltip: 'Delete Section',
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

              bool isFirstVideo = sectionIndex == 0 && videoIndex == 0;
              bool canAccessVideo = isFirstVideo || isEnrolled || isAdmin;

              return ListTile(
                leading: Icon(
                  isFirstVideo ? Icons.lock_open : Icons.lock,
                  color: isFirstVideo
                      ? Colors.green
                      : (canAccessVideo ? Colors.blueAccent : Colors.redAccent),
                ),
                title: Text(video.title ?? 'Untitled Video'),
                subtitle: Text(isFirstVideo
                    ? 'Free Preview'
                    : (canAccessVideo ? 'Available to Play' : 'Enroll to Play')),
                onTap: () {
                  if (canAccessVideo) {
                    _playVideo(video.videoUrl ?? '', sectionIndex, videoIndex);
                  } else {
                    _showEnrollPrompt();
                  }
                },
                trailing: isAdmin
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () => _showEditVideoDialog(
                          section.sectionTitle!, video, videoIndex),
                      tooltip: 'Edit Video',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteVideo(
                          widget.courseId,
                          section.sectionTitle ?? '',
                          videoIndex),
                      tooltip: 'Delete Video',
                    ),
                  ],
                )
                    : null,
              );
            }).toList()

          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text('No videos available')),
            ),
          if (isAdmin)
            TextButton.icon(
              onPressed: () =>
                  _showAddResourceDialog(widget.courseId, section.sectionTitle ?? ''),
              icon: Icon(Icons.add, color: Colors.teal),
              label: Text('Add Resource'),
            ),
          // List of PDFs
          if (section.pdfs.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: section.pdfs.length,
              itemBuilder: (context, pdfIndex) {
                final pdf = section.pdfs[pdfIndex];
                return ListTile(
                  title: Text(
                    pdf.title ?? "Untitled PDF",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading: Icon(Icons.picture_as_pdf, color: Colors.redAccent),
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
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await Provider.of<CourseProvider>(context, listen: false)
                          .deletePdfFromSection(courseId, section.sectionTitle!, pdfIndex);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('PDF deleted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                );
              },
            )
          else
            ListTile(title: Text('No PDFs available.')),
        ],
      ),
    );
  }

  /// Shows a prompt to enroll when trying to access restricted videos.
  void _showEnrollPrompt() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enroll to Access'),
          content: Text('You need to enroll in this course to access this video.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmEnroll();
              },
              child: Text('Enroll Now'),
            ),
          ],
        );
      },
    );
  }

  /// Plays the selected video using the YouTube player.
  void _playVideo(String videoUrl, int sectionIndex, int videoIndex) {
    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId != null) {
      setState(() {
        if (_youtubeController != null) {
          _youtubeController!.load(videoId);
        } else {
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
              enableCaption: true,
              isLive: false,
              showLiveFullscreenButton: true
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid video URL.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Shows a dialog to edit the course details.
  void _showEditCourseDialog(BuildContext context, Course course) {
    final TextEditingController titleController =
    TextEditingController(text: course.courseTitle);
    final TextEditingController descriptionController =
    TextEditingController(text: course.description);
    final TextEditingController priceController =
    TextEditingController(text: course.price.toString());
    final TextEditingController subjectController =
    TextEditingController(text: course.subject);
    final TextEditingController mediumController =
    TextEditingController(text: course.medium);


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
                  decoration: const InputDecoration(
                    labelText: 'Course Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Course Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Course Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mediumController,
                  decoration: const InputDecoration(
                    labelText: 'Medium',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    priceController.text.isNotEmpty) {
                  setState(() {
                    isActionLoading = true;
                  });

                  final updatedCourse = Course(
                    id: course.id,
                    courseTitle: titleController.text,
                    description: descriptionController.text,
                    price: double.tryParse(priceController.text) ?? course.price,
                    subject: subjectController.text,
                    duration: course.duration,
                    instructor: course.instructor,
                    averageRating: course.averageRating,
                    enrolledUserIds: course.enrolledUserIds,
                    sections: course.sections,
                    feedbacks: course.feedbacks,
                    medium: course.medium
                  );

                  await Provider.of<CourseProvider>(context, listen: false)
                      .updateCourse(updatedCourse);

                  setState(() {
                    isActionLoading = false;
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Course updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  await _initializeCourse();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please fill out all fields')));
                }
              },
              child: isActionLoading
                  ? SpinKitDoubleBounce(color: Colors.white)
                  : const Text('Save'),
            ),
          ],
        );
      },
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
        title: const Text('Add Feedback'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _feedbackController,
                  decoration: const InputDecoration(
                    labelText: 'Your Feedback',
                    hintText: 'Enter your thoughts...',
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
                const SizedBox(height: 12),
                Text(
                  'Rate this course:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 5),
                RatingBar.builder(
                  initialRating: _currentRating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding:
                  const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final courseProvider =
                Provider.of<CourseProvider>(context, listen: false);
                final authProvider =
                Provider.of<AuthService>(context, listen: false);
                final CustomUser? currentUser =
                await authProvider.getCurrentUser();

                if (currentUser == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You must be logged in to submit feedback.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                bool hasFeedback = _course!.feedbacks.any(
                        (fb) => fb.userId.toString() == currentUser.id);
                if (hasFeedback) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have already submitted feedback.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  Navigator.pop(context);
                  return;
                }

                setState(() {
                  _isSubmitting = true;
                });

                final result = await _addFeedback(
                  courseId,
                  currentUser.name ?? 'Anonymous',
                  _feedbackController.text,
                  currentUser.id!,
                  _currentRating,
                );

                _feedbackController.clear();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result
                          ? 'Feedback submitted successfully!'
                          : 'Failed to submit feedback. Please try again.',
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor:
                    result ? Colors.green : Colors.red,
                  ),
                );

                setState(() {
                  _isSubmitting = false;
                });

                await _initializeCourse();
              }
            },
            child: _isSubmitting
                ? const SpinKitDoubleBounce(
              color: Colors.white,
              size: 20.0,
            )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }

  /// Adds feedback to the course.
  Future<bool> _addFeedback(
      String courseId,
      String userName,
      String feedbackText,
      String userId,
      double rating,
      ) async {
    try {
      final courseProvider =
      Provider.of<CourseProvider>(context, listen: false);
      bool hasFeedback = _course!.feedbacks
          .any((fb) => fb.userId.toString() == userId);
      if (hasFeedback) {
        return false;
      }
      await courseProvider.addFeedback(
          courseId, userId, feedbackText, userName, rating);
      return true;
    } catch (e) {
      print("Error adding feedback: $e");
      return false;
    }
  }

  /// Builds the Feedbacks tab content.
  Widget _buildFeedbackTab(BuildContext context) {
    return FutureBuilder<CustomUser?>(
      future:
      Provider.of<AuthService>(context, listen: false).getCurrentUser(),
      builder:
          (BuildContext context, AsyncSnapshot<CustomUser?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitDoubleBounce(color: Colors.blueAccent),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No user data available'));
        } else {
          final currentUser = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Average Rating: ${_course!.averageRating?.toStringAsFixed(1) ?? 'N/A'} / 5',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_course!.averageRating != null)
                RatingBarIndicator(
                  rating: _course!.averageRating!,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 24.0,
                  direction: Axis.horizontal,
                )
              else
                const Text(
                  'No Ratings Yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 10),
              if ((isEnrolled || isAdmin) &&
                  !_course!.feedbacks.any((fb) => fb.userId.toString() == currentUser.id))
                _buildFeedbackForm(currentUser),
              const SizedBox(height: 10),
              Text(
                'Feedbacks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              ..._course!.feedbacks
                  .map((fb) => _buildFeedbackCard(fb, currentUser))
                  .toList(),
            ],
          );
        }
      },
    );
  }

  /// Builds individual feedback cards.
  Widget _buildFeedbackCard(FeedBack feedback, CustomUser currentUser) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(feedback.userId.toString())
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: Text('Error fetching user')),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: Text('User data not available')),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? 'Unknown User';
        final userProfileImageUrl = userData?['profileImageUrl'];
        final isOwnerOrAdmin = feedback.userId.toString() == currentUser.id || isAdmin;
        final formattedDate =
        DateFormat('yMMMd').format(feedback.date!.toDate());
        final isCurrentUserFeedback = feedback.userId.toString() == currentUser.id;

        return Card(
          margin: const EdgeInsets.symmetric(
              vertical: 8.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0)),
          elevation: 3,
          color: isCurrentUserFeedback
              ? Colors.lightBlue.shade50
              : Colors.white,
          child: Column(
            children: [
              ListTile(
                leading: CachedNetworkImage(
                  imageUrl: userProfileImageUrl ??
                      "https://via.placeholder.com/150",
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    backgroundImage: imageProvider,
                  ),
                  placeholder: (context, url) => const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: SpinKitDoubleBounce(
                        color: Colors.blueAccent, size: 20.0),
                  ),
                  errorWidget: (context, url, error) => const CircleAvatar(
                    backgroundImage:
                    AssetImage('assets/images/placeholder.png'),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        feedback.feedback ?? 'No feedback provided.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (feedback.rating != null)
                      RatingBarIndicator(
                        rating: feedback.rating!,
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 16.0,
                        direction: Axis.horizontal,
                      )
                    else
                      const Text(
                        'No Rating',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
                subtitle:
                Text('Posted by $userName on $formattedDate'),
                trailing: isOwnerOrAdmin
                    ? PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditFeedbackDialog(feedback, userName);
                    } else if (value == 'delete') {
                      _deleteFeedback(_course!.id!, feedback);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                )
                    : null,
              ),
              const Divider(),
            ],
          ),
        );
      },
    );
  }

  /// Shows a dialog to edit existing feedback.
  void _showEditFeedbackDialog(FeedBack feedback, String userName) {
    final TextEditingController _feedbackController =
    TextEditingController(text: feedback.feedback);
    double _currentRating = feedback.rating ?? 3.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Feedback'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _feedbackController,
                maxLines: 2,
                decoration:
                const InputDecoration(labelText: 'Your Feedback'),
              ),
              const SizedBox(height: 10),
              Text(
                'Rate this course:',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 5),
              RatingBar.builder(
                initialRating: _currentRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding:
                const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  _currentRating = rating;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (_feedbackController.text.isNotEmpty) {
                  setState(() {
                    _isSubmitting = true;
                  });

                  try {
                    await Provider.of<CourseProvider>(context, listen: false)
                        .updateFeedback(
                        _course!.id!,
                        feedback.userId.toString(),
                        _feedbackController.text,
                        _currentRating);

                    if (!mounted) return;

                    setState(() {
                      _isSubmitting = false;
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    await _initializeCourse();
                  } on FirebaseException catch (e) {
                    if (!mounted) return;

                    setState(() {
                      _isSubmitting = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update feedback: ${e.message}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;

                    setState(() {
                      _isSubmitting = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update feedback: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill out all fields')));
                }
              },
              child: _isSubmitting
                  ? const SpinKitDoubleBounce(color: Colors.white, size: 20)
                  : const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Deletes a specific feedback entry.
  void _deleteFeedback(String courseId, FeedBack feedback) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content:
          const Text('Are you sure you want to delete this feedback?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        _isSubmitting = true;
      });
      try {
        final courseProvider =
        Provider.of<CourseProvider>(context, listen: false);
        await courseProvider.deleteFeedback(
            courseId, feedback.userId.toString());

        setState(() {
          _isSubmitting = false;
        });

        await _initializeCourse();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Feedback deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print("Error deleting feedback: $e");
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete feedback. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Builds the feedback submission form.
  Widget _buildFeedbackForm(CustomUser user) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Your Feedback',
                hintText: 'Enter your thoughts...',
                prefixIcon: Icon(Icons.feedback, color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                ),
              ),
              maxLength: 150,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Text(
              'Rate this course:',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 5),
            RatingBar.builder(
              initialRating: _currentRating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _currentRating = rating;
                });
              },
            ),
            const SizedBox(height: 10),
            Text(
              '${_feedbackController.text.length}/150 characters',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
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
                    user.name ?? 'Anonymous',
                    _feedbackController.text,
                    user.id!,
                    _currentRating,
                  );
                  _feedbackController.clear();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result
                            ? 'Feedback submitted successfully!'
                            : 'Failed to submit feedback. Please try again.',
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor:
                      result ? Colors.green : Colors.red,
                    ),
                  );

                  setState(() {
                    _isSubmitting = false;
                  });

                  await _initializeCourse();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                          Text('Please fill out all fields')));
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
                backgroundColor:
                _isSubmitting ? Colors.grey : Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                elevation: 3,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.send, color: Colors.white),
                  SizedBox(width: 8),
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
    );
  }

  /// Builds the floating action button for adding feedback.
  FloatingActionButton? _buildFloatingActionButton() {
    return (isEnrolled || isAdmin)
        ? FloatingActionButton.extended(
      onPressed: () {
        _showAddFeedbackDialog(context, _course!.id ?? '');
      },
      icon: Icon(Icons.feedback),
      label: Text('Add Feedback'),
      backgroundColor: Colors.teal,
      tooltip: 'Add Feedback',
    )
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_course == null) {
      return SafeArea(child: SpinKitDoubleBounce(color: Colors.lightBlue));
    }
    return SafeArea(
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController ??
              YoutubePlayerController(
                initialVideoId: '',
                flags: const YoutubePlayerFlags(
                  autoPlay: false,
                  mute: false,
                  enableCaption: true,
                  isLive: false,
                ),
              ),
          showVideoProgressIndicator: true,
          onReady: () {
            if (_youtubeController == null &&
                _course!.sections.isNotEmpty &&
                _course!.sections.first.videos.isNotEmpty) {
              _initializeYoutubePlayer(
                  _course!.sections.first.videos.first.videoUrl);
            }
          },
          onEnded: (metaData) => print("Video has ended"),
        ),
        builder: (context, player) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_course!.courseTitle ?? 'Course Details'),
              backgroundColor: Colors.blueAccent,
              actions: [
                if (isAdmin)
                  IconButton(
                    icon: Icon(Icons.edit, semanticLabel: 'Edit Course'),
                    onPressed: () =>
                        _showEditCourseDialog(context, _course!),
                  ),
                if (isAdmin)
                  IconButton(
                    icon: Icon(Icons.delete, semanticLabel: 'Delete Course'),
                    onPressed: () async {
                      bool confirm =
                      await _showDeleteConfirmation(context);
                      if (confirm) {
                        await Provider.of<CourseProvider>(context,
                            listen: false)
                            .deleteCourse(_course!.id!);
                        Navigator.pop(context);
                      }
                    },
                  ),
                if (isAdmin)
                  IconButton(
                    icon: Icon(Icons.add, semanticLabel: 'Add Section'),
                    onPressed: () => _showAddSectionDialog(context),
                  ),
              ],
            ),
            body: Column(
              children: [
                if (_youtubeController != null && (isEnrolled || isAdmin))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: player,
                    ),
                  )
                else if (_course!.sections.isNotEmpty && _course!.sections.first.videos.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: YoutubePlayer(
                        controller: YoutubePlayerController(
                          initialVideoId: YoutubePlayer.convertUrlToId(
                              _course!.sections.first.videos.first.videoUrl!) ??
                              '',
                          flags: const YoutubePlayerFlags(
                            autoPlay: false,
                            mute: false,
                            enableCaption: true,
                            isLive: false,
                          ),
                        ),
                        showVideoProgressIndicator: true,
                        onReady: () => print("Player is ready"),
                        onEnded: (metaData) => print("Video has ended"),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    color: Colors.black12,
                    child: Center(
                      child: Text(
                        'No videos available.',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF3F51B5),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  tabs: (isEnrolled || isAdmin)
                      ? const [
                    Tab(text: "Overview"),
                    Tab(text: "Lessons"),
                    Tab(text: "Feedback"),
                  ]
                      : const [
                    Tab(text: "Overview"),
                    Tab(text: "Feedback"),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: (isEnrolled || isAdmin)
                        ? [
                      _buildOverview(_course!),
                      _buildSectionsList(_course!),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildFeedbackTab(context),
                      ),
                    ]
                        : [
                      _buildOverview(_course!),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildFeedbackTab(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: _buildFloatingActionButton(),
          );
        },
      ),
    );
  }

  /// Checks if the current user is an Admin.
  bool _isAdmin() {
    final authProvider =
    Provider.of<AuthService>(context, listen: false);
    return authProvider.user?.role == 'Admin';
  }
}
class PdfPreviewScreen extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const PdfPreviewScreen({Key? key, required this.pdfUrl, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            tooltip: 'Download PDF',
            onPressed: () async {
              final Uri uri = Uri.parse(pdfUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Unable to launch PDF URL'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: PDF().cachedFromUrl(
        pdfUrl,
        placeholder: (progress) => Center(child: Text('$progress %')),
        errorWidget: (error) => Center(child: Text('Error: $error')),
      ),
    );
  }
}