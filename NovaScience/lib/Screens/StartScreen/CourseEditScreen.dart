import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';

import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart';
import '../../Service/AuthService.dart';

class CourseEditScreen extends StatefulWidget {
  final String? courseId;

  const CourseEditScreen({
    Key? key,
    this.courseId,
  }) : super(key: key);

  @override
  _ImprovedCourseEditScreenState createState() => _ImprovedCourseEditScreenState();
}

class _ImprovedCourseEditScreenState extends State<CourseEditScreen> {
  // Controllers for text fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // State variables
  bool _isLoading = true;
  bool _isSaving = false;
  File? _courseImage;
  String? _currentImageUrl;
  String? _selectedMedium;
  List<String> _mediumOptions = ['Tamil', 'English', 'Sinhala'];

  // Modern Color Palette
  final Color primaryColor = const Color(0xFF11261f); // Dark Green
  final Color secondaryColor = const Color(0xFF123755); // Dark Blue
  final Color accentColor = const Color(0xFF722626); // Maroon
  final Color successColor = const Color(0xFF2E7D32); // Complementary Green for success
  final Color errorColor = const Color(0xFF722626); // Using Maroon for error too
  final Color surfaceColor = const Color(0xFFF5F5F5); // Light gray background
  final Color cardColor = Colors.white;
  final Color textDarkColor = const Color(0xFF1E1E1E); // Dark text
  final Color textLightColor = Colors.white; // Light text
  final Color dividerColor = const Color(0xFFE0E0E0); // Subtle divider

