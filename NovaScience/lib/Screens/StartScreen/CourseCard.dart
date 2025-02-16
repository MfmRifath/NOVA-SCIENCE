import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CourseCard extends StatelessWidget {
  final String courseTitle;
  final String time;
  final String instructor;
  final String imageUrl;
  final String subject;
  final String id;
  final double? rating; // Nullable for loading state
  final int? enrolledCount; // Nullable for loading state
  final VoidCallback onTap;

  const CourseCard({
    Key? key,
    required this.courseTitle,
    required this.time,
    required this.instructor,
    required this.imageUrl,
    required this.subject,
    required this.id,
    this.rating,
    this.enrolledCount,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to obtain available width
    return LayoutBuilder(
      builder: (context, constraints) {
        // Derive responsive sizes based on card width.
        final double cardWidth = constraints.maxWidth;
        final double horizontalPadding = cardWidth * 0.05;
        final double imageHeight = cardWidth * 0.6;
        final double titleFontSize = cardWidth * 0.1;
        final double infoFontSize = cardWidth * 0.08;
        final double iconSize = cardWidth * 0.06;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Image
                _buildCourseImage(imageHeight),
                Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Title
                      _buildCourseTitle(titleFontSize),
                      SizedBox(height: cardWidth * 0.03),
                      // Instructor
                      _buildInstructor(infoFontSize),
                      SizedBox(height: cardWidth * 0.02),
                      // Subject
                      _buildSubject(infoFontSize),
                      SizedBox(height: cardWidth * 0.01),
                      // Course Info Row
                      _buildCourseInfoRow(iconSize, infoFontSize),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseImage(double height) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      child: CachedNetworkImage(
        imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/150',
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(color: Colors.white),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: Icon(Icons.error, color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildCourseTitle(double fontSize) {
    return Text(
      courseTitle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInstructor(double fontSize) {
    return Text(
      instructor,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildSubject(double fontSize) {
    return Text(
      subject,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildCourseInfoRow(double iconSize, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Time info
        Row(
          children: [
            Icon(Icons.access_time, size: iconSize, color: Colors.grey),
            SizedBox(width: iconSize * 0.25),
            Text(
              time,
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
        // Rating & Enrollment
        Row(
          children: [
            _buildRatingIndicator(iconSize, fontSize),
            SizedBox(width: iconSize),
            _buildEnrollmentIndicator(iconSize, fontSize),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingIndicator(double iconSize, double fontSize) {
    return rating != null
        ? Row(
      children: [
        Icon(Icons.star, size: iconSize, color: Colors.amber),
        SizedBox(width: 2),
        Text(
          rating!.toStringAsFixed(1),
          style: TextStyle(fontSize: fontSize),
        ),
      ],
    )
        : Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: iconSize * 2,
        height: iconSize,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(iconSize * 0.5),
        ),
      ),
    );
  }

  Widget _buildEnrollmentIndicator(double iconSize, double fontSize) {
    return enrolledCount != null
        ? Row(
      children: [
        Icon(Icons.people, size: iconSize, color: Colors.grey),
        SizedBox(width: 2),
        Text(
          '$enrolledCount',
          style: TextStyle(fontSize: fontSize),
        ),
      ],
    )
        : Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: iconSize * 2,
        height: iconSize,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(iconSize * 0.5),
        ),
      ),
    );
  }
}