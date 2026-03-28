import 'package:candlestick_master/core/services/ad_service.dart';
import 'package:candlestick_master/core/theme/app_theme.dart';
import 'package:candlestick_master/features/challenge/challenge_hub_screen.dart';
import 'package:candlestick_master/features/home/dashboard_screen.dart';
import 'package:candlestick_master/features/learn/pattern_library_screen.dart';
import 'package:candlestick_master/features/profile/profile_screen.dart';
import 'package:candlestick_master/features/quiz/quiz_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;
  final int initialLearnTabIndex;

  const HomeScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialLearnTabIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Banner ad instance - managed here for proper lifecycle control
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  // Navigation State
  int _selectedIndex = 0;
  int _learnTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex.clamp(0, 4).toInt();
    _learnTabIndex = widget.initialLearnTabIndex.clamp(0, 1).toInt();
    _loadBannerAd();
  }

  /// Load the banner ad for monetization
  /// The ad is placed above the bottom navigation bar for non-intrusive visibility
  void _loadBannerAd() {
    _bannerAd = AdService.instance.createBannerAd(
      onLoaded: () {
        if (mounted) {
          setState(() => _isBannerLoaded = true);
        }
      },
      onFailed: (error) {
        // Ad failed to load - continue without showing ad
        debugPrint('Banner ad failed to load: $error');
      },
    );
  }

  @override
  void dispose() {
    // Important: Always dispose ads to prevent memory leaks
    _bannerAd?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index, {int? learnTabIndex}) {
    setState(() {
      _selectedIndex = index;
      if (learnTabIndex != null) {
        _learnTabIndex = learnTabIndex.clamp(0, 1).toInt();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // List of screens for bottom navigation
    final List<Widget> pages = [
      DashboardScreen(onTabChange: _onItemTapped),
      PatternLibraryScreen(initialTabIndex: _learnTabIndex),
      const QuizSelectionScreen(),
      const ChallengeHubScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      // No AppBar here - handled by individual screens
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      // Banner Ad - placed above bottom navigation
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner Ad Container
          if (_isBannerLoaded && _bannerAd != null)
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: AdWidget(ad: _bannerAd!),
            ),
          // Bottom Navigation
          BottomNavigationBar(
            backgroundColor: Theme.of(context).cardColor,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            type: BottomNavigationBarType.fixed, // Needed for >3 items
            currentIndex: _selectedIndex,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view), label: "Learn"),
              BottomNavigationBarItem(icon: Icon(Icons.quiz), label: "Quiz"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.local_fire_department), label: "Challenge"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: "Profile"),
            ],
            onTap: (index) => _onItemTapped(index),
          ),
        ],
      ),
    );
  }
}
