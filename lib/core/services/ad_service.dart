// =============================================================================
// AdService - Google AdMob Integration
// =============================================================================
// This service manages all ad-related functionality for the app.
// Features:
// - Banner ads for home screen
// - Interstitial ads at high-intent moments
// - Frequency capping to prevent ad fatigue
// - Preloading for fast display
// - Non-blocking behavior (user flow continues if ad fails)
//
// IMPORTANT: Test ad IDs are used in debug/profile. Release builds use
// production IDs.
// =============================================================================

import 'package:candlestick_master/core/constants/reward_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton service for managing Google AdMob ads
class AdService {
  // Private constructor for singleton pattern
  AdService._internal();
  static final AdService _instance = AdService._internal();
  static AdService get instance => _instance;

  // ============================================
  // Ad Unit IDs (test in debug/profile, production in release)
  // ============================================

  // Google's official test IDs (safe for development)
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // Production Ad Unit IDs
  static const String _prodBannerAdUnitId =
      'ca-app-pub-4392358942856616/7175980458';
  static const String _prodInterstitialAdUnitId =
      'ca-app-pub-4392358942856616/3094895523';
  static const String _prodRewardedAdUnitId =
      'ca-app-pub-4392358942856616/5797671098';

  static bool get _useTestAds => !kReleaseMode;

  static String get bannerAdUnitId =>
      _useTestAds ? _testBannerAdUnitId : _prodBannerAdUnitId;
  static String get interstitialAdUnitId =>
      _useTestAds ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;
  static String get rewardedAdUnitId =>
      _useTestAds ? _testRewardedAdUnitId : _prodRewardedAdUnitId;

  // SharedPreferences keys for session-based interstitial cadence.
  static const String _sessionCountKey = 'ad_session_count';
  static const String _lastInterstitialSessionKey =
      'ad_last_interstitial_session';

  int _sessionCount = 0;
  int _lastInterstitialSession = -1;
  bool _isSessionStateLoaded = false;

  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;
  bool _isInitialized = false;

  // ============================================
  // Initialization
  // ============================================

  /// Initialize the Mobile Ads SDK. Call this before using any ads.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      await _loadSessionState();
      // Pre-load an interstitial ad and a rewarded ad for faster display
      await _loadInterstitialAd();
      await _loadRewardedAd();
      debugPrint('AdService: Initialized successfully');
    } catch (e) {
      debugPrint('AdService: Failed to initialize - $e');
    }
  }

  // ============================================
  // Banner Ads
  // ============================================

  /// Creates a banner ad. The caller is responsible for disposing it.
  ///
  /// Usage:
  /// ```dart
  /// final bannerAd = AdService.instance.createBannerAd();
  /// // Add to widget tree using AdWidget(ad: bannerAd)
  /// // Don't forget to dispose when done
  /// ```
  BannerAd createBannerAd({
    Function()? onLoaded,
    Function(LoadAdError)? onFailed,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdService: Banner ad loaded');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: Banner ad failed - $error');
          ad.dispose();
          onFailed?.call(error);
        },
      ),
    )..load();
  }

  // ============================================
  // Interstitial Ads (session-based cadence)
  // ============================================

  /// Increment app session counter.
  /// Call this once per app launch after [initialize].
  Future<void> startSession() async {
    await _loadSessionState();
    _sessionCount += 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionCountKey, _sessionCount);

    debugPrint('AdService: Session $_sessionCount started');
  }

  Future<void> _loadSessionState() async {
    if (_isSessionStateLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    _sessionCount = prefs.getInt(_sessionCountKey) ?? 0;
    _lastInterstitialSession = prefs.getInt(_lastInterstitialSessionKey) ?? -1;
    _isSessionStateLoaded = true;
  }

  Future<bool> _canShowInterstitialThisSession() async {
    await _loadSessionState();

    if (_sessionCount <= 0) return false;

    final isEligibleSession =
        _sessionCount % RewardConstants.sessionsPerInterstitial == 0;
    final notShownInThisSession = _lastInterstitialSession != _sessionCount;

    return isEligibleSession && notShownInThisSession;
  }

  Future<void> _markInterstitialShownForSession() async {
    _lastInterstitialSession = _sessionCount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastInterstitialSessionKey, _lastInterstitialSession);
  }

  /// Load an interstitial ad. Call this to pre-load before showing.
  Future<void> _loadInterstitialAd() async {
    if (!_isInitialized) return;

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          debugPrint('AdService: Interstitial ad loaded');

          // Set up callbacks for when the ad is dismissed
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('AdService: Interstitial dismissed');
              ad.dispose();
              _isInterstitialReady = false;
              // Pre-load another one for next time
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdService: Interstitial failed to show - $error');
              ad.dispose();
              _isInterstitialReady = false;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Interstitial failed to load - $error');
          _isInterstitialReady = false;
        },
      ),
    );
  }

  /// Check if an interstitial ad is ready to show
  bool get isInterstitialReady => _isInterstitialReady;

  /// Show the pre-loaded interstitial ad based on session cadence.
  /// Returns true if shown successfully, false otherwise.
  Future<bool> showInterstitialAd() async {
    final shouldShow = await _canShowInterstitialThisSession();

    if (!shouldShow) {
      debugPrint('AdService: Skipping interstitial (session cadence)');
      return false;
    }

    // Show ad if ready
    if (_isInterstitialReady && _interstitialAd != null) {
      debugPrint('AdService: Showing interstitial ad');
      await _interstitialAd!.show();
      await _markInterstitialShownForSession();
      return true;
    }

    // Ad not ready - continue without blocking
    debugPrint('AdService: Interstitial not ready, skipping');
    return false;
  }

  /// Force show interstitial without frequency capping
  /// Use sparingly for explicit non-quiz placements.
  Future<bool> forceShowInterstitialAd() async {
    if (_isInterstitialReady && _interstitialAd != null) {
      debugPrint('AdService: Force showing interstitial ad');
      await _interstitialAd!.show();
      await _markInterstitialShownForSession();
      return true;
    }
    debugPrint('AdService: Force interstitial not ready, skipping');
    return false;
  }

  // ============================================
  // Rewarded Ads
  // ============================================

  /// Load a rewarded ad
  Future<void> _loadRewardedAd() async {
    if (!_isInitialized) return;

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
          debugPrint('AdService: Rewarded ad loaded');

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('AdService: Rewarded ad dismissed');
              ad.dispose();
              _isRewardedReady = false;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdService: Rewarded ad failed to show - $error');
              ad.dispose();
              _isRewardedReady = false;
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Rewarded ad failed to load - $error');
          _isRewardedReady = false;
        },
      ),
    );
  }

  /// Show a rewarded ad and execute a callback if the user earns the reward.
  Future<bool> showRewardedAd({required Function() onRewarded}) async {
    if (_isRewardedReady && _rewardedAd != null) {
      debugPrint('AdService: Showing rewarded ad');
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('AdService: User earned reward!');
          onRewarded();
        },
      );
      return true;
    }

    debugPrint('AdService: Rewarded ad not ready');
    // Pre-load if it wasn't ready
    _loadRewardedAd();
    return false;
  }

  // ============================================
  // Cleanup
  // ============================================

  /// Dispose all loaded ads. Call this when the app is closing.
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
