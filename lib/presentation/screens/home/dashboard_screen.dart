import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/ad_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pattern_model.dart';
import '../../providers/pattern_notifier.dart';
import '../../providers/theme_notifier.dart';

class DashboardScreen extends StatelessWidget {
  // Callback to switch tabs in the parent HomeScreen
  // We accept a function to navigate to other tabs
  final Function(int) onTabChange;

  const DashboardScreen({super.key, required this.onTabChange});

  /// Navigate to pattern detail with interstitial ad
  Future<void> _navigateToPattern(
      BuildContext context, CandlestickPattern pattern) async {
    await AdService.instance.showInterstitialAd();
    if (context.mounted) {
      context.push('/pattern/${pattern.id}', extra: pattern);
    }
  }

  /// Share app logo with marketing text
  Future<void> _shareApp(BuildContext context) async {
    try {
      // Marketing text for sharing
      const String marketingText = '''
🕯️ Master Candlestick Patterns with Candlestick Master!

📈 Learn 40+ candlestick patterns
🎯 Practice with interactive quizzes
📊 Track your learning progress
🌙 Beautiful dark/light mode

Download now and become a trading expert!
https://play.google.com/store/apps/details?id=com.candlestick.master
''';

      // Load the app logo from assets
      final ByteData bytes =
          await rootBundle.load('assets/AppIcons/playstore.png');
      final Uint8List logoBytes = bytes.buffer.asUint8List();

      // Save to temporary directory for sharing
      final tempDir = await getTemporaryDirectory();
      final logoFile = File('${tempDir.path}/candlestick_master_logo.png');
      await logoFile.writeAsBytes(logoBytes);

      // Share with image
      await Share.shareXFiles(
        [XFile(logoFile.path)],
        text: marketingText,
        subject: 'Check out Candlestick Master!',
      );
    } catch (e) {
      // Fallback to text-only sharing if image fails
      debugPrint('Share with image failed: $e');
      await Share.share(
        '🕯️ Master Candlestick Patterns with Candlestick Master!\n\n'
        '📈 Learn 40+ candlestick patterns\n'
        '🎯 Practice with interactive quizzes\n\n'
        'Download: https://play.google.com/store/apps/details?id=com.candlestick.master',
        subject: 'Check out Candlestick Master!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Candlestick Master"),
        automaticallyImplyLeading: false, // Don't show back button
        actions: [
          // Theme Toggle Button
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return IconButton(
                onPressed: () {
                  themeNotifier.toggleTheme(!themeNotifier.isDarkMode);
                },
                icon: Icon(
                  themeNotifier.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: themeNotifier.isDarkMode
                    ? "Switch to Light Mode"
                    : "Switch to Dark Mode",
              );
            },
          ),
          // Share App Button
          IconButton(
            onPressed: () => _shareApp(context),
            icon: const Icon(Icons.share),
            tooltip: "Share App",
          ),
          // TODO: Add notifications in future updates
          // IconButton(
          //   onPressed: () {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(
          //           content: Text('Notifications coming in next update!')),
          //     );
          //   },
          //   icon: const Icon(Icons.notifications),
          // ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent "Start Learning" Header (Replaces Greeting/User Section)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.8),
                    AppColors.primary.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Master the Markets",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Learn pattern recognition to improve your trading strategy.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Cheatsheet Section
            _buildCheatsheetSection(context),

            const SizedBox(height: 24),

            Text("Quick Access", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            _buildActionCard(
              context,
              "Pattern Library",
              "Browse all 40+ candlestick patterns",
              Icons.grid_view,
              Colors.purple,
              () => onTabChange(1), // Switch to Pattern Tab
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              "Practice Quiz",
              "Test your knowledge with quizzes",
              Icons.quiz,
              Colors.green,
              () => onTabChange(2), // Switch to Quiz Tab
            ),
          ],
        ),
      ),
    );
  }

  /// Build the horizontally scrollable cheatsheet section
  Widget _buildCheatsheetSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Pattern Cheatsheet",
                style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => onTabChange(1), // Go to Pattern Library
              child: const Text("See All",
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: Consumer<PatternsNotifier>(
            builder: (context, notifier, child) {
              if (notifier.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final patterns = notifier.patterns;
              if (patterns.isEmpty) {
                return const Center(
                  child: Text("No patterns available",
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              }

              // Show first 10 patterns for cheatsheet (mix of different types)
              final cheatsheetPatterns = patterns.take(10).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: cheatsheetPatterns.length,
                itemBuilder: (context, index) {
                  final pattern = cheatsheetPatterns[index];
                  return _buildCheatsheetCard(context, pattern);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build a single cheatsheet card
  Widget _buildCheatsheetCard(
      BuildContext context, CandlestickPattern pattern) {
    // Determine bias color
    Color biasColor = AppColors.neutral;
    if (pattern.bias == "Bullish") {
      biasColor = AppColors.bullish;
    } else if (pattern.bias == "Bearish") {
      biasColor = AppColors.bearish;
    }

    return GestureDetector(
      onTap: () => _navigateToPattern(context, pattern),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pattern Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 90,
                width: double.infinity,
                color: AppColors.surface,
                child: pattern.imagePath.isNotEmpty
                    ? Image.asset(
                        pattern.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Center(
                          child: Icon(Icons.candlestick_chart,
                              color: AppColors.primary, size: 40),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.candlestick_chart,
                            color: AppColors.primary, size: 40),
                      ),
              ),
            ),
            // Pattern Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pattern.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Bias Tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: biasColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pattern.bias,
                      style: TextStyle(
                        color: biasColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}
