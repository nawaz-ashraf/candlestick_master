// =============================================================================
// AdService - Google AdMob Integration
// =============================================================================
// This service manages all ad-related functionality for the app.
// Features:
// - Banner ads for home screen (caller-owned, no widget-rebuild re-requests)
// - Interstitial ads with LAZY loading (only requested when eligible per cadence)
// - Rewarded / RewardedInterstitial ads with loading-state feedback
// - Frequency capping to prevent ad fatigue and reduce wasted requests
// - Non-blocking behavior (user flow continues if ad fails)
//
// HOW LAZY LOADING FIXES "LOW SHOW RATE":
// Previously, InterstitialAd.load() was called on every cold-start AND after
// every dismissal, regardless of whether the user was in an eligible session.
// This bloated "Requests" while "Impressions" remained low.
// Now, _loadInterstitialAd() first checks _canShowInterstitialThisSession().
// If the user is not eligible, no request is sent — keeping RPM aligned with
// actual impressions.
//
// IMPORTANT: Test ad IDs are used in debug/profile. Release builds use
// production IDs.
// =============================================================================

import 'dart:async';

import 'package:candlestick_master/core/constants/reward_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Enum returned by showRewardedAd so the UI can react appropriately.
// ---------------------------------------------------------------------------
enum RewardedAdResult {
  /// Ad was shown and the user watched it to earn a reward.
  rewarded,

  /// Ad was shown but the user dismissed it early (no reward).
  dismissed,

  /// Ad was not ready. A background load has been triggered.
  /// The UI should show a "Loading…" indicator and retry.
  loading,

  /// The service is not yet initialised.
  notInitialized,
}

/// Internal state tracker for an individual rewarded ad display session.
/// Guarantees that rewards are executed strictly on [onUserEarnedReward],
/// that duplicate callbacks cannot trigger multiple grants, and that
/// dismissal unblocks the caller with the final result.
class _RewardedAdSession {
  final int id;
  bool isShowing = false;
  bool hasEarnedReward = false;
  bool hasGrantedReward = false;
  bool isDismissed = false;
  bool didFailToShow = false;
  final Completer<RewardedAdResult> completer = Completer<RewardedAdResult>();

  _RewardedAdSession(this.id);
}

/// Singleton service for managing Google AdMob ads.
class AdService {
  // Private constructor for singleton pattern.
  AdService._internal();
  static final AdService _instance = AdService._internal();
  static AdService get instance => _instance;

  // ============================================
  // Ad Unit IDs (test in debug/profile, production in release)
  // ============================================

  // Google's official test IDs (safe for development).
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  // Rewarded Interstitial test ID (Google official).
  static const String _testRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/5354046379';

  // Production Ad Unit IDs.
  static const String _prodBannerAdUnitId =
      'ca-app-pub-4392358942856616/7175980458';
  static const String _prodInterstitialAdUnitId =
      'ca-app-pub-4392358942856616/3094895523';
  static const String _prodRewardedAdUnitId =
      'ca-app-pub-4392358942856616/5797671098';
  static const String _prodRewardedInterstitialAdUnitId =
      'ca-app-pub-4392358942856616/7248724222';

  static bool get _useTestAds => !kReleaseMode;

  static String get bannerAdUnitId =>
      _useTestAds ? _testBannerAdUnitId : _prodBannerAdUnitId;
  static String get interstitialAdUnitId =>
      _useTestAds ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;
  static String get rewardedAdUnitId =>
      _useTestAds ? _testRewardedAdUnitId : _prodRewardedAdUnitId;
  static String get rewardedInterstitialAdUnitId => _useTestAds
      ? _testRewardedInterstitialAdUnitId
      : _prodRewardedInterstitialAdUnitId;

  // ============================================
  // Session cadence state (SharedPreferences-backed)
  // ============================================

  /// SharedPreferences key for the total app-open count.
  static const String _sessionCountKey = 'ad_session_count';

  /// SharedPreferences key for the session number in which the last
  /// interstitial was shown — prevents showing more than once per session.
  static const String _lastInterstitialSessionKey =
      'ad_last_interstitial_session';

  int _sessionCount = 0;
  int _lastInterstitialSession = -1;
  bool _isSessionStateLoaded = false;

  // ============================================
  // Ad instances
  // ============================================

  // NOTE: BannerAd instances are NOT stored here.
  // Use createBannerAd() and manage lifecycle in the calling widget to avoid
  // re-requesting on every widget rebuild.
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;

