import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nova_science/Screens/StartScreen/CourseEditScreen.dart';
import 'package:nova_science/Screens/StartScreen/Previewer.dart';
import 'package:nova_science/Screens/StartScreen/TeacherScreen.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart';

class EnhancedSectionManagement extends StatefulWidget {
  final String courseId;

  const EnhancedSectionManagement({
    Key? key,
    required this.courseId,
  }) : super(key: key);

  @override
  _EnhancedSectionManagementState createState() => _EnhancedSectionManagementState();
}

class _EnhancedSectionManagementState extends State<EnhancedSectionManagement> {
  // Controllers
  final TextEditingController _sectionTitleController = TextEditingController();
  final TextEditingController _editSectionTitleController = TextEditingController();
  final TextEditingController _resourceTitleController = TextEditingController();
  final TextEditingController _youtubeUrlController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _isEditMode = false;
  String? _currentEditingSectionId;
  Section? _currentEditingSection;

  // Resource management
  String _resourceType = "Video";
  File? _pickedPdfFile;
  bool _isLoadingResources = false;

  // New Modern Color Palette as requested
  final Color primaryColor = const Color(0xFF11261f); // Dark Green
  final Color secondaryColor = const Color(0xFF123755); // Dark Blue (listed as yellow but is blue)
  final Color accentColor = const Color(0xFF722626); // Maroon
  final Color successColor = const Color(0xFF2E7D32); // Complementary Green for success
  final Color errorColor = const Color(0xFF722626); // Using Maroon for error too
  final Color surfaceColor = const Color(0xFFF5F5F5); // Light gray background
  final Color cardColor = Colors.white;
  final Color textDarkColor = const Color(0xFF1E1E1E); // Dark text
  final Color textLightColor = Colors.white; // Light text
  final Color dividerColor = const Color(0xFFE0E0E0); // Subtle divider

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }
  String? extractYoutubeVideoId(String url) {
    // Try standard methods first
    String? videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) return videoId;

    // Manual parsing as fallback
    RegExp regExp = RegExp(
      r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
      caseSensitive: false,
      multiLine: false,
    );

    Match? match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 2) {
      return match.group(2);
    }

    return null;
  }
  Future<void> _loadCourseData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load course data
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      await courseProvider.getCourseById(widget.courseId);
    } catch (e) {
      print('Error loading course data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading course data. Please try again.',
            style: GoogleFonts.poppins(
              color: textLightColor,
            ),
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _sectionTitleController.dispose();
    _editSectionTitleController.dispose();
    _resourceTitleController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          'Manage Course Content',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textLightColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: textLightColor),
            onPressed: _loadCourseData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: secondaryColor,
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course title and info
            _buildCourseInfoCard(courseProvider),
            SizedBox(height: 20),

            // Section management
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left panel - Section list
                  Expanded(
                    flex: 1,
                    child: _buildSectionPanel(courseProvider),
                  ),

                  // Right panel - Section content
                  if (screenWidth > 800) ...[
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildResourcesPanel(courseProvider),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      // Responsive layout for mobile: show bottom sheet for resources when section is selected
      floatingActionButton: screenWidth <= 800 && _currentEditingSection != null
          ? FloatingActionButton(
        onPressed: () {
          _showResourcesBottomSheet(courseProvider);
        },
        backgroundColor: secondaryColor,
        child: Icon(Icons.list, color: textLightColor),
      )
          : screenWidth <= 800
          ? FloatingActionButton(
        onPressed: () {
          _showAddSectionDialog(courseProvider);
        },
        backgroundColor: primaryColor,
        child: Icon(Icons.add, color: textLightColor),
      )
          : null,
    );
  }

  Widget _buildCourseInfoCard(CourseProvider courseProvider) {
    return FutureBuilder<Course?>(
      future: courseProvider.getCourseById(widget.courseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: secondaryColor,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading course information',
                style: GoogleFonts.poppins(
                  color: errorColor,
                ),
              ),
            ),
          );
        }

        final course = snapshot.data!;

        return Card(
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  secondaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Course image with enhanced styling
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                          ? Image.network(
                        course.imageUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                      )
                          : _buildPlaceholderImage(),
                    ),
                  ),
                  SizedBox(width: 20),

                  // Course info with improved typography
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.courseTitle ?? 'Untitled Course',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textLightColor,
                            shadows: [
                              Shadow(
                                blurRadius: 2.0,
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          course.subject ?? 'No subject',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textLightColor.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            _buildCourseTag(
                              '${course.sections.length} Sections',
                              Icons.folder_outlined,
                            ),
                            SizedBox(width: 3),
                            _buildCourseTag(
                              'Rs. ${course.price}',
                              Icons.monetization_on_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Edit course button with improved UI
                  Container(
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Navigate to the course editing screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseEditScreen(courseId: widget.courseId),
                          ),
                        ).then((_) {
                          // Refresh data when returning from edit screen
                          _loadCourseData();
                        });
                      },
                      icon: Icon(
                        Icons.edit_outlined,
                        color: textLightColor,
                        size: 22,
                      ),
                      tooltip: 'Edit Course',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0);
      },
    );
  }

  Widget _buildCourseTag(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      margin: EdgeInsets.only(right: 4), // Add margin to prevent overflow
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Ensure row takes minimum space needed
        children: [
          Icon(
            icon,
            size: 10,
            color: textLightColor,
          ),
          SizedBox(width: 4),
          // Constrain text with Expanded or limit with maxLines
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: textLightColor,
              ),
              overflow: TextOverflow.ellipsis, // Handle text overflow gracefully
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildPlaceholderImage() {
    return Container(
      width: 100,
      height: 100,
      color: secondaryColor.withOpacity(0.3),
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: textLightColor.withOpacity(0.7),
      ),
    );
  }

  Widget _buildSectionPanel(CourseProvider courseProvider) {
    return FutureBuilder<Course?>(
      future: courseProvider.getCourseById(widget.courseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorCard('Error loading sections');
        }

        final course = snapshot.data!;
        final sections = course.sections;

        return Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with improved styling
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Course Sections',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    MediaQuery.of(context).size.width > 800
                        ? ElevatedButton.icon(
                      onPressed: () {
                        _showAddSectionDialog(courseProvider);
                      },
                      icon: Icon(Icons.add, size: 16),
                      label: Text(
                        'Add Section',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: textLightColor,
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    )
                        : Container(
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () {
                          _showAddSectionDialog(courseProvider);
                        },
                        icon: Icon(Icons.add_circle_outline, color: primaryColor),
                        tooltip: 'Add Section',
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),
                Divider(height: 1, color: dividerColor),
                SizedBox(height: 16),

                // Sections list with improved styling
                Expanded(
                  child: sections.isEmpty
                      ? _buildEmptySectionsList()
                      : ReorderableListView.builder(
                    itemCount: sections.length,
                    onReorder: (oldIndex, newIndex) {
                      // Handle reordering of sections
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }

                      courseProvider.reorderSections(
                        widget.courseId,
                        oldIndex,
                        newIndex,
                      );
                    },
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return _buildSectionItem(section, index, courseProvider);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildSectionsList(List<Section> sections, CourseProvider courseProvider) {
    return ReorderableListView.builder(
      itemCount: sections.length,
      onReorder: (oldIndex, newIndex) {
        // Handle reordering of sections
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }

        courseProvider.reorderSections(
          widget.courseId,
          oldIndex,
          newIndex,
        );
      },
      itemBuilder: (context, index) {
        final section = sections[index];
        // Ensure each item has a unique key
        return _buildSectionItem(section, index, courseProvider);
      },
    );
  }
  Widget _buildSectionItem(Section section, int index, CourseProvider courseProvider) {
    final isSelected = _currentEditingSection != null &&
        _currentEditingSection?.sectionTitle == section.sectionTitle;

    final videoCount = section.videos.length;
    final pdfCount = section.pdfs.length;

    return Container(
      key: Key('section-$index'), // Ensure each item has a proper key
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? secondaryColor.withOpacity(0.1) : cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? secondaryColor : dividerColor,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: secondaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? secondaryColor.withOpacity(0.2) : accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? secondaryColor.withOpacity(0.5) : accentColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            '${index + 1}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? secondaryColor : accentColor,
            ),
          ),
        ),
        title: Text(
          section.sectionTitle ?? 'Untitled Section',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textDarkColor,
          ),
          overflow: TextOverflow.ellipsis, // Prevent title overflow
          maxLines: 1,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Constrain the row size
            children: [
              if (videoCount > 0) ...[
                Icon(
                  Icons.video_library_outlined,
                  size: 12,
                  color: secondaryColor.withOpacity(0.7),
                ),
                SizedBox(width: 4),
                Text(
                  '$videoCount ${videoCount == 1 ? 'Video' : 'Videos'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textDarkColor.withOpacity(0.7),
                  ),
                ),
              ],
              if (videoCount > 0 && pdfCount > 0) SizedBox(width: 12),
              if (pdfCount > 0) ...[
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 12,
                  color: accentColor.withOpacity(0.7),
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '$pdfCount ${pdfCount == 1 ? 'PDF' : 'PDFs'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textDarkColor.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Container(
          width: 110, // Fix the width to prevent overflow
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: primaryColor,
                  ),
                  onPressed: () {
                    _showEditSectionDialog(courseProvider, section);
                  },
                  tooltip: 'Edit Section',
                  constraints: BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: errorColor,
                  ),
                  onPressed: () {
                    _showDeleteSectionDialog(courseProvider, section.sectionTitle!);
                  },
                  tooltip: 'Delete Section',
                  constraints: BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          setState(() {
            _currentEditingSection = section;
          });
        },
      ),
    );
  }

  Widget _buildResourcesGrid(CourseProvider courseProvider, Section section) {
    // Combine videos and PDFs into a single list of resources
    List<Map<String, dynamic>> resources = [];

    // Add videos
    for (int i = 0; i < section.videos.length; i++) {
      final video = section.videos[i];
      resources.add({
        'type': 'video',
        'title': video.title,
        'url': video.videoUrl,
        'index': i,
      });
    }

    // Add PDFs
    for (int i = 0; i < section.pdfs.length; i++) {
      final pdf = section.pdfs[i];
      resources.add({
        'type': 'pdf',
        'title': pdf.title,
        'url': pdf.pdfUrl,
        'index': i,
      });
    }

    return ReorderableGridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: resources.length,
      onReorder: (oldIndex, newIndex) {
        // Handle reordering of resources
        // Implementation depends on your CourseProvider
      },
      itemBuilder: (context, index) {
        final resource = resources[index];
        final isVideo = resource['type'] == 'video';

        return Card(
          key: Key('resource-$index'), // ⚠️ This must be KEY not ValueKey
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isVideo
                  ? secondaryColor.withOpacity(0.3)
                  : accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: /* Resource card content */ InkWell(
            onTap: () {
              if (isVideo) {
                _playVideo(resource['url']);
              } else {
                _viewPdf(resource['title'], resource['url']);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resource header with improved layout
                  Row(
                    mainAxisSize: MainAxisSize.min, // Prevent overflow
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isVideo
                              ? secondaryColor.withOpacity(0.1)
                              : accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isVideo
                                ? secondaryColor.withOpacity(0.3)
                                : accentColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          isVideo
                              ? Icons.video_library_outlined
                              : Icons.picture_as_pdf_outlined,
                          size: 18,
                          color: isVideo ? secondaryColor : accentColor,
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isVideo ? 'Video' : 'PDF Document',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isVideo ? secondaryColor : accentColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: /* Menu button code */
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 16,
                            color: textDarkColor.withOpacity(0.6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16, color: primaryColor),
                                  SizedBox(width: 10),
                                  Text(
                                    'Edit',
                                    style: GoogleFonts.poppins(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 16, color: errorColor),
                                  SizedBox(width: 10),
                                  Text(
                                    'Delete',
                                    style: GoogleFonts.poppins(
                                      color: errorColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditResourceDialog(
                                courseProvider,
                                section.sectionTitle!,
                                resource,
                              );
                            } else if (value == 'delete') {
                              _showDeleteResourceDialog(
                                courseProvider,
                                section.sectionTitle!,
                                resource,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),
                  Divider(height: 1, color: dividerColor),
                  SizedBox(height: 16),

                  // Resource title
                  Expanded(
                    child: Text(
                      resource['title'] ?? 'Untitled Resource',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textDarkColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Resource actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          if (isVideo) {
                            _playVideo(resource['url']);
                          } else {
                            _viewPdf(resource['title'], resource['url']);
                          }
                        },
                        icon: Icon(
                          isVideo ? Icons.play_arrow : Icons.visibility_outlined,
                          size: 16,
                        ),
                        label: Text(
                          isVideo ? 'Play' : 'View',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isVideo ? secondaryColor : accentColor,
                          side: BorderSide(
                            color: isVideo ? secondaryColor : accentColor,
                            width: 1.5,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptySectionsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_outlined,
              size: 48,
              color: primaryColor.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'No sections found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: textDarkColor,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Add a section to get started',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textDarkColor.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              _showAddSectionDialog(Provider.of<CourseProvider>(context, listen: false));
            },
            icon: Icon(Icons.add),
            label: Text(
              'Add Section',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: textLightColor,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesPanel(CourseProvider courseProvider) {
    if (_currentEditingSection == null) {
      return Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.touch_app_outlined,
                    size: 48,
                    color: secondaryColor.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Select a section to manage resources',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textDarkColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Click on any section from the list to view and manage its resources',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textDarkColor.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final section = _currentEditingSection!;
    final sectionTitle = section.sectionTitle!;

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with improved styling
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resources for',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: textDarkColor.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        sectionTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddResourceDialog(courseProvider, sectionTitle);
                  },
                  icon: Icon(Icons.add, size: 16),
                  label: Text(
                    'Add Resource',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: textLightColor,
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),
            Divider(height: 1, color: dividerColor),
            SizedBox(height: 20),

            // Resource type tabs with improved styling
            Row(
              children: [
                _buildResourceTypeTab('All', Icons.view_list_outlined, true),
                SizedBox(width: 16),
                _buildResourceTypeTab('Videos', Icons.video_library_outlined, false),
                SizedBox(width: 16),
                _buildResourceTypeTab('PDFs', Icons.picture_as_pdf_outlined, false),
              ],
            ),

            SizedBox(height: 20),

            // Resources list
            Expanded(
              child: _isLoadingResources
                  ? Center(
                child: CircularProgressIndicator(
                  color: secondaryColor,
                ),
              )
                  : section.videos.isEmpty && section.pdfs.isEmpty
                  ? _buildEmptyResourcesList(courseProvider, sectionTitle)
                  : _buildResourcesGrid(courseProvider, section),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTypeTab(String title, IconData icon, bool isSelected) {
    return InkWell(
      onTap: () {
        // Handle tab selection
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? secondaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? secondaryColor : dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? secondaryColor : textDarkColor.withOpacity(0.6),
            ),
            SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? secondaryColor : textDarkColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResourcesList(CourseProvider courseProvider, String sectionTitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: secondaryColor.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'No resources in this section',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: textDarkColor,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Add videos or PDFs to enhance your course',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textDarkColor.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _resourceType = "Video";
                  });
                  _showAddResourceDialog(courseProvider, sectionTitle);
                },
                icon: Icon(Icons.video_library_outlined),
                label: Text(
                  'Add Video',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryColor,
                  side: BorderSide(color: secondaryColor, width: 1.5),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _resourceType = "PDF";
                  });
                  _showAddResourceDialog(courseProvider, sectionTitle);
                },
                icon: Icon(Icons.picture_as_pdf_outlined),
                label: Text(
                  'Add PDF',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor, width: 1.5),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _showResourcesBottomSheet(CourseProvider courseProvider) {
    if (_currentEditingSection == null) return;

    final section = _currentEditingSection!;
    final sectionTitle = section.sectionTitle!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header with improved styling
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resources for',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: textDarkColor.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            sectionTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.close, color: textDarkColor),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),
              Divider(height: 1, color: dividerColor),
              SizedBox(height: 16),

              // Add resource button with improved styling
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddResourceDialog(courseProvider, sectionTitle);
                  },
                  icon: Icon(Icons.add, size: 16),
                  label: Text(
                    'Add Resource',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    foregroundColor: textLightColor,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Resources list with improved styling
              Expanded(
                child: section.videos.isEmpty && section.pdfs.isEmpty
                    ? _buildEmptyResourcesList(courseProvider, sectionTitle)
                    : ListView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (section.videos.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 18,
                            color: secondaryColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Videos',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: section.videos.length,
                        separatorBuilder: (context, index) => SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final video = section.videos[index];
                          return _buildResourceListItem(
                            courseProvider,
                            sectionTitle,
                            {
                              'type': 'video',
                              'title': video.title,
                              'url': video.videoUrl,
                              'index': index,
                            },
                          );
                        },
                      ),
                      SizedBox(height: 24),
                    ],

                    if (section.pdfs.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 18,
                            color: accentColor,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'PDFs',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: section.pdfs.length,
                        separatorBuilder: (context, index) => SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final pdf = section.pdfs[index];
                          return _buildResourceListItem(
                            courseProvider,
                            sectionTitle,
                            {
                              'type': 'pdf',
                              'title': pdf.title,
                              'url': pdf.pdfUrl,
                              'index': index,
                            },
                          );
                        },
                      ),
                    ],

                    // Add padding at the bottom for better UX
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResourceListItem(CourseProvider courseProvider, String sectionTitle, Map<String, dynamic> resource) {
    final isVideo = resource['type'] == 'video';

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isVideo
              ? secondaryColor.withOpacity(0.3)
              : accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isVideo
                ? secondaryColor.withOpacity(0.1)
                : accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isVideo
                  ? secondaryColor.withOpacity(0.3)
                  : accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            isVideo
                ? Icons.video_library_outlined
                : Icons.picture_as_pdf_outlined,
            size: 20,
            color: isVideo ? secondaryColor : accentColor,
          ),
        ),
        title: Text(
          resource['title'] ?? 'Untitled Resource',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textDarkColor,
          ),
        ),
        subtitle: Text(
          isVideo ? 'Video' : 'PDF Document',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isVideo ? secondaryColor.withOpacity(0.7) : accentColor.withOpacity(0.7),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: primaryColor,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showEditResourceDialog(
                    courseProvider,
                    sectionTitle,
                    resource,
                  );
                },
                constraints: BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: errorColor,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteResourceDialog(
                    courseProvider,
                    sectionTitle,
                    resource,
                  );
                },
                constraints: BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pop(context);
          if (isVideo) {
            _playVideo(resource['url']);
          } else {
            _viewPdf(resource['title'], resource['url']);
          }
        },
      ),
    ).animate().fade(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  // Helper methods with improved UI

  void _showAddSectionDialog(CourseProvider courseProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.create_new_folder_outlined,
                size: 40,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Add New Section',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: TextField(
          controller: _sectionTitleController,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: textDarkColor,
          ),
          decoration: InputDecoration(
            labelText: 'Section Title',
            labelStyle: GoogleFonts.poppins(
              color: secondaryColor,
              fontSize: 14,
            ),
            hintText: 'Enter section title',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: secondaryColor, width: 2),
            ),
            prefixIcon: Icon(Icons.title_outlined, color: secondaryColor, size: 20),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: textDarkColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_sectionTitleController.text.trim().isNotEmpty) {
                await courseProvider.addSection(
                  widget.courseId,
                  _sectionTitleController.text.trim(),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Section added successfully!',
                      style: GoogleFonts.poppins(
                        color: textLightColor,
                      ),
                    ),
                    backgroundColor: successColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );

                _sectionTitleController.clear();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter a section title',
                      style: GoogleFonts.poppins(
                        color: textLightColor,
                      ),
                    ),
                    backgroundColor: errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: textLightColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 2,
            ),
            child: Text(
              'Add Section',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSectionDialog(CourseProvider courseProvider, Section section) {
    _editSectionTitleController.text = section.sectionTitle ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 40,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Edit Section',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: TextField(
          controller: _editSectionTitleController,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: textDarkColor,
          ),
          decoration: InputDecoration(
            labelText: 'Section Title',
            labelStyle: GoogleFonts.poppins(
              color: secondaryColor,
              fontSize: 14,
            ),
            hintText: 'Enter section title',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: secondaryColor, width: 2),
            ),
            prefixIcon: Icon(Icons.title_outlined, color: secondaryColor, size: 20),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: textDarkColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_editSectionTitleController.text.trim().isNotEmpty) {
                await courseProvider.updateSectionTitle(
                  widget.courseId,
                  section.sectionTitle!,
                  _editSectionTitleController.text.trim(),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Section updated successfully!',
                      style: GoogleFonts.poppins(
                        color: textLightColor,
                      ),
                    ),
                    backgroundColor: successColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );

                _editSectionTitleController.clear();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter a section title',
                      style: GoogleFonts.poppins(
                        color: textLightColor,
                      ),
                    ),
                    backgroundColor: errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: textLightColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 2,
            ),
            child: Text(
              'Update Section',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteSectionDialog(CourseProvider courseProvider, String sectionTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 40,
                color: errorColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Delete Section',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: errorColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$sectionTitle"? All resources in this section will also be deleted. This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: textDarkColor,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: textDarkColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await courseProvider.deleteSection(
                widget.courseId,
                sectionTitle,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Section deleted successfully!',
                    style: GoogleFonts.poppins(
                      color: textLightColor,
                    ),
                  ),
                  backgroundColor: successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );

              if (_currentEditingSection?.sectionTitle == sectionTitle) {
                setState(() {
                  _currentEditingSection = null;
                });
              }

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: textLightColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 2,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddResourceDialog(CourseProvider courseProvider, String sectionTitle) {
    _resourceTitleController.clear();
    _youtubeUrlController.clear();
    _pickedPdfFile = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _resourceType == "Video"
                        ? secondaryColor.withOpacity(0.1)
                        : accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _resourceType == "Video"
                        ? Icons.video_library_outlined
                        : Icons.picture_as_pdf_outlined,
                    size: 40,
                    color: _resourceType == "Video" ? secondaryColor : accentColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Add Resource',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'to "$sectionTitle"',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textDarkColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Resource type selection with improved UI
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: dividerColor,
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Video option
                        _buildResourceTypeOption(
                          setState,
                          "Video",
                          Icons.video_library_outlined,
                          secondaryColor,
                        ),

                        Container(
                          height: 36,
                          width: 1,
                          color: dividerColor,
                        ),

                        // PDF option
                        _buildResourceTypeOption(
                          setState,
                          "PDF",
                          Icons.picture_as_pdf_outlined,
                          accentColor,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Resource title field with improved UI
                  TextField(
                    controller: _resourceTitleController,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: textDarkColor,
                    ),
                    decoration: InputDecoration(
                      labelText: _resourceType == "Video" ? 'Video Title' : 'PDF Title',
                      labelStyle: GoogleFonts.poppins(
                        color: _resourceType == "Video" ? secondaryColor : accentColor,
                        fontSize: 14,
                      ),
                      hintText: 'Enter ${_resourceType.toLowerCase()} title',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _resourceType == "Video" ? secondaryColor : accentColor,
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        _resourceType == "Video"
                            ? Icons.title_outlined
                            : Icons.description_outlined,
                        color: _resourceType == "Video" ? secondaryColor : accentColor,
                        size: 20,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Resource specific input (URL for Video, file for PDF) with improved UI
                  if (_resourceType == "Video")
                    TextField(
                      controller: _youtubeUrlController,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: textDarkColor,
                      ),
                      decoration: InputDecoration(
                        labelText: 'YouTube URL',
                        labelStyle: GoogleFonts.poppins(
                          color: secondaryColor,
                          fontSize: 14,
                        ),
                        hintText: 'Enter valid YouTube URL',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: secondaryColor, width: 2),
                        ),
                        prefixIcon: Icon(Icons.link, color: secondaryColor, size: 20),
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // PDF file picker button with improved UI
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Pick a PDF file using file_picker.
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                            );
                            if (result != null && result.files.isNotEmpty) {
                              setState(() {
                                _pickedPdfFile = File(result.files.first.path!);
                              });
                            }
                          },
                          icon: Icon(Icons.upload_file_outlined, size: 18),
                          label: Text(
                            'Select PDF File',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: textLightColor,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            minimumSize: Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                        ),
                        SizedBox(height: 16),
                        // Show selected file name with improved UI
                        if (_pickedPdfFile != null)
                          Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: accentColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: successColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: successColor,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _pickedPdfFile!.path.split('/').last,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: textDarkColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: textDarkColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  String title = _resourceTitleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please enter a resource title',
                          style: GoogleFonts.poppins(
                            color: textLightColor,
                          ),
                        ),
                        backgroundColor: errorColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    return;
                  }

                  if (_resourceType == "Video") {
                    String url = _youtubeUrlController.text.trim();
                    if (url.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please enter a video URL',
                            style: GoogleFonts.poppins(
                              color: textLightColor,
                            ),
                          ),
                          backgroundColor: errorColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      return;
                    }

                    // Validate YouTube URL.
                    String? videoId = extractYoutubeVideoId(url);
                    if (videoId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please enter a valid YouTube video URL',
                            style: GoogleFonts.poppins(
                              color: textLightColor,
                            ),
                          ),
                          backgroundColor: errorColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      return;
                    }

                    await courseProvider.addVideoToSection(
                      widget.courseId,
                      sectionTitle,
                      Video(title: title, videoUrl: url),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Video added successfully!',
                          style: GoogleFonts.poppins(
                            color: textLightColor,
                          ),
                        ),
                        backgroundColor: successColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  } else {
                    // PDF branch: ensure a file is picked.
                    if (_pickedPdfFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please select a PDF file',
                            style: GoogleFonts.poppins(
                              color: textLightColor,
                            ),
                          ),
                          backgroundColor: errorColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      return;
                    }

                    // Upload the picked PDF file.
                    String? pdfUrl = await courseProvider.uploadPdf(_pickedPdfFile!);
                    if (pdfUrl != null) {
                      await courseProvider.addPdfToSection(
                        widget.courseId,
                        sectionTitle,
                        title,
                        pdfUrl,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'PDF added successfully!',
                            style: GoogleFonts.poppins(
                              color: textLightColor,
                            ),
                          ),
                          backgroundColor: successColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to upload PDF',
                            style: GoogleFonts.poppins(
                              color: textLightColor,
                            ),
                          ),
                          backgroundColor: errorColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      return;
                    }
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: textLightColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 2,
                ),
                child: Text(
                  'Add Resource',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResourceTypeOption(
      StateSetter setState,
      String optionValue,
      IconData icon,
      Color color,
      ) {
    final bool isSelected = _resourceType == optionValue;

    return InkWell(
      onTap: () {
        setState(() {
          _resourceType = optionValue;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            SizedBox(width: 10),
            Text(
              optionValue,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : textDarkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditResourceDialog(CourseProvider courseProvider, String sectionTitle, Map<String, dynamic> resource) {
    final isVideo = resource['type'] == 'video';
    _resourceTitleController.text = resource['title'] ?? '';
    _youtubeUrlController.text = isVideo ? resource['url'] ?? '' : '';
    _resourceType = isVideo ? "Video" : "PDF";
    _pickedPdfFile = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isVideo
                      ? secondaryColor.withOpacity(0.1)
                      : accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVideo
                      ? Icons.video_library_outlined
                      : Icons.picture_as_pdf_outlined,
                  size: 40,
                  color: isVideo ? secondaryColor : accentColor,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Edit ${isVideo ? 'Video' : 'PDF'}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _resourceTitleController,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: textDarkColor,
                ),
                decoration: InputDecoration(
                  labelText: isVideo ? 'Video Title' : 'PDF Title',
                  labelStyle: GoogleFonts.poppins(
                    color: isVideo ? secondaryColor : accentColor,
                    fontSize: 14,
                  ),
                  hintText: 'Enter title',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isVideo ? secondaryColor : accentColor,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(
                    isVideo
                        ? Icons.title_outlined
                        : Icons.description_outlined,
                    color: isVideo ? secondaryColor : accentColor,
                    size: 20,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              SizedBox(height: 20),

              if (isVideo)
                TextField(
                  controller: _youtubeUrlController,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: textDarkColor,
                  ),
                  decoration: InputDecoration(
                    labelText: 'YouTube URL',
                    labelStyle: GoogleFonts.poppins(
                      color: secondaryColor,
                      fontSize: 14,
                    ),
                    hintText: 'Enter valid YouTube URL',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: secondaryColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.link, color: secondaryColor, size: 20),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: secondaryColor,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'To change the PDF file, delete this resource and add a new one.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textDarkColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
          TextButton(
          onPressed: () {
    Navigator.pop(context);
    },
      child: Text(
        'Cancel',
        style: GoogleFonts.poppins(
          color: textDarkColor.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    ElevatedButton(
    onPressed: () async {
    String title = _resourceTitleController.text.trim();
    if (title.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content: Text(
    'Please enter a resource title',
    style: GoogleFonts.poppins(
    color: textLightColor,
    ),
    ),
    backgroundColor: errorColor,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    );
    return;
    }

    if (isVideo) {
    String url = _youtubeUrlController.text.trim();
    if (url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content: Text(
    'Please enter a video URL',
    style: GoogleFonts.poppins(
    color: textLightColor,
    ),
    ),
    backgroundColor: errorColor,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    );
    return;
    }

    // Validate YouTube URL.
    String? videoId = extractYoutubeVideoId(url);
    if (videoId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content: Text(
    'Please enter a valid YouTube video URL',
    style: GoogleFonts.poppins(
    color: textLightColor,
    ),
    ),
    backgroundColor: errorColor,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    );
    return;
    }

    await courseProvider.updateVideo(
    widget.courseId,
    sectionTitle,
    resource['index'],
    Video(title: title, videoUrl: url),
    );

    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content: Text(
    'Video updated successfully!',
    style: GoogleFonts.poppins(
    color: textLightColor,
    ),
    ),
    backgroundColor: successColor,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    );
    } else {
    // For PDF, we only update the title
    await courseProvider.updatePdfTitle(
    widget.courseId,
    sectionTitle,
    resource['index'],
    title,
    );

    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content: Text(
    'PDF updated successfully!',
    style: GoogleFonts.poppins(
    color: textLightColor,
    ),
    ),
    backgroundColor: successColor,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    );
    }

    Navigator.pop(context);
    },
    style: ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: textLightColor,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    ),
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 2,
    ),
      child: Text(
        'Update Resource',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
          ],
      ),
    );
  }

  void _showDeleteResourceDialog(CourseProvider courseProvider, String sectionTitle, Map<String, dynamic> resource) {
    final isVideo = resource['type'] == 'video';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 40,
                color: errorColor,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Delete ${isVideo ? 'Video' : 'PDF'}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: errorColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${resource['title']}"? This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: textDarkColor,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: textDarkColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (isVideo) {
                await courseProvider.deleteVideo(
                  widget.courseId,
                  sectionTitle,
                  resource['index'],
                );
              } else {
                await courseProvider.deletePdfFromSection(
                  widget.courseId,
                  sectionTitle,
                  resource['index'],
                );
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${isVideo ? 'Video' : 'PDF'} deleted successfully!',
                    style: GoogleFonts.poppins(
                      color: textLightColor,
                    ),
                  ),
                  backgroundColor: successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: textLightColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 2,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _playVideo(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) return;

    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid YouTube URL',
            style: GoogleFonts.poppins(
              color: textLightColor,
            ),
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedVideoPlayerScreen(
          videoId: videoId,
          title: "Video Player",
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          accentColor: accentColor,
          errorColor: errorColor,
          textLightColor: textLightColor,
          textDarkColor: textDarkColor,
        ),
      ),
    );
  }

  void _viewPdf(String? title, String? pdfUrl) {
    if (pdfUrl == null || pdfUrl.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedPdfViewerScreen(
          pdfUrl: pdfUrl,
          title: title ?? 'PDF Document',
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          accentColor: accentColor,
          errorColor: errorColor,
          textLightColor: textLightColor,
          textDarkColor: textDarkColor,
        ),
      ),
    );
  }

  // Utility widgets

  Widget _buildLoadingCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: secondaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: errorColor,
                ),
              ),
              SizedBox(height: 20),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: errorColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadCourseData,
                icon: Icon(Icons.refresh),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: textLightColor,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced Video Player Screen
class EnhancedVideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color errorColor;
  final Color textLightColor;
  final Color textDarkColor;

  const EnhancedVideoPlayerScreen({
    Key? key,
    required this.videoId,
    required this.title,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.errorColor,
    required this.textLightColor,
    required this.textDarkColor,
  }) : super(key: key);

  @override
  _EnhancedVideoPlayerScreenState createState() => _EnhancedVideoPlayerScreenState();
}

class _EnhancedVideoPlayerScreenState extends State<EnhancedVideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullScreen
          ? null
          : AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: widget.textLightColor,
          ),
        ),
        backgroundColor: widget.primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: widget.textLightColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.fullscreen, color: widget.textLightColor),
            onPressed: () {
              setState(() {
                _isFullScreen = true;
              });
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]);
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video player with improved controls
            Expanded(
              child: Center(
                child: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: widget.secondaryColor,
                  progressColors: ProgressBarColors(
                    playedColor: widget.secondaryColor,
                    handleColor: widget.accentColor,
                  ),
                  onEnded: (data) {
                    _controller.seekTo(Duration.zero);
                    _controller.pause();
                  },
                  topActions: [
                    if (_isFullScreen)
                      IconButton(
                        icon: Icon(
                          Icons.fullscreen_exit,
                          color: widget.textLightColor,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _isFullScreen = false;
                          });
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.portraitUp,
                          ]);
                          SystemChrome.setEnabledSystemUIMode(
                            SystemUiMode.manual,
                            overlays: SystemUiOverlay.values,
                          );
                        },
                      ),
                  ],
                  bottomActions: [
                    CurrentPosition(),
                    ProgressBar(
                      isExpanded: true,
                      colors: ProgressBarColors(
                        playedColor: widget.secondaryColor,
                        handleColor: widget.accentColor,
                        bufferedColor: widget.secondaryColor.withOpacity(0.4),
                        backgroundColor: Colors.grey.withOpacity(0.5),
                      ),
                    ),
                    RemainingDuration(),
                    PlaybackSpeedButton(),
                  ],
                ),
              ),
            ),

            // Video controls and info
            if (!_isFullScreen)
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildControlButton(
                          icon: Icons.replay_10,
                          label: '10s',
                          onPressed: () {
                            final position = _controller.value.position;
                            final newPosition = position - Duration(seconds: 10);
                            _controller.seekTo(newPosition);
                          },
                        ),
                        _buildControlButton(
                          icon: _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          label: _controller.value.isPlaying ? 'Pause' : 'Play',
                          onPressed: () {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                            setState(() {});
                          },
                          isAccent: true,
                        ),
                        _buildControlButton(
                          icon: Icons.forward_10,
                          label: '10s',
                          onPressed: () {
                            final position = _controller.value.position;
                            final newPosition = position + Duration(seconds: 10);
                            _controller.seekTo(newPosition);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    // Additional controls row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSmallControlButton(
                          icon: Icons.volume_up,
                          onPressed: () {
                            // Show volume control
                          },
                        ),
                        _buildSmallControlButton(
                          icon: Icons.speed,
                          onPressed: () {
                            _showPlaybackSpeedDialog();
                          },
                        ),
                        _buildSmallControlButton(
                          icon: Icons.fullscreen,
                          onPressed: () {
                            setState(() {
                              _isFullScreen = true;
                            });
                            SystemChrome.setPreferredOrientations([
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ]);
                            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                          },
                        ),
                        _buildSmallControlButton(
                          icon: Icons.closed_caption,
                          onPressed: () {
                            // Toggle captions
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isAccent = false,
  }) {
    final Color buttonColor = isAccent ? widget.accentColor : widget.secondaryColor;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: buttonColor.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: buttonColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: buttonColor,
              size: isAccent ? 32 : 24,
            ),
            iconSize: isAccent ? 32 : 24,
            padding: EdgeInsets.all(isAccent ? 16 : 12),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: widget.textLightColor.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: widget.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.secondaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: widget.secondaryColor,
          size: 20,
        ),
        padding: EdgeInsets.all(8),
        constraints: BoxConstraints.tightFor(
          width: 40,
          height: 40,
        ),
      ),
    );
  }

  void _showPlaybackSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Playback Speed',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: widget.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSpeedOption(0.5),
            _buildSpeedOption(0.75),
            _buildSpeedOption(1.0, isSelected: true),
            _buildSpeedOption(1.25),
            _buildSpeedOption(1.5),
            _buildSpeedOption(2.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedOption(double speed, {bool isSelected = false}) {
    return InkWell(
      onTap: () {
        _controller.setPlaybackRate(speed);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? widget.secondaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: widget.secondaryColor, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${speed}x',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? widget.secondaryColor : widget.textDarkColor,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: widget.secondaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// Enhanced PDF Viewer Screen
class EnhancedPdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color errorColor;
  final Color textLightColor;
  final Color textDarkColor;

  const EnhancedPdfViewerScreen({
    Key? key,
    required this.pdfUrl,
    required this.title,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.errorColor,
    required this.textLightColor,
    required this.textDarkColor,
  }) : super(key: key);

  @override
  _EnhancedPdfViewerScreenState createState() => _EnhancedPdfViewerScreenState();
}

class _EnhancedPdfViewerScreenState extends State<EnhancedPdfViewerScreen> {
  bool _isFullScreen = false;
  bool _isLoading = true;
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfController;
  late PDF _pdf;

  @override
  void initState() {
    super.initState();
    _pdf = PDF(
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      nightMode: false,
      onPageChanged: (int? page, int? total) {
        if (page != null && total != null) {
          setState(() {
            _currentPage = page;
            _totalPages = total;
          });
        }
      },
      onViewCreated: (PDFViewController controller) {
        setState(() {
          _pdfController = controller;
          _isLoading = false;
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading PDF: $error',
              style: GoogleFonts.poppins(
                color: widget.textLightColor,
              ),
            ),
            backgroundColor: widget.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _isFullScreen
          ? null
          : AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: widget.textLightColor,
          ),
        ),
        backgroundColor: widget.primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: widget.textLightColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.fullscreen, color: widget.textLightColor),
            onPressed: () {
              setState(() {
                _isFullScreen = true;
              });
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]);
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // PDF Viewer
          Expanded(
            child: Stack(
              children: [
                // PDF View
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _pdf.fromUrl(
                    widget.pdfUrl,
                    placeholder: (progress) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress / 100,
                            color: widget.secondaryColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading PDF: ${progress.toInt()}%',
                            style: GoogleFonts.poppins(
                              color: widget.secondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    errorWidget: (error) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: widget.errorColor,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error loading PDF',
                            style: GoogleFonts.poppins(
                              color: widget.errorColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: GoogleFonts.poppins(
                              color: widget.textDarkColor.withOpacity(0.7),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fullscreen exit button
                if (_isFullScreen)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.fullscreen_exit,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isFullScreen = false;
                          });
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.portraitUp,
                          ]);
                          SystemChrome.setEnabledSystemUIMode(
                            SystemUiMode.manual,
                            overlays: SystemUiOverlay.values,
                          );
                        },
                      ),
                    ),
                  ),

                // Page indicator
                if (!_isLoading && _totalPages > 0)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Page ${_currentPage + 1} of $_totalPages',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // PDF Controls
          if (!_isFullScreen && !_isLoading)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Page slider
                  if (_totalPages > 1)
                    Slider(
                      value: _currentPage.toDouble(),
                      min: 0,
                      max: (_totalPages - 1).toDouble(),
                      divisions: _totalPages - 1,
                      activeColor: widget.secondaryColor,
                      inactiveColor: widget.secondaryColor.withOpacity(0.3),
                      label: 'Page ${_currentPage + 1}',
                      onChanged: (value) {
                        final page = value.toInt();
                        if (_pdfController != null) {
                          _pdfController!.setPage(page);
                        }
                        // The state will be updated via the onPageChanged callback
                      },
                    ),

                  SizedBox(height: 8),

                  // Controls row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPdfControlButton(
                        icon: Icons.first_page,
                        label: 'First',
                        onPressed: () {
                          if (_pdfController != null) {
                            _pdfController!.setPage(0);
                          }
                        },
                      ),
                      _buildPdfControlButton(
                        icon: Icons.navigate_before,
                        label: 'Previous',
                        onPressed: () {
                          if (_currentPage > 0 && _pdfController != null) {
                            _pdfController!.setPage(_currentPage - 1);
                          }
                        },
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.secondaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${_currentPage + 1} / $_totalPages',
                          style: GoogleFonts.poppins(
                            color: widget.secondaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _buildPdfControlButton(
                        icon: Icons.navigate_next,
                        label: 'Next',
                        onPressed: () {
                          if (_currentPage < _totalPages - 1 && _pdfController != null) {
                            _pdfController!.setPage(_currentPage + 1);
                          }
                        },
                      ),
                      _buildPdfControlButton(
                        icon: Icons.last_page,
                        label: 'Last',
                        onPressed: () {
                          if (_pdfController != null && _totalPages > 0) {
                            _pdfController!.setPage(_totalPages - 1);
                          }
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Additional controls row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPdfSmallControlButton(
                        icon: Icons.zoom_in,
                        onPressed: () {
                          // Zoom functionality is handled by pinch gestures in the viewer
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Use pinch gesture to zoom in/out',
                                style: GoogleFonts.poppins(color: widget.textLightColor),
                              ),
                              backgroundColor: widget.primaryColor,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                      ),
                      _buildPdfSmallControlButton(
                        icon: Icons.zoom_out,
                        onPressed: () {
                          // Zoom functionality is handled by pinch gestures in the viewer
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Use pinch gesture to zoom in/out',
                                style: GoogleFonts.poppins(color: widget.textLightColor),
                              ),
                              backgroundColor: widget.primaryColor,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                      ),
                      _buildPdfSmallControlButton(
                        icon: Icons.fullscreen,
                        onPressed: () {
                          setState(() {
                            _isFullScreen = true;
                          });
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.landscapeRight,
                          ]);
                          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                        },
                      ),
                      _buildPdfSmallControlButton(
                        icon: Icons.share,
                        onPressed: () {
                          // Share PDF
                        },
                      ),
                      _buildPdfSmallControlButton(
                        icon: Icons.dark_mode,
                        onPressed: () {
                          // Toggle night mode
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildPdfControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.secondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: widget.secondaryColor,
              size: 20,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: widget.textDarkColor.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfSmallControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: widget.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.secondaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: widget.secondaryColor,
          size: 20,
        ),
        padding: EdgeInsets.all(8),
        constraints: BoxConstraints.tightFor(
          width: 40,
          height: 40,
        ),
      ),
    );
  }
}

