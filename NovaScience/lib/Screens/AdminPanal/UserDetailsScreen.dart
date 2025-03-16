import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../Modals/User.dart';
import '../../Service/AuthService.dart';

class UserDetailsScreen extends StatefulWidget {
  final CustomUser user;

  const UserDetailsScreen({Key? key, required this.user}) : super(key: key);

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _enrolledCourses = [];
  TabController? _tabController;
  ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  // New premium color palette
  final Color primaryColor = const Color(0xFF11261F); // Dark green
  final Color secondaryColor = const Color(0xFF123755); // Deep blue
  final Color accentColor = const Color(0xFF722626); // Maroon
  final Color surfaceColor = const Color(0xFFF8F9FA); // Light background
  final Color cardColor = Colors.white;
  final Color textDarkColor = const Color(0xFF263238); // Dark text
  final Color textLightColor = Colors.white; // Light text
  final Color borderColor = const Color(0xFFE0E0E0); // Border
  final Color successColor = const Color(0xFF2E7D32); // Green success
  final Color dangerColor = const Color(0xFF722626); // Maroon for danger
  final Color warningColor = const Color(0xFF123755); // Blue for warning

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchEnrolledCourses();

    // Add listener for pull-to-refresh
    _scrollController.addListener(() {
      if (_scrollController.position.pixels < -100 && !_isRefreshing) {
        _handleRefresh();
      }
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await _fetchEnrolledCourses();

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchEnrolledCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final enrollments = widget.user.enrollments ?? [];
      List<Map<String, dynamic>> courseDetails = [];

      for (var enrollment in enrollments) {
        try {
          // Fetch course details from Firestore
          final courseDoc = await FirebaseFirestore.instance
              .collection('courses')
              .doc(enrollment.courseId)
              .get();

          if (courseDoc.exists) {
            final data = courseDoc.data() as Map<String, dynamic>;
            courseDetails.add({
              'courseId': enrollment.courseId,
              'title': data['title'] ?? 'Unknown Course',
              'instructor': data['instructor'] ?? 'Unknown Instructor',
              'enrollmentDate': enrollment.enrollmentDate,
              'endDate': enrollment.enrollmentEndDate,
              'thumbnail': data['thumbnail'] ?? '',
              'progress': data['progress'] ?? 0.0,
              'totalLessons': data['totalLessons'] ?? 0,
              'completedLessons': data['completedLessons'] ?? 0,
            });
          }
        } catch (e) {
          print('Error fetching course ${enrollment.courseId}: $e');
        }
      }

      setState(() {
        _enrolledCourses = courseDetails;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching enrolled courses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = widget.user;

    // Role-based color
    Color roleColor = secondaryColor;
    if (user.role?.toLowerCase() == 'teacher') {
      roleColor = accentColor;
    } else if (user.role?.toLowerCase() == 'admin') {
      roleColor = accentColor;
    }

    return Scaffold(
      backgroundColor: surfaceColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 320.0,
              floating: false,
              pinned: true,
              backgroundColor: primaryColor,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(user, roleColor),
              ),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: textLightColor),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit_rounded, color: textLightColor),
                  ),
                  onPressed: () => _editUser(context, user, authService),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.more_vert_rounded, color: textLightColor),
                  ),
                  onPressed: () => _showOptionsMenu(context, user, authService),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: accentColor,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: textLightColor,
                    unselectedLabelColor: textLightColor.withOpacity(0.7),
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      Tab(text: 'Profile'),
                      Tab(text: 'Courses'),
                      Tab(text: 'Activity'),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isLoading ? _buildLoadingShimmer() : _buildTabContent(user, roleColor),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactOptions(context, user),
        icon: Icon(Icons.message_rounded),
        label: Text('Contact'),
        backgroundColor: accentColor,
        foregroundColor: textLightColor,
        elevation: 4,
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card shimmer
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            // Title shimmer
            Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            // Course card shimmer
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(CustomUser user, Color roleColor) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Profile Tab
        RefreshIndicator(
          onRefresh: _handleRefresh,
          color: accentColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Personal Information'),
                const SizedBox(height: 16),
                _buildInfoCard([
                  _buildInfoRow(Icons.email_rounded, 'Email', user.email ?? 'Not provided'),
                  _buildInfoRow(Icons.phone_rounded, 'Phone', user.phoneNumber ?? 'Not provided'),
                  _buildInfoRow(Icons.location_on_rounded, 'Location', user.location ?? 'Not provided'),
                  _buildInfoRow(
                      Icons.cake_rounded,
                      'Birthday',
                      user.birthday != null
                          ? DateFormat.yMMMMd().format(user.birthday!)
                          : 'Not provided'
                  ),
                  _buildInfoRow(
                      Icons.calendar_today_rounded,
                      'Registered',
                      user.registrationDate != null
                          ? DateFormat.yMMMMd().format(user.registrationDate!)
                          : 'Unknown'
                  ),
                  _buildInfoRow(
                      Icons.schedule_rounded,
                      'Last Active',
                      user.lastActiveTime != null
                          ? timeago.format(user.lastActiveTime!)
                          : 'Unknown'
                  ),
                ]),

                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _buildSectionTitle('About Me'),
                  const SizedBox(height: 16),
                  _buildInfoCard([
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        user.bio!,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: textDarkColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ]),
                ],

                const SizedBox(height: 30),
                _buildSectionTitle('Account Statistics'),
                const SizedBox(height: 16),
                _buildStatsCard(),

                const SizedBox(height: 30),
                _buildSectionTitle('Actions'),
                const SizedBox(height: 16),
                _buildActionButtons(user, roleColor),

                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),

        // Courses Tab
        RefreshIndicator(
          onRefresh: _handleRefresh,
          color: accentColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Enrolled Courses (${_enrolledCourses.length})'),
                    if (_enrolledCourses.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All', style: TextStyle(color: secondaryColor, fontWeight: FontWeight.w500)),
                            ),
                            DropdownMenuItem(
                              value: 'active',
                              child: Text('Active', style: TextStyle(color: secondaryColor, fontWeight: FontWeight.w500)),
                            ),
                            DropdownMenuItem(
                              value: 'expired',
                              child: Text('Expired', style: TextStyle(color: secondaryColor, fontWeight: FontWeight.w500)),
                            ),
                          ],
                          onChanged: (value) {
                            // Implement filter
                          },
                          hint: Text('Filter', style: TextStyle(color: secondaryColor)),
                          underline: SizedBox(),
                          icon: Icon(Icons.filter_list_rounded, color: secondaryColor),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCoursesList(),

                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),

        // Activity Tab
        RefreshIndicator(
          onRefresh: _handleRefresh,
          color: accentColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Recent Activity'),
                const SizedBox(height: 16),
                _buildActivityTimeline(),

                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(CustomUser user, Color roleColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, Color(0xFF0A1A14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Hero(
                tag: 'user-avatar-${user.email}',
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: user.profileImageUrl != null
                        ? CachedNetworkImage(
                      imageUrl: user.profileImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentColor,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: secondaryColor.withOpacity(0.2),
                        child: Icon(
                          Icons.person_rounded,
                          size: 65,
                          color: secondaryColor,
                        ),
                      ),
                    )
                        : Container(
                      color: secondaryColor.withOpacity(0.2),
                      child: Icon(
                        Icons.person_rounded,
                        size: 65,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                user.name ?? 'Unknown User',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: textLightColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: roleColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      user.role ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textLightColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: user.isLoggedIn == true
                          ? successColor.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: user.isLoggedIn == true
                            ? successColor.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: user.isLoggedIn == true
                                ? successColor
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.isLoggedIn == true
                              ? 'Online'
                              : 'Offline',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textLightColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 22,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 15,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (index) {
          // Add dividers between items, but not after the last one
          if (index.isOdd) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: borderColor),
            );
          }
          return children[index ~/ 2];
        }),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    bool isCopyable = label == 'Email' || label == 'Phone';

    return InkWell(
      onTap: isCopyable
          ? () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied to clipboard'),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: secondaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textDarkColor.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textDarkColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isCopyable)
              Icon(
                Icons.content_copy,
                size: 18,
                color: secondaryColor.withOpacity(0.7),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    // Example stats - replace with actual data
    final int coursesEnrolled = _enrolledCourses.length;
    final int coursesCompleted = _enrolledCourses.where((c) =>
    c['progress'] != null && c['progress'] >= 0.9).length;
    final double avgProgress = _enrolledCourses.isEmpty ? 0.0 :
    _enrolledCourses.fold(0.0, (sum, c) => sum + (c['progress'] ?? 0.0)) / _enrolledCourses.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Courses Enrolled',
                  coursesEnrolled.toString(),
                  Icons.school_rounded,
                  secondaryColor,
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: borderColor,
              ),
              Expanded(
                child: _buildStatItem(
                  'Courses Completed',
                  coursesCompleted.toString(),
                  Icons.task_alt_rounded,
                  successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Avg. Progress',
                  '${(avgProgress * 100).toStringAsFixed(0)}%',
                  Icons.trending_up_rounded,
                  accentColor,
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: borderColor,
              ),
              Expanded(
                child: _buildStatItem(
                  'Last Activity',
                  widget.user.lastActiveTime != null
                      ? timeago.format(widget.user.lastActiveTime!)
                      : 'Unknown',
                  Icons.schedule_rounded,
                  secondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: color,
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: textDarkColor.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons(CustomUser user, Color roleColor) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Reset Password',
            Icons.lock_reset_rounded,
            secondaryColor,
                () => _showResetPasswordDialog(context, user),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            'Delete User',
            Icons.delete_rounded,
            dangerColor,
                () => _showDeleteConfirmation(context, user, Provider.of<AuthService>(context, listen: false)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textLightColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildCoursesList() {
    if (_enrolledCourses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_rounded,
              size: 60,
              color: secondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No courses enrolled',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'User has not enrolled in any courses yet',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: textDarkColor.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              onPressed: () {
                // Navigate to course catalog
              },
              icon: Icon(Icons.add_rounded),
              label: Text('Add Course'),
              style: OutlinedButton.styleFrom(
                foregroundColor: secondaryColor,
                side: BorderSide(color: secondaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _enrolledCourses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final course = _enrolledCourses[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final endDate = course['endDate'] as DateTime;
    final isExpired = endDate.isBefore(DateTime.now());
    final progress = course['progress'] ?? 0.0;
    final completedLessons = course['completedLessons'] ?? 0;
    final totalLessons = course['totalLessons'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Navigate to course details
            },
            splashColor: secondaryColor.withOpacity(0.1),
            highlightColor: secondaryColor.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course header with thumbnail
                Stack(
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      child: course['thumbnail'] != null && course['thumbnail'].toString().isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: course['thumbnail'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: secondaryColor.withOpacity(0.1),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: secondaryColor.withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              size: 50,
                              color: secondaryColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      )
                          : Container(
                        color: secondaryColor.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.school_rounded,
                            size: 50,
                            color: secondaryColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    if (isExpired)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: dangerColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'EXPIRED',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textLightColor,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 6,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: borderColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isExpired ? dangerColor : successColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),

                // Course details
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'] ?? 'Unknown Course',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        course['instructor'] ?? 'Unknown Instructor',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: textDarkColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Progress indicator
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Course Progress',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: textDarkColor.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isExpired ? dangerColor : successColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '$completedLessons/$totalLessons lessons',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: textDarkColor.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: successColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isExpired ? 'View Certificate' : 'Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: successColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Divider(height: 1, color: borderColor),
                      const SizedBox(height: 20),

                      // Course info
                      Row(
                        children: [
                          Expanded(
                            child: _buildCourseInfoItem(
                              'Enrolled',
                              course['enrollmentDate'] != null
                                  ? DateFormat.yMMMd().format(course['enrollmentDate'])
                                  : 'Unknown',
                              Icons.calendar_today_rounded,
                            ),
                          ),
                          Expanded(
                            child: _buildCourseInfoItem(
                              'Access Until',
                              course['endDate'] != null
                                  ? DateFormat.yMMMd().format(course['endDate'])
                                  : 'Unknown',
                              Icons.access_time_rounded,
                              isExpired: isExpired,
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
        ),
      ),
    );
  }

  Widget _buildCourseInfoItem(String label, String value, IconData icon, {bool isExpired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: textDarkColor.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isExpired ? dangerColor : secondaryColor,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isExpired ? dangerColor : textDarkColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityTimeline() {
    // Example activities - replace with actual data
    final List<Map<String, dynamic>> activities = [
      {
        'type': 'login',
        'timestamp': DateTime.now().subtract(Duration(hours: 2)),
        'details': 'User logged in',
      },
      {
        'type': 'course_progress',
        'timestamp': DateTime.now().subtract(Duration(days: 1)),
        'details': 'Completed "Introduction to Flutter" lesson',
        'courseId': 'course123',
        'courseName': 'Flutter Development Masterclass',
      },
      {
        'type': 'enrollment',
        'timestamp': DateTime.now().subtract(Duration(days: 3)),
        'details': 'Enrolled in new course',
        'courseId': 'course123',
        'courseName': 'Flutter Development Masterclass',
      },
      {
        'type': 'profile_update',
        'timestamp': DateTime.now().subtract(Duration(days: 7)),
        'details': 'Updated profile information',
      },
    ];

    if (activities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 60,
              color: secondaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No activity found',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'User has no recent activity',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: textDarkColor.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityItem(activity, index == activities.length - 1);
        },
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, bool isLast) {
    // Determine icon and color based on activity type
    IconData icon;
    Color color;

    switch (activity['type']) {
      case 'login':
        icon = Icons.login_rounded;
        color = successColor;
        break;
      case 'course_progress':
        icon = Icons.play_lesson_rounded;
        color = secondaryColor;
        break;
      case 'enrollment':
        icon = Icons.school_rounded;
        color = accentColor;
        break;
      case 'profile_update':
        icon = Icons.person_rounded;
        color = warningColor;
        break;
      default:
        icon = Icons.circle_rounded;
        color = secondaryColor;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 22,
                color: color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: borderColor,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity['details'],
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textDarkColor,
                ),
              ),
              if (activity['courseName'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  activity['courseName'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: secondaryColor,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                timeago.format(activity['timestamp']),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: textDarkColor.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  void _showContactOptions(BuildContext context, CustomUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Contact ${user.name}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildContactOption(
              'Send Email',
              Icons.email_rounded,
              secondaryColor,
                  () async {
                if (user.email != null) {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: user.email,
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                }
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            _buildContactOption(
              'Call',
              Icons.phone_rounded,
              successColor,
                  () async {
                if (user.phoneNumber != null) {
                  final Uri telUri = Uri(
                    scheme: 'tel',
                    path: user.phoneNumber,
                  );
                  if (await canLaunchUrl(telUri)) {
                    await launchUrl(telUri);
                  }
                }
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            _buildContactOption(
              'Send Message',
              Icons.message_rounded,
              accentColor,
                  () async {
                if (user.phoneNumber != null) {
                  final Uri smsUri = Uri(
                    scheme: 'sms',
                    path: user.phoneNumber,
                  );
                  if (await canLaunchUrl(smsUri)) {
                    await launchUrl(smsUri);
                  }
                }
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: borderColor),
                foregroundColor: textDarkColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, CustomUser user, AuthService authService) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 20, color: secondaryColor),
              const SizedBox(width: 12),
              Text(
                'Edit User',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'reset_password',
          child: Row(
            children: [
              Icon(Icons.lock_reset_rounded, size: 20, color: accentColor),
              const SizedBox(width: 12),
              Text(
                'Reset Password',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 20, color: dangerColor),
              const SizedBox(width: 12),
              Text(
                'Delete User',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        _editUser(context, user, authService);
      } else if (value == 'reset_password') {
        _showResetPasswordDialog(context, user);
      } else if (value == 'delete') {
        _showDeleteConfirmation(context, user, authService);
      }
    });
  }

  void _showResetPasswordDialog(BuildContext context, CustomUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Icon(
              Icons.lock_reset_rounded,
              size: 48,
              color: secondaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Reset Password',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reset the password for ${user.name}? A password reset link will be sent to their email.',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: textDarkColor,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: textDarkColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement reset password
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Password reset link sent to user\'s email',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: textLightColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 2,
            ),
            child: Text(
              'Reset Password',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Edit user dialog wrapper (navigate back to management screen)
  void _editUser(BuildContext context, CustomUser user, AuthService authService) async {
    // Navigate back to the user management screen for editing
    Navigator.of(context).pop(user);
  }

  // Delete confirmation dialog
  Future<void> _showDeleteConfirmation(
      BuildContext context, CustomUser user, AuthService authService) async {
    final bool result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Icon(
              Icons.warning_rounded,
              color: dangerColor,
              size: 60,
            ),
            SizedBox(height: 20),
            Text(
              'Confirm Deletion',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${user.name ?? 'this user'}? This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: textDarkColor,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: secondaryColor,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerColor,
              foregroundColor: textLightColor,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.delete_rounded, size: 20),
            label: Text(
              'DELETE',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;

    if (result && user.email != null) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(
              color: accentColor,
            ),
          ),
        );

        // Delete the user
        await authService.deleteUserByEmail(user.email!);

        // Close loading indicator
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'User deleted successfully!',
            style: GoogleFonts.poppins(color: textLightColor),
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ));

        // Navigate back to the user management screen
        Navigator.of(context).pop();
      } catch (e) {
        // Close loading indicator
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Failed to delete user: $e',
            style: GoogleFonts.poppins(color: textLightColor),
          ),
          backgroundColor: dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ));
      }
    }
  }
}