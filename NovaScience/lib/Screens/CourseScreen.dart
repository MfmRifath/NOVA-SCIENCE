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
  // Color palette
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color maroonColor = const Color(0xFF722626);
  final Color accentColor = const Color(0xFFe9c46a);

  // Secondary colors
  final Color backgroundColor = const Color(0xFFF5F5F5);
  final Color cardColor = Colors.white;
  final Color textColor = const Color(0xFF333333);
  final Color textSecondaryColor = const Color(0xFF666666);
  final Color errorColor = const Color(0xFFD32F2F);
  final Color successColor = const Color(0xFF388E3C);

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
          backgroundColor: greenColor,
          elevation: 0,
          title: Text(
            'Course Details',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Course not found',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: textColor,
            ),
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
        progressIndicatorColor: maroonColor,
        progressColors: ProgressBarColors(
          playedColor: maroonColor,
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
                  labelColor: maroonColor,
                  unselectedLabelColor: textSecondaryColor,
                  indicatorColor: maroonColor,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.roboto(
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

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: greenColor,
        elevation: 0,
        title: Text(
          'Loading Course',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
            SizedBox(height: 16),
            Text(
              'Loading course details...',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: greenColor,
      elevation: 0,
      title: Text(
        _course!.courseTitle ?? 'Course Details',
        style: GoogleFonts.roboto(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
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
      ],
    );
  }

  Widget _buildVideoPlayer(Widget player) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _youtubeController != null && (isEnrolled || isAdmin)
            ? player
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
            // Play button overlay
            if (!isEnrolled && !isAdmin)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.lock_outline,
                    color: greenColor,
                    size: 32,
                  ),
                  onPressed: () => _showEnrollPrompt(),
                ),
              ),
          ],
        )
            : Container(
          color: Colors.black,
          child: Center(
            child: Text(
              'No videos available',
              style: GoogleFonts.roboto(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course title
          Text(
            course.courseTitle ?? 'Course Title',
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: greenColor,
            ),
          ),
          SizedBox(height: 8),

          // Instructor
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 18,
                color: yellowColor,
              ),
              SizedBox(width: 8),
              Text(
                course.instructor ?? 'Instructor',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textSecondaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Course info card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description section
                Text(
                  'About This Course',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: greenColor,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  course.description ?? 'No description available.',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    height: 1.6,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 24),

                // Course metadata
                _buildInfoRow(
                  icon: Icons.language_outlined,
                  label: 'Medium',
                  value: course.medium ?? 'Not specified',
                ),
                SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.access_time_outlined,
                  label: 'Duration',
                  value: course.duration ?? 'Not specified',
                ),
                SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.category_outlined,
                  label: 'Subject',
                  value: course.subject ?? 'Not specified',
                ),
                SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.money_outlined,
                  label: 'Price',
                  value: 'Rs. ${course.price!.toStringAsFixed(0)}',
                ),

                // Rating summary
                SizedBox(height: 24),
                _buildRatingSummary(course),
              ],
            ),
          ),
          SizedBox(height: 32),

          // Enrollment section
          if (!isEnrolled && !isAdmin)
            _buildEnrollmentSection(course, adminPhoneNumber),

          // Enrolled actions section
          if (isEnrolled && !isAdmin)
            _buildEnrolledActions(),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: yellowColor,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textSecondaryColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: textColor,
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
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: greenColor,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Text(
                    course.averageRating?.toStringAsFixed(1) ?? 'N/A',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: greenColor,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.star,
                    color: greenColor,
                    size: 20,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Text(
              '${course.feedbacks.length} ${course.feedbacks.length == 1 ? 'review' : 'reviews'}',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: textSecondaryColor,
              ),
            ),
          ],
        ),
        if (course.averageRating != null) ...[
          SizedBox(height: 12),
          RatingBarIndicator(
            rating: course.averageRating!,
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: accentColor,
            ),
            itemCount: 5,
            itemSize: 20,
            direction: Axis.horizontal,
          ),
        ],
      ],
    );
  }

  Widget _buildEnrollmentSection(Course course, String adminPhoneNumber) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: yellowColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enrollment Options',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: greenColor,
            ),
          ),
          SizedBox(height: 16),

          // Admin contact section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Admin',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: greenColor,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 18,
                      color: yellowColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      adminPhoneNumber,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
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
                        style: OutlinedButton.styleFrom(
                          foregroundColor: yellowColor,
                          side: BorderSide(color: yellowColor),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          textStyle: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
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
                        icon: Icon(Icons.message_outlined, size: 18),
                        label: Text('MESSAGE'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: yellowColor,
                          side: BorderSide(color: yellowColor),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          textStyle: GoogleFonts.roboto(
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

          // Self-enroll button for free courses
          if (course.status == 'free') ...[
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _confirmEnroll(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: maroonColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  'ENROLL NOW',
                  style: GoogleFonts.roboto(
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
    );
  }

  Widget _buildEnrolledActions() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: greenColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                Icons.check_circle_outline,
                color: successColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You are enrolled in this course',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: greenColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'You have full access to all course content and materials.',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: textSecondaryColor,
            ),
          ),
          SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _confirmUnenroll(),
            icon: Icon(Icons.exit_to_app_outlined, size: 18),
            label: Text('UNENROLL'),
            style: OutlinedButton.styleFrom(
              foregroundColor: maroonColor,
              side: BorderSide(color: maroonColor),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              textStyle: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
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
            Icon(
              Icons.folder_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No sections available',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: textSecondaryColor,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddSectionDialog(context),
              icon: Icon(Icons.add),
              label: Text('ADD SECTION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: maroonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                textStyle: GoogleFonts.roboto(
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
            Icon(
              Icons.folder_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No sections available',
              style: GoogleFonts.roboto(
                fontSize: 16,
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
    return Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
        data: Theme.of(context).copyWith(
      dividerColor: Colors.transparent,
      colorScheme: ColorScheme.light(
        primary: yellowColor,
      ),
    ),
    child: ExpansionTile(
    leading: Icon(
    Icons.folder_outlined,
    color: yellowColor,
    ),
    title: Row(
    children: [
    Expanded(
    child: Text(
    section.sectionTitle ?? 'Untitled Section',
    style: GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textColor,
    ),
    ),
    ),
    if (isAdmin) ...[
    IconButton(
    icon: Icon(Icons.edit_outlined, size: 18, color: yellowColor),
    onPressed: () => _showEditSectionDialog(section, sectionIndex),
    tooltip: 'Edit Section',
    ),
    IconButton(
    icon: Icon(Icons.delete_outline, size: 18, color: maroonColor),
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

      return ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(
          isFirstVideo || canAccessVideo ? Icons.play_circle_outline : Icons.lock_outline,
          color: isFirstVideo || canAccessVideo ? accentColor : Colors.grey,
          size: 24,
        ),
        title: Text(
          video.title ?? 'Untitled Video',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: textColor,
          ),
        ),
        subtitle: Text(
          isFirstVideo ? 'Free Preview' : (canAccessVideo ? 'Available' : 'Locked Content'),
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: isFirstVideo ? accentColor : (canAccessVideo ? successColor : Colors.grey),
          ),
        ),
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
              icon: Icon(Icons.edit_outlined, size: 18, color: yellowColor),
              onPressed: () => _showEditVideoDialog(section.sectionTitle!, video, videoIndex),
              tooltip: 'Edit Video',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: maroonColor),
              onPressed: () => _deleteVideo(widget.courseId, section.sectionTitle ?? '', videoIndex),
              tooltip: 'Delete Video',
            ),
          ],
        )
            : null,
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
            return ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Icon(
                Icons.picture_as_pdf_outlined,
                color: maroonColor,
                size: 24,
              ),
              title: Text(
                pdf.title ?? "Untitled PDF",
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
              subtitle: Text(
                'PDF Document',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: textSecondaryColor,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfPreviewScreen(
                      pdfUrl: pdf.pdfUrl!,
                      title: pdf.title ?? "PDF Preview",
                      greenColor: greenColor,
                      maroonColor: maroonColor,
                    ),
                  ),
                );
              },
              trailing: isAdmin
                  ? IconButton(
                icon: Icon(Icons.delete_outline, size: 18, color: maroonColor),
                onPressed: () async {
                  await Provider.of<CourseProvider>(context, listen: false)
                      .deletePdfFromSection(courseId, section.sectionTitle!, pdfIndex);
                  _showSuccessSnackbar('PDF deleted successfully!');
                  await _initializeCourse();
                },
                tooltip: 'Delete PDF',
              )
                  : null,
            );
          },
        ),

      // Add resource button for admin
      if (isAdmin)
        Padding(
          padding: EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () => _showAddResourceDialog(widget.courseId, section.sectionTitle ?? ''),
            icon: Icon(Icons.add, size: 18),
            label: Text('ADD RESOURCE'),
            style: OutlinedButton.styleFrom(
              foregroundColor: yellowColor,
              side: BorderSide(color: yellowColor),
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              textStyle: GoogleFonts.roboto(
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
          padding: EdgeInsets.all(16),
          child: Text(
            'No content available in this section',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: textSecondaryColor,
            ),
            textAlign: TextAlign.center,
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
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: errorColor),
                SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.roboto(
                    color: textSecondaryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade400),
                SizedBox(height: 16),
                Text(
                  'Please sign in to view feedbacks',
                  style: GoogleFonts.roboto(
                    color: textSecondaryColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final currentUser = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Add feedback form (if eligible)
            if ((isEnrolled || isAdmin) &&
                !_course!.feedbacks.any((fb) => fb.userId.toString() == currentUser.id))
              _buildFeedbackForm(currentUser),

            SizedBox(height: 24),

            // Feedback list header
            Text(
              'Student Reviews',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: greenColor,
              ),
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

  Widget _buildFeedbackForm(CustomUser user) {
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write a Review',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: greenColor,
            ),
          ),
          SizedBox(height: 16),

          // Rating selection
          Text(
            'Rate this course:',
            style: GoogleFonts.roboto(
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
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: accentColor,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _currentRating = rating;
              });
            },
          ),
          SizedBox(height: 16),

          // Review text field
          TextField(
            controller: _feedbackController,
            decoration: InputDecoration(
              hintText: 'Share your experience with this course...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: yellowColor, width: 2),
              ),
              contentPadding: EdgeInsets.all(16),
            ),
            style: GoogleFonts.roboto(
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
                backgroundColor: maroonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: Text(
                _isSubmitting ? 'SUBMITTING...' : 'SUBMIT REVIEW',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFeedbackState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to share your experience with this course',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: textSecondaryColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(FeedBack feedback, CustomUser currentUser) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(feedback.userId.toString()).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                strokeWidth: 2,
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

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: isCurrentUserFeedback
                ? Border.all(color: accentColor.withOpacity(0.3))
                : Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Review header with user info and rating
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: accentColor.withOpacity(0.1),
                      backgroundImage: userProfileImageUrl != null
                          ? CachedNetworkImageProvider(userProfileImageUrl)
                          : null,
                      child: userProfileImageUrl == null
                          ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                        style: GoogleFonts.roboto(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
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
                          Text(
                            userName,
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: GoogleFonts.roboto(
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
                                  Icons.star,
                                  color: accentColor,
                                ),
                                itemCount: 5,
                                itemSize: 16,
                                direction: Axis.horizontal,
                              ),
                              SizedBox(width: 8),
                              Text(
                                feedback.rating?.toStringAsFixed(1) ?? 'N/A',
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w500,
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
              ),

              // Review text
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  feedback.feedback ?? 'No comment provided.',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    height: 1.5,
                    color: textColor,
                  ),
                ),
              ),

              // Action buttons for owner or admin
              if (isOwnerOrAdmin)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEditFeedbackDialog(feedback, userName),
                        icon: Icon(Icons.edit_outlined, size: 16),
                        label: Text('EDIT'),
                        style: TextButton.styleFrom(
                          foregroundColor: yellowColor,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _deleteFeedback(_course!.id!, feedback),
                        icon: Icon(Icons.delete_outlined, size: 16),
                        label: Text('DELETE'),
                        style: TextButton.styleFrom(
                          foregroundColor: maroonColor,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Utility methods for the course screen
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
            ),
          );
        }
      });
    } else {
      _showErrorSnackbar('Invalid video URL');
    }
  }

  Future<void> _enrollUser() async {
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
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          title: Text(
            'Enroll to Access',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              color: greenColor,
            ),
          ),
          content: Text(
            'You need to enroll in this course to access this content.',
            style: GoogleFonts.roboto(
              color: textColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CANCEL',
                style: GoogleFonts.roboto(
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmEnroll();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: maroonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'ENROLL NOW',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmEnroll() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          title: Text(
            'Confirm Enrollment',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              color: greenColor,
            ),
          ),
          content: Text(
            'Are you sure you want to enroll in this course?',
            style: GoogleFonts.roboto(
              color: textColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CANCEL',
                style: GoogleFonts.roboto(
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isActionLoading
                  ? null
                  : () {
                Navigator.of(context).pop();
                _enrollUser();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: maroonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: Text(
                'ENROLL',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmUnenroll() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          title: Text(
            'Confirm Unenrollment',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              color: maroonColor,
            ),
          ),
          content: Text(
            'Are you sure you want to unenroll from this course? You will lose access to all course content.',
            style: GoogleFonts.roboto(
              color: textColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'CANCEL',
                style: GoogleFonts.roboto(
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isActionLoading
                  ? null
                  : () {
                Navigator.of(context).pop();
                _unenrollUser();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: maroonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: Text(
                'UNENROLL',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
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
          builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
    ),
    title: Text(
    'Edit Your Review',
    style: GoogleFonts.roboto(
    fontWeight: FontWeight.w600,
    color: greenColor,
    ),
    ),
    content: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    'Update your rating:',
    style: GoogleFonts.roboto(
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
    itemSize: 24,
    itemBuilder: (context, _) => Icon(
    Icons.star,
    color: accentColor,
    ),
    onRatingUpdate: (rating) {
    _localRating = rating;
    },
    ),
    SizedBox(height: 16),
    Text(
    'Update your feedback:',
    style: GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
    ),
    ),
    SizedBox(height: 8),
    TextField(
    controller: _feedbackController,
    decoration: InputDecoration(
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: BorderSide(color: yellowColor, width: 2),
    ),
    contentPadding: EdgeInsets.all(12),
    ),
    style: GoogleFonts.roboto(
    fontSize: 14,
    color: textColor,
    ),
    maxLines: 3,
    maxLength: 150,
    ),
    ],
    ),
    actions: [
    TextButton(
    onPressed: () => Navigator.pop(context),
    child: Text(
    'CANCEL',
    style: GoogleFonts.roboto(
    color: textSecondaryColor,
    fontWeight: FontWeight.w500,
    letterSpacing: 1,
    ),
    ),
    ),
    ElevatedButton(
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
    backgroundColor: maroonColor,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(4),
    ),
    disabledBackgroundColor: Colors.grey.shade400,
    ),
    child: _isUpdating
    ? SizedBox(
    width: 16,
    height: 16,
    child: CircularProgressIndicator(
    color: Colors.white,
    strokeWidth: 2,
    ),
    )
        : Text(
    'SAVE',
    style: GoogleFonts.roboto(
    fontWeight: FontWeight.w500,
    letterSpacing: 1,
    ),
    ),
    ),
    ],
    ),
    );
  },
  );
}

