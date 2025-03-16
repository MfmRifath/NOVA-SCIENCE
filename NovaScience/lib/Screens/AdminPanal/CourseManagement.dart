import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart';
import 'CMSAppBar.dart';

import 'CMSDesignSystem.dart';
import 'CourseDetailScreen.dart';

class CourseManagementScreen extends StatefulWidget {
  @override
  _CourseManagementScreenState createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    courseProvider.fetchCourses(); // Fetch courses on initialization
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

  // Function to refresh courses
  Future<void> _refreshCourses() async {
    setState(() {
      _isRefreshing = true;
    });

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    await courseProvider.fetchCourses();

    setState(() {
      _isRefreshing = false;
    });

    showCMSToast(
      context,
      message: 'Courses refreshed successfully',
      icon: Icons.check_circle_outline_rounded,
    );
  }

  // Function to show delete confirmation dialog
  Future<void> _confirmDelete(BuildContext context, String courseId, String courseTitle) async {
    showDialog(
      context: context,
      builder: (context) => CMSConfirmationDialog(
        title: 'Delete Course',
        message: 'Are you sure you want to delete "$courseTitle"? This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: CMSDesignSystem.accentMaroon,
        icon: Icons.delete_forever_rounded,
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () async {
          Navigator.of(context).pop();
          final courseProvider = Provider.of<CourseProvider>(context, listen: false);
          await courseProvider.deleteCourse(courseId);
          showCMSToast(
            context,
            message: 'Course "$courseTitle" deleted successfully.',
            backgroundColor: CMSDesignSystem.accentMaroon,
            icon: Icons.delete_rounded,
          );
        },
      ),
    );
  }

  // Function to filter courses based on search query
  List<QueryDocumentSnapshot<Object?>> _filterCourses(List<QueryDocumentSnapshot<Object?>> courses) {
    if (_searchQuery.isEmpty) return courses;
    return courses.where((course) {
      final title = (course.data() as Map<String, dynamic>)['courseTitle']?.toString().toLowerCase() ?? '';
      final description = (course.data() as Map<String, dynamic>)['description']?.toString().toLowerCase() ?? '';
      final instructor = (course.data() as Map<String, dynamic>)['instructor']?.toString().toLowerCase() ?? '';
      final subject = (course.data() as Map<String, dynamic>)['subject']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery) ||
          description.contains(_searchQuery) ||
          instructor.contains(_searchQuery) ||
          subject.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);

    return Theme(
      data: CMSTheme.lightTheme,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: true,
                pinned: true,
                snap: false,
                title: Text(
                  'Course Management',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CMSDesignSystem.primaryGreen,
                          CMSDesignSystem.lightGreen,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Opacity(
                      opacity: 0.1,
                      child: Image.network(
                        'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh Courses',
                    onPressed: _isRefreshing ? null : _refreshCourses,
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded),
                    onSelected: (value) {
                      if (value == 'export') {
                        showCMSToast(
                          context,
                          message: 'Export feature will be available soon',
                          icon: Icons.info_outline_rounded,
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download_rounded, color: CMSDesignSystem.primaryBlue, size: 20),
                            SizedBox(width: 12),
                            Text('Export Data'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Free Courses'),
                    Tab(text: 'Premium Courses'),
                    Tab(text: 'Review Courses'),
                  ],
                  indicator: CMSTabIndicator(
                    color: Colors.white,
                    radius: 4,
                    height: 4,
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
              ),
            ];
          },
          body: courseProvider.isLoading
              ? CMSLoadingState(message: 'Loading courses...')
              : courseProvider.hasError
              ? CMSErrorState(
            message: 'Error loading courses. Please try again.',
            onRetry: () => courseProvider.fetchCourses(),
          )
              : Column(
            children: [
              // Search Bar
              CMSSearchBar(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                onClear: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
                hintText: 'Search courses by title, description or instructor',
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
                      CMSDesignSystem.freeCourseColor,
                    ),
                    // Premium Courses Tab
                    _buildCourseList(
                      context,
                      courseProvider.getPremiumCourses(),
                      'Premium Courses',
                      CMSDesignSystem.premiumCourseColor,
                    ),
                    // Review Courses Tab (courses not approved)
                    _buildCourseList(
                      context,
                      courseProvider.getReviewCourses(),
                      'Review Courses',
                      CMSDesignSystem.pendingCourseColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: SpeedDial(
          animatedIcon: AnimatedIcons.menu_close,
          backgroundColor: CMSDesignSystem.primaryBlue,
          foregroundColor: Colors.white,
          overlayColor: Colors.black,
          overlayOpacity: 0.4,
          spacing: 12,
          spaceBetweenChildren: 12,
          renderOverlay: true,
          tooltip: 'Course Actions',
          heroTag: 'course-speed-dial',
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          children: [
            SpeedDialChild(
              child: Icon(Icons.add_rounded, color: Colors.white),
              backgroundColor: CMSDesignSystem.primaryGreen,
              label: 'Add Course',
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: CMSDesignSystem.textPrimary,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCourseScreen()),
                );
              },
            ),
            SpeedDialChild(
              child: Icon(Icons.refresh_rounded, color: Colors.white),
              backgroundColor: CMSDesignSystem.lightBlue,
              label: 'Refresh',
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: CMSDesignSystem.textPrimary,
              ),
              onTap: _refreshCourses,
            ),
          ],
        ),
      ),
    );
  }

