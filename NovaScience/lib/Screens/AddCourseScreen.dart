import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Import to use File
import '../../Service/CourseProvider.dart';

class AddCourseScreen extends StatefulWidget {
  @override
  _AddCourseScreenState createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _courseTitle;
  String? _description;
  String? _duration;
  double? _price;
  String? _instructor;
  String? _status;
  File? _imageFile; // Store the selected image
  bool _isLoading = false; // Loading state

  final ImagePicker _picker = ImagePicker(); // Image picker instance

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/background.jpg', // Replace with your background image path
            fit: BoxFit.cover,
          ),
          // White overlay with opacity
          Container(
            color: Colors.white.withOpacity(0.7),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Course Title',
                      onSaved: (value) => _courseTitle = value,
                      validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                    ),
                    _buildTextField(
                      label: 'Status',
                      onSaved: (value) => _status = value,
                      validator: (value) => value!.isEmpty ? 'Please enter the status' : null,
                    ),
                    _buildTextField(
                      label: 'Course Instructor',
                      onSaved: (value) => _instructor = value,
                      validator: (value) => value!.isEmpty ? 'Please enter an instructor name' : null,
                    ),
                    _buildTextField(
                      label: 'Course Price',
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _price = double.tryParse(value ?? ''),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a price';
                        } else if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      label: 'Description',
                      maxLines: 3,
                      onSaved: (value) => _description = value,
                      validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                    ),
                    _buildTextField(
                      label: 'Duration',
                      onSaved: (value) => _duration = value,
                      validator: (value) => value!.isEmpty ? 'Please enter the duration' : null,
                    ),
                    SizedBox(height: 20),
                    _buildImagePreview(),
                    SizedBox(height: 10),
                    _buildImagePickerButton(),
                    SizedBox(height: 20),
                    _buildAddCourseButton(courseProvider),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Add Course',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.blueAccent.withOpacity(0.7),
      elevation: 0, // Removes shadow
      actions: [
        IconButton(
          icon: Icon(Icons.help_outline, color: Colors.white),
          onPressed: () {
            // TODO: Add help action
          },
        ),
        IconButton(
          icon: Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            // TODO: Add settings action
          },
        ),
      ],
    );
  }

  Widget _buildImagePickerButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.image, color: Colors.white),
      label: Text(
        'Pick Image from Gallery',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.0),
        elevation: 5,
      ),
      onPressed: _isLoading ? null : _pickImage,
    );
  }

  Widget _buildAddCourseButton(CourseProvider courseProvider) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.0),
        elevation: 5,
      ),
      onPressed: _isLoading ? null : () => _addCourse(courseProvider),
      child: _isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text('Add Course', style: TextStyle(fontSize: 16)),
    );
  }

  Future<void> _pickImage() async {
    // Pick an image from the gallery
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Store the image file
      });
    }
  }

  Future<void> _addCourse(CourseProvider courseProvider) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true; // Set loading state
      });

      // Upload the image to Firebase and get the URL
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await courseProvider.uploadImage(_imageFile!);
      }

      // Call the addCourse method from the provider
      await courseProvider.addCourse(
        title: _courseTitle,
        description: _description,
        duration: _duration,
        price: _price,
        instructor: _instructor,
        status: _status,
        imageUrl: imageUrl ?? "https://via.placeholder.com/150", // Pass the image URL to the addCourse method
      );

      // Show Snackbar for confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course added successfully!')),
      );

      // Reset the form
      _formKey.currentState!.reset();
      setState(() {
        _imageFile = null; // Clear the selected image
        _isLoading = false; // Reset loading state
      });

      // Navigate back after saving the course
      Navigator.pop(context);
    } else {
      setState(() {
        _isLoading = false; // Reset loading state if form is invalid
      });
    }
  }

  Widget _buildTextField({
    required String label,
    int maxLines = 1,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black54), // Change label color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: _imageFile != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Image.file(
          _imageFile!,
          fit: BoxFit.cover,
        ),
      )
          : Center(
        child: Text('No image selected', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