void _deleteFeedback(String courseId, FeedBack feedback) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text(
          'Delete Review',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: maroonColor,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this review?',
          style: GoogleFonts.roboto(
            color: textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.roboto(
                color: textSecondaryColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'DELETE',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
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
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      title: Text(
        'Delete Course',
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w600,
          color: maroonColor,
        ),
      ),
      content: Text(
        'Are you sure you want to delete this course? This action cannot be undone.',
        style: GoogleFonts.roboto(
          color: textColor,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'CANCEL',
            style: GoogleFonts.roboto(
              color: textSecondaryColor,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: maroonColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            'DELETE',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    ),
  ) ?? false;
}

void _showEditCourseDialog(BuildContext context, Course course) {
  final TextEditingController titleController = TextEditingController(text: course.courseTitle);
  final TextEditingController descriptionController = TextEditingController(text: course.description);
  final TextEditingController priceController = TextEditingController(text: course.price.toString());
  final TextEditingController subjectController = TextEditingController(text: course.subject);
  final TextEditingController mediumController = TextEditingController(text: course.medium);
  bool _isUpdating = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          title: Text(
            'Edit Course',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              color: greenColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Title',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondaryColor,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: yellowColor, width: 2),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  'Description',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondaryColor,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: yellowColor, width: 2),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: textColor,
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),

                Text(
                  'Price (Rs.)',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondaryColor,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: yellowColor, width: 2),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: textColor,
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),

                Text(
                  'Subject',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondaryColor,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: yellowColor, width: 2),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  'Medium',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondaryColor,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: mediumController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide(color: yellowColor, width: 2),
                    ),
                    contentPadding: EdgeInsets.all(12),
                  ),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: GoogleFonts.roboto(
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
            ElevatedButton(
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
                      duration: course.duration,
                      instructor: course.instructor,
                      averageRating: course.averageRating,
                      enrolledUserIds: course.enrolledUserIds,
                      sections: course.sections,
                      feedbacks: course.feedbacks,
                      medium: mediumController.text,
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
                backgroundColor: maroonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: _isUpdating
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                'SAVE',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
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
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text(
          'Add Section',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: greenColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Section Title',
              style: GoogleFonts.roboto(
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: yellowColor, width: 2),
                ),
                contentPadding: EdgeInsets.all(12),
              ),
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.roboto(
                color: textSecondaryColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
          ElevatedButton(
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
              backgroundColor: maroonColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            child: _isAdding
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              'ADD',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
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
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text(
          'Edit Section',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: greenColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Section Title',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textSecondaryColor,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _sectionTitleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: yellowColor, width: 2),
                ),
                contentPadding: EdgeInsets.all(12),
              ),
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: GoogleFonts.roboto(
                color: textSecondaryColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
          ElevatedButton(
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
                      _sectionTitleController.text
                  );

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
              backgroundColor: maroonColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            child: _isUpdating
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              'SAVE',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void _confirmDeleteSection(int sectionIndex, Section section) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text(
          'Delete Section',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: maroonColor,
          ),
        ),
        content: Text(
          'Are you sure you want to delete the "${section.sectionTitle}" section? This will remove all videos and resources in this section.',
          style: GoogleFonts.roboto(
            color: textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'CANCEL',
              style: GoogleFonts.roboto(
                color: textSecondaryColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
          ElevatedButton(
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
              backgroundColor: maroonColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            child: isActionLoading
                ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              'DELETE',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      );
    },
  );
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
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      title: Text(
        'Add Resource',
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w600,
          color: greenColor,
        ),
      ),
      content: SingleChildScrollView(
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      // Resource type selector
      Text(
      'Resource Type',
      style: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
      ),
    ),
  SizedBox(height: 8),
  Row(
  children: [
  Expanded(
  child: RadioListTile<String>(
  title: Text(
  'Video',
  style: GoogleFonts.roboto(
  fontSize: 14,
  color: textColor,
  ),
  ),
  value: "Video",
  groupValue: resourceType,
  activeColor: yellowColor,
  contentPadding: EdgeInsets.zero,
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
  style: GoogleFonts.roboto(
  fontSize: 14,
  color: textColor,
  ),
  ),
  value: "PDF",
  groupValue: resourceType,
  activeColor: yellowColor,
  contentPadding: EdgeInsets.zero,
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
  SizedBox(height: 16),

  // Resource title field
  Text(
  resourceType == "Video" ? 'Video Title' : 'PDF Title',
    style: GoogleFonts.roboto(
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: yellowColor, width: 2),
            ),
            contentPadding: EdgeInsets.all(12),
          ),
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: textColor,
          ),
        ),
        SizedBox(height: 16),

        // URL field for Video or file picker for PDF
        if (resourceType == "Video") ...[
          Text(
            'Video URL',
            style: GoogleFonts.roboto(
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: yellowColor, width: 2),
              ),
              contentPadding: EdgeInsets.all(12),
            ),
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ] else ...[
          Text(
            'PDF File',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textSecondaryColor,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            child: OutlinedButton.icon(
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
              icon: Icon(Icons.attach_file_outlined, size: 18),
              label: Text('SELECT PDF FILE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: yellowColor,
                side: BorderSide(color: yellowColor),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                textStyle: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          if (pickedPdf != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Selected: ${pickedPdf!.name}',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: textSecondaryColor,
                ),
              ),
            ),
        ],
      ],
      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CANCEL',
            style: GoogleFonts.roboto(
              color: textSecondaryColor,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
        ElevatedButton(
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
            backgroundColor: maroonColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            disabledBackgroundColor: Colors.grey.shade400,
          ),
          child: _isAdding
              ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Text(
            'ADD',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
      },
      ),
  );
}