  // Widget to build the course list
  Widget _buildCourseList(
      BuildContext context,
      Future<List<QueryDocumentSnapshot<Object?>>?> futureCourses,
      String courseType,
      Color statusColor,
      ) {
    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>?>(
      future: futureCourses,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CMSLoadingState(message: 'Loading $courseType...');
        }
        if (snapshot.hasError) {
          return CMSErrorState(
            message: 'Error fetching $courseType. Please try again.',
            onRetry: () {
              final courseProvider = Provider.of<CourseProvider>(context, listen: false);
              courseProvider.fetchCourses();
            },
          );
        }

        final courses = _filterCourses(snapshot.data ?? []);

        if (courses.isEmpty) {
          return CMSEmptyState(
            icon: _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.school_rounded,
            title: _searchQuery.isNotEmpty
                ? 'No results found'
                : 'No $courseType available',
            message: _searchQuery.isNotEmpty
                ? 'No courses match your search for "$_searchQuery"'
                : 'Courses you add will appear here',
            actionButton: _searchQuery.isNotEmpty
                ? TextButton.icon(
              icon: Icon(Icons.clear_rounded),
              label: Text('Clear Search'),
              onPressed: () {
                _searchController.clear();
              },
            )
                : ElevatedButton.icon(
              icon: Icon(Icons.add_rounded),
              label: Text('Add Your First Course'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCourseScreen()),
                );
              },
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshCourses,
          color: statusColor,
          child: ListView.builder(
            padding: EdgeInsets.only(bottom: 80.0), // Add padding for the FloatingActionButton
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final courseData = courses[index].data() as Map<String, dynamic>;
              final course = Course.fromMap(courseData, courses[index].id);

              return CMSCourseCard(
                id: course.id ?? '',
                title: course.courseTitle ?? 'No Title',
                imageUrl: course.imageUrl,
                instructor: course.instructor,
                description: course.description,
                status: course.status,
                medium: course.medium,
                price: course.price,
                isApproved: course.isApproved ?? true,
                onTap: () {
                  // Navigate to Course Detail Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CourseDetailScreen(course: course),
                    ),
                  );
                },
                onEdit: () {
                  // Navigate to Edit Course screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditCourseScreen(course: course),
                    ),
                  );
                },
                onDelete: () {
                  // Show delete confirmation dialog
                  _confirmDelete(context, course.id!, course.courseTitle ?? 'No Title');
                },
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
  final _formKey = GlobalKey<FormState>();

