import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
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

  const CourseScreen({required this.courseId, Key? key}) : super(key: key);

  @override
  _CourseScreenState createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> with TickerProviderStateMixin {
  // Modern color palette
  final Color primaryColor = const Color(0xFF11261f); // Green
  final Color secondaryColor = const Color(0xFF123755); // Blue
  final Color accentColor = const Color(0xFF722626); // Maroon
  final Color backgroundColor = const Color(0xFFF8F9FA); // Light gray
  final Color cardColor = Colors.white;
  final Color textColor = const Color(0xFF202124); // Dark text
  final Color textSecondaryColor = const Color(0xFF5F6368); // Medium gray
  final Color errorColor = const Color(0xFF722626); // Maroon for errors
  final Color successColor = const Color(0xFF11261f); // Green for success

  // Status colors
  final Color freeStatusColor = const Color(0xFF11261f); // Green for free courses
  final Color premiumStatusColor = const Color(0xFF722626); // Maroon for premium
  final Color lockedContentColor = const Color(0xFF9E9E9E); // Gray for locked content

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
  bool isAdmin = false;
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
        // Check Enrollment
        isEnrolled = (currentUser.enrollments as List?)?.any((enrollment) {
          return enrollment.courseId == _course!.id;
        }) ?? false;

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
      _showErrorSnackbar('Failed to load course data: $e');
    }
  }
