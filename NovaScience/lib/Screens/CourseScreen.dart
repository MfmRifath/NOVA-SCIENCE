import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../Modals/CourseAndSectionAndVideos.dart';
import '../Service/CourseProvider.dart';

class CourseScreen extends StatefulWidget {
  final int courseIndex;
  final String courseId; // Changed to follow naming convention

  CourseScreen({required this.courseIndex, required this.courseId}); // Accept courseIndex as a parameter

  @override
  _CourseScreenState createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> with TickerProviderStateMixin {
  late YoutubePlayerController _youtubeController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initializeYoutubePlayer();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _initializeYoutubePlayer() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    var firstVideoUrl = courseProvider.courses[widget.courseIndex].sections!.first.videos.first.videoUrl;
    String? videoId = YoutubePlayer.convertUrlToId(firstVideoUrl);

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
    _youtubeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _playVideo(String videoUrl) {
    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId != null) {
      _youtubeController.load(videoId);
    } else {
      print("Invalid video URL");
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final course = courseProvider.courses[widget.courseIndex]; // Access the specific course

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _youtubeController,
        showVideoProgressIndicator: true,
        onReady: () => print("Player is ready"),
        onEnded: (metaData) => print("Video has ended"),
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text(course.courseTitle!),
            backgroundColor: Colors.blueAccent,
            actions: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => _showEditCourseDialog(context, course),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  courseProvider.deleteCourse(course.id);
                  Navigator.pop(context);
                },
              ),
              IconButton(
                icon: Icon(Icons.add),
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
                      child: player,
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
                  SizedBox(
                    height: 500,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverview(course), // Overview Tab
                        _buildSectionsList(courseProvider), // Lessons Tab
                      ],
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

  // Overview Tab Content
  Widget _buildOverview(Course course) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Course Overview',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'By ${course.instructor ?? "Instructor Name"}',
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            course.description!,
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Text(
                  '\$${course.price}',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${course.duration ?? "Duration"}',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    // Handle 'Get Enroll' button press
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Lessons Tab Content with Sections and Videos
  Widget _buildSectionsList(CourseProvider courseProvider) {
    final course = courseProvider.courses[widget.courseIndex]; // Access the specific course
    return ListView.builder(
      itemCount: course.sections!.length,
      itemBuilder: (context, sectionIndex) {
        var section = course.sections![sectionIndex];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ExpansionTile(
            title: Text(
              section.sectionTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            children: [
              ...section.videos.asMap().entries.map((entry) {
                int videoIndex = entry.key; // Get the index of the video
                var video = entry.value; // Get the video object
                return ListTile(
                  leading: Icon(Icons.play_circle_fill, color: Colors.blueAccent),
                  title: Text(video.title),
                  onTap: () {
                    _playVideo(video.videoUrl);
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Delete the video using the videoIndex
                      courseProvider.deleteVideo(widget.courseIndex, sectionIndex, videoIndex);
                    },
                  ),
                );
              }).toList(),
              TextButton(
                onPressed: () {
                  _showAddVideoDialog(context, sectionIndex);
                },
                child: Text('Add Video'),
              ),
              TextButton(
                onPressed: () {
                  _showEditSectionDialog(context, sectionIndex);
                },
                child: Text('Edit Section'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show dialog to edit course
  void _showEditCourseDialog(BuildContext context, Course course) {
    final titleController = TextEditingController(text: course.courseTitle);
    final descriptionController = TextEditingController(text: course.description);
    final priceController = TextEditingController(text: course.price.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Course'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Course Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Provider.of<CourseProvider>(context, listen: false).editCourse(
                  widget.courseId,
                  titleController.text,
                  descriptionController.text,
                  priceController.text as double,
                );
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to add a section
  void _showAddSectionDialog(BuildContext context) {
    final sectionTitleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Section'),
          content: TextField(
            controller: sectionTitleController,
            decoration: InputDecoration(labelText: 'Section Title'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Provider.of<CourseProvider>(context, listen: false).addSection(
                  widget.courseId,
                  sectionTitleController.text,
                );
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to add a video
  void _showAddVideoDialog(BuildContext context, int sectionIndex) {
    final videoTitleController = TextEditingController();
    final videoUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: videoTitleController,
                decoration: InputDecoration(labelText: 'Video Title'),
              ),
              TextField(
                controller: videoUrlController,
                decoration: InputDecoration(labelText: 'Video URL'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Provider.of<CourseProvider>(context, listen: false).addVideo(
                  widget.courseIndex,
                  sectionIndex,
                  videoTitleController.text,
                  videoUrlController.text,
                );
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Show dialog to edit section
  void _showEditSectionDialog(BuildContext context, int sectionIndex) {
    final sectionTitleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Section'),
          content: TextField(
            controller: sectionTitleController,
            decoration: InputDecoration(labelText: 'Section Title'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Provider.of<CourseProvider>(context, listen: false).editSection(
                  widget.courseIndex,
                  sectionIndex,
                  sectionTitleController.text,
                );
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