  final List<String> statuses = ['free', 'Premium'];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.course.courseTitle);
    descriptionController = TextEditingController(text: widget.course.description);
    priceController = TextEditingController(text: widget.course.price?.toString() ?? '0');
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
      data: CMSTheme.lightTheme,
      child: Scaffold(
        appBar: CMSAppBar(
          title: 'Edit Course',
          actions: [
            IconButton(
              icon: Icon(Icons.save_rounded),
              tooltip: 'Save Changes',
              onPressed: isLoading
                  ? null
                  : () async {
                if (_formKey.currentState!.validate()) {
                  _saveChanges(courseProvider);
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CMSDesignSystem.primaryGreen,
                    CMSDesignSystem.lightGreen,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: CMSDesignSystem.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
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
                                  color: CMSDesignSystem.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15.0),
                                  border: Border.all(
                                    color: CMSDesignSystem.primaryBlue.withOpacity(0.3),
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
                                      Icons.image_rounded,
                                      size: 50,
                                      color: CMSDesignSystem.primaryBlue,
                                    ),
                                  )
                                      : Icon(
                                    Icons.image_rounded,
                                    size: 50,
                                    color: CMSDesignSystem.primaryBlue,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: CMSDesignSystem.primaryBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
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
                          color: CMSDesignSystem.primaryGreen,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Course Title
                      CMSFormField(
                        controller: titleController,
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

                      // Instructor
                      CMSFormField(
                        controller: instructorController,
                        label: 'Instructor',
                        hintText: 'Enter instructor name',
                        prefixIcon: Icons.person_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an instructor name';
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

                      // Description
                      CMSFormField(
                        controller: descriptionController,
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

                      // Duration
                      CMSFormField(
                        controller: durationController,
                        label: 'Course Duration',
                        hintText: 'Enter course duration (e.g., 4 weeks)',
                        prefixIcon: Icons.timer_rounded,
                      ),

                      // Price
                      CMSFormField(
                        controller: priceController,
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

                      // Status Dropdown
                      CMSDropdownField<String>(
                        label: 'Status',
                        value: selectedStatus,
                        items: statuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              status[0].toUpperCase() + status.substring(1),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                        prefixIcon: Icons.bookmark_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a status';
                          }
                          return null;
                        },
                      ),

                      // Subject
                      CMSFormField(
                        controller: subjectController,
                        label: 'Subject',
                        hintText: 'Enter subject name',
                        prefixIcon: Icons.book_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a subject';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 32),

                      // Save Button
                      CMSButton(
                        text: 'Save Changes',
                        icon: Icons.save_rounded,
                        onPressed: isLoading
                            ? () {}
                            : () {
                          if (_formKey.currentState!.validate()) {
                            _saveChanges(courseProvider);
                          }
                        },
                        isLoading: isLoading,
                      ),

                      SizedBox(height: 16),

                      // Cancel Button
                      CMSButton(
                        text: 'Cancel',
                        icon: Icons.cancel_rounded,
                        isOutlined: true,
                        color: CMSDesignSystem.accentMaroon,
                        textColor: CMSDesignSystem.accentMaroon,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Full-Screen Loading Indicator (shown when isLoading is true)
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(CMSDesignSystem.primaryBlue),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Saving changes...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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

  Future<void> _saveChanges(CourseProvider courseProvider) async {
    setState(() => isLoading = true);

    try {
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

      showCMSToast(
        context,
        message: 'Course updated successfully',
        backgroundColor: CMSDesignSystem.primaryGreen,
        icon: Icons.check_circle_outline_rounded,
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);

      showCMSToast(
        context,
        message: 'Error updating course: ${e.toString()}',
        backgroundColor: CMSDesignSystem.error,
        icon: Icons.error_outline_rounded,
      );
    }
  }
}

class AddCourseScreen extends StatefulWidget {
  @override
  _AddCourseScreenState createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController(text: '0');
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController instructorController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  String? selectedMedium;
  final List<String> mediums = ['Tamil', 'English', 'Sinhala'];

  String? selectedStatus = 'free';
  File? selectedImage;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    selectedMedium = mediums.first;
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
      data: CMSTheme.lightTheme,
      child: Scaffold(
        appBar: CMSAppBar(
          title: 'Add New Course',
          actions: [
            IconButton(
              icon: Icon(Icons.save_rounded),
              tooltip: 'Save Course',
              onPressed: isLoading
                  ? null
                  : () async {
                if (_formKey.currentState!.validate()) {
                  _createCourse(courseProvider);
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CMSDesignSystem.primaryGreen,
                    CMSDesignSystem.lightGreen,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: CMSDesignSystem.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
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
                                  color: CMSDesignSystem.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15.0),
                                  border: Border.all(
                                    color: CMSDesignSystem.primaryBlue.withOpacity(0.3),
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
                                      : Center(
                                    child: Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 50,
                                      color: CMSDesignSystem.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: CMSDesignSystem.primaryBlue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
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
                          color: CMSDesignSystem.primaryGreen,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Course Title
                      CMSFormField(
                        controller: titleController,
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

                      // Instructor
                      CMSFormField(
                        controller: instructorController,
                        label: 'Instructor',
                        hintText: 'Enter instructor name',
                        prefixIcon: Icons.person_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an instructor name';
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

                      // Description
                      CMSFormField(
                        controller: descriptionController,
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

                      // Duration
                      CMSFormField(
                        controller: durationController,
                        label: 'Course Duration',
                        hintText: 'Enter course duration (e.g., 4 weeks)',
                        prefixIcon: Icons.timer_rounded,
                      ),

                      // Price
                      CMSFormField(
                        controller: priceController,
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

                      // Status Dropdown
                      CMSDropdownField<String>(
                        label: 'Status',
                        value: selectedStatus,
                        items: ['free', 'Premium'].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              status[0].toUpperCase() + status.substring(1),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                        prefixIcon: Icons.bookmark_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a status';
                          }
                          return null;
                        },
                      ),

                      // Subject
                      CMSFormField(
                        controller: subjectController,
                        label: 'Subject',
                        hintText: 'Enter subject name',
                        prefixIcon: Icons.book_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a subject';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 32),

                      // Create Course Button
                      CMSButton(
                        text: 'Create Course',
                        icon: Icons.add_circle_outline_rounded,
                        onPressed: isLoading
                            ? () {}
                            : () {
                          if (_formKey.currentState!.validate()) {
                            _createCourse(courseProvider);
                          }
                        },
                        isLoading: isLoading,
                        color: CMSDesignSystem.primaryGreen,
                      ),

                      SizedBox(height: 16),

                      // Cancel Button
                      CMSButton(
                        text: 'Cancel',
                        icon: Icons.cancel_rounded,
                        isOutlined: true,
                        color: CMSDesignSystem.accentMaroon,
                        textColor: CMSDesignSystem.accentMaroon,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Full-Screen Loading Indicator
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(CMSDesignSystem.primaryGreen),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Creating your course...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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

  Future<void> _createCourse(CourseProvider courseProvider) async {
    setState(() => isLoading = true);

    try {
      // Upload the image if selected
      String? imageUrl;
      if (selectedImage != null) {
        imageUrl = await courseProvider.uploadImage(selectedImage!);
      }

      // Add the course
      await courseProvider.addCourse(
        title: titleController.text,
        description: descriptionController.text,
        price: double.tryParse(priceController.text),
        imageUrl: imageUrl,
        status: selectedStatus,
        subject: subjectController.text,
        instructor: instructorController.text,
        duration: durationController.text,
        medium: selectedMedium,
      );

      // Send a notification to all users
      await courseProvider.sendNotificationToAllUsers(
        title: "New Course Added!",
        body: "A new course titled '${titleController.text}' is now available. Enroll now!",
      );

      setState(() => isLoading = false);

      showCMSToast(
        context,
        message: 'Course created successfully',
        backgroundColor: CMSDesignSystem.primaryGreen,
        icon: Icons.check_circle_outline_rounded,
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);

      showCMSToast(
        context,
        message: 'Error creating course: ${e.toString()}',
        backgroundColor: CMSDesignSystem.error,
        icon: Icons.error_outline_rounded,
      );
    }
  }
}