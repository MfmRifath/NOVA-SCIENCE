import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../Screens/StartScreen/AppTheme.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final String messageId;
  final List<double> waveform;
  final int audioDuration;
  final Function(String) onPlayStateChanged;

  const VoiceMessagePlayer({
    Key? key,
    required this.audioUrl,
    required this.messageId,
    required this.waveform,
    required this.audioDuration,
    required this.onPlayStateChanged,
  }) : super(key: key);

  @override
  _VoiceMessagePlayerState createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;
  bool _isLoading = false;
  String? _errorMessage;

  // Stream subscriptions
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  // Animation for waveform
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  bool get _isPlaying => _playerState == PlayerState.playing;
  bool get _isPaused => _playerState == PlayerState.paused;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();

    // Initialize animation controller for waveform progress
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _playerState = PlayerState.stopped;

    // Configure player
    _audioPlayer.setReleaseMode(ReleaseMode.stop);

    // Initialize streams
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen(
          (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
      widget.onPlayStateChanged('');
    });

    _playerStateChangeSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();

    // Release player resources
    _audioPlayer.dispose();

    // Dispose animation controller
    _progressAnimationController.dispose();

    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    // Prevent setState calls after widget disposal
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _pause();
    } else {
      await _play();
    }
  }

  Future<void> _play() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Check if we need to set the source (first play)
      if (_playerState == PlayerState.stopped) {
        await _audioPlayer.setSourceUrl(widget.audioUrl);
      }

      await _audioPlayer.resume();

      setState(() {
        _isLoading = false;
      });

      // Notify parent about playback
      widget.onPlayStateChanged(widget.messageId);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      print('Error playing audio: $e');

      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing audio: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pause() async {
    try {
      await _audioPlayer.pause();
      widget.onPlayStateChanged('');
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Get the playback progress as a percentage
  double get _progressPercent {
    if (_position == null || _duration == null || _duration!.inMilliseconds == 0) {
      return 0.0;
    }

    final progress = _position!.inMilliseconds / _duration!.inMilliseconds;

    // Update the animation value if it's different
    if (_progressAnimationController.value != progress) {
      _progressAnimationController.animateTo(progress,
          duration: Duration(milliseconds: 200));
    }

    return progress;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Play/pause button with ripple effect
          Material(
            color: Colors.transparent,
            shape: CircleBorder(),
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: _togglePlayPause,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: _isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    strokeWidth: 2,
                  ),
                )
                    : Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),

          // Waveform and progress
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Base waveform (non-played part)
                Container(
                  height: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      widget.waveform.length,
                          (index) => AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: 2,
                        height: (widget.waveform[index] * 24).clamp(4.0, 24.0),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),

                // Progress indicator with colored waveform (played part)
                AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressPercent,
                          child: Container(
                            height: 36,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                widget.waveform.length,
                                    (index) => AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  width: 2,
                                  height: (widget.waveform[index] * 24).clamp(4.0, 24.0),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                ),

                // Add a transparent gesture detector to allow seeking
                Positioned.fill(
                  child: GestureDetector(
                    onTapDown: (details) {
                      if (_duration != null) {
                        final RenderBox box = context.findRenderObject() as RenderBox;
                        final position = details.localPosition.dx / box.size.width;
                        final seekPosition = (position * _duration!.inMilliseconds)
                            .clamp(0, _duration!.inMilliseconds);
                        _audioPlayer.seek(Duration(milliseconds: seekPosition.toInt()));
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 8),

          // Duration/position display
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _position != null
                  ? '${_formatDuration(_position)} / ${_formatDuration(_duration ?? Duration(seconds: widget.audioDuration))}'
                  : _formatDuration(Duration(seconds: widget.audioDuration)),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}