import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Import Provider package
import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart'; // Adjust the path as needed

class CourseManagementScreen extends StatefulWidget {
  @override
  _CourseManagementScreenState createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  Widget build(BuildContext context) {
    // Access CourseProvider
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Course Management'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Courses'),
            Expanded(
              child: AnimatedList(
                key: _listKey,
                initialItemCount: courseProvider.courses.length,
                itemBuilder: (context, index, animation) {
                  final course = courseProvider.courses[index];
                  return _buildCourseTile(course, animation, index);
                },
              ),
            ),
            FloatingActionButton(
              onPressed:()=> _addCourse,
              tooltip: 'Add Course',
              child: Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCourseTile(Course course, Animation<double> animation, int index) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        margin: EdgeInsets.all(8.0),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                course.imageUrl ?? 'https://via.placeholder.com/150', // Use default if null
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            ListTile(
              title: Text(course.courseTitle!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.description!, style: TextStyle(fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Instructor: ${course.instructor}', style: TextStyle(fontStyle: FontStyle.italic)),
                    SizedBox(height: 4),
                    Text('Duration: ${course.duration}', style: TextStyle(color: Colors.grey[600])),
                    SizedBox(height: 4),
                    Text('Start Date: ${DateFormat('yyyy-MM-dd').format(course.startDate!)}', style: TextStyle(color: Colors.grey[600])),
                    Text('End Date: ${DateFormat('yyyy-MM-dd').format(course.endDate!)}', style: TextStyle(color: Colors.grey[600])),
                    Text('Enrolled Students: ${course.enrolledStudents}', style: TextStyle(color: Colors.grey[600])),
                    Text('Price: \$${course.price?.toStringAsFixed(2)}', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _editCourse(context, index);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteCourse(index);
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

  void _editCourse(BuildContext context, int index) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final course = courseProvider.courses[index];

    // Controllers for editing
    final titleController = TextEditingController(text: course.courseTitle);
    final descriptionController = TextEditingController(text: course.description);
    final priceController = TextEditingController(text: course.price.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Course'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Course Title'),
                  controller: titleController,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Description'),
                  controller: descriptionController,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Price'),
                  controller: priceController,
                  keyboardType: TextInputType.number,
                ),
                // Add other fields similarly if needed
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Update course details
                courseProvider.editCourse(
                  course.id!,
                  titleController.text,
                  descriptionController.text,
                  double.tryParse(priceController.text) ?? 0,
                );
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCourse(int index) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final course = courseProvider.courses[index];

    // Confirm delete action
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Course'),
          content: Text('Are you sure you want to delete "${course.courseTitle}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _listKey.currentState!.removeItem(
                  index,
                      (context, animation) => _buildCourseTile(courseProvider.courses[index], animation, index),
                  duration: Duration(milliseconds: 300),
                );
                courseProvider.deleteCourse(course.id); // Pass the course ID to delete
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _addCourse(Course course) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    courseProvider.addCourse(title: course.courseTitle,price: course.price,instructor: course.instructor,description: course.description,duration: course.duration);
     }
}
