class RatingUtils {
  /// Ensures consistent rating data format and calculation
  /// for all course displays throughout the app
  static Map<String, dynamic> ensureRatingData(Map<String, dynamic> courseData) {
    // Make a copy to avoid modifying the original
    Map<String, dynamic> data = Map.from(courseData);

    // Look for feedbacks data to calculate average rating
    if (data.containsKey('feedbacks') && data['feedbacks'] is List) {
      List feedbacks = data['feedbacks'] as List;

      if (feedbacks.isNotEmpty) {
        double totalRating = 0.0;
        int validRatings = 0;

        for (var feedback in feedbacks) {
          if (feedback is Map<String, dynamic> &&
              feedback.containsKey('rating') &&
              feedback['rating'] != null) {
            double rating = (feedback['rating'] as num).toDouble();
            if (rating > 0) {
              totalRating += rating;
              validRatings++;
            }
          }
        }

        // Calculate and update average rating
        if (validRatings > 0) {
          data['rating'] = totalRating / validRatings;
          data['ratingCount'] = validRatings;
          data['averageRating'] = totalRating / validRatings;
        } else {
          // Default values for courses with no valid ratings
          data['rating'] = 0.0;
          data['ratingCount'] = 0;
          data['averageRating'] = 0.0;
        }
      } else {
        // Empty feedbacks list
        data['rating'] = 0.0;
        data['ratingCount'] = 0;
        data['averageRating'] = 0.0;
      }
    } else if (data.containsKey('rating') && data['rating'] != null) {
      // If rating exists but no feedbacks data, ensure proper type
      data['rating'] = (data['rating'] as num).toDouble();

      // Make sure ratingCount exists
      if (!data.containsKey('ratingCount') || data['ratingCount'] == null) {
        data['ratingCount'] = 0;
      } else {
        data['ratingCount'] = (data['ratingCount'] as num).toInt();
      }

      // Set averageRating to match rating for consistency
      data['averageRating'] = data['rating'];
    } else {
      // No rating data at all - set defaults
      data['rating'] = 0.0;
      data['ratingCount'] = 0;
      data['averageRating'] = 0.0;
    }

    return data;
  }

  /// Format the rating for display
  static String formatRating(double rating) {
    return rating > 0 ? rating.toStringAsFixed(1) : 'New';
  }

  /// Get the display text for ratings
  static String getRatingText(double rating, int ratingCount) {
    if (rating <= 0 || ratingCount <= 0) {
      return 'Not rated yet';
    } else if (ratingCount == 1) {
      return '${formatRating(rating)} (1 review)';
    } else {
      return '${formatRating(rating)} ($ratingCount reviews)';
    }
  }
}