import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                image: AssetImage('assets/images/background.jpg'), // Replace with your image URL
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
                  Colors.black.withOpacity(0.9), // Semi-transparent black
                  Colors.blue.shade400.withOpacity(0.7), // Semi-transparent blue
                  Colors.purple.shade300.withOpacity(0.7), // Semi-transparent purple
                ],
              ),),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  _buildSearchBar(),
                  SizedBox(height: 30),

                  // Continue Watching Section
                  _buildSectionTitle("Free Watching"),
                  SizedBox(height: 15),

                  // Horizontally Scrollable Course List
                  _buildHorizontalCourseList(),

                  SizedBox(height: 30),

                  // My Courses Section
                  _buildSectionTitle("My Courses"),
                  SizedBox(height: 10),

                  // Another Horizontal Course List
                  _buildHorizontalCourseList(),
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

  Widget _buildHorizontalCourseList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
      child: Row(
        children: [
          _buildAnimatedCourseCard(
            courseTitle: "Freelancing",
            description: "By Rifath",
            time: "100 minutes Done",
            imageUrl: "https://via.placeholder.com/150", // Network image URL
          ),
          _buildAnimatedCourseCard(
            courseTitle: "UI/UX Design",
            description: "By Mark",
            time: "100 minutes Done",
            imageUrl: "assets/images/background.jpg", // Asset image example
          ),
          _buildAnimatedCourseCard(
            courseTitle: "Graphic Design",
            description: "By Rifath",
            time: "100 minutes Done",
            imageUrl: "https://via.placeholder.com/150", // Network image URL
          ),
          _buildAnimatedCourseCard(
            courseTitle: "Web Design",
            description: "",
            time: "100 minutes Done",
            imageUrl: "assets/images/background.jpg", // Asset image example
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCourseCard({
    required String courseTitle,
    required String description,
    required String time,
    required String imageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0), // Add horizontal padding between cards
      child: InkWell(
        onTap: () {
          // Add your onTap logic here (navigate to course details)
        },
        splashColor: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300), // Smooth animation duration
          curve: Curves.easeInOut, // Apply smooth easing
          width: 200, // Set fixed width to fit in horizontal scroll
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
                      ? Image.network(imageUrl, width: double.infinity, height: 120, fit: BoxFit.cover)
                      : Image.asset(imageUrl, width: double.infinity, height: 120, fit: BoxFit.cover),
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
