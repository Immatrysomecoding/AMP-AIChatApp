import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:async';

class YouTubeAdDialog extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onAdCompleted;
  final int watchDurationSeconds;

  const YouTubeAdDialog({
    super.key,
    required this.videoUrl,
    required this.onAdCompleted,
    this.watchDurationSeconds = 15, // Default 15 seconds
  });

  @override
  State<YouTubeAdDialog> createState() => _YouTubeAdDialogState();
}

class _YouTubeAdDialogState extends State<YouTubeAdDialog> {
  late YoutubePlayerController _controller;
  Timer? _timer;
  int _secondsWatched = 0;
  bool _canClose = false;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();

    // Extract video ID from URL
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl) ?? '';

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: true,
        hideControls: true,
        controlsVisibleAtStart: false,
        enableCaption: false,
      ),
    );

    _controller.addListener(() {
      if (_controller.value.isReady && !_isVideoReady) {
        setState(() {
          _isVideoReady = true;
        });
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsWatched++;
        if (_secondsWatched >= widget.watchDurationSeconds) {
          _canClose = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.black,
        child: Stack(
          children: [
            // YouTube Player
            Center(
              child: YoutubePlayerBuilder(
                player: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.red,
                ),
                builder: (context, player) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Video container
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                          maxHeight: MediaQuery.of(context).size.height * 0.7,
                        ),
                        child: AspectRatio(aspectRatio: 16 / 9, child: player),
                      ),
                      const SizedBox(height: 20),
                      // Status text
                      Text(
                        _canClose
                            ? 'Video watched! You earned 5 tokens!'
                            : 'Watch for ${widget.watchDurationSeconds - _secondsWatched} more seconds...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Loading indicator
            if (!_isVideoReady)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Close button (top right)
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: _canClose ? Colors.white : Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: _canClose ? Colors.black : Colors.white54,
                  ),
                  onPressed:
                      _canClose
                          ? () {
                            Navigator.of(context).pop();
                            widget.onAdCompleted();
                          }
                          : null,
                ),
              ),
            ),

            // Timer display (top left)
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${widget.watchDurationSeconds - _secondsWatched}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Skip button (bottom) - only shows when timer is complete
            if (_canClose)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onAdCompleted();
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Claim Reward'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
