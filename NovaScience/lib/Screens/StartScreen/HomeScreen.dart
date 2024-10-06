import 'package:flutter/material.dart';
import 'package:nova_science/Screens/AddCourseScreen.dart';
import 'package:provider/provider.dart';
import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart';

String selectedCourseId = '';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access the CourseProvider
    final courseProvider = Provider.of<CourseProvider>(context);
    final courses = courseProvider.courses; // Assuming you have a 'courses' list

    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome RN"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background image with overlay
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.blue.shade400.withOpacity(0.7),
                  Colors.purple.shade300.withOpacity(0.7),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  SizedBox(height: 30),

                  // Continue Watching Section
                  _buildSectionTitle("Free Watching"),
                  SizedBox(height: 15),

                  // Horizontally Scrollable Course List or Add Video Button
                  courses.isNotEmpty
                      ? _buildHorizontalCourseList(courses: courses, context: context)
                      : _buildAddVideoButton(context),

                  SizedBox(height: 30),

                  // My Courses Section
                  _buildSectionTitle("My Courses"),
                  SizedBox(height: 10),

                  // Horizontally Scrollable Course List or Add Course Button
                  courses.isNotEmpty
                      ? _buildHorizontalCourseList(courses: courses, context: context)
                      : _buildAddCourseButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: 'Search',
          prefixIcon: Icon(Icons.search),
          contentPadding: EdgeInsets.all(16.0),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  // Add Course Button
  Widget _buildAddCourseButton(BuildContext context) {

    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context)=> AddCourseScreen())); // Navigate to Add Course Screen
        },
        icon: Icon(Icons.add),
        label: Text("Add Course"),
      ),
    );
  }

  // Add Video Button
  Widget _buildAddVideoButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/addVideoScreen'); // Navigate to Add Video Screen
        },
        icon: Icon(Icons.add),
        label: Text("Add Video"),
      ),
    );
  }

  Widget _buildHorizontalCourseList({required List<Course> courses, required BuildContext context}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: courses.map((course) => _buildAnimatedCourseCard(
          courseTitle: course.courseTitle!,
          description: course.description!,
          time: course.duration!,
          imageUrl: course.imageUrl!,
          context: context, id: course.id!,
        )).toList(),
      ),
    );
  }

  Widget _buildAnimatedCourseCard({
    required String courseTitle,
    required String description,
    required String time,
    required String imageUrl,
    required String id,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: InkWell(
        onTap: () {
          selectedCourseId = id;
          Navigator.pushNamed(context, '/courseScreen');
        },
        splashColor: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 8,
            shadowColor: Colors.black38,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  child: imageUrl.startsWith('http')
                      ? Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(child: Icon(Icons.error)); // Handle loading error
                    },
                  )
                      : Image.asset(
                    imageUrl,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseTitle,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(description),
                      SizedBox(height: 8),
                      Text(
                        time,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