  bool _isInterstitialLoading = false;
  bool _isInterstitialReady = false;

  bool _isRewardedLoading = false;
  bool _isRewardedReady = false;
  bool _isRewardedShowing = false;

  bool _isRewardedInterstitialLoading = false;
  bool _isRewardedInterstitialReady = false;
  bool _isRewardedInterstitialShowing = false;

  int _adSessionCounter = 0;
  bool _isInitialized = false;

  // ============================================
  // Initialization
  // ============================================

  /// Initialize the Mobile Ads SDK. Call this once at app startup.
  ///
  /// ▶ Interstitial/rewarded ads are NOT pre-loaded here. They will be loaded
  ///   lazily when [startSession] confirms the user is eligible for an ad this
  ///   session. This is the primary fix for the "Low Show Rate" issue.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      await _loadSessionState();
      debugPrint('AdService: Initialized successfully');
    } catch (e) {
      debugPrint('AdService: Failed to initialize – $e');
    }
  }

  // ============================================
  // Session management
  // ============================================

  /// Increment the app-open session counter and pre-load ads only if the user
  /// is eligible for an interstitial this session.
  ///
  /// Call this ONCE per app launch, after [initialize].
  Future<void> startSession() async {
    await _loadSessionState();
    _sessionCount += 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionCountKey, _sessionCount);

    debugPrint('AdService: Session $_sessionCount started');

    // ── Lazy pre-load: only request the ad if we will actually show it ──────
    // This is the core fix. Previously, load() was always called here and in
    // initialize(), wasting requests on ineligible sessions.
    if (await _canShowInterstitialThisSession()) {
      debugPrint('AdService: Eligible session – pre-loading interstitial');
      _loadInterstitialAd();
    } else {
      debugPrint(
          'AdService: Ineligible session – skipping interstitial pre-load');
    }

    // Rewarded ads are user-intent driven; always keep one ready.
    _loadRewardedAd();
  }

  Future<void> _loadSessionState() async {
    if (_isSessionStateLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    _sessionCount = prefs.getInt(_sessionCountKey) ?? 0;
    _lastInterstitialSession = prefs.getInt(_lastInterstitialSessionKey) ?? -1;
    _isSessionStateLoaded = true;
  }

  /// Returns true only when this session number is a multiple of the cadence
  /// AND we have not already shown an interstitial in this session.
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

  // ============================================
  // Banner Ads
  // ============================================

  /// Creates and loads a new [BannerAd].
  ///
  /// **The caller owns this object and MUST call [BannerAd.dispose] when the
  /// widget is removed from the tree.**  Do NOT call this method inside
  /// `build()` — create the ad once in [State.initState] and store it, so the
  /// widget can survive rebuilds without issuing new ad requests.
  ///
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   _bannerAd = AdService.instance.createBannerAd(
  ///     onLoaded: () => setState(() => _isBannerReady = true),
  ///   );
  /// }
  ///
  /// @override
  /// void dispose() {
  ///   _bannerAd?.dispose();
  ///   super.dispose();
  /// }
  /// ```
  BannerAd createBannerAd({
    AdSize size = AdSize.banner,
    Function()? onLoaded,
    Function(LoadAdError)? onFailed,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdService: Banner ad loaded');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: Banner ad failed – $error');
          ad.dispose();
          onFailed?.call(error);
        },
      ),
    )..load();
  }

  // ============================================
  // Interstitial Ads (session-based cadence, lazy loading)
  // ============================================

  /// Load an interstitial ad.
  ///
  /// This method is now CADENCE-GATED: it checks eligibility before calling
  /// [InterstitialAd.load], so no wasted network requests are made for
  /// sessions that will never show the ad.
  Future<void> _loadInterstitialAd() async {
    if (!_isInitialized) return;

    // ── Guard: skip if ineligible to avoid request inflation ───────────────
    final canShow = await _canShowInterstitialThisSession();
    if (!canShow) {
      debugPrint(
          'AdService: _loadInterstitialAd skipped – session not eligible');
      return;
    }

    // ── Guard: only one in-flight load at a time ────────────────────────────
    if (_isInterstitialLoading || _isInterstitialReady) return;
    _isInterstitialLoading = true;

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _isInterstitialLoading = false;
          debugPrint('AdService: Interstitial ad loaded');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('AdService: Interstitial dismissed');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;

              // ── Smart post-dismissal reload ──────────────────────────────
              // Only reload if the user is still eligible for ANOTHER ad this
              // session (i.e., they haven't used their one per-session slot
              // yet). In practice this will almost always be false after we
              // call _markInterstitialShownForSession(), so no wasted request.
              _conditionallyPreloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdService: Interstitial failed to show – $error');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              _isInterstitialLoading = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Interstitial failed to load – $error');
          _isInterstitialReady = false;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Reload only if still eligible (prevents bloating requests post-show).
  void _conditionallyPreloadInterstitial() {
    _canShowInterstitialThisSession().then((canShow) {
      if (canShow) _loadInterstitialAd();
    });
  }

  /// Whether an interstitial ad is loaded and ready to display.
  bool get isInterstitialReady => _isInterstitialReady;

  /// Whether a rewarded ad is loaded and ready to display.
  bool get isRewardedReady => _isRewardedReady;

  /// Show the pre-loaded interstitial ad if the session cadence allows it.
  ///
  /// Returns `true` if the ad was shown, `false` otherwise (not eligible,
  /// not loaded, etc.).
  Future<bool> showInterstitialAd() async {
    final shouldShow = await _canShowInterstitialThisSession();

    if (!shouldShow) {
      debugPrint('AdService: Skipping interstitial (session cadence)');
      return false;
    }

    if (_isInterstitialReady && _interstitialAd != null) {
      debugPrint('AdService: Showing interstitial ad');
      await _interstitialAd!.show();
      await _markInterstitialShownForSession();
      return true;
    }

    // Ad not yet loaded — trigger a load so it may be ready soon.
    debugPrint('AdService: Interstitial not ready, triggering load');
    _loadInterstitialAd();
    return false;
  }

  /// Force-show the interstitial ad without session-frequency enforcement.
  ///
  /// Use sparingly, e.g. for explicit placement buttons outside normal flow.
  Future<bool> forceShowInterstitialAd() async {
    if (_isInterstitialReady && _interstitialAd != null) {
      debugPrint('AdService: Force-showing interstitial ad');
      await _interstitialAd!.show();
      await _markInterstitialShownForSession();
      return true;
    }
    debugPrint('AdService: Force interstitial not ready');
    return false;
  }

  // ============================================
  // Rewarded Ads (user-intent driven, always pre-loaded)
  // ============================================

  /// Load a standard [RewardedAd] in the background.
  Future<void> _loadRewardedAd() async {
    if (!_isInitialized) {
      debugPrint('AdService: Cannot load rewarded ad – SDK not initialized');
      return;
    }
    if (_isRewardedLoading || _isRewardedReady) {
      debugPrint('AdService: Rewarded ad load skipped (already loading or ready)');
      return;
    }
    _isRewardedLoading = true;
    debugPrint('AdService: Loading rewarded ad ($rewardedAdUnitId)...');

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
          _isRewardedLoading = false;
          debugPrint('AdService: Rewarded ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Rewarded ad failed to load – ${error.message} (code: ${error.code})');
          _isRewardedReady = false;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  /// Wait for a rewarded ad to become ready, with a [timeout].
  ///
  /// Returns `true` if the ad is ready, `false` if the timeout elapsed.
  /// This allows the UI to show a proper loading indicator while waiting,
  /// instead of failing silently when the ad isn't loaded.
  Future<bool> waitForRewardedAd({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_isRewardedReady && _rewardedAd != null) {
      debugPrint('AdService: Rewarded ad already ready');
      return true;
    }

    debugPrint('AdService: Rewarded ad not ready, triggering load and waiting...');
    _loadRewardedAd();

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (_isRewardedReady && _rewardedAd != null) {
        debugPrint('AdService: Rewarded ad became ready while waiting');
        return true;
      }
    }
    debugPrint('AdService: Timed out waiting for rewarded ad');
    return false;
  }

  /// Show a rewarded ad.
  ///
  /// Parameters:
  /// - [onUserEarnedReward]: Invoked strictly when Google Mobile Ads SDK reports
  ///   an earned reward via [onUserEarnedReward]. The reward MUST be granted from
  ///   this callback to adhere to AdMob rewarded ad policies.
  ///
  /// Returns a [RewardedAdResult] enum when the ad flow is finished (dismissed or failed):
  /// - [RewardedAdResult.rewarded]  → the user earned the reward; post-ad action can resume.
  /// - [RewardedAdResult.dismissed] → user closed early or ad failed; no reward.
  /// - [RewardedAdResult.loading]   → ad not ready even after a wait;
  /// - [RewardedAdResult.notInitialized] → SDK not initialised.
  Future<RewardedAdResult> showRewardedAd({
    FutureOr<void> Function(RewardItem reward)? onUserEarnedReward,
  }) async {
    if (!_isInitialized) {
      debugPrint('AdService: Cannot show rewarded ad – SDK not initialized');
      return RewardedAdResult.notInitialized;
    }

    // Prevent double-show attempts while an ad is already on screen.
    if (_isRewardedShowing) {
      debugPrint('AdService: Rewarded ad already showing – ignoring duplicate request');
      return RewardedAdResult.loading;
    }

    if (!_isRewardedReady || _rewardedAd == null) {
      debugPrint(
          'AdService: Rewarded ad not ready – triggering load & returning loading state');
      _loadRewardedAd();
      return RewardedAdResult.loading;
    }

    // Capture a local reference so callbacks are safe.
    final ad = _rewardedAd!;
    _isRewardedShowing = true;
    _isRewardedReady = false;
    _rewardedAd = null;

    final session = _RewardedAdSession(++_adSessionCounter);
    debugPrint('AdService: [Session ${session.id}] Displaying rewarded ad');

    // Wire up full-screen callbacks BEFORE calling show().
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('AdService: [Session ${session.id}] Rewarded ad showed full screen');
        session.isShowing = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint(
            'AdService: [Session ${session.id}] Rewarded ad dismissed. Reward earned: ${session.hasEarnedReward}');
        session.isDismissed = true;
        ad.dispose();
        _isRewardedShowing = false;
        // Pre-load the next ad for future user actions.
        _loadRewardedAd();

        if (!session.completer.isCompleted) {
          session.completer.complete(
            session.hasEarnedReward
                ? RewardedAdResult.rewarded
                : RewardedAdResult.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint(
            'AdService: [Session ${session.id}] Rewarded ad failed to show – ${error.message} (code: ${error.code})');
        session.didFailToShow = true;
        session.isDismissed = true;
        ad.dispose();
        _isRewardedShowing = false;
        _loadRewardedAd();

        if (!session.completer.isCompleted) {
          session.completer.complete(RewardedAdResult.dismissed);
        }
      },
      onAdImpression: (ad) {
        debugPrint('AdService: [Session ${session.id}] Rewarded ad impression recorded');
      },
      onAdClicked: (ad) {
        debugPrint('AdService: [Session ${session.id}] Rewarded ad clicked');
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          debugPrint(
              'AdService: [Session ${session.id}] onUserEarnedReward invoked – amount: ${reward.amount}, type: ${reward.type}');
          session.hasEarnedReward = true;
          if (!session.hasGrantedReward) {
            session.hasGrantedReward = true;
            try {
              if (onUserEarnedReward != null) {
                await onUserEarnedReward(reward);
                debugPrint(
                    'AdService: [Session ${session.id}] Reward callback executed successfully');
              }
            } catch (e, stack) {
              debugPrint(
                  'AdService: [Session ${session.id}] Error in onUserEarnedReward callback: $e\n$stack');
            }
          } else {
            debugPrint(
                'AdService: [Session ${session.id}] Duplicate onUserEarnedReward callback ignored');
          }
        },
      );
    } catch (e, stack) {
      debugPrint(
          'AdService: [Session ${session.id}] Exception calling ad.show(): $e\n$stack');
      session.didFailToShow = true;
      ad.dispose();
      _isRewardedShowing = false;
      _loadRewardedAd();
      if (!session.completer.isCompleted) {
        session.completer.complete(RewardedAdResult.dismissed);
      }
    }

    return await session.completer.future;
  }

  // ============================================
  // Rewarded Interstitial Ads
  // ============================================

  /// Load a [RewardedInterstitialAd] in the background.
  ///
  /// Rewarded Interstitials are shown at natural content breaks (like
  /// Interstitials) but optionally reward the user — Google reports higher
  /// fill rates for these units than standard Rewarded ads.
  Future<void> _loadRewardedInterstitialAd() async {
    if (!_isInitialized) return;
    if (_isRewardedInterstitialLoading || _isRewardedInterstitialReady) return;
    _isRewardedInterstitialLoading = true;

    await RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialReady = true;
          _isRewardedInterstitialLoading = false;
          debugPrint('AdService: RewardedInterstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: RewardedInterstitial failed to load – $error');
          _isRewardedInterstitialReady = false;
          _isRewardedInterstitialLoading = false;
        },
      ),
    );
  }

  /// Whether a [RewardedInterstitialAd] is loaded and ready to display.
  bool get isRewardedInterstitialReady => _isRewardedInterstitialReady;

  /// Pre-load a [RewardedInterstitialAd] so it is ready when needed.
  ///
  /// Call this from a screen that may trigger a rewarded interstitial, e.g.
  /// at the start of a quiz round.
  void preloadRewardedInterstitialAd() => _loadRewardedInterstitialAd();

  /// Show a [RewardedInterstitialAd].
  ///
  /// Returns the same [RewardedAdResult] enum as [showRewardedAd].
  Future<RewardedAdResult> showRewardedInterstitialAd({
    FutureOr<void> Function(RewardItem reward)? onUserEarnedReward,
  }) async {
    if (!_isInitialized) {
      debugPrint('AdService: Cannot show RewardedInterstitial – SDK not initialized');
      return RewardedAdResult.notInitialized;
    }

    if (_isRewardedInterstitialShowing) {
      debugPrint(
          'AdService: RewardedInterstitial already showing – ignoring duplicate request');
      return RewardedAdResult.loading;
    }

    if (!_isRewardedInterstitialReady || _rewardedInterstitialAd == null) {
      debugPrint(
          'AdService: RewardedInterstitial not ready – triggering load & returning loading state');
      _loadRewardedInterstitialAd();
      return RewardedAdResult.loading;
    }

    final ad = _rewardedInterstitialAd!;
    _isRewardedInterstitialShowing = true;
    _isRewardedInterstitialReady = false;
    _rewardedInterstitialAd = null;

    final session = _RewardedAdSession(++_adSessionCounter);
    debugPrint('AdService: [Session ${session.id}] Showing RewardedInterstitial ad');

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('AdService: [Session ${session.id}] RewardedInterstitial showed full screen');
        session.isShowing = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint(
            'AdService: [Session ${session.id}] RewardedInterstitial dismissed. Reward earned: ${session.hasEarnedReward}');
        session.isDismissed = true;
        ad.dispose();
        _isRewardedInterstitialShowing = false;
        _loadRewardedInterstitialAd();

        if (!session.completer.isCompleted) {
          session.completer.complete(
            session.hasEarnedReward
                ? RewardedAdResult.rewarded
                : RewardedAdResult.dismissed,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint(
            'AdService: [Session ${session.id}] RewardedInterstitial failed to show – ${error.message} (code: ${error.code})');
        session.didFailToShow = true;
        session.isDismissed = true;
        ad.dispose();
        _isRewardedInterstitialShowing = false;
        _loadRewardedInterstitialAd();

        if (!session.completer.isCompleted) {
          session.completer.complete(RewardedAdResult.dismissed);
        }
      },
      onAdImpression: (ad) {
        debugPrint('AdService: [Session ${session.id}] RewardedInterstitial impression recorded');
      },
      onAdClicked: (ad) {
        debugPrint('AdService: [Session ${session.id}] RewardedInterstitial clicked');
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          debugPrint(
              'AdService: [Session ${session.id}] RewardedInterstitial onUserEarnedReward fired – ${reward.amount} ${reward.type}');
          session.hasEarnedReward = true;
          if (!session.hasGrantedReward) {
            session.hasGrantedReward = true;
            try {
              if (onUserEarnedReward != null) {
                await onUserEarnedReward(reward);
                debugPrint(
                    'AdService: [Session ${session.id}] Interstitial reward callback executed successfully');
              }
            } catch (e, stack) {
              debugPrint(
                  'AdService: [Session ${session.id}] Error in interstitial reward callback: $e\n$stack');
            }
          } else {
            debugPrint(
                'AdService: [Session ${session.id}] Duplicate interstitial reward callback ignored');
          }
        },
      );
    } catch (e, stack) {
      debugPrint(
          'AdService: [Session ${session.id}] Exception calling RewardedInterstitial ad.show(): $e\n$stack');
      session.didFailToShow = true;
      ad.dispose();
      _isRewardedInterstitialShowing = false;
      _loadRewardedInterstitialAd();
      if (!session.completer.isCompleted) {
        session.completer.complete(RewardedAdResult.dismissed);
      }
    }

    return await session.completer.future;
  }

  // ============================================
  // Cleanup
  // ============================================

  /// Dispose all loaded ads. Call this when the app is terminating.
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedInterstitialAd?.dispose();
  }
}
