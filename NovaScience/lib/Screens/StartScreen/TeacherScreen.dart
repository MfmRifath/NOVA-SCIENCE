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

class _TeacherScreenState extends State<TeacherScreen> {
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======== EARNINGS CARD ========
            FutureBuilder<double>(
              future: _fetchTeacherEarnings(authService, courseProvider),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading earnings'));
                } else {
                  double earnings = snapshot.data ?? 0;
                  return _buildEarningsCard(earnings);
                }
              },
            ),
            SizedBox(height: 20),

            // ======== COURSE FORM CARD ========
            _buildCourseForm(context, authService, courseProvider),
            SizedBox(height: 20),

            // ======== LIST OF COURSES ========
            FutureBuilder(
              future: _fetchTeacherCourses(authService, courseProvider),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading courses'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No courses found'));
                } else {
                  final courses = snapshot.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: courses.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return _buildCourseListItem(context, courseProvider, course);
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),


    );
  }

  /// Builds the gradient Earnings card at the top of the screen.
  Widget _buildEarningsCard(double earnings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(4, 4),
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
                color: Colors.white.withOpacity(0.2),
                size: 80,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Earnings',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  TweenAnimationBuilder(
                    duration: Duration(milliseconds: 1000),
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
      ),
    );
  }



  /// Builds the course creation/edit form inside a card.
  Widget _buildCourseForm(BuildContext context, AuthService authService,
      CourseProvider courseProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ======== TITLE ========
                Text(
                  _currentCourseId == null ? 'Create New Course' : 'Edit Course',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 15),

                // ======== IMAGE PICKER ========
                Center(child: _buildImagePicker(context)),
                SizedBox(height: 15),

                // ======== COURSE TITLE ========
                _buildTextField(_titleController, 'Course Title', Icons.title),
                SizedBox(height: 10),

                // ======== DESCRIPTION ========
                _buildTextField(
                    _descriptionController, 'Description', Icons.description),
                SizedBox(height: 10),

                // ======== INSTRUCTOR ========
                _buildTextField(
                    _instructorController, 'Instructor', Icons.person),
                SizedBox(height: 10),

                // ======== PRICE ========
                _buildTextField(_priceController, 'Price', Icons.attach_money,
                    isNumeric: true),
                SizedBox(height: 10),

                // ======== DURATION ========
                _buildTextField(
                    _durationController, 'Duration', Icons.timer),
                SizedBox(height: 10),

                // ======== SUBJECT ========
                _buildTextField(
                    _subjectController, 'Subject', Icons.subject),
                SizedBox(height: 20),

                // ======== SUBMIT BUTTON ========
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // 1. Get instructor email
                        String? instructorEmail =
                        await authService.getCurrentUserEmail();
                        if (instructorEmail == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: Instructor email not found')),
                          );
                          return;
                        }

                        // 2. Generate or use existing course ID
                        String courseId = _currentCourseId ??
                            DateTime.now().millisecondsSinceEpoch.toString();

                        // 3. Upload image if available
                        String? imageUrl = await _uploadCourseImage(courseId);

                        // 4. Create or update course
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
                          );
                        } else {
                          await courseProvider.editCourse(
                            _currentCourseId!,
                            _titleController.text,
                            _descriptionController.text,
                            double.tryParse(_priceController.text),
                            _subjectController.text,
                            imageUrl ?? _currentImageUrl!,
                          );
                        }

                        // 5. Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_currentCourseId == null
                                ? 'Course created successfully!'
                                : 'Course updated successfully!'),
                          ),
                        );

                        // 6. Clear fields
                        _clearFormFields();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                    ),
                    child: Text(
                      _currentCourseId == null ? 'Create Course' : 'Update Course',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Custom reusable text field builder with enhanced UI/UX.
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool isNumeric = false,
        bool isPassword = false,
        bool autoCapitalize = false,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      obscureText: isPassword, // Support for password fields
      textCapitalization:
      autoCapitalize ? TextCapitalization.words : TextCapitalization.none,
      style: TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey.shade700),
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      validator: (value) => value!.isEmpty ? '$label is required' : null,
    );
  }

  /// Builds the image picker widget (tap to pick or change an image).
  Widget _buildImagePicker(BuildContext context) {
    return InkWell(
      onTap: () => _showImageSourceDialog(context),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey[200],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // If user selected an image, display it
            if (_courseImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  _courseImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                ).animate().fade(duration: 500.ms), // Smooth fade effect
              )
            // If an image URL exists, load it from the network
            else if (_currentImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  _currentImageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
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
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                ).animate().fade(duration: 500.ms), // Smooth fade effect
              )
            // Otherwise, show placeholder UI
            else
              _buildPlaceholder(),
          ],
        ),
      ),
    );
  }

  /// Placeholder UI for when no image is selected
  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_rounded, size: 50, color: Colors.blue.shade500),
        SizedBox(height: 8),
        Text(
          'Tap to add course image',
          style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade600),
        ),
      ],
    ).animate().fade(duration: 600.ms).slideY(begin: 0.2, duration: 400.ms);
  }
  /// Pops up a dialog to choose between camera or gallery.
  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.image, size: 50, color: Colors.blue.shade600),
            SizedBox(height: 10),
            Text(
              'Choose Image Source',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Select where you want to upload the course image from.',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Camera Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
                icon: Icon(Icons.camera_alt, size: 24),
                label: Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Gallery Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
                icon: Icon(Icons.photo_library, size: 24),
                label: Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  /// Picks the image from the given [source].
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _courseImage = File(image.path);
      });
    }
  }

  /// Uploads the course image to Firebase Storage and returns the download URL.
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

  /// Builds a single course list item (with a popup menu for Edit, Delete, etc.).
  Widget _buildCourseListItem(
      BuildContext context, CourseProvider courseProvider, Map course) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
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
            : Icon(Icons.image, size: 50),
        title: Text(
          course['courseTitle'],
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Subject: ${course['subject']}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: PopupMenuButton(
          onSelected: (value) async {
            if (value == 'edit') {
              _editCourse(context, course, courseProvider);
            } else if (value == 'delete') {
              await courseProvider.deleteCourse(course['id']);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Course deleted successfully!')),
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
            PopupMenuItem(value: 'edit', child: Text('Edit Course')),
            PopupMenuItem(value: 'delete', child: Text('Delete Course')),
            PopupMenuItem(value: 'manageSections', child: Text('Manage Sections')),
          ],
        ),
      ),
    );
  }

  /// Clears all form fields and resets the state for creating a new course.
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
    });
  }

  /// Edits an existing course by populating the form with existing info.
  void _editCourse(
      BuildContext context, Map course, CourseProvider courseProvider) {
    setState(() {
      _currentCourseId = course['id'];
      _titleController.text = course['courseTitle'];
      _descriptionController.text = course['description'];
      _priceController.text = course['price'].toString();
      _durationController.text = course['duration'];
      _subjectController.text = course['subject'];
      _instructorController.text = course['instructor'];
      _currentImageUrl = course['imageUrl'];
      _courseImage = null; // Reset any currently picked image
    });

    // Animate to the form so the user can see it
    Scrollable.ensureVisible(
      _formKey.currentContext!,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  /// Fetches all courses for the current teacher from Firestore.
  Future<List<Map<String, dynamic>>> _fetchTeacherCourses(
      AuthService authService, CourseProvider courseProvider) async {
    String? email = await authService.getCurrentUserEmail();
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

  /// Calculates the teacher's total earnings (custom logic in `CourseProvider`).
  Future<double> _fetchTeacherEarnings(
      AuthService authService, CourseProvider courseProvider) async {
    String? email = await authService.getCurrentUserEmail();
    if (email == null) return 0.0;
    return courseProvider.calculateTeacherEarnings(email);
  }

  /// Helper method to build consistent InputDecoration for form fields.
  InputDecoration _buildInputDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      prefixIcon: icon != null ? Icon(icon) : null,
    );
  }
}