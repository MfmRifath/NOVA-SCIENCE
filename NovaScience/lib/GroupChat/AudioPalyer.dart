import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String audioUrl;
  final String audioTitle;

  const AudioPlayerScreen({
    Key? key,
    required this.audioUrl,
    required this.audioTitle,
  }) : super(key: key);

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _animationController;
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isAudioWaveformVisible = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for waveform
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();

      // Configure audio session
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      // Set up position and duration listeners
      _audioPlayer.positionStream.listen((position) {
        setState(() {
          _position = position;
        });
      });

      _audioPlayer.durationStream.listen((duration) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      });

      _audioPlayer.playerStateStream.listen((playerState) {
        setState(() {
          _isPlaying = playerState.playing;
        });
      });

      // Handle errors
      _audioPlayer.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          // Auto-rewind when playback completes
          _audioPlayer.seek(Duration.zero);
          setState(() {
            _isPlaying = false;
          });
        }
      });

      // Load audio source
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      await _audioPlayer.setUrl(widget.audioUrl).then((_) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
          _isAudioWaveformVisible = true;
        });
      }).catchError((error) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Could not load the audio file: ${error.toString()}';
        });
        print('Error setting URL: $error');
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Could not load the audio file: ${e.toString()}';
      });
      print('Error initializing audio player: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _togglePlayPause() async {
    if (!_isInitialized) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: ${e.toString()}')),
      );
    }
  }

  Future<void> _seekToPosition(Duration position) async {
    if (!_isInitialized) return;

    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  // This gives us the combined stream for various player states
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
            (position, bufferedPosition, duration) => PositionData(
          position: position,
          bufferedPosition: bufferedPosition,
          duration: duration ?? Duration.zero,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final Color cardColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
    final Color accentColor = Colors.blue;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Audio Player'),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Album art / audio visualization
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: _buildAudioVisualization(isDarkMode, accentColor),
              ),
            ),

            // Audio info
            Expanded(
              flex: 3,
              child: Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Audio title
                    Text(
                      widget.audioTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Audio progress
                    _buildProgressIndicator(accentColor, secondaryTextColor),

                    // Controls
                    _buildControls(accentColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioVisualization(bool isDarkMode, Color accentColor) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
            SizedBox(height: 16),
            Text(
              'Loading audio...',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Audio icon or album art
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Icon(
                Icons.audiotrack,
                size: 80 + (_isPlaying ? 10 * _animationController.value : 0),
                color: accentColor,
              );
            },
          ),
        ),

        SizedBox(height: 24),

        // Audio visualization (simplified)
        if (_isAudioWaveformVisible)
          Container(
            height: 60,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    30,
                        (index) {
                          // Ensure heightFactor is always positive
                          final double rawHeightFactor = _isPlaying ?
                          0.2 + 0.8 * sin(index / 2 + _animationController.value * 5) :
                          0.2 + (index % 3) * 0.2;

// Clamp heightFactor to be positive
                          final double heightFactor = max(0.05, rawHeightFactor);

                      return Container(
                        width: 4,
                        height: 100 * heightFactor,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(
                              _isPlaying ? 0.4 + 0.6 * heightFactor : 0.3
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProgressIndicator(Color accentColor, Color secondaryTextColor) {
    return StreamBuilder<PositionData>(
      stream: _positionDataStream,
      builder: (context, snapshot) {
        final positionData = snapshot.data ??
            PositionData(
              position: _position,
              bufferedPosition: Duration.zero,
              duration: _duration,
            );

        return Column(
          children: [
            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: accentColor,
                inactiveTrackColor: accentColor.withOpacity(0.2),
                thumbColor: accentColor,
                overlayColor: accentColor.withOpacity(0.2),
              ),
              child: Slider(
                min: 0.0,
                max: positionData.duration.inMilliseconds.toDouble(),
                value: min(
                  positionData.position.inMilliseconds.toDouble(),
                  positionData.duration.inMilliseconds.toDouble(),
                ),
                onChanged: (value) {
                  _seekToPosition(Duration(milliseconds: value.toInt()));
                },
              ),
            ),

            // Time indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(positionData.position),
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryTextColor,
                    ),
                  ),
                  Text(
                    _formatDuration(positionData.duration),
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Skip back 10 seconds
        IconButton(
          icon: Icon(Icons.replay_10),
          iconSize: 32,
          color: accentColor,
          onPressed: () {
            if (!_isInitialized) return;
            final newPosition = _position - Duration(seconds: 10);
            _seekToPosition(newPosition.isNegative ? Duration.zero : newPosition);
          },
        ),

        SizedBox(width: 24),

        // Play/Pause
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),

        SizedBox(width: 24),

        // Skip forward 10 seconds
        IconButton(
          icon: Icon(Icons.forward_10),
          iconSize: 32,
          color: accentColor,
          onPressed: () {
            if (!_isInitialized) return;
            final newPosition = _position + Duration(seconds: 10);
            final maxDuration = _duration;
            _seekToPosition(newPosition > maxDuration ? maxDuration : newPosition);
          },
        ),
      ],
    );
  }
}

// Data class for position information
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData({
    required this.position,
    required this.bufferedPosition,
    required this.duration,
  });
}