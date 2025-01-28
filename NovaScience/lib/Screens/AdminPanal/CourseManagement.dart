
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Your own imports
import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart';
import 'CourseDetailScreen.dart';
// Ensure this is correctly imported

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
    _tabController = TabController(length: 2, vsync: this);
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
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss dialog
                await courseProvider.deleteCourse(courseId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Course "$courseTitle" deleted successfully.')),
                );
              },
            ),
          ],
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Course Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Free Courses'),
            Tab(text: 'Premium Courses'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Courses',
            onPressed: () {
              // Reload courses
              courseProvider.fetchCourses();
            },
          ),
        ],
      ),
      body: courseProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : courseProvider.hasError
          ? Center(child: Text('Error loading courses'))
          : Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
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
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Colors.blue,
        // Ensure the SpeedDial has a defined size
        // Wrap it in a SizedBox if necessary
        // Alternatively, use the SpeedDial's properties to adjust size
        children: [
          SpeedDialChild(
            child: Icon(Icons.add, color: Colors.white),
            label: 'Add Course',
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.orange,
            onTap: () {
              courseProvider.fetchCourses();
            },
          ),
        ],
      ),
    );
  }

  // Widget to build the course list
  Widget _buildCourseList(BuildContext context, Future<List<QueryDocumentSnapshot<Object?>>?> futureCourses, String courseType) {
    return FutureBuilder<List<QueryDocumentSnapshot<Object?>>?>(
      future: futureCourses,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error fetching $courseType'));
        }

        final courses = _filterCourses(snapshot.data ?? []);

        if (courses.isEmpty) {
          return Center(child: Text('No $courseType available'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            final courseProvider = Provider.of<CourseProvider>(context, listen: false);
            await courseProvider.fetchCourses();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
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

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                elevation: 3.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                child: ListTile(
                  leading: course.imageUrl != null && course.imageUrl!.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      course.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 60, color: Colors.grey),
                    ),
                  )
                      : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(Icons.school, size: 40, color: Colors.white),
                  ),
                  title: Text(
                    course.courseTitle ?? 'No Title',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    course.description ?? 'No Description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Wrap(
                    spacing: 12, // space between two icons
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
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
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Course',
                        onPressed: () {
                          // Show delete confirmation dialog
                          _confirmDelete(context, course.id!, course.courseTitle ?? 'No Title');
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to Course Detail Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseDetailScreen(course: course),
                      ),
                    );
                  },
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

  String? selectedStatus;
  String? selectedSubject;
  DateTime? startDate;
  DateTime? endDate;
  File? selectedImage;
  bool isLoading = false;

  final List<String> statuses = ['free', 'premium'];
  final List<String> subjects = ['Math', 'Science', 'History', 'Programming'];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.course.courseTitle);
    descriptionController = TextEditingController(text: widget.course.description);
    priceController = TextEditingController(
      text: widget.course.price?.toString(),
    );

    // Validate selectedStatus and selectedSubject
    selectedStatus = statuses.contains(widget.course.status)
        ? widget.course.status
        : statuses.first;
    selectedSubject = subjects.contains(widget.course.subject)
        ? widget.course.subject
        : subjects.first;
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

    return Scaffold(
      appBar: AppBar(title: Text('Edit Course')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Course Title
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Course Title'),
            ),
            const SizedBox(height: 10),

            // Course Description
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Course Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),

            // Course Price
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 10),

            // Status Dropdown
            DropdownButtonFormField<String>(
              value: selectedStatus,
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
              items: statuses
                  .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              ))
                  .toList(),
              decoration: InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 10),

            // Subject Dropdown
            DropdownButtonFormField<String>(
              value: selectedSubject,
              onChanged: (value) {
                setState(() {
                  selectedSubject = value;
                });
              },
              items: subjects.map((subject) {
                return DropdownMenuItem(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              decoration: InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 10),


            // Image Picker
            ElevatedButton.icon(
              icon: Icon(Icons.image),
              label: Text(selectedImage == null ? 'Pick Image' : 'Change Image'),
              onPressed: _pickImage,
            ),
            if (selectedImage != null)
              Image.file(
                selectedImage!,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    selectedStatus == null ||
                    selectedSubject == null ||
                    startDate == null ||
                    endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                setState(() {
                  isLoading = true;
                });

                // Handle image upload
                String? imageUrl = widget.course.imageUrl;
                if (selectedImage != null) {
                  imageUrl = await courseProvider.uploadImage(selectedImage!);
                }

                // Update the course fields
                widget.course.courseTitle = titleController.text;
                widget.course.description = descriptionController.text;
                widget.course.price = double.tryParse(priceController.text);
                widget.course.status = selectedStatus;
                widget.course.subject = selectedSubject;
                widget.course.imageUrl = imageUrl;

                // Call provider to update
                await courseProvider.updateCourse(widget.course);

                setState(() {
                  isLoading = false;
                });

                Navigator.pop(context);
              },
              child: Text('Save Changes'),
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

class AddCourseScreen extends StatefulWidget {
  @override
  _AddCourseScreenState createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  String? selectedStatus = 'free';
  String? selectedSubject;
  DateTime? startDate;
  DateTime? endDate;
  File? selectedImage;
  bool isLoading = false;

  final List<String> subjects = ['Math', 'Science', 'History', 'Programming'];

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

    return Scaffold(
      appBar: AppBar(title: Text('Add New Course')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Course Title
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Course Title'),
            ),
            const SizedBox(height: 10),

            // Course Description
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Course Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),

            // Course Price
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 10),

            // Status Dropdown
            DropdownButtonFormField<String>(
              value: selectedStatus,
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
              items: ['free', 'premium']
                  .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              ))
                  .toList(),
              decoration: InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 10),

            // Subject Dropdown
            DropdownButtonFormField<String>(
              value: selectedSubject,
              onChanged: (value) {
                setState(() {
                  selectedSubject = value;
                });
              },
              items: subjects
                  .map((subject) => DropdownMenuItem(
                value: subject,
                child: Text(subject),
              ))
                  .toList(),
              decoration: InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 10),

            // Start Date Picker
            ListTile(
              title: Text(
                startDate == null
                    ? 'Pick Start Date'
                    : 'Start Date: ${startDate!.toLocal()}'.split(' ')[0],
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    startDate = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 10),

            // End Date Picker
            ListTile(
              title: Text(
                endDate == null
                    ? 'Pick End Date'
                    : 'End Date: ${endDate!.toLocal()}'.split(' ')[0],
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    endDate = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 10),

            // Image Picker
            ElevatedButton.icon(
              icon: Icon(Icons.image),
              label:
              Text(selectedImage == null ? 'Pick Image' : 'Change Image'),
              onPressed: _pickImage,
            ),
            if (selectedImage != null)
              Image.file(
                selectedImage!,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 20),

            // Add Course Button
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    selectedStatus == null ||
                    selectedSubject == null ||
                    startDate == null ||
                    endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in all fields'),
                    ),
                  );
                  return;
                }

                setState(() => isLoading = true);

                String? imageUrl;
                if (selectedImage != null) {
                  imageUrl = await courseProvider.uploadImage(
                    selectedImage!,
                  );
                }

                await courseProvider.addCourse(
                  title: titleController.text,
                  description: descriptionController.text,
                  price: double.tryParse(priceController.text),
                  startDate: startDate,
                  endDate: endDate,
                  imageUrl: imageUrl,
                  status: selectedStatus,
                  subject: selectedSubject,
                );

                setState(() => isLoading = false);
                Navigator.pop(context);
              },
              child: Text('Add Course'),
            ),
          ],
        ),
      ),
    );
  }
}