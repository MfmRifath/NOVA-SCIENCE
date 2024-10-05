import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image:AssetImage('assets/images/background.jpg'),// Replace with your background image URL
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent overlay gradient
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
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30),

                // Profile Picture with Animated Hover Effect
                _buildProfileImage(context),

                SizedBox(height: 20),

                // Name and Bio Section with Animation
                _buildProfileDetails(),

                SizedBox(height: 30),

                // Action Buttons with Animations
                _buildActionButtons(context),

                SizedBox(height: 30),

                // Additional Information List with Staggered Animations
                _buildProfileInfoList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Profile image with hover effect
  Widget _buildProfileImage(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          // Implement functionality to change profile picture
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 70,
            backgroundImage: NetworkImage("https://via.placeholder.com/150"),
          ),
        ),
      ),
    );
  }

  // Profile name and bio with smooth animation
  Widget _buildProfileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FadeInAnimation(
          key: ValueKey(1),
          child: Text(
            'John Doe',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 10),
        FadeInAnimation(
          key: ValueKey(2),
          child: Text(
            'UI/UX Designer | Flutter Enthusiast',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ),
        SizedBox(height: 10),
        FadeInAnimation(
          key: ValueKey(3),
          child: Text(
            'I love designing and building beautiful apps that scale!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
        ),
      ],
    );
  }

  // Action buttons (Edit Profile, Settings) with animations
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProfileButton(
          icon: Icons.edit,
          label: "Edit Profile",
          onTap: () {
            Navigator.pushNamed(context, '/editProfile');
          },
        ),
        SizedBox(width: 20),
        _buildProfileButton(
          icon: Icons.settings,
          label: "Settings",
          onTap: () {
            // Add your Settings logic here
          },
        ),
      ],
    );
  }

  // Custom button widget with ripple effect and hover animation
  Widget _buildProfileButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // List of profile info (email, phone number, etc.) with staggered animations
  Widget _buildProfileInfoList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredFadeInAnimation(
            key: ValueKey(4),
            child: _buildProfileInfoItem(Icons.email, "Email", "johndoe@example.com"),
          ),
          Divider(color: Colors.white54),
          StaggeredFadeInAnimation(
            key: ValueKey(5),
            child: _buildProfileInfoItem(Icons.phone, "Phone", "+123 456 7890"),
          ),
          Divider(color: Colors.white54),
          StaggeredFadeInAnimation(
            key: ValueKey(6),
            child: _buildProfileInfoItem(Icons.location_on, "Location", "San Francisco, CA"),
          ),
          Divider(color: Colors.white54),
          StaggeredFadeInAnimation(
            key: ValueKey(7),
            child: _buildProfileInfoItem(Icons.cake, "Birthday", "January 1, 1990"),
          ),
          Divider(color: Colors.white54),
        ],
      ),
    );
  }

  // Individual profile info item
  Widget _buildProfileInfoItem(IconData icon, String title, String info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                info,
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Fade-in Animation widget
class FadeInAnimation extends StatelessWidget {
  final Widget child;

  FadeInAnimation({required Key key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

// Custom Staggered Fade-in Animation widget
class StaggeredFadeInAnimation extends StatelessWidget {
  final Widget child;

  StaggeredFadeInAnimation({required Key key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }
}
