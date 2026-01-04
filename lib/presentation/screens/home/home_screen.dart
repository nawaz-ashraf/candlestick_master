// =============================================================================
// HomeScreen - Main Dashboard
// =============================================================================
// The primary navigation hub of the app. Shows:
// - User stats (streak, accuracy)
// - Quick actions (Pattern Library, Quiz, Chart Simulator)
// - Banner ad for monetization (non-intrusive placement above bottom nav)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ad_service.dart';
import 'dashboard_screen.dart';
import '../library/pattern_library_screen.dart';
import '../quiz/quiz_screen.dart';
import '../performance/performance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Banner ad instance - managed here for proper lifecycle control
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  // Navigation State
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // List of screens for bottom navigation
    // We recreate them or keep them stateful?
    // Using IndexedStack in body maintains state.
    final List<Widget> pages = [
      DashboardScreen(onTabChange: _onItemTapped),
      const PatternLibraryScreen(),
      const QuizScreen(),
      const PerformanceScreen(),
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
                  icon: Icon(Icons.grid_view), label: "Patterns"),
              BottomNavigationBarItem(icon: Icon(Icons.quiz), label: "Quiz"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart), label: "Performance"),
            ],
            onTap: _onItemTapped,
          ),
        ],
      ),
    );
  }
}
