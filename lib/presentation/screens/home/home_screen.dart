// =============================================================================
// HomeScreen - Main Dashboard
// =============================================================================
// The primary navigation hub of the app. Shows:
// - User stats (streak, accuracy)
// - Quick actions (Pattern Library, Quiz, Chart Simulator)
// - Banner ad for monetization (non-intrusive placement above bottom nav)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ad_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Banner ad instance - managed here for proper lifecycle control
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

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
        // This ensures the app still works even if ads fail
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Candlestick Master"),
        actions: [
          // TODO: Implement notification center when push notifications are fully integrated
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming in next update!')),
              );
            },
            icon: const Icon(Icons.notifications),
          ),
          // TODO: Implement profile screen with user stats and settings
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile coming in next update!')),
              );
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting & Stats
            const Text("Welcome back, Trader!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Stats Row
            // TODO: Connect to actual user progress from database
            Row(
              children: [
                _buildStatCard(context, "Streak", "3 Days", Icons.local_fire_department, Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard(context, "Accuracy", "85%", Icons.track_changes, Colors.blue),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Main Actions
            Text("Start Learning", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            
            _buildActionCard(
              context,
              "Pattern Library",
              "Browse all 40+ candlestick patterns",
              Icons.grid_view,
              Colors.purple,
              () => context.push('/library'),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              "Practice Quiz",
              "Test your knowledge with quizzes",
              Icons.quiz,
              Colors.green,
              () => context.push('/quiz'),
            ),
            const SizedBox(height: 12),
             _buildActionCard(
              context,
              "Chart Simulator",
              "Identify patterns in real charts",
              Icons.show_chart,
              Colors.redAccent,
              () => context.push('/chart'),
            ),
          ],
        ),
      ),
      // Banner Ad - placed above bottom navigation for visibility without being intrusive
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner Ad Container
          if (_isBannerLoaded && _bannerAd != null)
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              color: AppColors.background,
              child: AdWidget(ad: _bannerAd!),
            ),
          // Bottom Navigation
          BottomNavigationBar(
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Patterns"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            ],
            onTap: (index) {
              if (index == 1) context.push('/library');
              if (index == 2) {
                // Profile tab - show coming soon message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile coming in next update!')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surface.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
