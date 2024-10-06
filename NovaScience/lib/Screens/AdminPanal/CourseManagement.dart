import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Service/CourseProvider.dart';
import '../../Modals/CourseAndSectionAndVideos.dart'; // Ensure this is imported

class CourseManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Course Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Reload both free and premium courses
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
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot<Object?>>?>(
              future: courseProvider.getFreeCourses(), // Fetch free courses
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error fetching free courses'));
                }

                final freeCourses = snapshot.data ?? [];

                return ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Free Courses',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    freeCourses.isEmpty
                        ? Center(child: Text('No free courses available'))
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: freeCourses.length,
                      itemBuilder: (context, index) {
                        final courseData = freeCourses[index].data() as Map<String, dynamic>;
                        final course = Course.fromMap(courseData, freeCourses[index].id); // Pass document ID
                        return ListTile(
                          title: Text(course.courseTitle!),
                          subtitle: Text(course.description!),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              await courseProvider.deleteCourse(course.id);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          // Add premium courses FutureBuilder here
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot<Object?>>?>(
              future: courseProvider.getMyCourses(), // Fetch premium courses
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error fetching premium courses'));
                }

                final premiumCourses = snapshot.data ?? [];

                return ListView.builder(
                  itemCount: premiumCourses.length,
                  itemBuilder: (context, index) {
                    final courseData = premiumCourses[index].data() as Map<String, dynamic>;
                    final course = Course.fromMap(courseData, premiumCourses[index].id); // Pass document ID
                    return ListTile(
                      title: Text(course.courseTitle!),
                      subtitle: Text(course.description!),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          await courseProvider.deleteCourse(course.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Logic to add a new course, e.g., navigate to an add course screen
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
