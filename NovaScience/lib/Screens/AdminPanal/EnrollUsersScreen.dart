import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';

class EnrollUsersScreen extends StatefulWidget {
  @override
  _EnrollUsersScreenState createState() => _EnrollUsersScreenState();
}

class _EnrollUsersScreenState extends State<EnrollUsersScreen> {
  String? selectedUserId;
  String? selectedCourseId;
  DateTime? enrollmentEndDate; // Variable to store the selected end date

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enroll Users into Courses'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card for selecting user
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select User',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownSearch<Map<String, dynamic>>(
                      asyncItems: (String filter) => _fetchUsers(filter),
                      popupProps: PopupProps.bottomSheet(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            labelText: 'Search Users',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      itemAsString: (item) => item['email'] ?? 'Unnamed User',
                      onChanged: (value) {
                        setState(() {
                          selectedUserId = value?['id'];
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Select User',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Card for selecting course
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Course',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownSearch<Map<String, dynamic>>(
                      asyncItems: (String filter) => _fetchCourses(filter),
                      popupProps: PopupProps.bottomSheet(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            labelText: 'Search Courses',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      itemAsString: (item) => item['courseTitle'] ?? 'Untitled Course',
                      onChanged: (value) {
                        setState(() {
                          selectedCourseId = value?['id'];
                        });
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Select Course',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Card for selecting enrollment end date
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Enrollment End Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(DateTime.now().year + 5),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            enrollmentEndDate = selectedDate;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: Text(
                        enrollmentEndDate == null
                            ? 'Select End Date'
                            : 'End Date: ${enrollmentEndDate!.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Enroll Button (disabled if either dropdown or end date is not selected)
            ElevatedButton(
              onPressed: (selectedUserId != null && selectedCourseId != null && enrollmentEndDate != null)
                  ? () => _showConfirmationDialog(context)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
              child: Text(
                'Enroll User',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fetch users from Firestore
  Future<List<Map<String, dynamic>>> _fetchUsers(String filter) async {
    final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .where((user) => user['name'] != null && user['name'].toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }

  // Fetch courses from Firestore
  Future<List<Map<String, dynamic>>> _fetchCourses(String filter) async {
    final querySnapshot = await FirebaseFirestore.instance.collection('courses').get();
    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .where((course) => course['courseTitle'] != null && course['courseTitle'].toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }

  // Show a confirmation dialog before enrolling the user
  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Confirm Enrollment'),
          content: Text(
            'Are you sure you want to enroll this user in the selected course?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                Navigator.of(ctx).pop();
                if (selectedUserId != null && selectedCourseId != null && enrollmentEndDate != null) {
                  await enrollUserInCourse(selectedUserId!, selectedCourseId!, enrollmentEndDate!);
                }
              },
              child: Text('Yes, Enroll'),
            ),
          ],
        );
      },
    );
  }

  Future<void> enrollUserInCourse(String userId, String courseId, DateTime enrollmentEndDate) async {
    try {
      // Get the current date as the enrollment date
      DateTime enrollmentDate = DateTime.now();

      // Update the user's document with the enrollment details
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'enrolledCourses': FieldValue.arrayUnion([
          {
            'courseId': courseId,
            'enrollmentDate': enrollmentDate,
            'enrollmentEndDate': enrollmentEndDate,
          }
        ]),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User enrolled successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset selections
      setState(() {
        selectedUserId = null;
        selectedCourseId = null;
      });
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to enroll user. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}