  // Image picker
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _instructorController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.courseId != null) {
        // Load existing course data
        final courseProvider = Provider.of<CourseProvider>(context, listen: false);
        final course = await courseProvider.getCourseById(widget.courseId!);

        if (course != null) {
          _titleController.text = course.courseTitle ?? '';
          _subjectController.text = course.subject ?? '';
          _priceController.text = course.price?.toString() ?? '0';
          _descriptionController.text = course.description ?? '';
          _instructorController.text = course.instructor ?? '';
          _durationController.text = course.duration ?? '';
          _currentImageUrl = course.imageUrl;
          _selectedMedium = course.medium;
        }
      } else {
        // Set default instructor name if creating a new course
        final authService = Provider.of<AuthService>(context, listen: false);
        final email = await authService.getCurrentUserEmail();
        if (email != null) {
          _instructorController.text = email.split('@').first;
        }
      }
    } catch (e) {
      print('Error loading course data: $e');
      _showSnackBar('Failed to load course data', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Get current user email
      final instructorEmail = await authService.getCurrentUserEmail();
      if (instructorEmail == null) {
        throw Exception('Unable to get instructor email');
      }

      // Upload image if selected
      String? imageUrl = _currentImageUrl;
      if (_courseImage != null) {
        imageUrl = await courseProvider.uploadImage(_courseImage!);
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      // Parse price
      double? price = double.tryParse(_priceController.text);
      if (price == null) {
        throw Exception('Invalid price format');
      }

      if (widget.courseId == null) {
        // Create new course
        await courseProvider.addCourse(
          title: _titleController.text,
          description: _descriptionController.text,
          price: price,
          duration: _durationController.text,
          subject: _subjectController.text,
          instructor: _instructorController.text,
          status: 'Premium',
          instructorEmail: instructorEmail,
          imageUrl: imageUrl,
          medium: _selectedMedium,
        );

        _showSnackBar('Course created successfully');
      } else {
        // Update existing course
        await courseProvider.editCourse(
          widget.courseId!,
          _titleController.text,
          _descriptionController.text,
          price,
          _subjectController.text,
          imageUrl ?? '',
          _selectedMedium ?? 'English',
        );

        _showSnackBar('Course updated successfully');
      }

      // Return to previous screen
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('Error saving course: $e');
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: textLightColor,
          ),
        ),
        backgroundColor: isError ? errorColor : successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickImage() async {
    _showImageSourceDialog();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 20),

              Text(
                'Select Image Source',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 20),

              // Camera option
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: secondaryColor.withOpacity(0.1),
                  ),
                  child: Icon(Icons.camera_alt, color: secondaryColor),
                ),
                title: Text(
                  'Camera',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Take a new photo',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textDarkColor.withOpacity(0.6),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),

              // Gallery option
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.1),
                  ),
                  child: Icon(Icons.photo_library, color: primaryColor),
                ),
                title: Text(
                  'Gallery',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Choose from your photos',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textDarkColor.withOpacity(0.6),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),

              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _courseImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      _showSnackBar('Failed to get image', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          widget.courseId == null ? 'Create Course' : 'Edit Course',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textLightColor,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textLightColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: textLightColor,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.check, color: textLightColor),
              onPressed: _saveCourse,
              tooltip: 'Save',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: secondaryColor,
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course image picker
              _buildImagePicker(),
              SizedBox(height: 24),

              // Course details card
              _buildCourseDetailsCard(),
              SizedBox(height: 16),

              // Additional info card
              _buildAdditionalInfoCard(),
              SizedBox(height: 24),

              // Save button
              _buildSaveButton(),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 250,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: secondaryColor.withOpacity(0.05),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: _courseImage != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _courseImage!,
              fit: BoxFit.cover,
            ),
          )
              : _currentImageUrl != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              _currentImageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                    color: secondaryColor,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder();
              },
            ),
          )
              : _buildImagePlaceholder(),
        ),
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildImagePlaceholder() {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: Radius.circular(16),
      color: secondaryColor.withOpacity(0.6),
      strokeWidth: 2,
      dashPattern: [6, 4],
      child: Center(
        child: Container(
          width: 250,
          height: 150,
          decoration: BoxDecoration(
            color: secondaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 36,
                color: secondaryColor.withOpacity(0.6),
              ),
              SizedBox(height: 12),
              Text(
                'Upload Course Image',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Recommended size: 1280 x 720 px',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: textDarkColor.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dividerColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title with icon
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Course Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Course title
            _buildTextField(
              controller: _titleController,
              label: 'Course Title',
              hintText: 'Enter the course title',
              icon: Icons.title,
              validator: (value) => value!.isEmpty ? 'Title is required' : null,
            ),
            SizedBox(height: 16),

            // Subject
            _buildTextField(
              controller: _subjectController,
              label: 'Subject',
              hintText: 'Enter the course subject',
              icon: Icons.subject,
              validator: (value) => value!.isEmpty ? 'Subject is required' : null,
            ),
            SizedBox(height: 16),

            // Price
            _buildTextField(
              controller: _priceController,
              label: 'Price (Rs)',
              hintText: 'Enter the course price',
              icon: Icons.monetization_on_outlined,
              keyboardType: TextInputType.number,
              prefixText: 'Rs. ',
              validator: (value) {
                if (value!.isEmpty) return 'Price is required';
                if (double.tryParse(value) == null) return 'Enter a valid number';
                return null;
              },
            ),
            SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hintText: 'Enter course description',
              icon: Icons.description_outlined,
              maxLines: 4,
              validator: (value) => value!.isEmpty ? 'Description is required' : null,
            ),
          ],
        ),
      ),
    ).animate(delay: 100.ms).fade(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAdditionalInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dividerColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title with icon
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    color: secondaryColor,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Additional Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Instructor name
            _buildTextField(
              controller: _instructorController,
              label: 'Instructor',
              hintText: 'Enter instructor name',
              icon: Icons.person_outline,
              validator: (value) => value!.isEmpty ? 'Instructor name is required' : null,
            ),
            SizedBox(height: 16),

            // Duration
            _buildTextField(
              controller: _durationController,
              label: 'Duration',
              hintText: 'E.g., 8 weeks, 3 hours',
              icon: Icons.timer_outlined,
              validator: (value) => value!.isEmpty ? 'Duration is required' : null,
            ),
            SizedBox(height: 16),

            // Medium dropdown
            _buildDropdown(
              label: 'Medium',
              icon: Icons.language_outlined,
              value: _selectedMedium,
              items: _mediumOptions.map((medium) {
                return DropdownMenuItem<String>(
                  value: medium,
                  child: Text(medium),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMedium = newValue;
                });
              },
              validator: (value) => value == null ? 'Medium is required' : null,
            ),
          ],
        ),
      ),
    ).animate(delay: 200.ms).fade(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textDarkColor,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: textDarkColor,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            prefixIcon: Icon(icon, color: secondaryColor),
            prefixText: prefixText,
            prefixStyle: GoogleFonts.poppins(
              fontSize: 15,
              color: textDarkColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: secondaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 1),
            ),
            filled: true,
            fillColor: cardColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 0,
            ),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    required String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textDarkColor,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: secondaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: secondaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 1),
            ),
            filled: true,
            fillColor: cardColor,
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: textDarkColor,
          ),
          items: items,
          onChanged: onChanged,
          validator: validator,
          icon: Icon(Icons.arrow_drop_down, color: secondaryColor),
          isExpanded: true,
          hint: Text(
            'Select medium',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveCourse,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textLightColor,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          _isSaving
              ? 'Saving...'
              : widget.courseId == null
              ? 'Create Course'
              : 'Update Course',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ).animate(delay: 300.ms).fade(duration: 300.ms)..scale(begin: Offset(0.95, 0.95), end: Offset(1.0, 1.0));
  }
}