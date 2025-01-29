// widgets/advertisement_carousel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Modals/Advertisment.dart';

class AdvertisementCarousel extends StatefulWidget {
  final List<Advertisement> advertisements;

  AdvertisementCarousel({required this.advertisements});

  @override
  _AdvertisementCarouselState createState() => _AdvertisementCarouselState();
}

class _AdvertisementCarouselState extends State<AdvertisementCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  bool _isVideoPlaying = false; // Track if a video is playing

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlideTimer();
  }

  void _startAutoSlideTimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (Timer timer) {
      if (!_isVideoPlaying) { // Only auto-slide if no video is playing
        if (_currentPage < widget.advertisements.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onTapAdvertisement(Advertisement ad) async {
    if (ad.link.isNotEmpty) {
      final uri = Uri.parse(ad.link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  // Callback to update the playing state
  void _updateVideoPlayingState(bool isPlaying) {
    setState(() {
      _isVideoPlaying = isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250, // Adjust height as needed
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.advertisements.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
            _isVideoPlaying = false; // Reset when changing pages
          });
        },
        itemBuilder: (context, index) {
          final ad = widget.advertisements[index];
          return GestureDetector(
            onTap: () => _onTapAdvertisement(ad),
            child: Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: ad.type == AdvertisementType.image
                    ? Image.network(
                  ad.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(child: Text('Failed to load image', style: TextStyle(color: Colors.red)));
                  },
                )
                    : YouTubeVideoPlayer(
                  videoId: ad.videoUrl,
                  onPlayStateChanged: _updateVideoPlayingState, // Pass the callback
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class YouTubeVideoPlayer extends StatefulWidget {
  final String videoId;
  final Function(bool isPlaying)? onPlayStateChanged; // Callback to notify playback state

  YouTubeVideoPlayer({required this.videoId, this.onPlayStateChanged});

  @override
  _YouTubeVideoPlayerState createState() => _YouTubeVideoPlayerState();
}

class _YouTubeVideoPlayerState extends State<YouTubeVideoPlayer> {
  late YoutubePlayerController _controller;
  bool _isPlaying = false; // Internal state to track playback

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoId) ?? widget.videoId;
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        loop: false,
      ),
    )..addListener(_videoListener);
  }

  void _videoListener() {
    if (_controller.value.isPlaying != _isPlaying) {
      _isPlaying = _controller.value.isPlaying;
      if (widget.onPlayStateChanged != null) {
        widget.onPlayStateChanged!(_isPlaying);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Colors.blueAccent,
      onReady: () {
        // You can perform additional actions here if needed
      },
    );
  }
}