void _showEditVideoDialog(String sectionTitle, Video video, int videoIndex) {
  final TextEditingController _titleController = TextEditingController(text: video.title);
  final TextEditingController _urlController = TextEditingController(text: video.videoUrl);
  bool _isUpdating = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          title: Text(
            'Edit Video',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              color: greenColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Video Title',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondaryColor,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: yellowColor, width: 2),
                  ),
                  contentPadding: EdgeInsets.all(12),
                ),
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Video URL',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textSecondaryColor,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: yellowColor, width: 2),
                  ),
                  contentPadding: EdgeInsets.all(12),
                ),
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: GoogleFonts.roboto(
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isUpdating ? null : () async {
                String newTitle = _titleController.text.trim();
                String newUrl = _urlController.text.trim();

                if (newTitle.isEmpty || newUrl.isEmpty) {
                  _showErrorSnackbar('Please fill out both title and URL');
                  return;
                }

                String? videoId = YoutubePlayer.convertUrlToId(newUrl);
                if (videoId == null) {
                  _showErrorSnackbar('Please enter a valid YouTube URL');
                  return;
                }

                setState(() {
                  _isUpdating = true;
                });

                try {
                  final courseProvider = Provider.of<CourseProvider>(context, listen: false);
                  await courseProvider.updateVideo(_course!.id!, sectionTitle, videoIndex, newTitle, newUrl);

                  Navigator.pop(context);
                  _showSuccessSnackbar('Video updated successfully!');
                  await _initializeCourse();
                } catch (e) {
                  _showErrorSnackbar('Failed to update video: $e');
                } finally {
                  setState(() {
                    _isUpdating = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: maroonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: _isUpdating
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                'SAVE',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _deleteVideo(String courseId, String sectionTitle, int videoIndex) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        title: Text(
          'Delete Video',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: maroonColor,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this video?',
          style: GoogleFonts.roboto(
            color: textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.roboto(
                color: textSecondaryColor,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'DELETE',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
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

// Helper methods for floating action button and notifications
Widget? _buildFloatingActionButton() {
  if (isAdmin) {
    return FloatingActionButton(
      onPressed: () => _showAddSectionDialog(context),
      backgroundColor: maroonColor,
      foregroundColor: Colors.white,
      elevation: 4,
      tooltip: 'Add Section',
      child: Icon(Icons.add),
    );
  }
  return null;
}

void _showErrorSnackbar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: GoogleFonts.roboto(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: maroonColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      margin: EdgeInsets.all(8),
      duration: Duration(seconds: 3),
    ),
  );
}

void _showSuccessSnackbar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: GoogleFonts.roboto(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: yellowColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      margin: EdgeInsets.all(8),
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
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
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
                    content: Text('Unable to launch PDF URL'),
                    backgroundColor: maroonColor,
                  ),
                );
              }
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
                  style: GoogleFonts.roboto(
                    fontSize: 16,
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
                Icon(
                  Icons.error_outline,
                  color: maroonColor,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Error: $error',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}