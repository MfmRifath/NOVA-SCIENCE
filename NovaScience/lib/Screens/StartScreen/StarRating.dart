import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final double size;
  final bool showRatingCount;
  final bool compact;
  final Color starColor;
  final Color emptyStarColor;

  const StarRating({
    required this.rating,
    this.totalRatings = 0,
    this.size = 16,
    this.showRatingCount = false,
    this.compact = false,
    this.starColor = Colors.amber,
    this.emptyStarColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    // If there are no ratings, we should show a special message
    if (rating <= 0 || totalRatings == 0) {
      return Text(
        'Not rated yet',
        style: GoogleFonts.poppins(
          fontSize: size * 0.75,
          fontStyle: FontStyle.italic,
          color: Colors.grey[600],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Star icons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            // Calculate fill percentage for current star
            double fillPercent = rating - index;
            if (fillPercent > 1.0) fillPercent = 1.0;
            if (fillPercent < 0.0) fillPercent = 0.0;

            // Choose icon based on fill percentage
            IconData icon;
            if (fillPercent >= 0.75) {
              icon = Icons.star_rounded;
            } else if (fillPercent >= 0.25) {
              icon = Icons.star_half_rounded;
            } else {
              icon = Icons.star_border_rounded;
            }

            return Icon(
              icon,
              color: fillPercent > 0 ? starColor : emptyStarColor,
              size: size,
            );
          }),
        ),

        // Rating count
        if (showRatingCount && !compact)
          Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              '($totalRatings)',
              style: GoogleFonts.poppins(
                fontSize: size * 0.7,
                color: Colors.grey[600],
              ),
            ),
          ),

        // Compact view with number
        if (compact)
          Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              rating.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: size * 0.8,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
