import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart';

class ManageSectionsScreen extends StatelessWidget {
  final String courseId;
  ManageSectionsScreen({required this.courseId});

  // Controller used only for adding new sections.
  final TextEditingController _sectionTitleController = TextEditingController();

  // Custom color palette
  final Color greenColor = const Color(0xFF11261f); // Dark green - primary
  final Color yellowColor = const Color(0xFF123755); // Navy blue - secondary
  final Color maroonColor = const Color(0xFF722626); // Maroon - error
  final Color accentColor = const Color(0xFFe9c46a); // Gold accent
  final Color surfaceColor = const Color(0xFFF7F7F2); // Light cream background
  final Color textDarkColor = const Color(0xFF1F2937); // Dark text
  final Color textLightColor = const Color(0xFFF9FAFB); // Light text
  String resourceType = "Video";
  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: Text(
          'Manage Sections',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textLightColor,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: greenColor,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2.0),
          child: Container(
            color: accentColor,
            height: 2.0,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: textLightColor),
            onPressed: () {
              // Refresh the course data
              courseProvider.getCourseById(courseId);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Section Form
            _buildAddSectionForm(context, courseProvider),
            SizedBox(height: 24),

            // Section List Header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'COURSE SECTIONS',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                    color: greenColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // List of Sections and Resources
            Expanded(
              child: FutureBuilder<Course?>(
                future: courseProvider.getCourseById(courseId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: accentColor,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading sections',
                        style: GoogleFonts.poppins(
                          color: maroonColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData ||
                      snapshot.data!.sections.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 48,
                            color: yellowColor.withOpacity(0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No sections found',
                            style: GoogleFonts.poppins(
                              color: yellowColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create a section to get started',
                            style: GoogleFonts.poppins(
                              color: textDarkColor.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final course = snapshot.data!;
                    return ListView.builder(
                      itemCount: course.sections.length,
                      itemBuilder: (context, sectionIndex) {
                        final section = course.sections[sectionIndex];
                        return _buildSectionCard(context, courseProvider, course, section, sectionIndex);
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the add section form card
  Widget _buildAddSectionForm(BuildContext context, CourseProvider courseProvider) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: greenColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: yellowColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Add New Section',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: greenColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Divider(color: accentColor.withOpacity(0.3)),
              SizedBox(height: 12),
              TextFormField(
                controller: _sectionTitleController,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textDarkColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Section Title',
                  labelStyle: GoogleFonts.poppins(
                    color: yellowColor,
                    fontSize: 14,
                  ),
                  hintText: 'Enter section title',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: accentColor, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: maroonColor),
                  ),
                  prefixIcon: Icon(Icons.title_outlined, color: yellowColor, size: 20),
                  filled: true,
                  fillColor: surfaceColor,
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_sectionTitleController.text.isNotEmpty) {
                      await courseProvider.addSection(
                          courseId, _sectionTitleController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Section added successfully!',
                            style: GoogleFonts.poppins(
                              color: textLightColor,
                            ),
                          ),
                          backgroundColor: greenColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      _sectionTitleController.clear();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please enter a section title',
                            style: GoogleFonts.poppins(
                              color: textLightColor,
                            ),
                          ),
                          backgroundColor: maroonColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenColor,
                    foregroundColor: textLightColor,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'ADD SECTION',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build section card with expansion tile
  Widget _buildSectionCard(BuildContext context, CourseProvider courseProvider, Course course, Section section, int sectionIndex) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      margin: EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: greenColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            colorScheme: ColorScheme.light(
              primary: yellowColor,
            ),
          ),
          child: ExpansionTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_outlined,
                color: yellowColor,
                size: 20,
              ),
            ),
            title: Text(
              section.sectionTitle ?? "Untitled Section",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: greenColor,
              ),
            ),
            subtitle: Text(
              '${section.videos.length} videos, ${section.pdfs.length} PDFs',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: textDarkColor.withOpacity(0.6),
              ),
            ),
            collapsedIconColor: yellowColor,
            iconColor: accentColor,
            childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Divider(color: accentColor.withOpacity(0.3)),

              // Button to add a resource
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: OutlinedButton.icon(
                  onPressed: () => _showAddResourceDialog(
                      context, courseId, section.sectionTitle ?? ''),
                  icon: Icon(Icons.add, size: 18),
                  label: Text(
                    'Add Resource',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: yellowColor,
                    side: BorderSide(color: yellowColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),

              // Resource headers if resources exist
              if (section.videos.isNotEmpty || section.pdfs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RESOURCES',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                          color: greenColor,
                        ),
                      ),
                    ],
                  ),
                ),

              // List of Videos
              if (section.videos.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: section.videos.length,
                  itemBuilder: (context, videoIndex) {
                    final video = section.videos[videoIndex];
                    return _buildResourceTile(
                      context,
                      courseProvider,
                      courseId,
                      section.sectionTitle!,
                      video.title ?? "Untitled Video",
                      true,
                      videoIndex,
                      video.videoUrl,
                    );
                  },
                )
              else if (section.pdfs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'No resources available in this section',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: textDarkColor.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // List of PDFs
              if (section.pdfs.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: section.pdfs.length,
                  itemBuilder: (context, pdfIndex) {
                    final pdf = section.pdfs[pdfIndex];
                    return _buildResourceTile(
                      context,
                      courseProvider,
                      courseId,
                      section.sectionTitle!,
                      pdf.title ?? "Untitled PDF",
                      false,
                      pdfIndex,
                      pdf.pdfUrl,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Build resource tile (video or PDF)
  Widget _buildResourceTile(
      BuildContext context,
      CourseProvider courseProvider,
      String courseId,
      String sectionTitle,
      String title,
      bool isVideo,
      int index,
      String? url,
      ) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isVideo
                ? yellowColor.withOpacity(0.1)
                : maroonColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isVideo ? Icons.video_library_outlined : Icons.picture_as_pdf_outlined,
            color: isVideo ? yellowColor : maroonColor,
            size: 18,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textDarkColor,
          ),
        ),
        subtitle: Text(
          isVideo ? 'Video' : 'PDF Document',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: textDarkColor.withOpacity(0.6),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.visibility_outlined,
                color: yellowColor,
                size: 18,
              ),
              onPressed: () {
                if (isVideo) {
                  String? videoId = YoutubePlayer.convertUrlToId(url ?? '');
                  if (videoId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(
                          videoId: videoId,
                          greenColor: greenColor,
                          yellowColor: yellowColor,
                          accentColor: accentColor,
                          textLightColor: textLightColor,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Invalid YouTube URL',
                          style: GoogleFonts.poppins(
                            color: textLightColor,
                          ),
                        ),
                        backgroundColor: maroonColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  // Navigate to PDF preview
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfPreviewScreen(
                        pdfUrl: url ?? '',
                        title: title,
                        greenColor: greenColor,
                        yellowColor: yellowColor,
                        accentColor: accentColor,
                        textLightColor: textLightColor,
                      ),
                    ),
                  );
                }
              },
              tooltip: 'View',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: maroonColor,
                size: 18,
              ),
              onPressed: () async {
                // Show delete confirmation
                bool confirm = await _showDeleteConfirmation(context);
                if (confirm) {
                  if (isVideo) {
                    await courseProvider.deleteVideo(
                      courseId,
                      sectionTitle,
                      index,
                    );
                  } else {
                    await courseProvider.deletePdfFromSection(
                      courseId,
                      sectionTitle,
                      index,
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isVideo
                            ? 'Video deleted successfully!'
                            : 'PDF deleted successfully!',
                        style: GoogleFonts.poppins(
                          color: textLightColor,
                        ),
                      ),
                      backgroundColor: greenColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              tooltip: 'Delete',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        onTap: () {
          if (isVideo) {
            String? videoId = YoutubePlayer.convertUrlToId(url ?? '');
            if (videoId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(
                    videoId: videoId,
                    greenColor: greenColor,
                    yellowColor: yellowColor,
                    accentColor: accentColor,
                    textLightColor: textLightColor,
                  ),
                ),
              );
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfPreviewScreen(
                  pdfUrl: url ?? '',
                  title: title,
                  greenColor: greenColor,
                  yellowColor: yellowColor,
                  accentColor: accentColor,
                  textLightColor: textLightColor,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // Delete confirmation dialog
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: maroonColor,
              size: 40,
            ),
            SizedBox(height: 16),
            Text(
              'Confirm Deletion',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: greenColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this resource? This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: textDarkColor,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: yellowColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: maroonColor,
              foregroundColor: textLightColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'DELETE',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Displays a dialog to add a resource (Video or PDF) to a section.
  void _showAddResourceDialog(
      BuildContext context, String courseId, String sectionTitle) {
    // Local controllers for the resource title.
    final TextEditingController resourceTitleController = TextEditingController();
    // For Video, we use a text field; for PDF, we'll allow picking a file.
    final TextEditingController resourceUrlController = TextEditingController();

    // Default resource type is Video.

    // For PDF, we store the picked file.
    PlatformFile? pickedPdfFile;

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
        builder: (context, setState) {
      return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Column(
            children: [
              Icon(
                resourceType == "Video"
                    ? Icons.video_library_outlined
                    : Icons.picture_as_pdf_outlined,
                color: resourceType == "Video" ? yellowColor : maroonColor,
                size: 40,
              ),
              SizedBox(height: 16),
              Text(
                'Add Resource',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: greenColor,
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
            // Resource type selection
            Container(
            decoration: BoxDecoration(
            color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Video option
                _buildResourceTypeOption(
                  setState,
                  resourceType,
                  "Video",
                  Icons.video_library_outlined,
                  yellowColor,
                ),

                Container(
                  height: 30,
                  width: 1,
                  color: accentColor.withOpacity(0.3),
                ),

                // PDF option
                _buildResourceTypeOption(
                  setState,
                  resourceType,
                  "PDF",
                  Icons.picture_as_pdf_outlined,
                  maroonColor,
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Resource title field
          TextFormField(
            controller: resourceTitleController,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textDarkColor,
            ),
            decoration: InputDecoration(
              labelText: resourceType == "Video" ? 'Video Title' : 'PDF Title',
              labelStyle: GoogleFonts.poppins(
                color: resourceType == "Video" ? yellowColor : maroonColor,
                fontSize: 14,
              ),
              hintText: 'Enter ${resourceType.toLowerCase()} title',
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: resourceType == "Video" ? yellowColor : maroonColor,
                  width: 1.5,
                ),
              ),
              prefixIcon: Icon(
                resourceType == "Video"
                    ? Icons.title_outlined
                    : Icons.description_outlined,
                color: resourceType == "Video" ? yellowColor : maroonColor,
                size: 20,
              ),
              filled: true,
              fillColor: surfaceColor,
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          SizedBox(height: 16),

          // Resource specific input (URL for Video, file for PDF)
          if (resourceType == "Video")
      TextFormField(
          controller: resourceUrlController,
          style: GoogleFonts.poppins(
          fontSize: 14,
          color: textDarkColor,
      ),
    decoration: InputDecoration(
    labelText: 'YouTube URL',
    labelStyle: GoogleFonts.poppins(
    color: yellowColor,
    fontSize: 14,
    ),
    hintText: 'Enter valid YouTube URL',
    hintStyle: GoogleFonts.poppins(
    color: Colors.grey.shade400,
    fontSize: 14,
    ),
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Colors.grey.shade300),
    ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: yellowColor, width: 1.5),
      ),
      prefixIcon: Icon(Icons.link, color: yellowColor, size: 20),
      filled: true,
      fillColor: surfaceColor,
      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    ),
      )
          else
            Column(
              children: [
                // PDF file picker button
                ElevatedButton.icon(
                  onPressed: () async {
                    // Pick a PDF file using file_picker.
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                    );
                    if (result != null && result.files.isNotEmpty) {
                      setState(() {
                        pickedPdfFile = result.files.first;
                      });
                    }
                  },
                  icon: Icon(Icons.upload_file_outlined, size: 18),
                  label: Text(
                    'Select PDF File',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroonColor,
                    foregroundColor: textLightColor,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Show selected file name
                if (pickedPdfFile != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: maroonColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: greenColor,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pickedPdfFile!.name,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
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
              'CANCEL',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: yellowColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              String title = resourceTitleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter a resource title',
                      style: GoogleFonts.poppins(
                        color: textLightColor,
                      ),
                    ),
                    backgroundColor: maroonColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              if (resourceType == "Video") {
                String url = resourceUrlController.text.trim();
                if (url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a video URL',
                        style: GoogleFonts.poppins(
                          color: textLightColor,
                        ),
                      ),
                      backgroundColor: maroonColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                // Validate YouTube URL.
                String? videoId = YoutubePlayer.convertUrlToId(url);
                if (videoId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a valid YouTube video URL',
                        style: GoogleFonts.poppins(
                          color: textLightColor,
                        ),
                      ),
                      backgroundColor: maroonColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                await Provider.of<CourseProvider>(context, listen: false)
                    .addVideoToSection(courseId, sectionTitle, Video(title: title, videoUrl: url));

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Video added successfully!',
                      style: GoogleFonts.poppins(
                        color: textLightColor,
                      ),
                    ),
                    backgroundColor: greenColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                // PDF branch: ensure a file is picked.
                if (pickedPdfFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please select a PDF file',
                        style: GoogleFonts.poppins(
                          color: textLightColor,
                        ),
                      ),
                      backgroundColor: maroonColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                // Upload the picked PDF file.
                File pdfFile = File(pickedPdfFile!.path!);
                String? pdfUrl = await Provider.of<CourseProvider>(context, listen: false).uploadPdf(pdfFile);
                if (pdfUrl != null) {
                  await Provider.of<CourseProvider>(context, listen: false)
                      .addPdfToSection(courseId, sectionTitle, title, pdfUrl);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'PDF added successfully!',
                        style: GoogleFonts.poppins(
                          color: textLightColor,
                        ),
                      ),
                      backgroundColor: greenColor,
                      behavior: SnackBarBehavior.floating,
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
                      backgroundColor: maroonColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: greenColor,
              foregroundColor: textLightColor,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'ADD RESOURCE',
              style: GoogleFonts.poppins(
                fontSize: 14,
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

  // Helper widget for resource type option in the dialog
  Widget _buildResourceTypeOption(
      StateSetter setState,
      String currentValue,
      String optionValue,
      IconData icon,
      Color color,
      ) {
    final bool isSelected = currentValue == optionValue;

    return InkWell(
      onTap: () {
        setState(() {
          resourceType = optionValue;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            SizedBox(width: 8),
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
}

// Video Player Screen to play YouTube videos.
class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final Color greenColor;
  final Color yellowColor;
  final Color accentColor;
  final Color textLightColor;

  VideoPlayerScreen({
    required this.videoId,
    required this.greenColor,
    required this.yellowColor,
    required this.accentColor,
    required this.textLightColor,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
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
      appBar: AppBar(
        title: Text(
          'Video Player',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: widget.textLightColor,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: widget.greenColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: widget.textLightColor),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2.0),
          child: Container(
            color: widget.accentColor,
            height: 2.0,
          ),
        ),
      ),
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: widget.accentColor,
          progressColors: ProgressBarColors(
            playedColor: widget.accentColor,
            handleColor: widget.yellowColor,
          ),
          onReady: () {
            print('YouTube Player is ready.');
          },
        ),
      ),
    );
  }
}

// PDF Preview Screen to display PDF documents within the app.
class PdfPreviewScreen extends StatelessWidget {
  final String pdfUrl;
  final String title;
  final Color greenColor;
  final Color yellowColor;
  final Color accentColor;
  final Color textLightColor;

  const PdfPreviewScreen({
    Key? key,
    required this.pdfUrl,
    required this.title,
    required this.greenColor,
    required this.yellowColor,
    required this.accentColor,
    required this.textLightColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textLightColor,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: greenColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textLightColor),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2.0),
          child: Container(
            color: accentColor,
            height: 2.0,
          ),
        ),
      ),
      body: PDF(
        swipeHorizontal: false,
      ).cachedFromUrl(
        pdfUrl,
        placeholder: (progress) =>
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress / 100,
                    color: accentColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading PDF: $progress %',
                    style: GoogleFonts.poppins(
                      color: yellowColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        errorWidget: (error) =>
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Color(0xFF722626),
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading PDF',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF722626),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: GoogleFonts.poppins(
                      color: Color(0xFF1F2937),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
      ),
    );
  }
}