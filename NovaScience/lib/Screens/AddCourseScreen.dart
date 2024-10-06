import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Import to use File
import '../../Service/CourseProvider.dart';
import '../../Modals/CourseAndSectionAndVideos.dart';

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
  File? _imageFile; // Store the selected image

  final ImagePicker _picker = ImagePicker(); // Image picker instance

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Course'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  onPressed: () async {
                    // Pick an image from the gallery
                    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        _imageFile = File(pickedFile.path); // Store the image file
                      });
                    }
                  },
                  child: Text('Pick Image from Gallery'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

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
                        imageUrl: imageUrl, // Pass the image URL to the addCourse method
                      );

                      // Navigate back after saving the course
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Add Course'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
          ),
        ),
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 100,
      width: 100,
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
          : Center(child: Text('No image selected')),
    );
  }
}