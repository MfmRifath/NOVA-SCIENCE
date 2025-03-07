import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Your own imports
import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart';
import 'CourseDetailScreen.dart';

// Custom color palette
class AppColors {
  static const Color primaryGreen = Color(0xFF11261F);
  static const Color secondaryBlue = Color(0xFF123755);
  static const Color accentMaroon = Color(0xFF722626);
  static const Color lightGreen = Color(0xFF1A3F33);
  static const Color lightBlue = Color(0xFF1D517D);
  static const Color lightMaroon = Color(0xFF8F3F3F);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFFDFDFD);
  static const Color textLight = Color(0xFFEEEEEE);
  static const Color textDark = Color(0xFF333333);
}

// Custom theme
final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.primaryGreen,
  scaffoldBackgroundColor: AppColors.backgroundLight,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primaryGreen,
    foregroundColor: AppColors.textLight,
    elevation: 0,
  ),
  tabBarTheme: TabBarTheme(
    labelColor: AppColors.textLight,
    unselectedLabelColor: AppColors.textLight.withOpacity(0.7),
    indicatorColor: AppColors.secondaryBlue,
  ),
  cardTheme: CardTheme(
    color: AppColors.cardBg,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.secondaryBlue,
      foregroundColor: AppColors.textLight,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.secondaryBlue,
      side: BorderSide(color: AppColors.secondaryBlue),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.secondaryBlue,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.secondaryBlue.withOpacity(0.5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.secondaryBlue, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.secondaryBlue.withOpacity(0.3)),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  ),
  colorScheme: ColorScheme.light(
    primary: AppColors.primaryGreen,
    secondary: AppColors.secondaryBlue,
    error: AppColors.accentMaroon,
  ),
);

