import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:aichat/core/services/subscription_state_manager.dart';

class AdManagerService {
  static final AdManagerService _instance = AdManagerService._internal();
  factory AdManagerService() => _instance;
  AdManagerService._internal();

  // Test Ad Unit IDs - Replace with your real ad unit IDs for production
  static const String _androidRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  RewardedAd? _rewardedAd;
  bool _isInitialized = false;
  final SubscriptionStateManager _subscriptionManager =
      SubscriptionStateManager();

  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return _androidRewardedAdUnitId;
    } else if (Platform.isIOS) {
      return _iosRewardedAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    _isInitialized = true;

    // Load the first ad
    await loadRewardedAd();
  }

  Future<void> loadRewardedAd() async {
    if (_rewardedAd != null) return; // Ad already loaded

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          print('Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  bool get isAdReady => _rewardedAd != null;

  void showRewardedAd({
    required Function(int) onUserEarnedReward,
    required Function() onAdDismissed,
    required Function(String) onAdFailedToShow,
  }) {
    if (_rewardedAd == null) {
      onAdFailedToShow('No ad available. Please try again later.');
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        onAdDismissed();
        // Load next ad
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onAdFailedToShow(error.toString());
        // Load next ad
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onUserEarnedReward(reward.amount.toInt());
      },
    );
  }

  void dispose() {
    _rewardedAd?.dispose();
  }
}
