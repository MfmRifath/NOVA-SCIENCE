import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart';

class ManageSectionsScreen extends StatelessWidget {
  final String courseId;
  ManageSectionsScreen({required this.courseId});

  // Controller used only for adding new sections.
  final TextEditingController _sectionTitleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Sections'),
        backgroundColor: Colors.blueAccent,
        elevation: 10,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Refresh the course data
              courseProvider.getCourseById(courseId);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Section Form
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sectionTitleController,
                        decoration: InputDecoration(
                          labelText: 'Section Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        if (_sectionTitleController.text.isNotEmpty) {
                          await courseProvider.addSection(
                              courseId, _sectionTitleController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Section added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _sectionTitleController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please enter a section title'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('Add Section'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // List of Sections and Resources
            Expanded(
              child: FutureBuilder<Course?>(
                future: courseProvider.getCourseById(courseId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.blueAccent,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading sections',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  } else if (!snapshot.hasData ||
                      snapshot.data!.sections.isEmpty) {
                    return Center(
                      child: Text(
                        'No sections found',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  } else {
                    final course = snapshot.data!;
                    return ListView.builder(
                      itemCount: course.sections.length,
                      itemBuilder: (context, sectionIndex) {
                        final section = course.sections[sectionIndex];
                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              section.sectionTitle ?? "Untitled Section",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: [
                              // Button to add a resource (Video or PDF)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ElevatedButton.icon(
                                  onPressed: () => _showAddResourceDialog(
                                      context, courseId, section.sectionTitle ?? ''),
                                  icon: Icon(Icons.add),
                                  label: Text('Add Resource'),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
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
                                    return ListTile(
                                      title: Text(
                                        video.title ?? "Untitled Video",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      leading: Icon(Icons.video_collection,
                                          color: Colors.blueAccent),
                                      onTap: () {
                                        String? videoId = YoutubePlayer.convertUrlToId(video.videoUrl!);
                                        if (videoId != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => VideoPlayerScreen(videoId: videoId),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Invalid YouTube URL'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          await courseProvider.deleteVideo(
                                              courseId,
                                              section.sectionTitle!,
                                              videoIndex);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Video deleted successfully!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                )
                              else
                                ...[ListTile(title: Text('No videos available.'))],
                              // List of PDFs
                              if (section.pdfs.isNotEmpty)
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: section.pdfs.length,
                                  itemBuilder: (context, pdfIndex) {
                                    final pdf = section.pdfs[pdfIndex];
                                    return ListTile(
                                      title: Text(
                                        pdf.title ?? "Untitled PDF",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      leading: Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                                      onTap: () {
                                        // Navigate to PDF preview screen.
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PdfPreviewScreen(
                                              pdfUrl: pdf.pdfUrl!,
                                              title: pdf.title ?? "PDF Preview",
                                            ),
                                          ),
                                        );
                                      },
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          await courseProvider.deletePdfFromSection(
                                              courseId,
                                              section.sectionTitle!,
                                              pdfIndex);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('PDF deleted successfully!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                )
                              else
                                ...[ListTile(title: Text('No PDFs available.'))],
                            ],
                          ),
                        );
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

  /// Displays a dialog to add a resource (Video or PDF) to a section.
  void _showAddResourceDialog(
      BuildContext context, String courseId, String sectionTitle) {
    // Local controllers for the resource title.
    final TextEditingController resourceTitleController = TextEditingController();
    // For Video, we use a text field; for PDF, we'll allow picking a file.
    final TextEditingController resourceUrlController = TextEditingController();

    // Default resource type is Video.
    String resourceType = "Video";
    // For PDF, we store the picked file.
    PlatformFile? pickedPdfFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add Resource to "$sectionTitle"'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Radio buttons to select resource type.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<String>(
                        value: "Video",
                        groupValue: resourceType,
                        onChanged: (value) {
                          setState(() {
                            resourceType = value!;
                          });
                        },
                      ),
                      Text("Video"),
                      SizedBox(width: 20),
                      Radio<String>(
                        value: "PDF",
                        groupValue: resourceType,
                        onChanged: (value) {
                          setState(() {
                            resourceType = value!;
                          });
                        },
                      ),
                      Text("PDF"),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Resource title field (same for both)
                  TextField(
                    controller: resourceTitleController,
                    decoration: InputDecoration(
                      labelText: resourceType == "Video"
                          ? 'Video Title'
                          : 'PDF Title',
                      hintText: 'Enter ${resourceType.toLowerCase()} title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: resourceType == "Video"
                          ? Icon(Icons.video_library)
                          : Icon(Icons.picture_as_pdf),
                    ),
                  ),
                  SizedBox(height: 10),
                  // For Video, show a text field to enter URL.
                  // For PDF, show a button to pick the file.
                  if (resourceType == "Video")
                    TextField(
                      controller: resourceUrlController,
                      decoration: InputDecoration(
                        labelText: 'Video URL',
                        hintText: 'Enter valid YouTube URL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.link),
                      ),
                    )
                  else
                    Column(
                      children: [
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
                          icon: Icon(Icons.folder),
                          label: Text('Pick PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                        ),
                        if (pickedPdfFile != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Selected File: ${pickedPdfFile!.name}',
                              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
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
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  String title = resourceTitleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter a resource title'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (resourceType == "Video") {
                    String url = resourceUrlController.text.trim();
                    if (url.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a video URL'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    // Validate YouTube URL.
                    String? videoId = YoutubePlayer.convertUrlToId(url);
                    if (videoId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a valid YouTube video URL'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    await Provider.of<CourseProvider>(context, listen: false)
                        .addVideoToSection(courseId, sectionTitle, Video(title: title, videoUrl: url));
                  } else {
                    // PDF branch: ensure a file is picked.
                    if (pickedPdfFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please pick a PDF file'),
                          backgroundColor: Colors.red,
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
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to upload PDF'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  }
                  Navigator.pop(context);
                  // Optionally, refresh the course data.
                },
                child: Text('Add Resource'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Video Player Screen to play YouTube videos.
class VideoPlayerScreen extends StatefulWidget {
  final String videoId;

  VideoPlayerScreen({required this.videoId});

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
      appBar: AppBar(
        title: Text('Video Player'),
        backgroundColor: Colors.blueAccent,
        elevation: 10,
      ),
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.blueAccent,
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

  const PdfPreviewScreen({Key? key, required this.pdfUrl, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blueAccent,
      ),
      body: PDF().cachedFromUrl(
        pdfUrl,
        placeholder: (progress) => Center(child: Text('$progress %')),
        errorWidget: (error) => Center(child: Text('Error: $error')),
      ),
    );
  }
}