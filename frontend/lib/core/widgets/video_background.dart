import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackground extends StatefulWidget {
  final String videoPath;
  final Widget child;
  final double overlayOpacity;

  const VideoBackground({
    super.key,
    required this.videoPath,
    required this.child,
    this.overlayOpacity = 0.5,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlayingForward = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset(widget.videoPath);
    
    try {
      await _controller.initialize();
      await _controller.setLooping(false); // Disable auto-loop, we'll handle it manually
      await _controller.setVolume(0.0); // Mute video
      
      // Listen for video completion to create bounce effect
      _controller.addListener(_onVideoPositionChanged);
      
      await _controller.play();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }
  
  void _onVideoPositionChanged() {
    if (!_controller.value.isInitialized || !mounted) return;
    
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    
    // Check if video reached the end (forward playback)
    if (_isPlayingForward && position >= duration - const Duration(milliseconds: 100)) {
      _isPlayingForward = false;
      _playBackward();
    }
    // Check if video reached the beginning (backward playback)
    else if (!_isPlayingForward && position <= const Duration(milliseconds: 100)) {
      _isPlayingForward = true;
      _playForward();
    }
  }
  
  void _playForward() {
    if (!mounted) return;
    _controller.play();
  }
  
  void _playBackward() {
    if (!mounted) return;
    // Simulate backward playback by seeking backward frame by frame
    _seekBackward();
  }
  
  void _seekBackward() async {
    if (!mounted || _isPlayingForward) return;
    
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - const Duration(milliseconds: 33); // ~30fps
    
    if (newPosition > Duration.zero) {
      await _controller.seekTo(newPosition);
      // Continue seeking backward
      Future.delayed(const Duration(milliseconds: 33), _seekBackward);
    } else {
      // Reached beginning, switch to forward
      await _controller.seekTo(Duration.zero);
      _isPlayingForward = true;
      _playForward();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoPositionChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video background
        if (_isInitialized)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        else
          // Fallback gradient while video loads
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A1128),
                    Color(0xFF001F54),
                    Color(0xFF034078),
                  ],
                ),
              ),
            ),
          ),
        
        // Dark overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(widget.overlayOpacity),
          ),
        ),
        
        // Content
        widget.child,
      ],
    );
  }
}
