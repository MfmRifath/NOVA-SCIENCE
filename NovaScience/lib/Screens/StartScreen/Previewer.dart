import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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
  final Completer<PDFViewController> _pdfViewerCompleter = Completer<PDFViewController>();
  PDFViewController? _pdfViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isFullScreen = false;
  bool _isControlsVisible = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  void _showControls() {
    setState(() {
      _isControlsVisible = true;
    });
    _startHideControlsTimer();
  }

  Future<void> _downloadPdf() async {
    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      // Create a temporary file
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/${widget.title.replaceAll(' ', '_')}.pdf';
      final file = File(filePath);

      // Download the file with progress tracking
      final request = http.Request('GET', Uri.parse(widget.pdfUrl));
      final response = await http.Client().send(request);

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final fileStream = file.openWrite();

      await response.stream.forEach((List<int> chunk) {
        receivedBytes += chunk.length;
        fileStream.add(chunk);

        final progress = totalBytes > 0 ? receivedBytes / totalBytes : 0;
        setState(() {
          _downloadProgress = progress.toDouble();
        });
      });

      await fileStream.flush();
      await fileStream.close();

      // Use the simplest sharing method - should work with all share_plus versions
      try {
        await Share.share('Sharing PDF: ${widget.title}\nFile: $filePath');
      } catch (shareError) {
        print("Error sharing: $shareError");
        // If even this fails, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sharing the file. File saved to: $filePath',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      setState(() {
        _isDownloading = false;
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _hasError = true;
        _errorMessage = 'Failed to download PDF: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to download PDF',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
          backgroundColor: widget.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
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
          actions: [
            IconButton(
              icon: Icon(Icons.share_outlined),
              onPressed: _isDownloading ? null : _downloadPdf,
              tooltip: 'Share PDF',
            ),
            IconButton(
              icon: Icon(Icons.fullscreen),
              onPressed: _toggleFullScreen,
              tooltip: 'Full Screen',
            ),
          ],
        ),
        body: GestureDetector(
          onTap: _showControls,
          child: Stack(
            children: [
              // PDF Viewer
              Container(
                color: Colors.grey[900],
                child: PDF(
                  enableSwipe: true,
                  swipeHorizontal: true,
                  autoSpacing: true,
                  pageFling: true,
                  pageSnap: true,
                  fitPolicy: FitPolicy.BOTH,
                  preventLinkNavigation: false,
                  onViewCreated: (PDFViewController controller) {
                    _pdfViewerCompleter.complete(controller);
                    _pdfViewController = controller;
                    setState(() {
                      _isLoading = false;
                    });
                  },
                  onPageChanged: (page, total) {
                    setState(() {
                      _currentPage = page!;
                      _totalPages = total!;
                      _isControlsVisible = true;
                    });
                    _startHideControlsTimer();
                  },
                  onError: (error) {
                    setState(() {
                      _hasError = true;
                      _errorMessage = error.toString();
                      _isLoading = false;
                    });
                  },
                  onPageError: (page, error) {
                    print('Error loading page $page: $error');
                  },
                ).cachedFromUrl(
                  widget.pdfUrl,
                  placeholder: (progress) => _buildLoadingWidget(progress),
                  errorWidget: (error) => _buildErrorWidget(error),
                ),
              ),

              // Controls overlay
              if (_isControlsVisible && !_isLoading && !_hasError)
                _buildControlsOverlay(),

              // Download progress overlay
              if (_isDownloading)
                _buildDownloadOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(double progress) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: progress > 0 ? progress / 100 : null,
              color: widget.secondaryColor,
            ),
            SizedBox(height: 16),
            Text(
              progress > 0 ? 'Loading PDF: ${progress.toInt()}%' : 'Loading PDF...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.primaryColor,
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildErrorWidget(dynamic error) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: widget.errorColor,
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading PDF',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: widget.errorColor,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                error.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: widget.textDarkColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back),
              label: Text(
                'Go Back',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: widget.textLightColor,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black87,
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.first_page, color: Colors.white),
                  onPressed: _pdfViewController != null
                      ? () => _pdfViewController!.setPage(0)
                      : null,
                  tooltip: 'First Page',
                ),
                IconButton(
                  icon: Icon(Icons.navigate_before, color: Colors.white),
                  onPressed: (_pdfViewController != null && _currentPage > 0)
                      ? () => _pdfViewController!.setPage(_currentPage - 1)
                      : null,
                  tooltip: 'Previous Page',
                ),
                IconButton(
                  icon: Icon(Icons.navigate_next, color: Colors.white),
                  onPressed: (_pdfViewController != null && _currentPage < _totalPages - 1)
                      ? () => _pdfViewController!.setPage(_currentPage + 1)
                      : null,
                  tooltip: 'Next Page',
                ),
                IconButton(
                  icon: Icon(Icons.last_page, color: Colors.white),
                  onPressed: _pdfViewController != null
                      ? () => _pdfViewController!.setPage(_totalPages - 1)
                      : null,
                  tooltip: 'Last Page',
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildDownloadOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: _downloadProgress,
                color: widget.secondaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'Downloading PDF...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: widget.primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${(_downloadProgress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: widget.textDarkColor,
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isDownloading = false;
                  });
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: widget.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

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
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isControlsVisible = true;
  bool _showQualityOptions = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: false,
      ),
    )..addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (_controller.value.isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });
    }
    if (_controller.value.playerState == PlayerState.ended) {
      setState(() {
        _isControlsVisible = true;
      });
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _isControlsVisible = false;
        });
      }
    });
  }

  void _showControls() {
    setState(() {
      _isControlsVisible = true;
    });
    _startHideControlsTimer();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    if (_isMuted) {
      _controller.mute();
    } else {
      _controller.unMute();
    }
  }

  void _shareVideo() {
    final youtubeUrl = 'https://www.youtube.com/watch?v=${widget.videoId}';
    Share.share('Check out this video: ${widget.title}\n$youtubeUrl');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        if (_showQualityOptions) {
          setState(() {
            _showQualityOptions = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
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
          actions: [
            IconButton(
              icon: Icon(Icons.share_outlined),
              onPressed: _shareVideo,
              tooltip: 'Share Video',
            ),
            IconButton(
              icon: Icon(Icons.fullscreen),
              onPressed: _toggleFullScreen,
              tooltip: 'Full Screen',
            ),
          ],
        ),
        body: GestureDetector(
          onTap: _showControls,
          child: Stack(
            children: [
              // YouTube Player
              Center(
                child: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: widget.accentColor,
                  progressColors: ProgressBarColors(
                    playedColor: widget.accentColor,
                    handleColor: widget.secondaryColor,
                  ),
                  onReady: () {
                    print('Player is ready.');
                    _startHideControlsTimer();
                  },
                ),
              ),

              // Custom controls overlay
              if (_isControlsVisible)
                _buildControlsOverlay(),

              // Quality options overlay
              if (_showQualityOptions)
                _buildQualityOptionsOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Stack(
        children: [
          // Center play/pause button
          Center(
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                size: 64,
                color: Colors.white,
              ),
              onPressed: () {
                if (_isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
                setState(() {
                  _isPlaying = !_isPlaying;
                });
                _startHideControlsTimer();
              },
            ),
          ),

          // Bottom control bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black87,
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar wrapper (already provided by YoutubePlayer)
                  SizedBox(height: 8),

                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.replay_10,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          final currentPos = _controller.value.position;
                          final newPos = currentPos - Duration(seconds: 10);
                          _controller.seekTo(newPos);
                          _startHideControlsTimer();
                        },
                        tooltip: 'Rewind 10s',
                      ),
                      IconButton(
                        icon: Icon(
                          _isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                        ),
                        onPressed: _toggleMute,
                        tooltip: _isMuted ? 'Unmute' : 'Mute',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _showQualityOptions = true;
                          });
                        },
                        tooltip: 'Settings',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.forward_10,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          final currentPos = _controller.value.position;
                          final newPos = currentPos + Duration(seconds: 10);
                          _controller.seekTo(newPos);
                          _startHideControlsTimer();
                        },
                        tooltip: 'Forward 10s',
                      ),
                      IconButton(
                        icon: Icon(
                          _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white,
                        ),
                        onPressed: _toggleFullScreen,
                        tooltip: _isFullScreen ? 'Exit Full Screen' : 'Full Screen',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildQualityOptionsOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          width: 250,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Video Quality',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
              SizedBox(height: 16),
              _buildQualityOption('Auto', true),
              _buildQualityOption('720p', false),
              _buildQualityOption('480p', false),
              _buildQualityOption('360p', false),
              _buildQualityOption('240p', false),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showQualityOptions = false;
                  });
                  _startHideControlsTimer();
                },
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    color: widget.errorColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildQualityOption(String quality, bool isSelected) {
    return InkWell(
      onTap: () {
        // In reality, we would set the quality here using the YouTube API
        // For now, we'll just close the dialog
        setState(() {
          _showQualityOptions = false;
        });
        _startHideControlsTimer();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? widget.secondaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              quality,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? widget.secondaryColor : widget.textDarkColor,
              ),
            ),
            Spacer(),
            if (isSelected)
              Icon(
                Icons.check,
                size: 18,
                color: widget.secondaryColor,
              ),
          ],
        ),
      ),
    );
  }
}