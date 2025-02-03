import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // Import YouTube player package
import '../../Modals/CourseAndSectionAndVideos.dart';
import '../../Service/CourseProvider.dart';

class ManageSectionsScreen extends StatelessWidget {
  final String courseId;
  ManageSectionsScreen({required this.courseId});

  final TextEditingController _sectionTitleController = TextEditingController();
  final TextEditingController _videoTitleController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();

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
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
            // List of Sections and Videos
            Expanded(
              child: FutureBuilder(
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
                  } else if (!snapshot.hasData || snapshot.data!.sections.isEmpty) {
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
                              // Add Video Form
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _videoTitleController,
                                      decoration: InputDecoration(
                                        labelText: 'Video Title',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        prefixIcon: Icon(Icons.video_library),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    TextFormField(
                                      controller: _videoUrlController,
                                      decoration: InputDecoration(
                                        labelText: 'Video URL',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        prefixIcon: Icon(Icons.link),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (_videoTitleController.text.isNotEmpty &&
                                            _videoUrlController.text.isNotEmpty) {
                                          await courseProvider.addVideoToSection(
                                            courseId,
                                            section.sectionTitle!,
                                            Video(
                                              title: _videoTitleController.text,
                                              videoUrl: _videoUrlController.text,
                                            ),
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Video added successfully!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          _videoTitleController.clear();
                                          _videoUrlController.clear();
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Please fill all fields'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text('Add Video'),
                                    ),
                                  ],
                                ),
                              ),
                              // List of Videos
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
                                    subtitle: Text(
                                      video.videoUrl ?? "No URL",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    leading: Icon(Icons.video_collection,
                                        color: Colors.blueAccent),
                                    onTap: () {
                                      // Extract YouTube video ID from the URL
                                      String? videoId =
                                      YoutubePlayer.convertUrlToId(video.videoUrl!);
                                      if (videoId != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VideoPlayerScreen(videoId: videoId),
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
                                            courseId, section.sectionTitle!, videoIndex);
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
                              ),
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
}

// Video Player Screen
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
          progressColors: ProgressBarColors(
            playedColor: Colors.blue,
            handleColor: Colors.blueAccent,
          ),
          onReady: () {
            print('YouTube Player is ready.');
          },
        ),
      ),
    );
  }
}