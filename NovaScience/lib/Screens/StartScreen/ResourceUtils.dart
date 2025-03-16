// ResourceUtils.dart - Enhanced with UI/UX support and comprehensive utilities
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

/// ResourceUtils provides centralized utilities for the resource management system.
/// This includes color schemes, icons, formatting functions, and Firebase operations.
class ResourceUtils {
  // ============== Color Schemes ==============

  // App theme colors
  static final Color primaryColor = Color(0xFF11261f);
  static final Color secondaryColor = Color(0xFF722626);
  static final Color accentColor = Color(0xFFe9c46a);
  static final Color backgroundColor = Color(0xFFF5F5F5);
  static final Color surfaceColor = Colors.white;
  static final Color textPrimaryColor = Color(0xFF2D3748);
  static final Color textSecondaryColor = Color(0xFF718096);

  // Stream-specific colors for consistent use throughout the app
  static Map<String, Color> streamColors = {
    'Science Stream': Colors.blue.shade700,
    'Arts Stream': Colors.purple.shade700,
    'Commerce Stream': Colors.green.shade700,
    'Technology Stream': Colors.orange.shade700,
    'O/L': Colors.red.shade700,
  };

  // Category-specific colors
  static Map<String, Color> categoryColors = {
    'Exam Papers': Colors.blue.shade700,
    'Notes': Colors.green.shade700,
    'Tutorials': Colors.orange.shade700,
    'Books': Colors.purple.shade700,
    'Other Materials': Colors.grey.shade700,
  };

  // Category icons for consistent use throughout the app
  static Map<String, IconData> categoryIcons = {
    'Exam Papers': Icons.description,
    'Notes': Icons.note,
    'Tutorials': Icons.school,
    'Books': Icons.book,
    'Other Materials': Icons.insert_drive_file,
  };

  // Subcategory icons for consistent use throughout the app
  static Map<String, IconData> subcategoryIcons = {
    'Term Papers': Icons.assignment,
    'Model Papers': Icons.model_training,
    'Past Papers': Icons.history_edu,
    'Term Paper Keys': Icons.key,
    'Past Paper Keys': Icons.vpn_key,
  };

  // Map to define subcategories for each category
  static Map<String, List<String>> categorySubcategories = {
    'Exam Papers': [
      'Term Papers',
      'Model Papers',
      'Past Papers',
      'Term Paper Keys',
      'Past Paper Keys',
    ],
    'Notes': [],
    'Tutorials': [],
    'Books': [],
    'Other Materials': [],
  };

  // ============== Typography Styles ==============

