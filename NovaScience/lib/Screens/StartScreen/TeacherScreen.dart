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

  // New color palette
  final Color greenColor = const Color(0xFF11261f); // Dark green - primary
  final Color yellowColor = const Color(0xFF123755); // Navy blue - secondary
  final Color maroonColor = const Color(0xFF722626); // Maroon - error
  final Color accentColor = const Color(0xFFe9c46a); // Gold accent
  final Color surfaceColor = const Color(0xFFF7F7F2); // Light cream background
  final Color textDarkColor = const Color(0xFF1F2937); // Dark text
  final Color textLightColor = const Color(0xFFF9FAFB); // Light text

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    return Scaffold(
      /// AppBar with official design
      appBar: AppBar(
        title: Text(
          'Teacher Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textLightColor,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: greenColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Container(
            color: accentColor,
            height: 2.0,
          ),
        ),
      ),
      backgroundColor: surfaceColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======= EARNINGS SECTION =======
            _buildEarningsSection(authService, courseProvider),
            const SizedBox(height: 24),

            // ======= COURSE FORM =======
            _buildCourseForm(context, authService, courseProvider)
                .animate()
                .fade(duration: 400.ms)
                .slideY(begin: 0.05),

            const SizedBox(height: 24),

            // ======= LIST OF COURSES =======
            _buildCoursesHeader(),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTeacherCourses(authService),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFe9c46a),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading courses. Please try again.',
                      style: GoogleFonts.poppins(
                        color: maroonColor,
                        fontSize: 14,
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No courses found',
                      style: GoogleFonts.poppins(
                        color: yellowColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                } else {
                  final courses = snapshot.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: courses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Revenue Overview',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: greenColor,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // 1) TEACHER'S OVERALL EARNINGS (Card)
        FutureBuilder<double>(
          future: _fetchTeacherEarnings(authService, courseProvider),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                elevation: 0,
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.5), width: 1),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFe9c46a),
                    ),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading earnings',
                  style: GoogleFonts.poppins(color: maroonColor),
                ),
              );
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
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: greenColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: greenColor.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: accentColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -15,
              right: -15,
              child: Icon(
                Icons.monetization_on_rounded,
                color: accentColor.withOpacity(0.15),
                size: 100,
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
                      color: accentColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween<double>(begin: 0, end: earnings),
                    builder: (context, double value, child) {
                      return Text(
                        '\$${value.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: textLightColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
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

  // ---------------------------------------------------------------------------
  // (C) TEACHER MONTHLY EARNINGS (ALL COURSES)
  // ---------------------------------------------------------------------------
  Widget _buildTeacherMonthlyEarningsSection(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return FutureBuilder<String?>(
      future: authService.getCurrentUserEmail(),
      builder: (context, snapshotEmail) {
        if (snapshotEmail.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.5), width: 1),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFe9c46a),
                ),
              ),
            ),
          );
        } else if (snapshotEmail.hasError || snapshotEmail.data == null) {
          return Center(
            child: Text(
              'Error fetching teacher email',
              style: GoogleFonts.poppins(color: maroonColor),
            ),
          );
        }

        final teacherEmail = snapshotEmail.data!;
        return FutureBuilder<Map<String, double>>(
          future: _fetchMonthlyEarningsForTeacher(teacherEmail),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Card(
                elevation: 0,
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.5), width: 1),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFe9c46a),
                    ),
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading monthly teacher earnings',
                  style: GoogleFonts.poppins(color: maroonColor),
                ),
              );
            } else {
              final monthlyData = snapshot.data ?? {};
              if (monthlyData.isEmpty) {
                return Center(
                  child: Text(
                    'No monthly earnings data',
                    style: GoogleFonts.poppins(
                      color: yellowColor,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              return Card(
                elevation: 0,
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.5), width: 1),
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
                        Icons.bar_chart_outlined,
                        color: yellowColor,
                      ),
                      title: Text(
                        'Monthly Revenue (All Courses)',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: greenColor,
                        ),
                      ),
                      collapsedIconColor: yellowColor,
                      iconColor: accentColor,
                      children: monthlyData.entries.map((entry) {
                        final month = entry.key; // "YYYY-MM"
                        final totalEarning = entry.value;
                        return ListTile(
                          leading: Icon(
                            Icons.calendar_month,
                            color: yellowColor.withOpacity(0.7),
                            size: 20,
                          ),
                          title: Text(
                            month,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: greenColor,
                            ),
                          ),
                          trailing: Text(
                            '\$${totalEarning.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: yellowColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
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
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: greenColor.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE
              Row(
                children: [
                  Icon(
                    _currentCourseId == null
                        ? Icons.add_circle_outline
                        : Icons.edit_outlined,
                    color: yellowColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentCourseId == null
                        ? 'Create New Course'
                        : 'Edit Course',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: greenColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: accentColor.withOpacity(0.3)),
              const SizedBox(height: 16),

              // IMAGE PICKER
              Center(child: _buildImagePicker(context)),
              const SizedBox(height: 20),

              // FORM FIELDS
              _buildTextField(_titleController, 'Course Title', Icons.title),
              const SizedBox(height: 16),
              _buildTextField(
                  _descriptionController, 'Description', Icons.description),
              const SizedBox(height: 16),
              _buildTextField(
                  _instructorController, 'Instructor', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(
                  _priceController, 'Price', Icons.attach_money,
                  isNumeric: true),
              const SizedBox(height: 16),
              _buildTextField(_durationController, 'Duration', Icons.timer),
              const SizedBox(height: 16),
              _buildTextField(_subjectController, 'Subject', Icons.subject),
              const SizedBox(height: 20),

              // DROPDOWN
              _buildMediumDropdown(),
              const SizedBox(height: 24),

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
                          SnackBar(
                            content: Text(
                              'Error: Instructor email not found',
                              style: GoogleFonts.poppins(
                                color: textLightColor,
                              ),
                            ),
                            backgroundColor: maroonColor,
                          ),
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
                          content: Text(
                            _currentCourseId == null
                                ? 'Course created successfully!'
                                : 'Course updated successfully!',
                            style: GoogleFonts.poppins(
                              color: textLightColor,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: greenColor,
                        ),
                      );

                      // 6) Clear
                      _clearFormFields();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenColor,
                    foregroundColor: textLightColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentCourseId == null
                            ? Icons.add_circle_outline
                            : Icons.save_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentCourseId == null
                            ? 'CREATE COURSE'
                            : 'UPDATE COURSE',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: greenColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: textDarkColor,
          ),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: yellowColor, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
            filled: true,
            fillColor: surfaceColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
          validator: (value) => value!.isEmpty ? '$label is required' : null,
        ),
      ],
    );
  }

  Widget _buildMediumDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medium',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: greenColor,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedMedium,
          decoration: InputDecoration(
            hintText: 'Select medium',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(Icons.language, color: yellowColor, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
            filled: true,
            fillColor: surfaceColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: textDarkColor,
          ),
          dropdownColor: Colors.white,
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
          icon: Icon(Icons.arrow_drop_down, color: yellowColor),
          validator: (value) =>
          (value == null || value.isEmpty) ? 'Select a medium' : null,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // (E) IMAGE PICKER
  // ---------------------------------------------------------------------------
  Widget _buildImagePicker(BuildContext context) {
    return InkWell(
      onTap: () => _showImageSourceDialog(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: 170,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accentColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // If user selected an image, display it
            if (_courseImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
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
                borderRadius: BorderRadius.circular(10),
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
                        color: accentColor,
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
        Icon(
          Icons.image_outlined,
          size: 40,
          color: yellowColor.withOpacity(0.6),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to add course image',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: yellowColor.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fade().slideY(begin: 0.2, duration: 400.ms);
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Icon(
                Icons.image_outlined,
                size: 44,
                color: yellowColor,
              ),
              const SizedBox(height: 12),
              Text(
                'Choose Image Source',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: greenColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'Select where you want to upload the course image from.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textDarkColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
          ElevatedButton.icon(
          onPressed: () {
    Navigator.pop(context);
    _pickImage(ImageSource.camera);
    },
      icon: const Icon(Icons.camera_alt, size: 18),
      label: Text(
        'Camera',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: yellowColor,
        foregroundColor: textLightColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    const SizedBox(width: 12),
    ElevatedButton.icon(
    onPressed: () {
    Navigator.pop(context);
    _pickImage(ImageSource.gallery);
    },
    icon: const Icon(Icons.photo_library, size: 18),
    label: Text(
    'Gallery',
    style: GoogleFonts.poppins(
    fontWeight: FontWeight.w500,
    ),
    ),
      // Continuing from where we left off...

      style: ElevatedButton.styleFrom(
        backgroundColor: greenColor,
        foregroundColor: textLightColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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
  // (F) COURSES HEADER
  // ---------------------------------------------------------------------------
  Widget _buildCoursesHeader() {
    return Row(
      children: [
        Icon(
          Icons.school_outlined,
          size: 20,
          color: yellowColor,
        ),
        const SizedBox(width: 8),
        Text(
          'Your Courses',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: greenColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // (G) LIST OF COURSES
  // ---------------------------------------------------------------------------
  Widget _buildCourseListItem(
      BuildContext context, CourseProvider courseProvider, Map course) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.5), width: 1),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            colorScheme: ColorScheme.light(
              primary: yellowColor,
            ),
          ),
          child: ExpansionTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: course['imageUrl'] != null
                  ? Image.network(
                course['imageUrl'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  color: surfaceColor,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: yellowColor.withOpacity(0.6),
                    size: 24,
                  ),
                ),
              )
                  : Container(
                width: 50,
                height: 50,
                color: surfaceColor,
                child: Icon(
                  Icons.image_outlined,
                  color: yellowColor.withOpacity(0.6),
                  size: 24,
                ),
              ),
            ),
            title: Text(
              course['courseTitle'],
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: greenColor,
              ),
            ),
            subtitle: Text(
              'Subject: ${course['subject']}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: textDarkColor.withOpacity(0.7),
              ),
            ),
            collapsedIconColor: yellowColor,
            iconColor: accentColor,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              // Divider with accent color
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: accentColor.withOpacity(0.3)),
              ),

              // (F1) Monthly Earnings for This Course
              FutureBuilder<Map<String, Map<String, double>>>(
                future: _fetchMonthlyEarningsForCourse(
                  course['id'],
                  course['price'] ?? 0.0,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFe9c46a),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error loading monthly earnings: ${snapshot.error}',
                        style: GoogleFonts.poppins(
                          color: maroonColor,
                          fontSize: 13,
                        ),
                      ),
                    );
                  } else {
                    final data = snapshot.data;
                    if (data == null || data[course['id']] == null) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No enrollment earnings data found',
                          style: GoogleFonts.poppins(
                            color: yellowColor.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      );
                    }
                    final monthlyData = data[course['id']]!;
                    if (monthlyData.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No enrollment earnings recorded',
                          style: GoogleFonts.poppins(
                            color: yellowColor.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      );
                    }

                    return _buildMonthlyEarningsList(monthlyData);
                  }
                },
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      color: yellowColor,
                      onPressed: () {
                        _editCourse(context, course, courseProvider);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      label: 'Sections',
                      icon: Icons.folder_outlined,
                      color: greenColor,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ManageSectionsScreen(courseId: course['id']),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      label: 'Delete',
                      icon: Icons.delete_outline,
                      color: maroonColor,
                      onPressed: () async {
                        await _showDeleteConfirmationDialog(
                          context,
                          course['id'],
                          courseProvider,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for action buttons
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  // Delete confirmation dialog
  Future<void> _showDeleteConfirmationDialog(
      BuildContext context,
      String courseId,
      CourseProvider courseProvider,
      ) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Column(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: maroonColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm Deletion',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: maroonColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this course? This action cannot be undone.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textDarkColor.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'CANCEL',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: yellowColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: maroonColor,
                foregroundColor: textLightColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'DELETE',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await courseProvider.deleteCourse(courseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Course deleted successfully!',
              style: GoogleFonts.poppins(
                color: textLightColor,
              ),
            ),
            backgroundColor: greenColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // (F1) Helper to build monthly earnings list
  Widget _buildMonthlyEarningsList(Map<String, double> monthlyData) {
    final monthTiles = monthlyData.entries.map((entry) {
      final month = entry.key; // e.g., "2025-02"
      final earnings = entry.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: yellowColor.withOpacity(0.7),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              month,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: greenColor,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '\$${earnings.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: yellowColor,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Monthly Revenue',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: greenColor,
            ),
          ),
        ),
        ...monthTiles,
      ],
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeIn);
  }

  // ---------------------------------------------------------------------------
  // (H) FETCHING DATA
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
  // (I) EDIT COURSE & CLEAR FORM
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