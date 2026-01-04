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
// IMPORTANT: This file uses TEST AD IDs. Before release, replace with your
// actual AdMob ad unit IDs.
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Singleton service for managing Google AdMob ads
class AdService {
  // Private constructor for singleton pattern
  AdService._internal();
  static final AdService _instance = AdService._internal();
  static AdService get instance => _instance;

  // ============================================
  // TODO: Replace with your production Ad Unit IDs before release
  // ============================================
  
  // Test Ad Unit IDs (safe for development - won't get account banned)
  // These are Google's official test IDs
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  
  // TODO: Your production Ad Unit IDs (replace before release)
  // static const String _prodBannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  // static const String _prodInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  
  // Use test IDs for now
  static String get bannerAdUnitId => _testBannerAdUnitId;
  static String get interstitialAdUnitId => _testInterstitialAdUnitId;

  // ============================================
  // Frequency Capping Configuration
  // ============================================
  // Shows ads at most once every N actions to prevent user fatigue
  static const int _interstitialFrequencyCap = 3;
  int _interstitialActionCount = 0;

  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
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
      // Pre-load an interstitial ad for faster display
      await _loadInterstitialAd();
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
  BannerAd createBannerAd({Function()? onLoaded, Function(LoadAdError)? onFailed}) {
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
  // Interstitial Ads with Frequency Capping
  // ============================================
  
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
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
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

  /// Show the pre-loaded interstitial ad with frequency capping.
  /// Returns true if shown successfully, false otherwise.
  /// 
  /// Frequency capping: Only shows ad every N actions to prevent user fatigue.
  /// If ad is not ready or frequency cap not met, returns false silently
  /// to allow user flow to continue uninterrupted.
  Future<bool> showInterstitialAd() async {
    // Increment action counter
    _interstitialActionCount++;
    
    // Check frequency cap - only show every N actions
    if (_interstitialActionCount < _interstitialFrequencyCap) {
      debugPrint('AdService: Skipping interstitial (action ${_interstitialActionCount}/$_interstitialFrequencyCap)');
      return false;
    }
    
    // Reset counter
    _interstitialActionCount = 0;
    
    // Show ad if ready
    if (_isInterstitialReady && _interstitialAd != null) {
      debugPrint('AdService: Showing interstitial ad');
      await _interstitialAd!.show();
      return true;
    }
    
    // Ad not ready - continue without blocking
    debugPrint('AdService: Interstitial not ready, skipping');
    return false;
  }

  /// Force show interstitial without frequency capping
  /// Use sparingly for high-intent moments like quiz start
  Future<bool> forceShowInterstitialAd() async {
    if (_isInterstitialReady && _interstitialAd != null) {
      debugPrint('AdService: Force showing interstitial ad');
      _interstitialActionCount = 0; // Reset counter
      await _interstitialAd!.show();
      return true;
    }
    debugPrint('AdService: Force interstitial not ready, skipping');
    return false;
  }

  // ============================================
  // Cleanup
  // ============================================
  
  /// Dispose all loaded ads. Call this when the app is closing.
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}