  static TextStyle get headingStyle => GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: primaryColor,
  );

  static TextStyle get subheadingStyle => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: primaryColor,
  );

  static TextStyle get bodyStyle => GoogleFonts.roboto(
    fontSize: 14,
    color: textPrimaryColor,
  );

  static TextStyle get captionStyle => GoogleFonts.roboto(
    fontSize: 12,
    color: textSecondaryColor,
  );

  // ============== Formatting Functions ==============

  /// Format file size for display in a human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Format date for display
  static String formatDate(dynamic date) {
    if (date == null) return 'Unknown date';

    if (date is Timestamp) {
      DateTime dateTime = date.toDate();
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }

    return 'Unknown date';
  }

  /// Format date with time for display
  static String formatDateWithTime(dynamic date) {
    if (date == null) return 'Unknown date';

    if (date is Timestamp) {
      DateTime dateTime = date.toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    }

    return 'Unknown date';
  }

  /// Format date as a relative time (e.g., "2 days ago")
  static String formatRelativeDate(dynamic date) {
    if (date == null) return 'Unknown date';

    if (date is Timestamp) {
      DateTime dateTime = date.toDate();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return '$years ${years == 1 ? 'year' : 'years'} ago';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    }

    return 'Unknown date';
  }

  /// Get the first letter of each word in a string for avatars
  static String getInitials(String fullName) {
    if (fullName == null || fullName.isEmpty) return '?';

    List<String> nameParts = fullName.split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }

    return nameParts[0][0].toUpperCase() +
        (nameParts.length > 1 ? nameParts[1][0].toUpperCase() : '');
  }

  /// Generate a consistent color from a string (e.g., for user avatars)
  static Color getColorFromString(String text) {
    if (text == null || text.isEmpty) return Colors.blue;

    // Use a hash code from the string to generate a predictable but distributed color
    final int hash = text.hashCode.abs();

    // Create a list of material colors
    final List<MaterialColor> materialColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
    ];

    // Use the hash to pick a color and shade
    final MaterialColor baseColor = materialColors[hash % materialColors.length];
    final List<int> shades = [300, 400, 500, 600, 700];
    final int shade = shades[hash % shades.length];

    return baseColor[shade]!;
  }

  // Get a color for a subcategory (derived from the parent category color)
  static Color getSubcategoryColor(String subcategory) {
    switch (subcategory) {
      case 'Term Papers':
        return Colors.blue.shade400;
      case 'Model Papers':
        return Colors.blue.shade500;
      case 'Past Papers':
        return Colors.blue.shade600;
      case 'Term Paper Keys':
        return Colors.blue.shade700;
      case 'Past Paper Keys':
        return Colors.blue.shade800;
      default:
        return Colors.blue;
    }
  }

  // ============== UI Helper Methods ==============

  /// Build a consistent gradient for backgrounds
  static LinearGradient getBackgroundGradient(Color baseColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.1),
        baseColor.withOpacity(0.2),
      ],
    );
  }

  /// Generate a random pastel color (good for empty state illustrations)
  static Color getRandomPastelColor() {
    final random = math.Random();
    // Pastel colors have high values for RGB components
    int r = 200 + random.nextInt(55); // 200-255
    int g = 200 + random.nextInt(55); // 200-255
    int b = 200 + random.nextInt(55); // 200-255

    return Color.fromARGB(255, r, g, b);
  }

  /// Convert hex color string to Color object
  static Color hexToColor(String hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.black;

    hexString = hexString.toUpperCase().replaceAll('#', '');
    if (hexString.length == 6) {
      hexString = 'FF' + hexString;
    }
    return Color(int.parse(hexString, radix: 16));
  }

  // ============== Firebase Operations ==============

  /// Get resources by stream
  static Future<List<Map<String, dynamic>>> getResourcesByStream(String stream) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('resources')
        .where('stream', isEqualTo: stream)
        .orderBy('uploadDate', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get resources by category
  static Future<List<Map<String, dynamic>>> getResourcesByCategory(String category) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('resources')
        .where('category', isEqualTo: category)
        .orderBy('uploadDate', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get resources by subcategory
  static Future<List<Map<String, dynamic>>> getResourcesBySubcategory(String category, String subcategory) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('resources')
        .where('category', isEqualTo: category)
        .where('subcategory', isEqualTo: subcategory)
        .orderBy('uploadDate', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get all resources uploaded by a specific user
  static Future<List<Map<String, dynamic>>> getResourcesByUser(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('resources')
        .where('uploaderId', isEqualTo: userId)
        .orderBy('uploadDate', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get recently added resources
  static Future<List<Map<String, dynamic>>> getRecentResources({int limit = 5}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('resources')
        .orderBy('uploadDate', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Get popular resources (based on view count)
  static Future<List<Map<String, dynamic>>> getPopularResources({int limit = 5}) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('resources')
        .orderBy('viewCount', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Delete resource and its file
  static Future<void> deleteResource(String resourceId) async {
    try {
      // Get resource data
      final docSnap = await FirebaseFirestore.instance
          .collection('resources')
          .doc(resourceId)
          .get();

      if (!docSnap.exists) {
        throw Exception('Resource not found');
      }

      final data = docSnap.data();

      // Delete file from storage if URL exists
      if (data != null && data['fileUrl'] != null) {
        try {
          final storageRef = FirebaseStorage.instance.refFromURL(data['fileUrl']);
          await storageRef.delete();
        } catch (e) {
          print('Error deleting file from storage: $e');
          // Continue with document deletion even if file deletion fails
        }
      }

      // Delete document
      await FirebaseFirestore.instance
          .collection('resources')
          .doc(resourceId)
          .delete();
    } catch (e) {
      print('Error deleting resource: $e');
      throw e;
    }
  }

  /// Increment resource view count
  static Future<void> incrementResourceViewCount(String resourceId) async {
    try {
      await FirebaseFirestore.instance
          .collection('resources')
          .doc(resourceId)
          .update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  /// Get resource statistics
  static Future<Map<String, dynamic>> getResourceStats() async {
    try {
      // Get total resources count
      final resourcesSnapshot = await FirebaseFirestore.instance
          .collection('resources')
          .get();

      final totalCount = resourcesSnapshot.docs.length;

      // Initialize stream and category counters
      Map<String, int> streamCounts = {};
      for (var stream in streamColors.keys) {
        streamCounts[stream] = 0;
      }

      Map<String, int> categoryCounts = {};
      for (var category in categoryIcons.keys) {
        categoryCounts[category] = 0;
      }

      // Initialize subcategory counts
      Map<String, int> subcategoryCounts = {};
      for (var subcategory in subcategoryIcons.keys) {
        subcategoryCounts[subcategory] = 0;
      }

      // Calculate counts
      for (var doc in resourcesSnapshot.docs) {
        final data = doc.data();

        // Count by stream
        final stream = data['stream'];
        if (stream != null && streamCounts.containsKey(stream)) {
          streamCounts[stream] = streamCounts[stream]! + 1;
        }

        // Count by category
        final category = data['category'];
        if (category != null && categoryCounts.containsKey(category)) {
          categoryCounts[category] = categoryCounts[category]! + 1;
        }

        // Count by subcategory (only for Exam Papers)
        if (category == 'Exam Papers') {
          final subcategory = data['subcategory'];
          if (subcategory != null && subcategoryCounts.containsKey(subcategory)) {
            subcategoryCounts[subcategory] = subcategoryCounts[subcategory]! + 1;
          }
        }
      }

      // Calculate most popular stream and category
      String? mostPopularStream;
      int mostPopularStreamCount = 0;
      for (var entry in streamCounts.entries) {
        if (entry.value > mostPopularStreamCount) {
          mostPopularStreamCount = entry.value;
          mostPopularStream = entry.key;
        }
      }

      String? mostPopularCategory;
      int mostPopularCategoryCount = 0;
      for (var entry in categoryCounts.entries) {
        if (entry.value > mostPopularCategoryCount) {
          mostPopularCategoryCount = entry.value;
          mostPopularCategory = entry.key;
        }
      }

      return {
        'totalCount': totalCount,
        'streamCounts': streamCounts,
        'categoryCounts': categoryCounts,
        'subcategoryCounts': subcategoryCounts,
        'mostPopularStream': mostPopularStream,
        'mostPopularCategory': mostPopularCategory,
        'lastUpdated': Timestamp.now(),
      };
    } catch (e) {
      print('Error getting resource stats: $e');
      return {
        'totalCount': 0,
        'streamCounts': {},
        'categoryCounts': {},
        'subcategoryCounts': {},
        'mostPopularStream': null,
        'mostPopularCategory': null,
        'lastUpdated': Timestamp.now(),
      };
    }
  }

  // ============== Layout Utilities ==============

  /// Return appropriate text overflow based on available width
  static TextOverflow getTextOverflow(double width) {
    if (width < 100) {
      return TextOverflow.fade;
    } else if (width < 200) {
      return TextOverflow.ellipsis;
    } else {
      return TextOverflow.clip;
    }
  }

  /// Calculate appropriate number of grid columns based on screen width
  static int getGridColumnCount(double width) {
    if (width < 400) {
      return 1;
    } else if (width < 700) {
      return 2;
    } else if (width < 1000) {
      return 3;
    } else {
      return 4;
    }
  }

  // ============== Widget Utilities ==============

  /// Create a shimmer loading effect for placeholders
  static Widget buildShimmerLoading({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment(-1.0, -0.5),
          end: Alignment(1.0, 0.5),
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  /// Create a standard card container
  static Widget buildCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double elevation = 1,
    BorderRadius? borderRadius,
  }) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  /// Create a standard section header
  static Widget buildSectionHeader({
    required String title,
    IconData? icon,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: primaryColor, size: 20),
              SizedBox(width: 8),
            ],
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
          ],
        ),
        if (onAction != null && actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
      ],
    );
  }

  /// Create a standard empty state widget
  static Widget buildEmptyState({
    required String message,
    String? submessage,
    IconData icon = Icons.folder_off,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 24),
            Text(
              message,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (submessage != null) ...[
              SizedBox(height: 8),
              Text(
                submessage,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Create a badge with icon and text
  static Widget buildBadge({
    required String text,
    required Color color,
    IconData? icon,
    double? fontSize,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Create an avatar for a user
  static Widget buildAvatar({
    required String name,
    double size = 40,
  }) {
    final initials = getInitials(name);
    final color = getColorFromString(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.roboto(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ============== Export and PDF Functions (Placeholders for future implementation) ==============

  /// Export resources to CSV format (placeholder)
  static Future<String> exportResourcesToCsv(List<Map<String, dynamic>> resources) async {
    // This would be implemented to generate a CSV file of resources
    // and return the file path or URL
    return 'Not implemented';
  }

  /// Generate PDF for a single resource (placeholder)
  static Future<String> generateResourcePdf(Map<String, dynamic> resource) async {
    // This would be implemented to generate a PDF report for a single resource
    // and return the file path or URL
    return 'Not implemented';
  }
}