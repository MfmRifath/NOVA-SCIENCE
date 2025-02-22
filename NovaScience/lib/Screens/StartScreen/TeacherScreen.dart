import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../Service/AuthService.dart';
import '../../Service/CourseProvider.dart';
import 'ManageSectionsScreen.dart';

class TeacherScreen extends StatefulWidget {
  @override
  _TeacherScreenState createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _courseImage;

  // Currently editing course
  String? _currentCourseId;
  String? _currentImageUrl;

  // Dropdown for Medium
  String? _selectedMedium;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    return Scaffold(
      /// 1) **AppBar** with gradient background
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blueAccent.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======= EARNINGS SECTION =======
            _buildEarningsSection(authService, courseProvider),
            const SizedBox(height: 20),

            // ======= COURSE FORM =======
            _buildCourseForm(context, authService, courseProvider)
                .animate()
                .fade(duration: 400.ms)
                .slideY(begin: 0.05),

            const SizedBox(height: 20),

            // ======= LIST OF COURSES =======
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTeacherCourses(authService),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error loading courses. Please try again.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No courses found'));
                } else {
                  final courses = snapshot.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: courses.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return _buildCourseListItem(
                          context, courseProvider, course);
                    },
                  )
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.05, curve: Curves.easeInOut);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // (A) EARNINGS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildEarningsSection(
      AuthService authService, CourseProvider courseProvider) {
    return Column(
      children: [
        // 1) TEACHER'S OVERALL EARNINGS (Card)
        FutureBuilder<double>(
          future: _fetchTeacherEarnings(authService, courseProvider),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading earnings'));
            } else {
              double earnings = snapshot.data ?? 0;
              return _buildEarningsCard(earnings)
                  .animate()
                  .fade(duration: 500.ms)
                  .slideY(begin: -0.1, curve: Curves.easeOut);
            }
          },
        ),

        const SizedBox(height: 20),

        // 2) TEACHER'S MONTHLY EARNINGS ACROSS ALL COURSES
        _buildTeacherMonthlyEarningsSection(context),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // (B) SINGLE EARNINGS CARD
  // ---------------------------------------------------------------------------
  Widget _buildEarningsCard(double earnings) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blueAccent.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Icon(
              Icons.monetization_on_rounded,
              color: Colors.white.withOpacity(0.15),
              size: 100,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Earnings',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween<double>(begin: 0, end: earnings),
                  builder: (context, double value, child) {
                    return Text(
                      '\$${value.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // (C) TEACHER MONTHLY EARNINGS (ALL COURSES)
  // ---------------------------------------------------------------------------
  Widget _buildTeacherMonthlyEarningsSection(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return FutureBuilder<String?>(
      future: authService.getCurrentUserEmail(),
      builder: (context, snapshotEmail) {
        if (snapshotEmail.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshotEmail.hasError || snapshotEmail.data == null) {
          return const Center(child: Text('Error fetching teacher email'));
        }

        final teacherEmail = snapshotEmail.data!;
        return FutureBuilder<Map<String, double>>(
          future: _fetchMonthlyEarningsForTeacher(teacherEmail),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (snapshot.hasError) {
              return const Center(
                  child: Text('Error loading monthly teacher earnings'));
            } else {
              final monthlyData = snapshot.data ?? {};
              if (monthlyData.isEmpty) {
                return const Center(child: Text('No monthly earnings data'));
              }

              return Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ExpansionTile(
                  leading: const Icon(Icons.bar_chart_outlined,
                      color: Colors.blue),
                  title: const Text(
                    'Monthly Teacher Earnings (All Courses)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: monthlyData.entries.map((entry) {
                    final month = entry.key; // "YYYY-MM"
                    final totalEarning = entry.value;
                    return ListTile(
                      leading: const Icon(Icons.calendar_month,
                          color: Colors.blueGrey),
                      title: Text(month),
                      trailing: Text(
                        '\$${totalEarning.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fade(duration: 600.ms).slideY(begin: 0.1);
            }
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // (D) COURSE FORM
  // ---------------------------------------------------------------------------
  Widget _buildCourseForm(BuildContext context, AuthService authService,
      CourseProvider courseProvider) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE
              Text(
                _currentCourseId == null
                    ? 'Create New Course'
                    : 'Edit Course',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              const SizedBox(height: 15),

              // IMAGE PICKER
              Center(child: _buildImagePicker(context)),
              const SizedBox(height: 15),

              // FORM FIELDS
              _buildTextField(_titleController, 'Course Title', Icons.title),
              const SizedBox(height: 10),
              _buildTextField(
                  _descriptionController, 'Description', Icons.description),
              const SizedBox(height: 10),
              _buildTextField(
                  _instructorController, 'Instructor', Icons.person),
              const SizedBox(height: 10),
              _buildTextField(
                  _priceController, 'Price', Icons.attach_money,
                  isNumeric: true),
              const SizedBox(height: 10),
              _buildTextField(_durationController, 'Duration', Icons.timer),
              const SizedBox(height: 10),
              _buildTextField(_subjectController, 'Subject', Icons.subject),
              const SizedBox(height: 20),

              // DROPDOWN
              _buildMediumDropdown(),
              const SizedBox(height: 20),

              // SUBMIT BUTTON
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // 1) Get instructor email
                      String? instructorEmail =
                      await authService.getCurrentUserEmail();
                      if (instructorEmail == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                              Text('Error: Instructor email not found')),
                        );
                        return;
                      }

                      // 2) Course ID
                      String courseId = _currentCourseId ??
                          DateTime.now().millisecondsSinceEpoch.toString();

                      // 3) Upload image
                      String? imageUrl = await _uploadCourseImage(courseId);

                      // 4) Create / Update
                      if (_currentCourseId == null) {
                        await courseProvider.addCourse(
                          title: _titleController.text,
                          description: _descriptionController.text,
                          price: double.tryParse(_priceController.text),
                          duration: _durationController.text,
                          subject: _subjectController.text,
                          instructor: _instructorController.text,
                          status: 'Premium',
                          instructorEmail: instructorEmail,
                          imageUrl: imageUrl,
                          medium: _selectedMedium,
                        );
                      } else {
                        await courseProvider.editCourse(
                          _currentCourseId!,
                          _titleController.text,
                          _descriptionController.text,
                          double.tryParse(_priceController.text),
                          _subjectController.text,
                          imageUrl ?? _currentImageUrl!,
                          _selectedMedium!,
                        );
                      }

                      // 5) Show success
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_currentCourseId == null
                              ? 'Course created successfully!'
                              : 'Course updated successfully!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green.shade600,
                        ),
                      );

                      // 6) Clear
                      _clearFormFields();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                  ),
                  child: Text(
                    _currentCourseId == null
                        ? 'Create Course'
                        : 'Update Course',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey.shade700),
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      validator: (value) => value!.isEmpty ? '$label is required' : null,
    );
  }

  Widget _buildMediumDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMedium,
      decoration: InputDecoration(
        labelText: 'Medium',
        prefixIcon: const Icon(Icons.density_medium),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      items: ['Tamil', 'English', 'Sinhala']
          .map(
            (medium) => DropdownMenuItem<String>(
          value: medium,
          child: Text(medium),
        ),
      )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedMedium = value;
        });
      },
      validator: (value) =>
      (value == null || value.isEmpty) ? 'Select a medium' : null,
    );
  }

  // ---------------------------------------------------------------------------
  // (E) IMAGE PICKER
  // ---------------------------------------------------------------------------
  Widget _buildImagePicker(BuildContext context) {
    return InkWell(
      onTap: () => _showImageSourceDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 170,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // If user selected an image, display it
            if (_courseImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _courseImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 170,
                ).animate().fade(duration: 500.ms),
              )
            // If an image URL exists, load it from network
            else if (_currentImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _currentImageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 170,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                            (progress.expectedTotalBytes ?? 1)
                            : null,
                        color: Colors.blue.shade400,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(),
                ),
              ).animate().fade(duration: 500.ms)
            // Otherwise, show placeholder
            else
              _buildPlaceholder().animate().fade(duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt, size: 45, color: Colors.blue.shade500),
        const SizedBox(height: 8),
        Text(
          'Tap to add course image',
          style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade600),
        ),
      ],
    ).animate().fade().slideY(begin: 0.2, duration: 400.ms);
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.image, size: 50, color: Colors.blue.shade600),
            const SizedBox(height: 10),
            const Text(
              'Choose Image Source',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Select where you want to upload the course image from.',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            icon: const Icon(Icons.camera_alt, size: 20),
            label: const Text('Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            icon: const Icon(Icons.photo_library, size: 20),
            label: const Text('Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ).animate().fade(duration: 300.ms),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _courseImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadCourseImage(String courseId) async {
    if (_courseImage == null) return null;
    try {
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('course_images')
          .child('$courseId.jpg');
      await storageRef.putFile(_courseImage!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // (F) LIST OF COURSES
  // ---------------------------------------------------------------------------
  Widget _buildCourseListItem(
      BuildContext context, CourseProvider courseProvider, Map course) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: course['imageUrl'] != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            course['imageUrl'],
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        )
            : const Icon(Icons.image, size: 50),
        title: Text(
          course['courseTitle'],
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Subject: ${course['subject']}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        children: [
          // (F1) Monthly Earnings for This Course
          FutureBuilder<Map<String, Map<String, double>>>(
            future: _fetchMonthlyEarningsForCourse(
              course['id'],
              course['price'] ?? 0.0,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:
                  Text('Error loading monthly earnings: ${snapshot.error}'),
                );
              } else {
                final data = snapshot.data;
                if (data == null || data[course['id']] == null) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No enrollment earnings data found'),
                  );
                }
                final monthlyData = data[course['id']]!;
                if (monthlyData.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No enrollment earnings recorded'),
                  );
                }

                return _buildMonthlyEarningsList(monthlyData);
              }
            },
          ),

          // (F2) Popup Menu for course actions
          ButtonBar(
            alignment: MainAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    _editCourse(context, course, courseProvider);
                  } else if (value == 'delete') {
                    await courseProvider.deleteCourse(course['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Course deleted successfully!')),
                    );
                  } else if (value == 'manageSections') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ManageSectionsScreen(courseId: course['id']),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'edit', child: Text('Edit Course')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Delete Course')),
                  const PopupMenuItem(
                      value: 'manageSections', child: Text('Manage Sections')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // (F1) Helper to build monthly earnings list
  Widget _buildMonthlyEarningsList(Map<String, double> monthlyData) {
    final monthTiles = monthlyData.entries.map((entry) {
      final month = entry.key; // e.g., "2025-02"
      final earnings = entry.value;
      return ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.blueGrey),
        title: Text(month),
        trailing: Text(
          '\$${earnings.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }).toList();

    return Column(children: monthTiles)
        .animate()
        .fade(duration: 400.ms)
        .slideY(begin: 0.1, curve: Curves.easeIn);
  }

  // ---------------------------------------------------------------------------
  // (G) FETCHING DATA
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchTeacherCourses(
      AuthService authService) async {
    String? email = await authService.getCurrentUserEmail();
    if (email == null) return [];

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: email)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<double> _fetchTeacherEarnings(
      AuthService authService, CourseProvider courseProvider) async {
    String? email = await authService.getCurrentUserEmail();
    if (email == null) return 0.0;
    return courseProvider.calculateTeacherEarnings(email);
  }

  /// Returns { courseId: { 'YYYY-MM': monthlyEarning } }
  Future<Map<String, Map<String, double>>> _fetchMonthlyEarningsForCourse(
      String courseId, double coursePrice) async {
    final userSnapshot =
    await FirebaseFirestore.instance.collection('users').get();

    Map<String, int> monthCount = {};
    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final List<dynamic>? enrolledCourses = userData['enrolledCourses'];
      if (enrolledCourses == null) continue;

      for (var enrolled in enrolledCourses) {
        if (enrolled is Map<String, dynamic>) {
          if (enrolled['courseId'] == courseId) {
            final Timestamp? ts = enrolled['enrollmentDate'];
            if (ts == null) continue;

            final date = ts.toDate();
            final monthKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}';

            monthCount.update(
              monthKey,
                  (existing) => existing + 1,
              ifAbsent: () => 1,
            );
          }
        }
      }
    }

    Map<String, double> monthlyEarnings = {};
    monthCount.forEach((month, count) {
      monthlyEarnings[month] = count * coursePrice;
    });

    return {courseId: monthlyEarnings};
  }

  /// Returns { 'YYYY-MM': totalEarningAcrossAllCourses }
  Future<Map<String, double>> _fetchMonthlyEarningsForTeacher(
      String teacherEmail) async {
    // 1) All courses for this teacher
    final courseSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('instructorEmail', isEqualTo: teacherEmail)
        .get();

    final Map<String, double> teacherCourses = {};
    for (var doc in courseSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final priceValue = data['price'] ?? 0.0;
      final double coursePrice = double.tryParse(priceValue.toString()) ?? 0.0;
      teacherCourses[doc.id] = coursePrice;
    }

    final Map<String, double> monthlyEarnings = {};
    final userSnapshot =
    await FirebaseFirestore.instance.collection('users').get();

    for (var userDoc in userSnapshot.docs) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final List<dynamic>? enrolledCourses = userData['enrolledCourses'];
      if (enrolledCourses == null) continue;

      for (var enrolled in enrolledCourses) {
        if (enrolled is Map<String, dynamic>) {
          final String? cId = enrolled['courseId'];
          if (cId != null && teacherCourses.containsKey(cId)) {
            final Timestamp? ts = enrolled['enrollmentDate'];
            if (ts == null) continue;
            final date = ts.toDate();
            final monthKey =
                '${date.year}-${date.month.toString().padLeft(2, '0')}';

            final double price = teacherCourses[cId] ?? 0.0;
            monthlyEarnings.update(
              monthKey,
                  (existing) => existing + price,
              ifAbsent: () => price,
            );
          }
        }
      }
    }

    return monthlyEarnings;
  }

  // ---------------------------------------------------------------------------
  // (H) EDIT COURSE & CLEAR FORM
  // ---------------------------------------------------------------------------
  void _editCourse(
      BuildContext context,
      Map course,
      CourseProvider courseProvider,
      ) {
    setState(() {
      _currentCourseId = course['id'];
      _titleController.text = course['courseTitle'];
      _descriptionController.text = course['description'];
      _priceController.text = course['price'].toString();
      _durationController.text = course['duration'];
      _subjectController.text = course['subject'];
      _instructorController.text = course['instructor'];
      _currentImageUrl = course['imageUrl'];
      _courseImage = null;
      _selectedMedium = course['medium'];
    });

    // Animate to the form so the user can see it
    Scrollable.ensureVisible(
      _formKey.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _clearFormFields() {
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _durationController.clear();
    _subjectController.clear();
    _instructorController.clear();

    setState(() {
      _courseImage = null;
      _currentCourseId = null;
      _currentImageUrl = null;
      _selectedMedium = null;
    });
  }
}