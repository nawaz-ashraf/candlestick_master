// =============================================================================
// Pattern Library Screen
// =============================================================================
// Displays all candlestick patterns in a scrollable list.
// Features:
// - Loading state with spinner
// - Error state with retry button
// - Category filtering (All, Bullish, Bearish, Neutral, General)
// - Interstitial ad on pattern tap (high-intent action)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/pattern_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/ad_service.dart';
import '../../../data/models/pattern_model.dart';

class PatternLibraryScreen extends StatelessWidget {
  const PatternLibraryScreen({super.key});

  /// Show interstitial ad before navigating to pattern detail
  /// Ad is non-blocking - navigation continues even if ad fails
  Future<void> _navigateToPattern(
      BuildContext context, CandlestickPattern pattern) async {
    // Show interstitial ad (non-blocking)
    await AdService.instance.showInterstitialAd();

    // Navigate to pattern detail
    if (context.mounted) {
      context.push('/pattern/${pattern.id}', extra: pattern);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pattern Library"),
      ),
      body: Consumer<PatternsNotifier>(
        builder: (context, notifier, child) {
          // Loading State
          if (notifier.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading patterns...",
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          // Error State with Retry Button
          if (notifier.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: AppColors.bearish),
                    const SizedBox(height: 16),
                    Text(
                      notifier.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => notifier.reloadPatterns(),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty State (no patterns at all)
          if (notifier.patterns.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text("No patterns found.",
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => notifier.reloadPatterns(),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reload"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          // Get filtered patterns
          final filteredPatterns = notifier.filteredPatterns;

          // Pattern list with filter chips
          return Column(
            children: [
              // Category Filter Chips
              _buildCategoryFilters(context, notifier),

              // Divider
              const Divider(height: 1),

              // Pattern List or Empty Filtered State
              Expanded(
                child: filteredPatterns.isEmpty
                    ? _buildEmptyFilteredState(context, notifier)
                    : ListView.builder(
                        itemCount: filteredPatterns.length,
                        itemBuilder: (context, index) {
                          final pattern = filteredPatterns[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: _buildLeadingIcon(pattern),
                              title: Text(pattern.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                "${pattern.category} • ${pattern.difficulty}",
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(Icons.chevron_right,
                                  color: AppColors.textSecondary),
                              onTap: () => _navigateToPattern(context, pattern),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build the category filter chips section
  Widget _buildCategoryFilters(
      BuildContext context, PatternsNotifier notifier) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: PatternCategory.values.map((category) {
          final isSelected = notifier.selectedCategory == category;
          final displayName = PatternsNotifier.getCategoryDisplayName(category);

          // Assign colors to each category
          Color chipColor = AppColors.primary;
          if (category == PatternCategory.bullish) {
            chipColor = AppColors.bullish;
          } else if (category == PatternCategory.bearish) {
            chipColor = AppColors.bearish;
          } else if (category == PatternCategory.neutral) {
            chipColor = AppColors.neutral;
          } else if (category == PatternCategory.general) {
            chipColor = Colors.blue;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(displayName),
              selected: isSelected,
              onSelected: (_) => notifier.setCategory(category),
              selectedColor: chipColor.withOpacity(0.2),
              checkmarkColor: chipColor,
              labelStyle: TextStyle(
                color: isSelected ? chipColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? chipColor : AppColors.divider,
              ),
              backgroundColor: Theme.of(context).cardColor,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build empty state for filtered results
  Widget _buildEmptyFilteredState(
      BuildContext context, PatternsNotifier notifier) {
    final categoryName =
        PatternsNotifier.getCategoryDisplayName(notifier.selectedCategory);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            "No $categoryName patterns found.",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => notifier.setCategory(PatternCategory.all),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Show All Patterns"),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(CandlestickPattern pattern) {
    Color color = AppColors.neutral;
    IconData icon = Icons.candlestick_chart;

    if (pattern.bias == "Bullish") {
      color = AppColors.bullish;
      icon = Icons.trending_up;
    } else if (pattern.bias == "Bearish") {
      color = AppColors.bearish;
      icon = Icons.trending_down;
    } else if (pattern.category == "General") {
      color = Colors.blue;
      icon = Icons.menu_book;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }
}