// Add these missing methods to the _CourseScreenState class

  void _showEditCourseDialog(BuildContext context, Course course) {
    final TextEditingController titleController = TextEditingController(text: course.courseTitle);
    final TextEditingController descriptionController = TextEditingController(text: course.description);
    final TextEditingController priceController = TextEditingController(text: course.price.toString());
    final TextEditingController subjectController = TextEditingController(text: course.subject);
    final TextEditingController mediumController = TextEditingController(text: course.medium);
    final TextEditingController durationController = TextEditingController(text: course.duration);
    String statusValue = course.status ?? 'premium';
    bool _isUpdating = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Course',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 20),

                    Text(
                      'Course Title',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryColor, width: 1),
                        ),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 16),

                    Text(
                      'Description',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryColor, width: 1),
                        ),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor,
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),

                    Text(
                      'Price (Rs.)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryColor, width: 1),
                        ),
                        contentPadding: EdgeInsets.all(16),
                        prefixIcon: Icon(Icons.currency_rupee, size: 18),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Subject',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondaryColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: subjectController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: backgroundColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: primaryColor, width: 1),
                                  ),
                                  contentPadding: EdgeInsets.all(16),
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Medium',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondaryColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: mediumController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: backgroundColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: primaryColor, width: 1),
                                  ),
                                  contentPadding: EdgeInsets.all(16),
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    Text(
                      'Duration',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: durationController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryColor, width: 1),
                        ),
                        contentPadding: EdgeInsets.all(16),
                        hintText: 'e.g., 12 weeks',
                        prefixIcon: Icon(Icons.access_time, size: 18),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 16),

                    Text(
                      'Course Type',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                'Free',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              value: "free",
                              groupValue: statusValue,
                              activeColor: freeStatusColor,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              dense: true,
                              onChanged: (value) {
                                setState(() {
                                  statusValue = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                'Premium',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              value: "premium",
                              groupValue: statusValue,
                              activeColor: premiumStatusColor,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              dense: true,
                              onChanged: (value) {
                                setState(() {
                                  statusValue = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.poppins(
                                color: textSecondaryColor,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textSecondaryColor,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isUpdating ? null : () async {
                              if (titleController.text.isNotEmpty &&
                                  descriptionController.text.isNotEmpty &&
                                  priceController.text.isNotEmpty) {
                                setState(() {
                                  _isUpdating = true;
                                });

                                try {
                                  final updatedCourse = Course(
                                    id: course.id,
                                    courseTitle: titleController.text,
                                    description: descriptionController.text,
                                    price: double.tryParse(priceController.text) ?? course.price,
                                    subject: subjectController.text,
                                    duration: durationController.text,
                                    instructor: course.instructor,
                                    averageRating: course.averageRating,
                                    enrolledUserIds: course.enrolledUserIds,
                                    sections: course.sections,
                                    feedbacks: course.feedbacks,
                                    medium: mediumController.text,
                                    status: statusValue,
                                  );

                                  await Provider.of<CourseProvider>(context, listen: false)
                                      .updateCourse(updatedCourse);

                                  Navigator.pop(context);
                                  _showSuccessSnackbar('Course updated successfully!');
                                  await _initializeCourse();
                                } catch (e) {
                                  _showErrorSnackbar('Failed to update course: $e');
                                } finally {
                                  setState(() {
                                    _isUpdating = false;
                                  });
                                }
                              } else {
                                _showErrorSnackbar('Please fill out all required fields');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor: Colors.grey.shade400,
                            ),
                            child: _isUpdating
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              'SAVE',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddSectionDialog(BuildContext context) {
    final TextEditingController _sectionTitleController = TextEditingController();
    bool _isAdding = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Section',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Section Title',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondaryColor,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _sectionTitleController,
                  decoration: InputDecoration(
                    hintText: 'Enter section title',
                    filled: true,
                    fillColor: backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor, width: 1),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.poppins(
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondaryColor,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAdding ? null : () async {
                          if (_sectionTitleController.text.isNotEmpty) {
                            setState(() {
                              _isAdding = true;
                            });

                            try {
                              final courseProvider = Provider.of<CourseProvider>(context, listen: false);
                              await courseProvider.addSection(widget.courseId, _sectionTitleController.text);

                              Navigator.pop(context);
                              _showSuccessSnackbar('Section added successfully!');
                              await _initializeCourse();
                            } catch (e) {
                              _showErrorSnackbar('Failed to add section: $e');
                            } finally {
                              setState(() {
                                _isAdding = false;
                              });
                            }
                          } else {
                            _showErrorSnackbar('Please enter a section title');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey.shade400,
                        ),
                        child: _isAdding
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'ADD',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditSectionDialog(Section section, int sectionIndex) {
    final TextEditingController _sectionTitleController = TextEditingController(text: section.sectionTitle);
    bool _isUpdating = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Section',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Section Title',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondaryColor,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _sectionTitleController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor, width: 1),
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.poppins(
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondaryColor,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : () async {
                          if (_sectionTitleController.text.isNotEmpty) {
                            setState(() {
                              _isUpdating = true;
                            });

                            try {
                              final courseProvider = Provider.of<CourseProvider>(context, listen: false);
                              await courseProvider.editSection(
                                  widget.courseId,
                                  section.sectionTitle ?? '',
                                  _sectionTitleController.text);

                              Navigator.pop(context);
                              _showSuccessSnackbar('Section updated successfully!');
                              await _initializeCourse();
                            } catch (e) {
                              _showErrorSnackbar('Failed to update section: $e');
                            } finally {
                              setState(() {
                                _isUpdating = false;
                              });
                            }
                          } else {
                            _showErrorSnackbar('Please enter a section title');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey.shade400,
                        ),
                        child: _isUpdating
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'SAVE',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteSection(int sectionIndex, Section section) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 40,
                    color: errorColor,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Delete Section',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete the "${section.sectionTitle}" section? This will remove all videos and resources in this section.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textSecondaryColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.poppins(
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondaryColor,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isActionLoading
                            ? null
                            : () async {
                          setState(() => isActionLoading = true);

                          try {
                            await Provider.of<CourseProvider>(context, listen: false)
                                .deleteSection(widget.courseId, section.sectionTitle ?? '');

                            Navigator.of(context).pop();
                            _showSuccessSnackbar('Section deleted successfully!');
                            await _initializeCourse();
                          } catch (e) {
                            _showErrorSnackbar('Failed to delete section: $e');
                          } finally {
                            setState(() => isActionLoading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: errorColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey.shade400,
                        ),
                        child: isActionLoading
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'DELETE',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
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

  void _deleteVideo(String courseId, String sectionTitle, int videoIndex) async {
    final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
      return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
            Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 40,
              color: errorColor,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Delete Video',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Are you sure you want to delete this video? This action cannot be undone.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textSecondaryColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Row(
              children: [
          Expanded(
          child: OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
    child: Text(
    'CANCEL',
    style: GoogleFonts.poppins(
    color: textSecondaryColor,
    fontWeight: FontWeight.w500,
    letterSpacing: 1,
    ),
    ),
    style: OutlinedButton.styleFrom(
    foregroundColor: textSecondaryColor,
    side: BorderSide(color: Colors.grey.shade300),
    padding: EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    ),
    ),
    ),
    ),
    SizedBox(width: 12),
    Expanded(
    child: ElevatedButton(
    onPressed: () => Navigator.of(context).pop(true),
    style: ElevatedButton.styleFrom(
    backgroundColor: errorColor,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    ),
    ),
    child: Text(
    'DELETE',
    style: GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
    ),
    ),),
    ),
              ],
          ),
                ],
            ),
          ),
      );
        },
    );

    if (shouldDelete == true) {
      setState(() {
        isActionLoading = true;
      });

      try {
        final courseProvider = Provider.of<CourseProvider>(context, listen: false);
        await courseProvider.deleteVideo(courseId, sectionTitle, videoIndex);

        setState(() {
          isActionLoading = false;
        });

        _showSuccessSnackbar('Video deleted successfully');
        await _initializeCourse();
      } catch (e) {
        setState(() {
          isActionLoading = false;
        });

        _showErrorSnackbar('Failed to delete video: $e');
      }
    }
  }

  void _showAddResourceDialog(String courseId, String sectionTitle) {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _urlController = TextEditingController();
    String resourceType = "Video"; // Default type is Video
    PlatformFile? pickedPdf; // Holds the picked PDF file if any
    bool _isAdding = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Resource',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Resource type selector
                    Text(
                      'Resource Type',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                'Video',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              value: "Video",
                              groupValue: resourceType,
                              activeColor: primaryColor,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              dense: true,
                              onChanged: (value) {
                                setState(() {
                                  resourceType = value!;
                                  pickedPdf = null;
                                  _urlController.clear();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text(
                                'PDF',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              value: "PDF",
                              groupValue: resourceType,
                              activeColor: secondaryColor,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              dense: true,
                              onChanged: (value) {
                                setState(() {
                                  resourceType = value!;
                                  _urlController.clear();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Resource title field
                    Text(
                      resourceType == "Video" ? 'Video Title' : 'PDF Title',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter title',
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryColor, width: 1),
                        ),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 20),

                    // URL field for Video or file picker for PDF
                    if (resourceType == "Video") ...[
                      Text(
                        'Video URL',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textSecondaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: 'Enter YouTube URL',
                          filled: true,
                          fillColor: backgroundColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: primaryColor, width: 1),
                          ),
                          contentPadding: EdgeInsets.all(16),
                          prefixIcon: Icon(Icons.link, size: 18),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'PDF File',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textSecondaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                            );
                            if (result != null && result.files.isNotEmpty) {
                              setState(() {
                                pickedPdf = result.files.first;
                                _urlController.text = pickedPdf!.name;
                              });
                            }
                          },
                          icon: Icon(Icons.file_upload_outlined, size: 18),
                          label: Text('SELECT PDF FILE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      if (pickedPdf != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: secondaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: secondaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.picture_as_pdf_outlined,
                                  color: secondaryColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selected file:',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: textSecondaryColor,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        pickedPdf!.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: textSecondaryColor,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      pickedPdf = null;
                                      _urlController.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.poppins(
                                color: textSecondaryColor,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textSecondaryColor,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isAdding ? null : () async {
                              String title = _titleController.text.trim();
                              if (title.isEmpty) {
                                _showErrorSnackbar('Please enter a resource title');
                                return;
                              }

                              setState(() {
                                _isAdding = true;
                              });

                              try {
                                if (resourceType == "Video") {
                                  String url = _urlController.text.trim();
                                  if (url.isEmpty) {
                                    _showErrorSnackbar('Please enter a video URL');
                                    setState(() {
                                      _isAdding = false;
                                    });
                                    return;
                                  }

                                  String? videoId = YoutubePlayer.convertUrlToId(url);
                                  if (videoId == null) {
                                    _showErrorSnackbar('Please enter a valid YouTube URL');
                                    setState(() {
                                      _isAdding = false;
                                    });
                                    return;
                                  }

                                  await Provider.of<CourseProvider>(context, listen: false)
                                      .addVideoToSection(courseId, sectionTitle, Video(title: title, videoUrl: url));
                                } else {
                                  if (pickedPdf == null) {
                                    _showErrorSnackbar('Please pick a PDF file');
                                    setState(() {
                                      _isAdding = false;
                                    });
                                    return;
                                  }

                                  File pdfFile = File(pickedPdf!.path!);
                                  String? uploadedPdfUrl = await Provider.of<CourseProvider>(context, listen: false)
                                      .uploadPdf(pdfFile);

                                  if (uploadedPdfUrl != null) {
                                    await Provider.of<CourseProvider>(context, listen: false)
                                        .addPdfToSection(courseId, sectionTitle, title, uploadedPdfUrl);
                                  } else {
                                    _showErrorSnackbar('Failed to upload PDF');
                                    setState(() {
                                      _isAdding = false;
                                    });
                                    return;
                                  }
                                }

                                Navigator.pop(context);
                                _showSuccessSnackbar('Resource added successfully!');
                                await _initializeCourse();
                              } catch (e) {
                                _showErrorSnackbar('Failed to add resource: $e');
                              } finally {
                                setState(() {
                                  _isAdding = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor: Colors.grey.shade400,
                            ),
                            child: _isAdding
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              'ADD',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
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
  String? extractYoutubeVideoId(String url) {
    // Try standard methods first
    String? videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) return videoId;

    // Manual parsing as fallback
    RegExp regExp = RegExp(
      r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );

    Match? match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 2) {
      return match.group(2);
    }

    return null;
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _tabController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    if (_course == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          title: Text(
            'Course Details',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: textSecondaryColor.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'Course not found',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'The requested course could not be loaded',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textSecondaryColor,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back),
                label: Text('BACK TO COURSES'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return YoutubePlayerBuilder(
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
        progressIndicatorColor: accentColor,
        progressColors: ProgressBarColors(
          playedColor: accentColor,
          handleColor: accentColor,
          bufferedColor: Colors.grey.shade300,
          backgroundColor: Colors.grey.shade100,
        ),
        onReady: () {
          if (_youtubeController == null &&
              _course!.sections.isNotEmpty &&
              _course!.sections.first.videos.isNotEmpty) {
            _initializeYoutubePlayer(_course!.sections.first.videos.first.videoUrl);
          }
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              // Header card with course info
              _buildCourseHeaderCard(),

              // Video player
              _buildVideoPlayer(player),

              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: primaryColor,
                  unselectedLabelColor: textSecondaryColor,
                  indicatorColor: primaryColor,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                  tabs: (isEnrolled || isAdmin)
                      ? const [
                    Tab(text: "OVERVIEW"),
                    Tab(text: "LESSONS"),
                    Tab(text: "FEEDBACK"),
                  ]
                      : const [
                    Tab(text: "OVERVIEW"),
                    Tab(text: "FEEDBACK"),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: (isEnrolled || isAdmin)
                      ? [
                    _buildOverview(_course!),
                    _buildSectionsList(_course!),
                    _buildFeedbackTab(context),
                  ]
                      : [
                    _buildOverview(_course!),
                    _buildFeedbackTab(context),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
        );
      },
    );
  }

  Widget _buildCourseHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course title
            Row(
              children: [
                Expanded(
                  child: Text(
                    _course!.courseTitle ?? 'Course Title',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_course!.status == 'free')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'FREE',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 8),

            // Instructor and rating
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
                SizedBox(width: 6),
                Text(
                  _course!.instructor ?? 'Instructor',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(width: 16),
                Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Colors.amber,
                ),
                SizedBox(width: 4),
                Text(
                  _course!.averageRating?.toStringAsFixed(1) ?? 'N/A',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  '(${_course!.feedbacks.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'Loading Course',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            SizedBox(height: 24),
            Text(
              'Loading course details...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textSecondaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait a moment',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textSecondaryColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryColor,
      elevation: 0,
      title: Text(
        'Course Details',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (isAdmin) ...[
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Edit Course',
            onPressed: () => _showEditCourseDialog(context, _course!),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Delete Course',
            onPressed: () async {
              bool confirm = await _showDeleteConfirmation(context);
              if (confirm) {
                await Provider.of<CourseProvider>(context, listen: false)
                    .deleteCourse(_course!.id!);
                Navigator.pop(context);
              }
            },
          ),
        ],
        IconButton(
          icon: Icon(Icons.share_outlined, color: Colors.white),
          tooltip: 'Share Course',
          onPressed: () {
            _showShareOptions();
          },
        ),
      ],
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Share this course',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.chat_bubble_outline, 'WhatsApp', Colors.green[700]!),
                _buildShareOption(Icons.messenger_outline, 'Messenger', secondaryColor),
                _buildShareOption(Icons.email_outlined, 'Email', accentColor),
                _buildShareOption(Icons.more_horiz, 'More', Colors.grey[700]!),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _showSuccessSnackbar('Sharing via $label');
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(Widget player) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _youtubeController != null
            ? player  // Always show player if controller is initialized
            : _course!.sections.isNotEmpty && _course!.sections.first.videos.isNotEmpty
            ? Stack(
          alignment: Alignment.center,
          children: [
            // Thumbnail or placeholder
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Icon(
                Icons.video_library_outlined,
                color: Colors.white.withOpacity(0.3),
                size: 64,
              ),
            ),
            // Play button for first video (available to everyone)
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: () {
                  _initializeYoutubePlayer(_course!.sections.first.videos.first.videoUrl);
                },
              ),
            ),
          ],
        )
            : Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow_outlined,
                  color: Colors.white.withOpacity(0.7),
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'No videos available',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverview(Course course) {
    final String adminPhoneNumber = course.medium == 'Tamil'
        ? "+94757439885"
        : "+94766224999";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course description card
          Card(
            elevation: 0,
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About This Course',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    course.description ?? 'No description available.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.6,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Course metadata card
          Card(
            elevation: 0,
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Course Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.language_outlined,
                    label: 'Medium',
                    value: course.medium ?? 'Not specified',
                  ),
                  Divider(height: 24, color: Colors.grey.shade200),
                  _buildInfoRow(
                    icon: Icons.access_time_outlined,
                    label: 'Duration',
                    value: course.duration ?? 'Not specified',
                  ),
                  Divider(height: 24, color: Colors.grey.shade200),
                  _buildInfoRow(
                    icon: Icons.category_outlined,
                    label: 'Subject',
                    value: course.subject ?? 'Not specified',
                  ),
                  Divider(height: 24, color: Colors.grey.shade200),
                  _buildInfoRow(
                    icon: Icons.money_outlined,
                    label: 'Price',
                    value: 'Rs. ${course.price!.toStringAsFixed(0)}',
                  ),
                  Divider(height: 24, color: Colors.grey.shade200),
                  _buildInfoRow(
                    icon: Icons.vpn_key_outlined,
                    label: 'Course Type',
                    value: course.status == 'free' ? 'Free' : 'Premium',
                    valueColor: course.status == 'free' ? freeStatusColor : premiumStatusColor,
                  ),
                ],
              ),
            ),
          ),

          // Ratings card
          Card(
            elevation: 0,
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildRatingSummary(course),
            ),
          ),

          // Enrollment section
          if (!isEnrolled && !isAdmin)
            _buildEnrollmentSection(course, adminPhoneNumber),

          // Enrolled actions section
          if (isEnrolled && !isAdmin)
            _buildEnrolledActions(),

          // Bottom padding
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 22,
            color: primaryColor,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondaryColor,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSummary(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Rating',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  course.averageRating?.toStringAsFixed(1) ?? 'N/A',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber[800],
                  ),
                ),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (course.averageRating != null) ...[
                    RatingBarIndicator(
                      rating: course.averageRating!,
                      itemBuilder: (context, _) => Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 24,
                      direction: Axis.horizontal,
                    ),
                    SizedBox(height: 8),
                  ],
                  Text(
                    '${course.feedbacks.length} ${course.feedbacks.length == 1 ? 'review' : 'reviews'}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (course.feedbacks.isNotEmpty) ...[
          SizedBox(height: 16),
          Text(
            'What students are saying',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                ...course.feedbacks.take(2).map((feedback) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.format_quote, color: primaryColor.withOpacity(0.5), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feedback.feedback ?? 'Great course!',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: textSecondaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                if (course.feedbacks.length > 2)
                  TextButton(
                    onPressed: () {
                      _tabController.animateTo((isEnrolled || isAdmin) ? 2 : 1);
                    },
                    child: Text(
                      'VIEW ALL REVIEWS',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEnrollmentSection(Course course, String adminPhoneNumber) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: course.status == 'free'
                ? freeStatusColor.withOpacity(0.3)
                : accentColor.withOpacity(0.3)
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enrollment Options',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),

            // Course type notice
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: course.status == 'free'
                    ? freeStatusColor.withOpacity(0.1)
                    : accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: course.status == 'free'
                          ? freeStatusColor.withOpacity(0.2)
                          : accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      course.status == 'free'
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      color: course.status == 'free'
                          ? freeStatusColor
                          : accentColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.status == 'free'
                              ? 'Free Course'
                              : 'Premium Course',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: course.status == 'free'
                                ? freeStatusColor
                                : accentColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          course.status == 'free'
                              ? 'This is a free course. You can enroll directly.'
                              : 'This is a premium course. Please contact admin to enroll.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Admin contact section
            Text(
              'Contact Admin',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.phone_outlined,
                          size: 20,
                          color: secondaryColor,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        adminPhoneNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final Uri phoneUri = Uri(scheme: 'tel', path: adminPhoneNumber);
                            if (await canLaunchUrl(phoneUri)) {
                              await launchUrl(phoneUri);
                            } else {
                              _showErrorSnackbar('Could not launch phone dialer.');
                            }
                          },
                          icon: Icon(Icons.call_outlined, size: 18),
                          label: Text('CALL'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            textStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final String whatsappNumber = adminPhoneNumber.replaceAll('+', '');
                            final String message =
                                'I want to enroll in the course ${_course!.courseTitle ?? 'Unknown'}. The Instructor is ${_course!.instructor ?? "Unknown"}';
                            final Uri whatsappUrl = Uri.parse("https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}");
                            if (await canLaunchUrl(whatsappUrl)) {
                              await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                            } else {
                              _showErrorSnackbar('Could not launch WhatsApp.');
                            }
                          },
                          icon: Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: Text('WHATSAPP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF25D366), // WhatsApp green
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            textStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Self-enroll button for free courses only
            if (course.status == 'free') ...[
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _confirmEnroll(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'ENROLL NOW',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledActions() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: successColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: successColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are enrolled in this course',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: successColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'You have full access to all course content',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to lessons tab
                      _tabController.animateTo(1);
                    },
                    icon: Icon(Icons.play_circle_outline_rounded, size: 18),
                    label: Text('START LEARNING'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _confirmUnenroll(),
                  icon: Icon(Icons.exit_to_app_outlined, size: 18),
                  label: Text('UNENROLL'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: errorColor,
                    side: BorderSide(color: errorColor),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionsList(Course course) {
    if (course.sections.isEmpty) {
      return Center(
        child: isAdmin
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_outlined,
                size: 48,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No sections available',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add sections to organize course content',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textSecondaryColor,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddSectionDialog(context),
              icon: Icon(Icons.add),
              label: Text('ADD SECTION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_outlined,
                size: 48,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No content available yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The instructor is still preparing course content',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: course.sections.length,
      itemBuilder: (context, index) {
        final section = course.sections[index];
        return _buildSectionCard(section, index, course.id!);
      },
    );
  }

  Widget _buildSectionCard(Section section, int sectionIndex, String courseId) {
    int totalItems = section.videos.length + section.pdfs.length;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.light(
            primary: primaryColor,
          ),
        ),
        child: ExpansionTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.folder_outlined,
              color: primaryColor,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.sectionTitle ?? 'Untitled Section',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (totalItems > 0)
                      Text(
                        '$totalItems ${totalItems == 1 ? 'item' : 'items'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (isAdmin) ...[
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 20, color: primaryColor),
                  onPressed: () => _showEditSectionDialog(section, sectionIndex),
                  tooltip: 'Edit Section',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: errorColor),
                  onPressed: () => _confirmDeleteSection(sectionIndex, section),
                  tooltip: 'Delete Section',
                ),
              ],
            ],
          ),
          children: [
            // Videos list
            if (section.videos.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: section.videos.length,
                itemBuilder: (context, videoIndex) {
                  Video video = section.videos[videoIndex];
                  bool isFirstVideo = sectionIndex == 0 && videoIndex == 0;
                  bool canAccessVideo = isFirstVideo || isEnrolled || isAdmin;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      color: isFirstVideo
                          ? accentColor.withOpacity(0.1)
                          : (canAccessVideo
                          ? Colors.white
                          : Colors.grey.shade100),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isFirstVideo
                                ? accentColor.withOpacity(0.2)
                                : (canAccessVideo
                                ? primaryColor.withOpacity(0.1)
                                : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isFirstVideo || canAccessVideo
                                ? Icons.play_circle_outline_rounded
                                : Icons.lock_outline_rounded,
                            color: isFirstVideo
                                ? accentColor
                                : (canAccessVideo ? primaryColor : lockedContentColor),
                            size: 24,
                          ),
                        ),
                        title: Text(
                          video.title ?? 'Untitled Video',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: canAccessVideo ? textColor : textSecondaryColor,
                          ),
                        ),
                        subtitle: Text(
                          isFirstVideo
                              ? 'Free Preview'
                              : (canAccessVideo ? 'Available' : 'Locked Content'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isFirstVideo
                                ? accentColor
                                : (canAccessVideo ? successColor : lockedContentColor),
                          ),
                        ),
                        trailing: isAdmin
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 20, color: errorColor),
                              onPressed: () => _deleteVideo(widget.courseId, section.sectionTitle ?? '', videoIndex),
                              tooltip: 'Delete Video',
                            ),
                          ],
                        )
                            : Icon(
                          Icons.play_arrow_rounded,
                          color: canAccessVideo ? primaryColor : Colors.grey.shade400,
                        ),
                        onTap: () {
                          if (canAccessVideo) {
                            _playVideo(video.videoUrl ?? '', sectionIndex, videoIndex);
                          } else {
                            _showEnrollPrompt();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),

            // PDFs list
            if (section.pdfs.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: section.pdfs.length,
                itemBuilder: (context, pdfIndex) {
                  final pdf = section.pdfs[pdfIndex];
                  bool canAccessPdf = isEnrolled || isAdmin;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      color: canAccessPdf ? Colors.white : Colors.grey.shade100,
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: canAccessPdf
                                ? secondaryColor.withOpacity(0.1)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            canAccessPdf
                                ? Icons.picture_as_pdf_outlined
                                : Icons.lock_outline_rounded,
                            color: canAccessPdf ? secondaryColor : lockedContentColor,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          pdf.title ?? "Untitled PDF",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: canAccessPdf ? textColor : textSecondaryColor,
                          ),
                        ),
                        subtitle: Text(
                          canAccessPdf ? 'PDF Document' : 'Locked Content',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: canAccessPdf ? secondaryColor : lockedContentColor,
                          ),
                        ),
                        trailing: isAdmin
                            ? IconButton(
                          icon: Icon(Icons.delete_outline, size: 20, color: errorColor),
                          onPressed: () async {
                            await Provider.of<CourseProvider>(context, listen: false)
                                .deletePdfFromSection(courseId, section.sectionTitle!, pdfIndex);
                            _showSuccessSnackbar('PDF deleted successfully!');
                            await _initializeCourse();
                          },
                          tooltip: 'Delete PDF',
                        )
                            : Icon(
                          canAccessPdf
                              ? Icons.arrow_forward_ios_rounded
                              : null,
                          size: 16,
                          color: canAccessPdf ? secondaryColor : Colors.transparent,
                        ),
                        onTap: () {
                          if (canAccessPdf) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfPreviewScreen(
                                  pdfUrl: pdf.pdfUrl!,
                                  title: pdf.title ?? "PDF Preview",
                                  greenColor: primaryColor,
                                  maroonColor: accentColor,
                                ),
                              ),
                            );
                          } else {
                            _showEnrollPrompt();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),

            // Add resource button for admin
            if (isAdmin)
              Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddResourceDialog(widget.courseId, section.sectionTitle ?? ''),
                  icon: Icon(Icons.add, size: 18),
                  label: Text('ADD RESOURCE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    textStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

            // Empty state for no content
            if (section.videos.isEmpty && section.pdfs.isEmpty)
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.source_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No content available in this section',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackTab(BuildContext context) {
    return FutureBuilder<CustomUser?>(
        future: Provider.of<AuthService>(context, listen: false).getCurrentUser(),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return Center(
    child: CircularProgressIndicator(
    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
    ),
    );
    } else if (snapshot.hasError) {
    return Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
    color: errorColor.withOpacity(0.1),
    shape: BoxShape.circle,
    ),
    child: Icon(
    Icons.error_outline_rounded,
    color: errorColor,
    size: 48,
    ),
    ),
    SizedBox(height: 24),
    Text(
    'Error loading user data',
    style: GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textColor,
    ),
    ),
    SizedBox(height: 8),
    Text(
    '${snapshot.error}',
    style: GoogleFonts.poppins(
    color: textSecondaryColor,
    fontSize: 14,
    ),
    textAlign: TextAlign.center,
    ),
    ],
    ),
    );
    } else if (!snapshot.hasData) {
    return Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
    color: primaryColor.withOpacity(0.1),
    shape: BoxShape.circle,
    ),
    child: Icon(
    Icons.person_off_outlined,
    color: primaryColor,
    size: 48,
    ),
    ),
    SizedBox(height: 24),
    Text(
    'Sign in required',
    style: GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textColor,
    ),
    ),
    SizedBox(height: 8),
    Text(
    'Please sign in to view and write reviews',
    style: GoogleFonts.poppins(
    color: textSecondaryColor,
    fontSize: 14,
    ),
    ),
    SizedBox(height: 24),
    ElevatedButton.icon(
    onPressed: () {
    // Navigate to sign in page
    _showErrorSnackbar('Please sign in to continue');
    },
    icon: Icon(Icons.login),
    label: Text('SIGN IN'),
    style: ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    ),
    elevation: 0,
    ),
    ),
    ],
    ),
    );
    }

    final currentUser = snapshot.data!;
    return ListView(
    padding: const EdgeInsets.all(16),
    children: [
    // Add feedback form (if eligible)
    if ((isEnrolled || isAdmin) &&
    !_course!.feedbacks.any((fb) => fb.userId.toString() == currentUser.id))
    _buildFeedbackForm(currentUser),

    SizedBox(height: 24),

    // Feedback list header
    Row(
    children: [
    Text(
    'Student Reviews',
    style: GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryColor,
    ),
    ),
    SizedBox(width: 8),
    Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
    color: primaryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
    '${_course!.feedbacks.length}',
    style: GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primaryColor,
    ),
    ),
    ),
    Spacer(),
    if (_course!.feedbacks.isNotEmpty)
    Text(
    'Sort by: Latest',
    style: GoogleFonts.poppins(
    fontSize: 14,
      color: textSecondaryColor,
    ),
    ),
    ],
    ),
      SizedBox(height: 16),

      // Feedback list
      if (_course!.feedbacks.isEmpty)
        _buildEmptyFeedbackState()
      else
        ..._course!.feedbacks.map((fb) => _buildFeedbackCard(fb, currentUser)).toList(),
    ],
    );
    },
    );
  }

  void _initializeYoutubePlayer(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) return;

    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId == null) {
      print("Invalid video URL");
      return;
    }

    setState(() {
      // Always create a new controller when initializing
      if (_youtubeController != null) {
        _youtubeController!.dispose();
      }

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,  // Set to true to auto-play when initialized
          mute: false,
          enableCaption: true,
          isLive: false,
        ),
      );
    });
  }

  void _playVideo(String videoUrl, int sectionIndex, int videoIndex) {
    // Check access control - allow first video for everyone
    bool isFirstVideo = sectionIndex == 0 && videoIndex == 0;
    bool canAccessVideo = isFirstVideo || isEnrolled || isAdmin;

    if (!canAccessVideo) {
      _showEnrollPrompt();
      return;
    }

    // Get video ID from URL
    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId == null) {
      _showErrorSnackbar('Invalid video URL');
      return;
    }

    // Initialize or update the controller
    setState(() {
      if (_youtubeController == null) {
        // Initialize a new controller if none exists
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: true,
            isLive: false,
          ),
        );
      } else {
        try {
          // Only try to load if controller is ready
          if (_youtubeController!.value.isReady) {
            _youtubeController!.load(videoId);
          } else {
            // If not ready, reinitialize the controller
            _youtubeController!.dispose();
            _youtubeController = YoutubePlayerController(
              initialVideoId: videoId,
              flags: const YoutubePlayerFlags(
                autoPlay: true,
                mute: false,
                enableCaption: true,
                isLive: false,
              ),
            );
          }
        } catch (e) {
          // Handle any errors by reinitializing
          print("Error playing video: $e");
          _youtubeController!.dispose();
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
              enableCaption: true,
              isLive: false,
            ),
          );
        }
      }
    });
  }

  Widget _buildFeedbackForm(CustomUser user) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Write a Review',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),

            // Rating selection
            Text(
              'Rate this course:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textSecondaryColor,
              ),
            ),
            SizedBox(height: 8),
            RatingBar.builder(
              initialRating: _currentRating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 30,
              unratedColor: Colors.amber.withOpacity(0.2),
              itemBuilder: (context, _) => Icon(
                Icons.star_rounded,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _currentRating = rating;
                });
              },
            ),
            SizedBox(height: 20),

            // Review text field
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: 'Share your experience with this course...',
                filled: true,
                fillColor: backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryColor, width: 1),
                ),
                contentPadding: EdgeInsets.all(16),
              ),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textColor,
              ),
              maxLines: 3,
              maxLength: 150,
            ),
            SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () async {
                  if (_feedbackController.text.trim().isEmpty) {
                    _showErrorSnackbar('Please enter your feedback');
                    return;
                  }

                  setState(() {
                    _isSubmitting = true;
                  });

                  final result = await _addFeedback(
                    _course!.id!,
                    user.name ?? 'Anonymous',
                    _feedbackController.text.trim(),
                    user.id!,
                    _currentRating,
                  );

                  setState(() {
                    _isSubmitting = false;
                  });

                  if (result) {
                    _feedbackController.clear();
                    _showSuccessSnackbar('Feedback submitted successfully!');
                    await _initializeCourse();
                  } else {
                    _showErrorSnackbar('Failed to submit feedback. Please try again.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                child: _isSubmitting
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'SUBMITTING...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                )
                    : Text(
                  'SUBMIT REVIEW',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeedbackState() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rate_review_outlined,
                size: 40,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'No reviews yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to share your experience with this course',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if ((isEnrolled || isAdmin))
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Scroll to top where the form is
                    // This requires a scrollController in real implementation
                  },
                  icon: Icon(Icons.edit_outlined),
                  label: Text('WRITE A REVIEW'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(FeedBack feedback, CustomUser currentUser) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(feedback.userId.toString()).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 0,
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Container(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? 'Anonymous User';
        final userProfileImageUrl = userData?['profileImageUrl'];
        final isOwnerOrAdmin = feedback.userId.toString() == currentUser.id || isAdmin;
        final formattedDate = feedback.date != null
            ? DateFormat('MMM d, yyyy').format(feedback.date!.toDate())
            : 'Unknown date';
        final isCurrentUserFeedback = feedback.userId.toString() == currentUser.id;

        return Card(
          elevation: 0,
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isCurrentUserFeedback
                  ? accentColor.withOpacity(0.3)
                  : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Review header with user info and rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: accentColor.withOpacity(0.1),
                      backgroundImage: userProfileImageUrl != null
                          ? CachedNetworkImageProvider(userProfileImageUrl)
                          : null,
                      child: userProfileImageUrl == null
                          ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                        style: GoogleFonts.poppins(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                          : null,
                    ),
                    SizedBox(width: 12),

                    // User name, date and rating
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                userName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              if (isCurrentUserFeedback) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'YOU',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: textSecondaryColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              RatingBarIndicator(
                                rating: feedback.rating ?? 0,
                                itemBuilder: (context, _) => Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                ),
                                itemCount: 5,
                                itemSize: 18,
                                unratedColor: Colors.amber.withOpacity(0.2),
                                direction: Axis.horizontal,
                              ),
                              SizedBox(width: 8),
                              Text(
                                feedback.rating?.toStringAsFixed(1) ?? 'N/A',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Review text
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 16, 0, 0),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      feedback.feedback ?? 'No comment provided.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.5,
                        color: textColor,
                      ),
                    ),
                  ),
                ),

                // Action buttons for owner or admin
                if (isOwnerOrAdmin)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showEditFeedbackDialog(feedback, userName),
                          icon: Icon(Icons.edit_outlined, size: 16),
                          label: Text('EDIT'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _deleteFeedback(_course!.id!, feedback),
                          icon: Icon(Icons.delete_outlined, size: 16),
                          label: Text('DELETE'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: errorColor,
                            side: BorderSide(color: errorColor),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Utility methods for the course screen
  Future<void> _enrollUser() async {
    // Check if course is free - only allow self-enrollment for free courses
    if (_course!.status != 'free') {
      _showErrorSnackbar('This is a premium course. Please contact the admin to enroll.');
      return;
    }

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final authProvider = Provider.of<AuthService>(context, listen: false);
    final CustomUser? currentUser = await authProvider.getCurrentUser();

    if (currentUser == null) {
      _showErrorSnackbar('You must be logged in to enroll');
      return;
    }

    setState(() {
      isActionLoading = true;
    });

    bool success = await courseProvider.enrollInCourse(_course!.id!, currentUser.id!);

    setState(() {
      isActionLoading = false;
      if (success) {
        isEnrolled = true;
        _tabController.dispose();
        _tabController = TabController(length: (isEnrolled || isAdmin) ? 3 : 2, vsync: this);
      }
    });

    if (success) {
      _showSuccessSnackbar('Successfully enrolled in the course!');
      if (_course!.sections.isNotEmpty && _course!.sections.first.videos.isNotEmpty) {
        _initializeYoutubePlayer(_course!.sections.first.videos.first.videoUrl);
      }
    } else {
      _showErrorSnackbar('Failed to enroll. Please try again.');
    }
  }

  Future<void> _unenrollUser() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final authProvider = Provider.of<AuthService>(context, listen: false);
    final CustomUser? currentUser = await authProvider.getCurrentUser();

    if (currentUser == null) {
      _showErrorSnackbar('You must be logged in to unenroll');
      return;
    }

    setState(() {
      isActionLoading = true;
    });

    bool success = await courseProvider.unenrollFromCourse(_course!.id!, currentUser.id!);

    setState(() {
      isActionLoading = false;
      if (success) {
        isEnrolled = false;
        _tabController.dispose();
        _tabController = TabController(length: (isEnrolled || isAdmin) ? 3 : 2, vsync: this);
      }
    });

    if (success) {
      _showSuccessSnackbar('Successfully unenrolled from the course');
      _youtubeController?.dispose();
      _youtubeController = null;
    } else {
      _showErrorSnackbar('Failed to unenroll. Please try again.');
    }
  }

  // Dialogs and confirmations
  void _showEnrollPrompt() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: accentColor,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Enroll to Access',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'You need to enroll in this course to access this content.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textSecondaryColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                if (_course!.status != 'free')
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: accentColor,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This is a premium course. Please contact admin to enroll.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.poppins(
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondaryColor,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    if (_course!.status == 'free')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _confirmEnroll();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'ENROLL NOW',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
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
  void _confirmEnroll() {
    // Check if course is free - only allow self-enrollment for free courses
    if (_course!.status != 'free') {
      _showErrorSnackbar('This is a premium course. Please contact the admin to enroll.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    size: 40,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Confirm Enrollment',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to enroll in this course?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textSecondaryColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.poppins(
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondaryColor,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isActionLoading
                            ? null
                            : () {
                          Navigator.of(context).pop();
                          _enrollUser();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey.shade400,
                        ),
                        child: isActionLoading
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'ENROLL',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
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

  void _confirmUnenroll() {
    showDialog(
        context: context,
        builder: (context) {
      return Dialog(
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: errorColor.withOpacity(0.1),
    shape: BoxShape.circle,
    ),
    child: Icon(
    Icons.exit_to_app_rounded,
    size: 40,
    color: errorColor,
    ),
    ),
    SizedBox(height: 20),
    Text(
    'Confirm Unenrollment',
    style: GoogleFonts.poppins(
    fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textColor,
    ),
      ),
          SizedBox(height: 16),
          Text(
          'Are you sure you want to unenroll from this course? You will lose access to all course content.',
          style: GoogleFonts.poppins(
          fontSize: 14,
          color: textSecondaryColor,
          height: 1.5,
          ),
          textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Row(
          children: [
          Expanded(
          child: OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
          'CANCEL',
          style: GoogleFonts.poppins(
          color: textSecondaryColor,
          fontWeight: FontWeight.w500,
          letterSpacing: 1,
          ),
          ),
          style: OutlinedButton.styleFrom(
          foregroundColor: textSecondaryColor,
          side: BorderSide(color: Colors.grey.shade300),
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          ),
          ),
          ),
          ),
          SizedBox(width: 12),
          Expanded(
          child: ElevatedButton(
          onPressed: isActionLoading
          ? null
              : () {
          Navigator.of(context).pop();
          _unenrollUser();
          },
          style: ElevatedButton.styleFrom(
          backgroundColor: errorColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          ),
          disabledBackgroundColor: Colors.grey.shade400,
          ),
          child: isActionLoading
          ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
          ),
          )
              : Text(
          'UNENROLL',
          style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          ),
          ),
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

  // Feedback related methods
  Future<bool> _addFeedback(
      String courseId,
      String userName,
      String feedbackText,
      String userId,
      double rating
      ) async {
    try {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      bool alreadySubmitted = _course!.feedbacks.any((fb) => fb.userId.toString() == userId);

      if (alreadySubmitted) return false;

      await courseProvider.addFeedback(courseId, userId, feedbackText, userName, rating);
      return true;
    } catch (e) {
      print("Error adding feedback: $e");
      return false;
    }
  }

  void _showEditFeedbackDialog(FeedBack feedback, String userName) {
    final TextEditingController _feedbackController = TextEditingController(text: feedback.feedback);
    double _localRating = feedback.rating ?? 3.0;
    bool _isUpdating = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Your Review',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Update your rating:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textSecondaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  RatingBar.builder(
                    initialRating: _localRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 28,
                    unratedColor: Colors.amber.withOpacity(0.2),
                    itemBuilder: (context, _) => Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      _localRating = rating;
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Update your feedback:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textSecondaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _feedbackController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primaryColor, width: 1),
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textColor,
                    ),
                    maxLines: 3,
                    maxLength: 150,
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'CANCEL',
                            style: GoogleFonts.poppins(
                              color: textSecondaryColor,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textSecondaryColor,
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isUpdating ? null : () async {
                            if (_feedbackController.text.trim().isEmpty) {
                              _showErrorSnackbar('Please enter your feedback');
                              return;
                            }

                            setState(() {
                              _isUpdating = true;
                            });

                            try {
                              await Provider.of<CourseProvider>(context, listen: false)
                                  .updateFeedback(
                                  _course!.id!,
                                  feedback.userId.toString(),
                                  _feedbackController.text.trim(),
                                  _localRating
                              );

                              Navigator.pop(context);
                              _showSuccessSnackbar('Feedback updated successfully!');
                              await _initializeCourse();
                            } catch (e) {
                              _showErrorSnackbar('Failed to update feedback: $e');
                            } finally {
                              setState(() {
                                _isUpdating = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            disabledBackgroundColor: Colors.grey.shade400,
                          ),
                          child: _isUpdating
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            'SAVE',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _deleteFeedback(String courseId, FeedBack feedback) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 40,
                    color: errorColor,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Delete Review',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to delete this review? This action cannot be undone.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textSecondaryColor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.poppins(
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondaryColor,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: errorColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'DELETE',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
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

    if (shouldDelete == true) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await Provider.of<CourseProvider>(context, listen: false)
            .deleteFeedback(_course!.id!, feedback.userId.toString());
        setState(() {
          _isSubmitting = false;
        });
        await _initializeCourse();
        _showSuccessSnackbar('Review deleted successfully');
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
        _showErrorSnackbar('Failed to delete review. Please try again.');
      }
    }
  }

  // Admin related methods
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 40,
                  color: errorColor,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Delete Course',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this course? This action cannot be undone.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textSecondaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.poppins(
                          color: textSecondaryColor,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondaryColor,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: errorColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'DELETE',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ?? false;
  }

  // Helper methods for floating action button and notifications
  Widget? _buildFloatingActionButton() {
    if (isAdmin) {
      return FloatingActionButton(
        onPressed: () => _showAddSectionDialog(context),
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 2,
        tooltip: 'Add Section',
        child: Icon(Icons.add_rounded),
      );
    }
    return null;
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// PDF Preview Screen with the updated style
class PdfPreviewScreen extends StatelessWidget {
  final String pdfUrl;
  final String title;
  final Color greenColor;
  final Color maroonColor;

  const PdfPreviewScreen({
    Key? key,
    required this.pdfUrl,
    required this.title,
    required this.greenColor,
    required this.maroonColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: greenColor,
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download_outlined, color: Colors.white),
            tooltip: 'Download PDF',
            onPressed: () async {
              final Uri uri = Uri.parse(pdfUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Unable to launch PDF URL',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: maroonColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: EdgeInsets.all(16),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, color: Colors.white),
            tooltip: 'Share PDF',
            onPressed: () {
              // Share functionality would go here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sharing PDF...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade200,
        child: PDF().cachedFromUrl(
          pdfUrl,
          placeholder: (progress) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(maroonColor),
                ),
                SizedBox(height: 16),
                Text(
                  '$progress %',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          errorWidget: (error) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red[700],
                    size: 48,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Error Loading PDF',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Error: $error',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back),
                  label: Text('GO BACK'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}