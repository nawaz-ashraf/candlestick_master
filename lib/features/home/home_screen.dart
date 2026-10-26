import "package:candlestick_master/core/services/ad_service.dart";
import "package:candlestick_master/core/theme/app_theme.dart";
import "package:candlestick_master/features/challenge/challenge_hub_screen.dart";
import "package:candlestick_master/features/home/dashboard_screen.dart";
import "package:candlestick_master/features/journal/journal_screen.dart";
import "package:candlestick_master/features/learn/pattern_library_screen.dart";
import "package:candlestick_master/features/profile/profile_screen.dart";
import "package:candlestick_master/features/quiz/quiz_selection_screen.dart";
import "package:candlestick_master/widgets/app_drawer.dart";
import "package:flutter/material.dart";
import "package:google_mobile_ads/google_mobile_ads.dart";

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Banner ad instance
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  // Navigation State
  // 0=Home, 1=Learn, 2=Quiz, 3=Journal, 4=Challenge, 5=Profile
  int _selectedIndex = 0;
  int _learnTabIndex = 0;
  final List<int> _navigationHistory = [0];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex.clamp(0, 5).toInt();
    _navigationHistory.clear();
    _navigationHistory.add(_selectedIndex);
    _learnTabIndex = widget.initialLearnTabIndex.clamp(0, 1).toInt();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    try {
      _bannerAd = AdService.instance.createBannerAd(
        onLoaded: () {
          if (mounted) {
            setState(() => _isBannerLoaded = true);
          }
        },
        onFailed: (error) {
          debugPrint("Banner ad failed to load: $error");
        },
      );
    } catch (e) {
      debugPrint("Banner ad initialization skipped: $e");
    }
  }

  @override
  void dispose() {
    try {
      _bannerAd?.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onItemTapped(int index, {int? learnTabIndex}) {
    if (index == _selectedIndex && learnTabIndex == null) return;

    setState(() {
      _selectedIndex = index.clamp(0, 5).toInt();
      if (_navigationHistory.isEmpty || _navigationHistory.last != _selectedIndex) {
        _navigationHistory.add(_selectedIndex);
      }
      if (learnTabIndex != null) {
        _learnTabIndex = learnTabIndex.clamp(0, 1).toInt();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 6 screens preserved in IndexedStack (preserves scroll & state)
    // 0=Home, 1=Learn, 2=Quiz, 3=Journal, 4=Challenge, 5=Profile
    final List<Widget> pages = [
      DashboardScreen(onTabChange: _onItemTapped, onOpenDrawer: _openDrawer),
      PatternLibraryScreen(
        initialTabIndex: _learnTabIndex,
        onOpenDrawer: _openDrawer,
      ),
      QuizSelectionScreen(onOpenDrawer: _openDrawer),
      JournalScreen(onOpenDrawer: _openDrawer),
      ChallengeHubScreen(onOpenDrawer: _openDrawer),
      ProfileScreen(onOpenDrawer: _openDrawer),
    ];

    return PopScope(
      canPop: _navigationHistory.length <= 1 && _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Close drawer first if open
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }

        // Handle tab back navigation
        if (_navigationHistory.length > 1) {
          setState(() {
            _navigationHistory.removeLast();
            _selectedIndex = _navigationHistory.last;
          });
        } else if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
            _navigationHistory.clear();
            _navigationHistory.add(0);
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppDrawer(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => _onItemTapped(index),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Banner Ad Container (above bottom bar, never overlaps content)
            if (_isBannerLoaded && _bannerAd != null)
              Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: AdWidget(ad: _bannerAd!),
              ),

            // Modern 4-item Material-style Bottom Navigation Bar
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                index: 0,
                label: "Home",
                icon: Icons.home_rounded,
                activeIcon: Icons.home_rounded,
              ),
              _buildBottomNavItem(
                index: 1,
                label: "Learn",
                icon: Icons.grid_view_rounded,
                activeIcon: Icons.grid_view_rounded,
              ),
              _buildBottomNavItem(
                index: 2,
                label: "Quiz",
                icon: Icons.quiz_rounded,
                activeIcon: Icons.quiz_rounded,
              ),
              _buildBottomNavItem(
                index: 3,
                label: "Journal",
                icon: Icons.book_outlined,
                activeIcon: Icons.book_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
