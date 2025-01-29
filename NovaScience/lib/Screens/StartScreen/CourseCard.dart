// In CourseCard.dart
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
            _buildCourseImage(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseTitle(),
                  SizedBox(height: 6),
                  _buildInstructor(),
                  SizedBox(height: 6),
                  _buildSubject(),
                  SizedBox(height: 12),
                  _buildCourseInfoRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseImage() {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      child: CachedNetworkImage(
        imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/150',
        height: 100,
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

  Widget _buildCourseTitle() {
    return Text(
      courseTitle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInstructor() {
    return Text(
      instructor,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildSubject() {
    return Text(
      subject,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildCourseInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey),
            SizedBox(width: 4),
            Text(time),
          ],
        ),
        Row(
          children: [
            _buildRatingIndicator(),
            SizedBox(width: 8),
            _buildEnrollmentIndicator(),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingIndicator() {
    return rating != null
        ? Row(
      children: [
        Icon(Icons.star, size: 16, color: Colors.amber),
        Text(rating!.toStringAsFixed(1)),
      ],
    )
        : Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 30,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildEnrollmentIndicator() {
    return enrolledCount != null
        ? Row(
      children: [
        Icon(Icons.people, size: 16, color: Colors.grey),
        Text('$enrolledCount'),
      ],
    )
        : Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 30,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}