class CourseManagementScreen extends StatefulWidget {
  @override
  _CourseManagementScreenState createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    courseProvider.fetchCourses(); // Fetch courses on initialization
    // Update TabController length to 3.
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Function to show delete confirmation dialog
  Future<void> _confirmDelete(BuildContext context, String courseId, String courseTitle) async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Course'),
          content: Text('Are you sure you want to delete "$courseTitle"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
              },
            ),
            TextButton(
              child: Text(
                  'Delete',
                  style: TextStyle(color: AppColors.accentMaroon)
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss dialog
                await courseProvider.deleteCourse(courseId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Course "$courseTitle" deleted successfully.'),
                    backgroundColor: AppColors.accentMaroon,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Colors.white,
          elevation: 5,
        );
      },
    );
  }

  // Function to filter courses based on search query
  List<QueryDocumentSnapshot<Object?>> _filterCourses(List<QueryDocumentSnapshot<Object?>> courses) {
    if (_searchQuery.isEmpty) return courses;
    return courses.where((course) {
      final title = (course.data() as Map<String, dynamic>)['courseTitle']?.toString().toLowerCase() ?? '';
      final description = (course.data() as Map<String, dynamic>)['description']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery) || description.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);

    return Theme(
      data: appTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Course Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Free Courses'),
              Tab(text: 'Premium Courses'),
              Tab(text: 'Review Courses'),
            ],
            indicator: BoxDecoration(
              color: AppColors.secondaryBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            padding: EdgeInsets.symmetric(horizontal: 8),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              tooltip: 'Refresh Courses',
              onPressed: () {
                // Reload courses
                courseProvider.fetchCourses();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Refreshing course list...'),
                    backgroundColor: AppColors.secondaryBlue,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          ],
        ),
        body: courseProvider.isLoading
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryBlue),
          ),
        )
            : courseProvider.hasError
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.accentMaroon,
              ),
              SizedBox(height: 16),
              Text(
                'Error loading courses',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => courseProvider.fetchCourses(),
                child: Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryBlue,
                ),
              ),
            ],
          ),
        )
            : Column(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.secondaryBlue,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: AppColors.secondaryBlue,
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
              ),
            ),
            // Expanded TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Free Courses Tab
                  _buildCourseList(
                    context,
                    courseProvider.getFreeCourses(),
                    'Free Courses',
                  ),
                  // Premium Courses Tab
                  _buildCourseList(
                    context,
                    courseProvider.getPremiumCourses(),
                    'Premium Courses',
                  ),
                  // Review Courses Tab (courses not approved)
                  _buildCourseList(
                    context,
                    courseProvider.getReviewCourses(),
                    'Review Courses',
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: SpeedDial(
          animatedIcon: AnimatedIcons.menu_close,
          backgroundColor: AppColors.secondaryBlue,
          foregroundColor: Colors.white,
          overlayColor: Colors.black,
          overlayOpacity: 0.4,
          spacing: 12,
          spaceBetweenChildren: 12,
          children: [
            SpeedDialChild(
              child: Icon(Icons.add, color: Colors.white),
              label: 'Add Course',
              labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark
              ),
              backgroundColor: AppColors.primaryGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCourseScreen()),
                );
              },
            ),
            SpeedDialChild(
              child: Icon(Icons.refresh, color: Colors.white),
              label: 'Refresh',
              labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark
              ),
              backgroundColor: AppColors.lightBlue,
              onTap: () {
                courseProvider.fetchCourses();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Refreshing course list...'),
                    backgroundColor: AppColors.secondaryBlue,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget to build the course list
  Widget _buildCourseList(BuildContext context, Future<List<QueryDocumentSnapshot<Object?>>?> futureCourses, String courseType) {
    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>?>(
      future: futureCourses,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryBlue),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.accentMaroon,
                ),
                SizedBox(height: 16),
                Text(
                  'Error fetching $courseType',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
                    courseProvider.fetchCourses();
                  },
                  child: Text('Try Again'),
                ),
              ],
            ),
          );
        }

        final courses = _filterCourses(snapshot.data ?? []);

        if (courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty ? Icons.search_off : Icons.school_outlined,
                  size: 64,
                  color: AppColors.secondaryBlue.withOpacity(0.5),
                ),
                SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No results found for "$_searchQuery"'
                      : 'No $courseType available',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: TextButton.icon(
                      icon: Icon(Icons.clear),
                      label: Text('Clear Search'),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final courseProvider = Provider.of<CourseProvider>(context, listen: false);
            await courseProvider.fetchCourses();
          },
          color: AppColors.secondaryBlue,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final courseData = courses[index].data() as Map<String, dynamic>;
              final course = Course.fromMap(courseData, courses[index].id);

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                final title = course.courseTitle?.toLowerCase() ?? '';
                final description = course.description?.toLowerCase() ?? '';
                if (!title.contains(_searchQuery) && !description.contains(_searchQuery)) {
                  return SizedBox.shrink(); // Skip this item
                }
              }

              // Determine course status color
              Color statusColor;
              if (courseType == 'Free Courses') {
                statusColor = AppColors.primaryGreen;
              } else if (courseType == 'Premium Courses') {
                statusColor = AppColors.secondaryBlue;
              } else {
                statusColor = AppColors.accentMaroon;
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  side: BorderSide(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15.0),
                  onTap: () {
                    // Navigate to Course Detail Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseDetailScreen(course: course),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15.0),
                            topRight: Radius.circular(15.0),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Course Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                                  ? Image.network(
                                course.imageUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 100,
                                  height: 100,
                                  color: AppColors.lightBlue.withOpacity(0.1),
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: AppColors.secondaryBlue,
                                  ),
                                ),
                              )
                                  : Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Icon(
                                  Icons.school,
                                  size: 40,
                                  color: AppColors.secondaryBlue,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            // Course Information
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          course.status?.capitalize() ?? 'N/A',
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      if (course.medium != null)
                                        Container(
                                          margin: EdgeInsets.only(left: 8),
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondaryBlue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            course.medium!,
                                            style: TextStyle(
                                              color: AppColors.secondaryBlue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    course.courseTitle ?? 'No Title',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  if (course.instructor != null && course.instructor!.isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 16,
                                          color: AppColors.secondaryBlue,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          course.instructor!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.secondaryBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  SizedBox(height: 8),
                                  Text(
                                    course.description ?? 'No Description',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Price or Free badge
                            Row(
                              children: [
                                Icon(
                                  course.price != null && course.price! > 0
                                      ? Icons.attach_money
                                      : Icons.money_off,
                                  size: 16,
                                  color: course.price != null && course.price! > 0
                                      ? AppColors.secondaryBlue
                                      : AppColors.primaryGreen,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  course.price != null && course.price! > 0
                                      ? '${course.price}'
                                      : 'Free',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: course.price != null && course.price! > 0
                                        ? AppColors.secondaryBlue
                                        : AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                            // Action buttons
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: AppColors.secondaryBlue,
                                  ),
                                  tooltip: 'Edit Course',
                                  onPressed: () {
                                    // Navigate to Edit Course screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditCourseScreen(course: course),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: AppColors.accentMaroon,
                                  ),
                                  tooltip: 'Delete Course',
                                  onPressed: () {
                                    // Show delete confirmation dialog
                                    _confirmDelete(context, course.id!, course.courseTitle ?? 'No Title');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class EditCourseScreen extends StatefulWidget {
  final Course course;

  const EditCourseScreen({required this.course});

  @override
  _EditCourseScreenState createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  late TextEditingController subjectController;
  late TextEditingController instructorController;
  late TextEditingController durationController;
  String? selectedMedium;
  final List<String> mediums = ['Tamil', 'English', 'Sinhala'];

  String? selectedStatus;
  File? selectedImage;
  bool isLoading = false;

  final List<String> statuses = ['free', 'Premium'];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.course.courseTitle);
    descriptionController = TextEditingController(text: widget.course.description);
    priceController = TextEditingController(text: widget.course.price?.toString());
    subjectController = TextEditingController(text: widget.course.subject ?? '');
    instructorController = TextEditingController(text: widget.course.instructor ?? '');
    durationController = TextEditingController(text: widget.course.duration ?? '');
    // Set the selected medium (default to the course value or the first option)
    selectedMedium = widget.course.medium ?? mediums.first;

    selectedStatus = statuses.contains(widget.course.status)
        ? widget.course.status
        : statuses.first;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    return Theme(
      data: appTheme,
      child: Scaffold(
      appBar: AppBar(
      title: Text(
      'Edit Course',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevation: 0,
    ),
    body: Stack(
    children: [
    Container(
    height: 120,
    color: AppColors.primaryGreen,
    ),
    Container(
    margin: EdgeInsets.only(top: 30),
    decoration: BoxDecoration(
    color: AppColors.backgroundLight,
    borderRadius: BorderRadius.only(
    topLeft: Radius.circular(30),
    topRight: Radius.circular(30),
    ),
    ),
    child: SingleChildScrollView(
    padding: const EdgeInsets.all(24.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Center(
    child: GestureDetector(
    onTap: _pickImage,
    child: Stack(
    children: [
    Container(
    width: 120,
    height: 120,
    decoration: BoxDecoration(
    color: AppColors.secondaryBlue.withOpacity(0.1),
    borderRadius: BorderRadius.circular(15.0),
    border: Border.all(
    color: AppColors.secondaryBlue.withOpacity(0.3),
    width: 2,
    ),
    ),
    child: ClipRRect(
    borderRadius: BorderRadius.circular(13.0),
    child: selectedImage != null
    ? Image.file(
    selectedImage!,
    fit: BoxFit.cover,
    )
        : widget.course.imageUrl != null && widget.course.imageUrl!.isNotEmpty
    ? Image.network(
    widget.course.imageUrl!,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => Icon(
    Icons.image,
    size: 60,
    color: AppColors.secondaryBlue,
    ),
    )
        : Icon(
    Icons.image,
    size: 60,
    color: AppColors.secondaryBlue,
    ),
    ),
    ),
      Positioned(
        right: 0,
        bottom: 0,
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondaryBlue,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    ],
    ),
    ),
    ),
      SizedBox(height: 32),
      Text(
        'Course Information',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGreen,
        ),
      ),
      SizedBox(height: 16),

      // Title Field
      _buildInputField(
        controller: titleController,
        label: 'Course Title',
        hintText: 'Enter course title',
        icon: Icons.title,
      ),
      SizedBox(height: 16),

      // Instructor Field
      _buildInputField(
        controller: instructorController,
        label: 'Instructor',
        hintText: 'Enter instructor name',
        icon: Icons.person,
      ),
      SizedBox(height: 16),

      // Medium Dropdown
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: selectedMedium,
          decoration: InputDecoration(
            labelText: 'Medium',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: Icon(
              Icons.language,
              color: AppColors.secondaryBlue,
            ),
          ),
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a medium';
            }
            return null;
          },
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      SizedBox(height: 16),

      // Description Field
      _buildInputField(
        controller: descriptionController,
        label: 'Course Description',
        hintText: 'Enter course description',
        icon: Icons.description,
        maxLines: 3,
      ),
      SizedBox(height: 16),

      // Duration Field
      _buildInputField(
        controller: durationController,
        label: 'Course Duration',
        hintText: 'Enter course duration (e.g., 4 weeks)',
        icon: Icons.timer,
      ),
      SizedBox(height: 16),

      // Price Field
      _buildInputField(
        controller: priceController,
        label: 'Price',
        hintText: 'Enter price (e.g., 20.99)',
        icon: Icons.attach_money,
        keyboardType: TextInputType.number,
      ),
      SizedBox(height: 16),

      // Status Dropdown
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: selectedStatus,
          items: statuses
              .map(
                (status) => DropdownMenuItem(
              value: status,
              child: Text(
                status[0].toUpperCase() + status.substring(1),
              ),
            ),
          )
              .toList(),
          onChanged: (value) => setState(() {
            selectedStatus = value;
          }),
          decoration: InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: Icon(
              Icons.bookmark,
              color: AppColors.secondaryBlue,
            ),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      SizedBox(height: 16),

      // Subject Field
      _buildInputField(
        controller: subjectController,
        label: 'Subject',
        hintText: 'Enter subject name',
        icon: Icons.book,
      ),
      SizedBox(height: 32),

      // Save Button
      Container(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(Icons.save),
          label: Text('Save Changes'),
          onPressed: isLoading
              ? null
              : () async {
            if (titleController.text.isEmpty ||
                descriptionController.text.isEmpty ||
                subjectController.text.isEmpty ||
                selectedStatus == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please fill in all required fields'),
                  backgroundColor: AppColors.accentMaroon,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              return;
            }

            setState(() => isLoading = true);

            // Handle image upload
            String? imageUrl = widget.course.imageUrl;
            if (selectedImage != null) {
              imageUrl = await courseProvider.uploadImage(selectedImage!);
            }

            // Update course fields
            widget.course.courseTitle = titleController.text;
            widget.course.description = descriptionController.text;
            widget.course.price = double.tryParse(priceController.text);
            widget.course.status = selectedStatus;
            widget.course.subject = subjectController.text;
            widget.course.imageUrl = imageUrl;
            widget.course.instructor = instructorController.text;
            widget.course.duration = durationController.text;
            widget.course.medium = selectedMedium;

            await courseProvider.updateCourse(widget.course);

            setState(() => isLoading = false);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Course updated successfully'),
                backgroundColor: AppColors.primaryGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );

            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryBlue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      SizedBox(height: 16),

      // Cancel Button
      Container(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: Icon(Icons.cancel),
          label: Text('Cancel'),
          onPressed: () {
            Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentMaroon,
            side: BorderSide(color: AppColors.accentMaroon),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      SizedBox(height: 32),
    ],
    ),
    ),
    ),

      // Full-Screen Loading Indicator
      if (isLoading)
        Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryBlue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Saving changes...',
                    style: TextStyle(
                      color: AppColors.secondaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
    ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.secondaryBlue,
          ),
        ),
      ),
    );
  }
}

class AddCourseScreen extends StatefulWidget {
  @override
  _AddCourseScreenState createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController instructorController= TextEditingController();
  final TextEditingController durationController= TextEditingController();
  String? selectedMedium;
  final List<String> mediums = ['Tamil', 'English', 'Sinhala'];

  String? selectedStatus = 'free';
  File? selectedImage;
  bool isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    return Theme(
      data: appTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Add New Course',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevation: 0,
        ),
        body: Stack(
          children: [
            Container(
              height: 120,
              color: AppColors.primaryGreen,
            ),
            Container(
              margin: EdgeInsets.only(top: 30),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15.0),
                                border: Border.all(
                                  color: AppColors.secondaryBlue.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13.0),
                                child: selectedImage != null
                                    ? Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                )
                                    : Icon(
                                  Icons.image,
                                  size: 60,
                                  color: AppColors.secondaryBlue,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    Text(
                      'New Course Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Title Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Course Title',
                          hintText: 'Enter course title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(
                            Icons.title,
                            color: AppColors.secondaryBlue,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Medium Dropdown
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedMedium,
                        decoration: InputDecoration(
                          labelText: 'Course Medium',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(
                            Icons.language,
                            color: AppColors.secondaryBlue,
                          ),
                        ),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a medium';
                          }
                          return null;
                        },
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Description Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Course Description',
                          hintText: 'Enter course description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(
                            Icons.description,
                            color: AppColors.secondaryBlue,
                          ),
                        ),
                        maxLines: 3,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Duration Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: durationController,
                        decoration: InputDecoration(
                          labelText: 'Course Duration',
                          hintText: 'Enter course duration (e.g., 4 weeks)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(
                            Icons.timer,
                            color: AppColors.secondaryBlue,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Price Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Price',
                          hintText: 'Enter price (e.g., 20.99)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: AppColors.secondaryBlue,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Status Dropdown
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        items: ['free', 'Premium']
                            .map(
                              (status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              status[0].toUpperCase() + status.substring(1),
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: (value) => setState(() {
                          selectedStatus = value;
                        }),
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(
                            Icons.bookmark,
                            color: AppColors.secondaryBlue,
                          ),
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Subject Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: subjectController,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          hintText: 'Enter subject name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(
                            Icons.book,
                            color: AppColors.secondaryBlue,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Instructor Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: instructorController,
                        decoration: InputDecoration(
                          labelText: 'Instructor',
                          hintText: 'Enter instructor name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(
                            Icons.person,
                            color: AppColors.secondaryBlue,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),

                    // Add Course Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.add_circle),
                        label: Text('Create Course'),
                        onPressed: isLoading
                            ? null
                            : () async {
                          if (titleController.text.isEmpty ||
                              descriptionController.text.isEmpty ||
                              subjectController.text.isEmpty ||
                              selectedStatus == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please fill in all required fields'),
                                backgroundColor: AppColors.accentMaroon,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                            return;
                          }

                          setState(() => isLoading = true);

                          String? imageUrl;
                          if (selectedImage != null) {
                            imageUrl = await courseProvider.uploadImage(selectedImage!);
                          }

                          await courseProvider.addCourse(
                              title: titleController.text,
                              description: descriptionController.text,
                              price: double.tryParse(priceController.text),
                              imageUrl: imageUrl,
                              status: selectedStatus,
                              subject: subjectController.text,
                              instructor: instructorController.text,
                              duration: durationController.text,
                              medium: selectedMedium
                          );

                          await courseProvider.sendNotificationToAllUsers(
                            title: "New Course Added!",
                            body: "A new course titled '${titleController.text}' is now available. Enroll now!",
                          );

                          setState(() => isLoading = false);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Course created successfully'),
                              backgroundColor: AppColors.primaryGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Cancel Button
                    Container(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.cancel),
                        label: Text('Cancel'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentMaroon,
                          side: BorderSide(color: AppColors.accentMaroon),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Full-Screen Loading Indicator
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryBlue),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Creating your course...',
                          style: TextStyle(
                            color: AppColors.secondaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}