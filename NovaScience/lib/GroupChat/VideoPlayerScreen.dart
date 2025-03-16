import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../Screens/StartScreen/AppTheme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? videoTitle;

  const VideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    this.videoTitle,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = 'Error loading video';
  String _validatedUrl = '';
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _validateAndLoadVideo();
  }

  Future<void> _validateAndLoadVideo() async {
    try {
      // First try to validate and potentially refresh the URL
      _validatedUrl = await _getValidVideoUrl(widget.videoUrl);

      // Test if URL is accessible with a HEAD request
      try {
        final response = await http.head(Uri.parse(_validatedUrl));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Video URL returned status code: ${response.statusCode}');
        }
      } catch (httpError) {
        // Even if HTTP check fails, still try to initialize the player
        // Some video URLs might work even if they don't respond to HEAD requests
        print('HTTP check failed but continuing: $httpError');
      }

      await _initializeVideoPlayer();
    } catch (e) {
      print('Error validating video URL: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Invalid video URL: ${e.toString()}';
      });
    }
  }

  Future<String> _getValidVideoUrl(String url) async {
    // For Firebase Storage URLs, refresh the token
    if (url.contains('firebasestorage.googleapis.com')) {
      try {
        // Extract the path from the URL
        Uri uri = Uri.parse(url);
        String bucket = uri.host.split('.').first;
        String encodedPath = uri.path.split('/o/').last;
        String path = Uri.decodeComponent(encodedPath.split('?').first);

        // Create a reference to the file
        final storageRef = FirebaseStorage.instance.ref().child(path);

        // Get a fresh download URL
        return await storageRef.getDownloadURL();
      } catch (e) {
        print('Error refreshing Firebase URL: $e');
        // If refreshing fails, return the original URL
        return url;
      }
    }
    return url;
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.network(_validatedUrl);

      // Add error listener
      _videoPlayerController.addListener(() {
        final playerValue = _videoPlayerController.value;
        if (playerValue.hasError && mounted) {
          print('Video player error: ${playerValue.errorDescription}');
          setState(() {
            _hasError = true;
            _errorMessage = playerValue.errorDescription ?? 'Unknown video player error';
          });
        }
      });

      // Initialize the controller
      await _videoPlayerController.initialize();

      // If successful, create the Chewie controller
      if (_videoPlayerController.value.isInitialized) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          aspectRatio: _videoPlayerController.value.aspectRatio,
          autoPlay: true,
          looping: false,
          allowedScreenSleep: false,
          allowFullScreen: true,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppTheme.primaryColor,
            handleColor: AppTheme.primaryColor,
            bufferedColor: Colors.grey[300]!,
            backgroundColor: Colors.grey[100]!,
          ),
          placeholder: Container(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          ),
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 42),
                  SizedBox(height: 12),
                  Text(
                    'Error playing video',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    errorMessage,
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
          fullScreenByDefault: false,
        );

        _chewieController!.addListener(() {
          if (_chewieController!.isFullScreen != _isFullScreen) {
            setState(() {
              _isFullScreen = _chewieController!.isFullScreen;
            });
          }
        });
      } else {
        throw Exception('Video player failed to initialize');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing video player: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide app bar in fullscreen mode
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullScreen
          ? null
          : AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.videoTitle ?? 'Video Player',
          style: TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing video...')),
              );
              // Implement share functionality here
            },
          ),
          IconButton(
            icon: Icon(Icons.download_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading video...')),
              );
              // Implement download functionality here
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
              SizedBox(height: 16),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        )
            : _hasError
            ? _buildErrorWidget()
            : Center(
          child: Chewie(
            controller: _chewieController!,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Failed to load video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _hasError = false;
                    });
                    _validateAndLoadVideo();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    launchUrl(
                        Uri.parse(widget.videoUrl),
                        mode: LaunchMode.externalApplication
                    );
                  },
                  icon: Icon(Icons.open_in_new, color: Colors.white),
                  label: Text('Open Externally', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white54),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Go Back'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}