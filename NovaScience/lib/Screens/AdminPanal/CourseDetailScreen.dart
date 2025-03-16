import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Modals/User.dart';
import '../../Service/CourseNotificationService.dart';
import '../../Service/CourseProvider.dart';
import '../../Service/AuthService.dart';
import 'CMSAppBar.dart';
import 'CMSDesignSystem.dart';
import 'VideoPlayerScreen.dart';


class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

    return Theme(
      data: CMSTheme.lightTheme,
      child: Scaffold(
        body: Stack(
          children: [
            // Main content
            CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Tab bar for navigation between sections
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(
                              icon: Icon(Icons.info_outline_rounded),
                              text: 'Overview',
                            ),
                            Tab(
                              icon: Icon(Icons.people_outline_rounded),
                              text: 'Students',
                            ),
                            Tab(
                              icon: Icon(Icons.comment_rounded),
                              text: 'Feedback',
                            ),
                          ],
                          labelColor: CMSDesignSystem.primaryGreen,
                          unselectedLabelColor: CMSDesignSystem.textSecondary,
                          indicatorColor: CMSDesignSystem.primaryGreen,
                          indicatorWeight: 3,
                        ),
                      ),

                      // Content based on selected tab - FIX: Use SizedBox instead of Container with constraints
                      SizedBox(
                        height: MediaQuery.of(context).size.height - 300,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Overview Tab
                            _buildOverviewTab(context),

                            // Students Tab
                            _buildEnrolledStudentsTab(context, authService),

                            // Feedback Tab
                            _buildFeedbackTab(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(CMSDesignSystem.primaryBlue),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: CMSFloatingActionButton(
          onPressed: () {
            _showAddFeedbackDialog(context, widget.course.id ?? '');
          },
          icon: Icons.rate_review_rounded,
          label: 'Add Feedback',
        ),
      ),
    );
  }

  // Make sure each of your tab building methods return widgets with proper constraints

  /// Builds the overview tab content
  Widget _buildOverviewTab(BuildContext context) {
    // FIX: Return a widget with a defined size and use proper constraints
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(), // Ensure scrolling works
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course info card
          _buildCourseInfoCard(),
          SizedBox(height: 24),

          // Course description
          Text(
            'About this course',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CMSDesignSystem.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.course.description ?? 'No description available.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: CMSDesignSystem.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 24),

          // Course sections
          Text(
            'Course Content',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CMSDesignSystem.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          _buildSections(),
        ],
      ),
    );
  }

  /// Builds the enrolled students tab.
  Widget _buildEnrolledStudentsTab(BuildContext context, AuthService authService) {
    // FIX: Handle null values safely and make sure sizing is appropriate
    return FutureBuilder<List<CustomUser>>(
      future: authService.getUsersEnrolledInCourse(widget.course.id ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(CMSDesignSystem.primaryBlue),
            ),
          );
        }

        if (snapshot.hasError) {
          return CMSErrorState(
            message: 'Unable to load enrolled students: ${snapshot.error}',
            onRetry: () {
              setState(() {});
            },
          );
        }

        // FIX: Handle null data safely
        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return CMSEmptyState(
            icon: Icons.people_alt_rounded,
            title: 'No Students Enrolled',
            message: 'No students have enrolled in this course yet.',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: students.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final student = students[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: CMSAvatar(
                  imageUrl: student.profileImageUrl,
                  name: student.name ?? 'Student',
                  size: 50,
                ),
                title: Text(
                  student.name ?? 'Unnamed Student',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      student.email ?? 'No Email',
                      style: TextStyle(
                        fontSize: 14,
                        color: CMSDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.person_remove_rounded,
                    color: CMSDesignSystem.accentMaroon,
                  ),
                  tooltip: 'Unenroll Student',
                  onPressed: () {
                    _showUnenrollConfirmationDialog(context, student.id ?? '', student.name ?? 'this student');
                  },
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the feedback tab.
  Widget _buildFeedbackTab(BuildContext context) {
    // FIX: Make sure widget.course.feedbacks is safely accessed
    final feedbacks = widget.course.feedbacks ?? [];

    if (feedbacks.isEmpty) {
      return CMSEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No Feedback Yet',
        message: 'No one has provided feedback for this course yet.',
        actionButton: CMSButton(
          text: 'Add First Feedback',
          icon: Icons.add_comment_rounded,
          onPressed: () {
            _showAddFeedbackDialog(context, widget.course.id ?? '');
          },
          width: 220,
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: feedbacks.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final feedback = feedbacks[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CMSAvatar(
                    name: feedback.userName ?? 'Anonymous',
                    size: 40,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback.userName ?? 'Anonymous',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            RatingBarIndicator(
                              rating: feedback.rating ?? 0.0,
                              itemBuilder: (context, _) => Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 16.0,
                              direction: Axis.horizontal,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${feedback.rating?.toStringAsFixed(1) ?? "0.0"}',
                              style: TextStyle(
                                fontSize: 14,
                                color: CMSDesignSystem.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    feedback.date != null
                        ? DateFormat.yMMMd().format(feedback.date!.toDate())
                        : '',
                    style: TextStyle(
                      fontSize: 12,
                      color: CMSDesignSystem.textSecondary,
                    ),
                  ),
                ],
              ),
              if (feedback.feedback != null && feedback.feedback!.isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  feedback.feedback!,
                  style: TextStyle(
                    fontSize: 15,
                    color: CMSDesignSystem.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Builds a list showing sections with videos and PDFs
  Widget _buildSections() {
    // FIX: Ensure widget.course.sections is safely accessed
    final sections = widget.course.sections ?? [];

    if (sections.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.folder_off_rounded,
                size: 48,
                color: CMSDesignSystem.textSecondary.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'No sections available yet',
                style: TextStyle(
                  fontSize: 16,
                  color: CMSDesignSystem.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: sections.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CMSDesignSystem.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: CMSDesignSystem.primaryBlue,
                ),
              ),
              title: Text(
                section.sectionTitle ?? "Untitled Section",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CMSDesignSystem.textPrimary,
                ),
              ),
              subtitle: Text(
                '${section.videos?.length ?? 0} videos, ${section.pdfs?.length ?? 0} PDFs',
                style: TextStyle(
                  fontSize: 12,
                  color: CMSDesignSystem.textSecondary,
                ),
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              childrenPadding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              children: [
                // Videos section - safely handle null values
                if (section.videos != null && section.videos.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                    child: Text(
                      'Videos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CMSDesignSystem.primaryBlue,
                      ),
                    ),
                  ),
                  ...section.videos.map((video) => _buildVideoItem(video)).toList(),
                ],

                // PDFs section - safely handle null values
                if (section.pdfs != null && section.pdfs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                    child: Text(
                      'Resources',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CMSDesignSystem.accentMaroon,
                      ),
                    ),
                  ),
                  ...section.pdfs.map((pdf) => _buildPdfItem(pdf)).toList(),
                ],

                // Empty state if no content
                if ((section.videos == null || section.videos.isEmpty) &&
                    (section.pdfs == null || section.pdfs.isEmpty))
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No content in this section',
                        style: TextStyle(
                          fontSize: 14,
                          color: CMSDesignSystem.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds the sliver app bar with background image and course title.
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 16, bottom: 16, right: 72),
        title: Text(
          widget.course.courseTitle ?? 'Course Detail',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.5))],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Course image or placeholder
            (widget.course.imageUrl != null && widget.course.imageUrl!.isNotEmpty)
                ? CachedNetworkImage(
              imageUrl: widget.course.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: CMSDesignSystem.primaryGreen.withOpacity(0.2),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(CMSDesignSystem.primaryBlue),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: CMSDesignSystem.primaryGreen.withOpacity(0.2),
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    size: 80,
                    color: CMSDesignSystem.primaryGreen.withOpacity(0.5),
                  ),
                ),
              ),
            )
                : Container(
              color: CMSDesignSystem.primaryGreen.withOpacity(0.2),
              child: Center(
                child: Icon(
                  Icons.school_rounded,
                  size: 80,
                  color: CMSDesignSystem.primaryGreen.withOpacity(0.5),
                ),
              ),
            ),

            // Gradient overlay for better readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Status indicator (Free/Premium/Under Review)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.course.status != null
                      ? widget.course.status![0].toUpperCase() + widget.course.status!.substring(1)
                      : 'Unknown',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // Approval status if needed
            if (widget.course.isApproved == false)
              Positioned(
                top: 60,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CMSDesignSystem.accentMaroon.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Under Review',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        _buildAppBarActions(),
      ],
    );
  }
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => CMSConfirmationDialog(
        title: 'Delete Course',
        message: 'Are you sure you want to delete this course? This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: CMSDesignSystem.accentMaroon,
        icon: Icons.delete_forever_rounded,
        onCancel: () => Navigator.of(context).pop(false),
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    ) ?? false;
  }
  /// Returns the color associated with the course status.
  Color _getStatusColor() {
    if (widget.course.status == 'free') {
      return CMSDesignSystem.freeCourseColor;
    } else if (widget.course.status == 'Premium') {
      return CMSDesignSystem.premiumCourseColor;
    } else {
      return CMSDesignSystem.pendingCourseColor;
    }
  }

  /// Builds action buttons in the app bar.
  Widget _buildAppBarActions() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Colors.white),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            _showEditCourseDialog(context);
            break;
          case 'delete':
            bool confirm = await _showDeleteConfirmation(context);
            if (confirm) {
              setState(() => _isLoading = true);
              try {
                final courseProvider = Provider.of<CourseProvider>(context, listen: false);
                await courseProvider.deleteCourse(widget.course.id ?? '');
                Navigator.pop(context); // Navigate back after deletion
                showCMSToast(
                  context,
                  message: 'Course deleted successfully',
                  backgroundColor: CMSDesignSystem.accentMaroon,
                  icon: Icons.delete_rounded,
                );
              } catch (e) {
                showCMSToast(
                  context,
                  message: 'Error deleting course: ${e.toString()}',
                  backgroundColor: CMSDesignSystem.error,
                  icon: Icons.error_outline_rounded,
                );
              } finally {
                setState(() => _isLoading = false);
              }
            }
            break;
          case 'approve':
            setState(() => _isLoading = true);
            try {
              final courseProvider = Provider.of<CourseProvider>(context, listen: false);
              final updatedCourse = Course(
                id: widget.course.id,
                courseTitle: widget.course.courseTitle,
                description: widget.course.description,
                price: widget.course.price,
                subject: widget.course.subject,
                imageUrl: widget.course.imageUrl,
                status: widget.course.status,
                duration: widget.course.duration,
                instructor: widget.course.instructor,
                averageRating: widget.course.averageRating,
                enrolledUserIds: widget.course.enrolledUserIds,
                sections: widget.course.sections,
                feedbacks: widget.course.feedbacks,
                instructorEmail: widget.course.instructorEmail,
                medium: widget.course.medium,
                isApproved: true,
              );

              // First update the course to approved status
              await courseProvider.updateCourse(updatedCourse);

              // Then send notifications to all users
              final notificationService = CourseNotificationService();
              await notificationService.sendCourseApprovalNotifications(
                  courseId: widget.course.id ?? '',
                  courseTitle: widget.course.courseTitle ?? 'New Course',
                  instructorName: widget.course.instructor ?? 'Instructor',
                  instructorEmail: widget.course.instructorEmail ?? '',
                  subject: widget.course.subject ?? 'General',
                  medium: widget.course.medium ?? 'Unknown'
              );

              showCMSToast(
                context,
                message: 'Course approved successfully! All users notified.',
                backgroundColor: CMSDesignSystem.success,
                icon: Icons.check_circle_outline_rounded,
              );

              setState(() {}); // Refresh UI
            } catch (e) {
              showCMSToast(
                context,
                message: 'Error approving course: ${e.toString()}',
                backgroundColor: CMSDesignSystem.error,
                icon: Icons.error_outline_rounded,
              );
            } finally {
              setState(() => _isLoading = false);
            }
            break;
          case 'disapprove':
            setState(() => _isLoading = true);
            try {
              final courseProvider = Provider.of<CourseProvider>(context, listen: false);
              final updatedCourse = Course(
                id: widget.course.id,
                courseTitle: widget.course.courseTitle,
                description: widget.course.description,
                price: widget.course.price,
                subject: widget.course.subject,
                imageUrl: widget.course.imageUrl,
                status: widget.course.status,
                duration: widget.course.duration,
                instructor: widget.course.instructor,
                averageRating: widget.course.averageRating,
                enrolledUserIds: widget.course.enrolledUserIds,
                sections: widget.course.sections,
                feedbacks: widget.course.feedbacks,
                instructorEmail: widget.course.instructorEmail,
                medium: widget.course.medium,
                isApproved: false,
              );
              await courseProvider.updateCourse(updatedCourse);
              showCMSToast(
                context,
                message: 'Course set to review status',
                backgroundColor: CMSDesignSystem.warning,
                icon: Icons.warning_amber_rounded,
              );
              setState(() {});
            } catch (e) {
              showCMSToast(
                context,
                message: 'Error updating course status: ${e.toString()}',
                backgroundColor: CMSDesignSystem.error,
                icon: Icons.error_outline_rounded,
              );
            } finally {
              setState(() => _isLoading = false);
            }
            break;
          default:
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        // Build a list of menu items.
        final List<PopupMenuEntry<String>> items = [
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, color: CMSDesignSystem.primaryBlue, size: 20),
                SizedBox(width: 12),
                Text('Edit Course'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_rounded, color: CMSDesignSystem.accentMaroon, size: 20),
                SizedBox(width: 12),
                Text('Delete Course'),
              ],
            ),
          ),
        ];

        // Add approve/disapprove option based on current status
        items.add(
          PopupMenuItem<String>(
            value: widget.course.isApproved == true ? 'disapprove' : 'approve',
            child: Row(
              children: [
                Icon(
                  widget.course.isApproved == true
                      ? Icons.unpublished_rounded
                      : Icons.check_circle_rounded,
                  color: widget.course.isApproved == true
                      ? CMSDesignSystem.warning
                      : CMSDesignSystem.success,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(widget.course.isApproved == true
                    ? 'Set to Review'
                    : 'Approve Course'),
              ],
            ),
          ),
        );

        return items;
      },
    );
  }


  /// Sends notifications to all users when a course is approved

  /// Sends notifications to all users when a course is approved
  Future<void> _sendCourseApprovalNotifications({
    required String courseId,
    required String courseTitle,
    required String instructorName,
    required String subject,
    required String medium,
  }) async {
    try {
      // 1. Get all users
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

      // 2. Create a batch for efficient writes
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 3. Notification data
      final notificationData = {
        'title': 'New Course Available',
        'body': '$courseTitle by $instructorName is now available!',
        'data': {
          'courseId': courseId,
          'courseTitle': courseTitle,
          'instructorName': instructorName,
          'subject': subject,
          'medium': medium,
          'notificationType': 'courseApproved',
          'timestamp': FieldValue.serverTimestamp(),
        },
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // 4. Add notification to each user's notifications collection
      for (var userDoc in usersSnapshot.docs) {
        // Skip sending notification to the course creator
        if (userDoc.data() is Map<String, dynamic>) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          if (userData['email'] == widget.course.instructorEmail) {
            continue;
          }
        }

        // Create notification document reference
        DocumentReference notificationRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc(); // Auto-generate ID

        // Add to batch
        batch.set(notificationRef, notificationData);
      }

      // 5. Add to global activities collection for analytics
      DocumentReference activityRef = FirebaseFirestore.instance.collection('activities').doc();
      batch.set(activityRef, {
        'type': 'courseApproved',
        'teacherId': widget.course.instructorEmail,
        'title': 'Course Approved',
        'description': '$courseTitle has been approved and is now available',
        'courseId': courseId,
        'courseTitle': courseTitle,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 6. Commit the batch
      await batch.commit();

      print('Approval notifications sent for course: $courseTitle');

    } catch (e) {
      print('Error sending course approval notifications: $e');
      // We don't throw error to prevent failing the course approval process
      // if notification sending fails
    }
  }






  /// Builds the overview tab content


  /// Builds a card with course basic information.
  Widget _buildCourseInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.courseTitle ?? 'Untitled Course',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: CMSDesignSystem.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (widget.course.instructor != null && widget.course.instructor!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: CMSDesignSystem.primaryBlue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            widget.course.instructor!,
                            style: TextStyle(
                              fontSize: 15,
                              color: CMSDesignSystem.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPriceBackgroundColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.course.price != null && widget.course.price! > 0
                      ? '\$${widget.course.price!.toStringAsFixed(2)}'
                      : 'Free',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 16),
          // Course information rows
          ..._buildInfoRows(),
        ],
      ),
    );
  }

  /// Returns the background color for the price tag.
  Color _getPriceBackgroundColor() {
    if (widget.course.price == null || widget.course.price == 0) {
      return CMSDesignSystem.freeCourseColor;
    } else {
      return CMSDesignSystem.premiumCourseColor;
    }
  }

  /// Builds information rows for the course info card.
  List<Widget> _buildInfoRows() {
    return [
      // Medium
      if (widget.course.medium != null)
        _buildInfoRow(Icons.language_rounded, 'Medium', widget.course.medium!),

      // Duration
      if (widget.course.duration != null && widget.course.duration!.isNotEmpty)
        _buildInfoRow(Icons.timer_rounded, 'Duration', widget.course.duration!),

      // Subject
      if (widget.course.subject != null && widget.course.subject!.isNotEmpty)
        _buildInfoRow(Icons.category_rounded, 'Subject', widget.course.subject!),

      // Rating
      if (widget.course.averageRating != null)
        _buildInfoRow(
          Icons.star_rounded,
          'Rating',
          '${widget.course.averageRating!.toStringAsFixed(1)}/5.0',
          trailing: RatingBarIndicator(
            rating: widget.course.averageRating ?? 0,
            itemBuilder: (context, _) => Icon(
              Icons.star_rounded,
              color: Colors.amber,
            ),
            itemCount: 5,
            itemSize: 18.0,
            direction: Axis.horizontal,
          ),
        ),

      // Number of enrolled students
      if (widget.course.enrolledUserIds != null)
        _buildInfoRow(
          Icons.people_rounded,
          'Enrolled Students',
          '${widget.course.enrolledUserIds!.length}',
        ),
    ];
  }

  /// Builds a single information row with icon, label, and value.
  Widget _buildInfoRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CMSDesignSystem.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: CMSDesignSystem.primaryGreen,
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: CMSDesignSystem.textSecondary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: CMSDesignSystem.textPrimary,
                ),
              ),
            ],
          ),
          if (trailing != null) ...[
            Spacer(),
            trailing,
          ],
        ],
      ),
    );
  }

  /// Builds the sections list, including both videos and PDFs.

  /// Builds a single video item in the section.
  Widget _buildVideoItem(Video video) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CMSDesignSystem.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.play_circle_filled_rounded,
          color: CMSDesignSystem.primaryBlue,
        ),
      ),
      title: Text(
        video.title ?? 'Untitled Video',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: CMSDesignSystem.primaryBlue,
      ),
      onTap: () {
        if (video.videoUrl != null && _isValidYouTubeUrl(video.videoUrl!)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(videoUrl: video.videoUrl!),
            ),
          );
        } else {
          showCMSToast(
            context,
            message: 'Invalid YouTube video URL',
            backgroundColor: CMSDesignSystem.error,
            icon: Icons.error_outline_rounded,
          );
        }
      },
    );
  }

  /// Builds a single PDF item in the section.
  Widget _buildPdfItem(PdfResource pdf) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CMSDesignSystem.accentMaroon.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.picture_as_pdf_rounded,
          color: CMSDesignSystem.accentMaroon,
        ),
      ),
      title: Text(
        pdf.title ?? 'Untitled PDF',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: CMSDesignSystem.accentMaroon,
      ),
      onTap: () {
        if (pdf.pdfUrl != null && pdf.pdfUrl!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfPreviewScreen(
                pdfUrl: pdf.pdfUrl!,
                title: pdf.title ?? "PDF Preview",
              ),
            ),
          );
        } else {
          showCMSToast(
            context,
            message: 'Invalid PDF URL',
            backgroundColor: CMSDesignSystem.error,
            icon: Icons.error_outline_rounded,
          );
        }
      },
    );
  }

  /// Builds the enrolled students tab.

  /// Shows a dialog to confirm unenrolling a student.
  void _showUnenrollConfirmationDialog(BuildContext context, String userId, String studentName) {
    showDialog(
      context: context,
      builder: (ctx) {
        return CMSConfirmationDialog(
          title: 'Unenroll Student',
          message: 'Are you sure you want to unenroll $studentName from this course?',
          confirmText: 'Unenroll',
          confirmColor: CMSDesignSystem.accentMaroon,
          icon: Icons.person_remove_rounded,
          onCancel: () => Navigator.of(ctx).pop(),
          onConfirm: () async {
            Navigator.of(ctx).pop();
            await _unenrollStudent(context, userId);
          },
        );
      },
    );
  }

  /// Unenrolls a student by updating Firestore.
  Future<void> _unenrollStudent(BuildContext rootContext, String userId) async {
    setState(() => _isLoading = true);

    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      List<dynamic> enrolledCourses = userData['enrolledCourses'] ?? [];

      Map<String, dynamic>? courseToRemove;
      for (var course in enrolledCourses) {
        if (course['courseId'] == widget.course.id) {
          courseToRemove = course as Map<String, dynamic>;
          break;
        }
      }

      if (courseToRemove != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'enrolledCourses': FieldValue.arrayRemove([courseToRemove]),
        });

        showCMSToast(
          rootContext,
          message: 'Student successfully unenrolled',
          backgroundColor: CMSDesignSystem.success,
          icon: Icons.check_circle_outline_rounded,
        );

        // Refresh the students list
        setState(() {});
      } else {
        showCMSToast(
          rootContext,
          message: 'Course not found for this student',
          backgroundColor: CMSDesignSystem.error,
          icon: Icons.error_outline_rounded,
        );
      }
    } catch (e) {
      print('Error unenrolling student: $e');
      showCMSToast(
        rootContext,
        message: 'Failed to unenroll student: ${e.toString()}',
        backgroundColor: CMSDesignSystem.error,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Builds the feedback tab.

  /// Shows a dialog to add feedback.
  void _showAddFeedbackDialog(BuildContext context, String courseId) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _feedbackController = TextEditingController();
    double _currentRating = 3.0;
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.rate_review_rounded,
                  color: CMSDesignSystem.primaryBlue,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text('Add Feedback'),
              ],
            ),
            content: Stack(
              children: [
                SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Rating Bar
                        Text(
                          'How would you rate this course?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: CMSDesignSystem.textPrimary,
                          ),
                        ),
                        SizedBox(height: 16),
                        RatingBar.builder(
                          initialRating: _currentRating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {
                            _currentRating = rating;
                          },
                        ),
                        SizedBox(height: 24),

                        // Feedback Text
                        TextFormField(
                          controller: _feedbackController,
                          decoration: InputDecoration(
                            labelText: 'Your Feedback',
                            hintText: 'Share your thoughts about this course...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.comment_rounded),
                          ),
                          maxLength: 150,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your feedback';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isSubmitting)
                  Container(
                    color: Colors.white.withOpacity(0.8),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(CMSDesignSystem.primaryBlue),
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isSubmitting = true;
                    });

                    try {
                      final CustomUser? currentUser =
                      Provider.of<AuthService>(context, listen: false).currentUser as CustomUser?;
                      if (currentUser == null) {
                        showCMSToast(
                          context,
                          message: 'You must be logged in to submit feedback',
                          backgroundColor: CMSDesignSystem.error,
                          icon: Icons.error_outline_rounded,
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

                      showCMSToast(
                        context,
                        message: 'Feedback submitted successfully',
                        backgroundColor: CMSDesignSystem.success,
                        icon: Icons.check_circle_outline_rounded,
                      );

                      Navigator.pop(dialogContext);

                      // Refresh the course data
                      setState(() {});
                    } catch (e) {
                      showCMSToast(
                        context,
                        message: 'Error submitting feedback: ${e.toString()}',
                        backgroundColor: CMSDesignSystem.error,
                        icon: Icons.error_outline_rounded,
                      );
                    } finally {
                      setState(() {
                        _isSubmitting = false;
                      });
                    }
                  }
                },
                child: Text('Submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CMSDesignSystem.primaryBlue,
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  /// Shows a dialog to edit the course.
  void _showEditCourseDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController _titleController =
    TextEditingController(text: widget.course.courseTitle);
    final TextEditingController _descriptionController =
    TextEditingController(text: widget.course.description);
    final TextEditingController _priceController =
    TextEditingController(text: widget.course.price?.toString() ?? '0');
    final TextEditingController _statusController =
    TextEditingController(text: widget.course.status);

    // List of allowed mediums
    final List<String> mediums = ['Tamil', 'English', 'Sinhala'];
    // Initialize selected medium
    String? selectedMedium = widget.course.medium != null && mediums.contains(widget.course.medium)
        ? widget.course.medium
        : mediums.first;

    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.edit_rounded,
                  color: CMSDesignSystem.primaryBlue,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text('Edit Course'),
              ],
            ),
            content: Stack(
              children: [
                SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Course Title
                        CMSFormField(
                          controller: _titleController,
                          label: 'Course Title',
                          hintText: 'Enter course title',
                          prefixIcon: Icons.title_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a course title';
                            }
                            return null;
                          },
                        ),

                        // Course Description
                        CMSFormField(
                          controller: _descriptionController,
                          label: 'Course Description',
                          hintText: 'Enter course description',
                          prefixIcon: Icons.description_rounded,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a course description';
                            }
                            return null;
                          },
                        ),

                        // Medium Dropdown
                        CMSDropdownField<String>(
                          label: 'Medium',
                          value: selectedMedium,
                          items: mediums.map((medium) {
                            return DropdownMenuItem(
                              value: medium,
                              child: Text(medium),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedMedium = value;
                            });
                          },
                          prefixIcon: Icons.language_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a medium';
                            }
                            return null;
                          },
                        ),

                        // Course Price
                        CMSFormField(
                          controller: _priceController,
                          label: 'Price',
                          hintText: 'Enter price (e.g., 20.99)',
                          prefixIcon: Icons.attach_money_rounded,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a price (0 for free courses)';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),

                        // Course Status
                        CMSFormField(
                          controller: _statusController,
                          label: 'Status',
                          hintText: 'Enter status (e.g., free, Premium)',
                          prefixIcon: Icons.bookmark_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a status';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isSubmitting)
                  Container(
                    color: Colors.white.withOpacity(0.8),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(CMSDesignSystem.primaryBlue),
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isSubmitting = true;
                    });

                    try {
                      final updatedCourse = Course(
                        id: widget.course.id,
                        courseTitle: _titleController.text,
                        description: _descriptionController.text,
                        price: double.parse(_priceController.text),
                        status: _statusController.text,
                        imageUrl: widget.course.imageUrl,
                        sections: widget.course.sections,
                        feedbacks: widget.course.feedbacks,
                        medium: selectedMedium,
                        isApproved: widget.course.isApproved,
                        enrolledUserIds: widget.course.enrolledUserIds,
                        instructor: widget.course.instructor,
                        subject: widget.course.subject,
                        duration: widget.course.duration,
                        averageRating: widget.course.averageRating,
                        instructorEmail: widget.course.instructorEmail,
                      );

                      await Provider.of<CourseProvider>(context, listen: false)
                          .updateCourse(updatedCourse);

                      showCMSToast(
                        context,
                        message: 'Course updated successfully',
                        backgroundColor: CMSDesignSystem.success,
                        icon: Icons.check_circle_outline_rounded,
                      );

                      Navigator.pop(dialogContext);

                      // Update the state to reflect changes
                      setState(() {
                        widget.course.courseTitle = _titleController.text;
                        widget.course.description = _descriptionController.text;
                        widget.course.price = double.parse(_priceController.text);
                        widget.course.status = _statusController.text;
                        widget.course.medium = selectedMedium;
                      });
                    } catch (e) {
                      showCMSToast(
                        context,
                        message: 'Error updating course: ${e.toString()}',
                        backgroundColor: CMSDesignSystem.error,
                        icon: Icons.error_outline_rounded,
                      );
                    } finally {
                      setState(() {
                        _isSubmitting = false;
                      });
                    }
                  }
                },
                child: Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CMSDesignSystem.primaryBlue,
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
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
    return Theme(
      data: CMSTheme.lightTheme,
      child: Scaffold(
        appBar: CMSAppBar(
          title: title,
        ),
        body: Container(
          color: Colors.grey[200],
          child: PDF().cachedFromUrl(
            pdfUrl,
            placeholder: (progress) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(CMSDesignSystem.primaryBlue),
                    value: progress / 100,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading PDF: $progress %',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            errorWidget: (error) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: CMSDesignSystem.error,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading PDF',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CMSDesignSystem.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: CMSDesignSystem.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded),
                    label: Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CMSDesignSystem.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Implement download functionality if needed
            showCMSToast(
              context,
              message: 'PDF download feature will be available soon',
              icon: Icons.info_outline_rounded,
            );
          },
          backgroundColor: CMSDesignSystem.primaryBlue,
          child: Icon(Icons.download_rounded),
          tooltip: 'Download PDF',
        ),
      ),
    );
  }
}