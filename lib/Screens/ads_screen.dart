import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aichat/core/services/subscription_state_manager.dart';
import 'package:aichat/widgets/sidebar.dart';
import 'package:aichat/widgets/Dialog/youtube_ad_dialog.dart';
import 'dart:async';
import 'dart:math';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  final SubscriptionStateManager _subscriptionManager =
      SubscriptionStateManager();

  bool _isLoadingAd = false;
  bool _canWatchAd = true;
  int _dailyAdsWatched = 0;
  static const int _maxDailyAds = 5;
  DateTime? _lastAdWatchTime;
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  // List of YouTube video URLs to use as ads
  final List<String> _adVideos = [
    'https://www.youtube.com/watch?v=IXE1rX2nnfQ',
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ', // Rick Roll as an ad :)
    'https://www.youtube.com/watch?v=9bZkp7q19f0', // Gangnam Style
    'https://www.youtube.com/watch?v=kJQP7kiw5Fk', // Despacito
    'https://www.youtube.com/watch?v=JGwWNGJdvx8', // Shape of You
  ];

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_lastAdWatchTime != null) {
            final timeSince = DateTime.now().difference(_lastAdWatchTime!);
            _secondsRemaining = 60 - timeSince.inSeconds;

            if (_secondsRemaining <= 0) {
              _canWatchAd = true;
              _secondsRemaining = 0;
            }
          }
        });
      }
    });
  }

  bool get _canWatchMoreAds {
    if (_subscriptionManager.isPro) return false;
    if (_dailyAdsWatched >= _maxDailyAds) return false;
    if (_lastAdWatchTime != null) {
      final timeSince = DateTime.now().difference(_lastAdWatchTime!);
      if (timeSince.inSeconds < 60) return false;
    }
    return _canWatchAd;
  }

  void _watchAd() async {
    if (!_canWatchMoreAds) return;

    // Select a random video from the list
    final randomVideo = _adVideos[Random().nextInt(_adVideos.length)];

    // Show the YouTube ad dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => YouTubeAdDialog(
            videoUrl: randomVideo,
            watchDurationSeconds: 15, // Watch for 15 seconds
            onAdCompleted: () {
              // Give user tokens for watching an ad
              final tokensToAdd = 5;
              _subscriptionManager.setTokens(
                _subscriptionManager.availableTokens + tokensToAdd,
              );

              setState(() {
                _dailyAdsWatched++;
                _lastAdWatchTime = DateTime.now();
                _canWatchAd = false;
                _secondsRemaining = 60;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You earned $tokensToAdd free tokens!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
    );
  }

  String _getTimeUntilNextAd() {
    if (_secondsRemaining <= 0) return '';

    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;

    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar:
          isLargeScreen
              ? null
              : AppBar(
                title: const Text('Earn Free Tokens'),
                backgroundColor: Colors.blue.shade50,
                iconTheme: const IconThemeData(color: Colors.blue),
                elevation: 0,
              ),
      drawer:
          isLargeScreen
              ? null
              : const Drawer(child: Sidebar(selectedItem: 'Ads')),
      body:
          isLargeScreen
              ? Row(
                children: [
                  const Sidebar(selectedItem: 'Ads'),
                  Expanded(child: _buildContent()),
                ],
              )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_subscriptionManager.isPro) {
      return _buildProUserContent();
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monetization_on,
                size: 60,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            const Text(
              'Earn Free Tokens',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Watch YouTube videos to earn free tokens for using Jarvis AI',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Current tokens display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orange.shade600,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Tokens: ${_subscriptionManager.availableTokens}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Daily Ads Watched: $_dailyAdsWatched / $_maxDailyAds',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Watch ad button
            ElevatedButton.icon(
              onPressed: _canWatchMoreAds ? _watchAd : null,
              icon: const Icon(Icons.play_circle_fill),
              label: Text(
                _canWatchMoreAds
                    ? 'Watch Video (Earn 5 Tokens)'
                    : _dailyAdsWatched >= _maxDailyAds
                    ? 'Daily Limit Reached'
                    : 'Next video in ${_getTimeUntilNextAd()}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Show timer countdown
            if (_secondsRemaining > 0)
              Text(
                'Cooling down: ${_getTimeUntilNextAd()}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),

            const SizedBox(height: 16),

            // Video info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Watch for 15 seconds to earn tokens',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProUserContent() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium,
              size: 80,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 24),
            const Text(
              'You\'re a Pro User!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'You have unlimited tokens and don\'t need to watch ads.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/chat');
              },
              icon: const Icon(Icons.chat),
              label: const Text('Go to Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
