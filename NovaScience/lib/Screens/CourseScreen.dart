import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../Modals/CourseAndSectionAndVideos.dart';
import '../Service/CourseProvider.dart';

class CourseScreen extends StatefulWidget {
  final String courseId;

  CourseScreen({required this.courseId});

  @override
  _CourseScreenState createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> with TickerProviderStateMixin {
  YoutubePlayerController? _youtubeController;
  late TabController _tabController;
  Course? _course;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCourseData();
  }

  void _initializeYoutubePlayer(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) return;

    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          isLive: false,
        ),
      );
    } else {
      print("Invalid video URL");
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _playVideo(String videoUrl) {
    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId != null) {
      _youtubeController!.load(videoId);
    } else {
      print("Invalid video URL");
    }
  }

  Future<void> _fetchCourseData() async {
    try {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      _course = await courseProvider.getCourseById(widget.courseId);

      setState(() {
        isLoading = false;
      });

      if (_course != null && _course!.sections.isNotEmpty && _course!.sections.first.videos.isNotEmpty) {
        _initializeYoutubePlayer(_course!.sections.first.videos.first.videoUrl);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load course data: $e'),
        duration: Duration(seconds: 3),
      ));
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addVideoToSection(String courseId, String sectionTitle, String videoTitle, String videoUrl, BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    courseProvider.addVideoToSection(courseId, sectionTitle, Video(title: videoTitle, videoUrl: videoUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!(_youtubeController is YoutubePlayerController)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: Column(
          children: [
            Center(child: Text('Video player not initialized')),
            _buildSectionsList(_course!)
          ],
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        onReady: () => print("Player is ready"),
        onEnded: (metaData) => print("Video has ended"),
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_course!.courseTitle ?? 'Course Details'),
            backgroundColor: Colors.blueAccent,
            actions: [
              IconButton(
                icon: Icon(Icons.edit, semanticLabel: 'Edit Course'),
                onPressed: () => _showEditCourseDialog(context, _course!),
              ),
              IconButton(
                icon: Icon(Icons.delete, semanticLabel: 'Delete Course'),
                onPressed: () {
                  Provider.of<CourseProvider>(context, listen: false).deleteCourse(_course!.id);
                  Navigator.pop(context);
                },
              ),
              IconButton(
                icon: Icon(Icons.add, semanticLabel: 'Add Section'),
                onPressed: () => _showAddSectionDialog(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'videoHero',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: player,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF3F51B5),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: "Overview"),
                      Tab(text: "Lessons"),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Expanded(
                      child: SizedBox(
                        height: 500, // To prevent scroll issues
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverview(_course!),
                            _buildSectionsList(_course!),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverview(Course course) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Course Overview',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Text(
            'By ${course.instructor ?? "Instructor Name"}',
            style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          Text(
            course.description ?? 'No description available.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Text(
                  '\$${course.price}',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 10),
                Text(
                  '${course.duration ?? "Duration not specified"}',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enrollment coming soon!')));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Text(
                    'GET ENROLL',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsList(Course course) {
    if (course.sections.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () => _showAddSectionDialog(context),
          child: Text('Add Sections'),
        ),
      );
    }

    return SizedBox(
      height: 500.0,
      child: ListView.builder(
        itemCount: course.sections.length,
        itemBuilder: (context, index) {
          final section = course.sections[index];
          return _buildSectionCard(section, index);
        },
      ),
    );
  }

  Widget _buildSectionCard(Section section, int sectionIndex) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        title: Text(
          section.sectionTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        children: [
          if (section.videos.isNotEmpty)
            ...section.videos.map((video) => ListTile(
              leading: Icon(Icons.play_circle_outline),
              title: Text(video.title),
              subtitle: Text('Click to play'),
              onTap: () => _playVideo(video.videoUrl),
            )).toList()
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text('No videos available')),
            ),
          TextButton(
            onPressed: () => _showAddVideoDialog(widget.courseId, section.sectionTitle),
            child: Text('Add Video'),
          ),
        ],
      ),
    );
  }

  void _showEditCourseDialog(BuildContext context, Course course) {
    final TextEditingController titleController = TextEditingController(text: course.courseTitle);
    final TextEditingController descriptionController = TextEditingController(text: course.description);
    final TextEditingController priceController = TextEditingController(text: course.price.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Course Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Course Description'),
                  maxLines: 3,
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Course Price'),
                  keyboardType: TextInputType.number,
                ),

              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Validate and save course details
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    priceController.text.isNotEmpty);
                  // Update the course object with new values
                  Provider.of<CourseProvider>(context, listen: false).editCourse(
                    course.id!,
                    titleController.text,
                    descriptionController.text,
                    double.parse(priceController.text),
                  );

                  // Dismiss the dialog
                  Navigator.pop(context);
                }
              ,
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }


  void _showAddSectionDialog(BuildContext context) {
    final _sectionTitleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Section'),
        content: TextField(
          controller: _sectionTitleController,
          decoration: InputDecoration(labelText: 'Section Title', hintText: 'Enter section title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              if (_sectionTitleController.text.isNotEmpty) {
                final courseProvider = Provider.of<CourseProvider>(context, listen: false);
                courseProvider.addSection(widget.courseId,_sectionTitleController.text);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a section title')));
              }
            },
            child: Text('Add Section'),
          ),
        ],
      ),
    );
  }

  void _showAddVideoDialog(String courseId, String sectionTitle) {
    final _videoTitleController = TextEditingController();
    final _videoUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Video to $sectionTitle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _videoTitleController,
              decoration: InputDecoration(labelText: 'Video Title', hintText: 'Enter video title'),
            ),
            TextField(
              controller: _videoUrlController,
              decoration: InputDecoration(labelText: 'Video URL', hintText: 'Enter valid YouTube URL'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              if (_videoTitleController.text.isNotEmpty && _videoUrlController.text.isNotEmpty) {
                _addVideoToSection(courseId, sectionTitle, _videoTitleController.text, _videoUrlController.text, context);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill out all fields')));
              }
            },
            child: Text('Add Video'),
          ),
        ],
      ),
    );
  }
}
