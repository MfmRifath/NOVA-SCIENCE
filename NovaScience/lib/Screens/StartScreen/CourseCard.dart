import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseCard extends StatelessWidget {
  // Color palette
  final Color greenColor = const Color(0xFF11261f);
  final Color yellowColor = const Color(0xFF123755);
  final Color maroonColor = const Color(0xFF722626);
  final Color accentColor = const Color(0xFFe9c46a);

  final String courseTitle;
  final String time;
  final String instructor;
  final String imageUrl;
  final String subject;
  final String id;
  final double? rating;
  final int? enrolledCount;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth;
        final double titleFontSize = cardWidth > 200 ? 15 : 13;
        final double infoFontSize = cardWidth > 200 ? 12 : 11;
        final double iconSize = cardWidth > 200 ? 14 : 12;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Material(
              color: Colors.white,
              child: InkWell(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Image with subject tag
                    _buildImageSection(cardWidth),

                    // Course Details
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Course Title
                            Text(
                              courseTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.roboto(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w600,
                                color: greenColor,
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 8),

                            // Course metadata
                            _buildInfoRow(Icons.person_outline, instructor, infoFontSize, iconSize),
                            SizedBox(height: 4),
                            _buildInfoRow(Icons.access_time_outlined, time, infoFontSize, iconSize),

                            Spacer(),

                            // Bottom row with enrollment and rating
                            _buildBottomRow(infoFontSize, iconSize),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection(double cardWidth) {
    final double imageHeight = cardWidth * 0.56;

    return Stack(
      children: [
        // Main course image
        Hero(
          tag: 'course_image_$id',
          child: CachedNetworkImage(
            imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/150',
            height: imageHeight,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(color: Colors.white),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade200,
              child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
            ),
          ),
        ),

        // Subject tag
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: yellowColor,
            ),
            child: Text(
              subject,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        // Rating badge if available
        if (rating != null && rating! > 0)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: accentColor,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: greenColor,
                    size: 12,
                  ),
                  SizedBox(width: 2),
                  Text(
                    rating!.toStringAsFixed(1),
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: greenColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, double fontSize, double iconSize) {
    return Row(
      children: [
        Icon(
          icon,
          size: iconSize,
          color: yellowColor,
        ),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: fontSize,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(double fontSize, double iconSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Enrollment count
        enrolledCount != null
            ? Row(
          children: [
            Icon(
              Icons.people_outline,
              size: iconSize,
              color: yellowColor,
            ),
            SizedBox(width: 4),
            Text(
              _formatEnrollmentCount(enrolledCount!),
              style: GoogleFonts.roboto(
                fontSize: fontSize,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        )
            : Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 60,
            height: 16,
            color: Colors.grey.shade300,
          ),
        ),

        // View button
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: maroonColor,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          child: Text(
            'VIEW',
            style: GoogleFonts.roboto(
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  String _formatEnrollmentCount(int count) {
    if (count >= 1000000) {
      double num = count / 1000000;
      return '${num.toStringAsFixed(num.truncateToDouble() == num ? 0 : 1)}M';
    } else if (count >= 1000) {
      double num = count / 1000;
      return '${num.toStringAsFixed(num.truncateToDouble() == num ? 0 : 1)}K';
    }
    return count.toString();
  }
}