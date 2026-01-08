// =============================================================================
// Patterns Notifier - State Management for Pattern Library
// =============================================================================
// Manages the state of candlestick patterns for the UI.
// Features:
// - Automatic loading on initialization
// - Error state with retry capability
// - Pattern lookup by ID for deep linking
// - Category filtering (Bullish, Bearish, Neutral, General)
// =============================================================================

import 'package:flutter/foundation.dart';
import '../../data/repositories/pattern_repository.dart';
import '../../data/models/pattern_model.dart';

/// Available filter categories for patterns
enum PatternCategory {
  all,
  bullish,
  bearish,
  neutral,
  general,
}

class PatternsNotifier extends ChangeNotifier {
  final PatternRepository _repository;

  List<CandlestickPattern> _patterns = [];
  bool _isLoading = false;
  String? _error;
  PatternCategory _selectedCategory = PatternCategory.all;

  PatternsNotifier(this._repository) {
    // Load patterns on initialization
    loadPatterns();
  }

  // Getters
  List<CandlestickPattern> get patterns => _patterns;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PatternCategory get selectedCategory => _selectedCategory;

  /// Get patterns filtered by the selected category
  List<CandlestickPattern> get filteredPatterns {
    if (_selectedCategory == PatternCategory.all) {
      return _patterns;
    }

    return _patterns.where((pattern) {
      switch (_selectedCategory) {
        case PatternCategory.bullish:
          return pattern.bias == 'Bullish';
        case PatternCategory.bearish:
          return pattern.bias == 'Bearish';
        case PatternCategory.neutral:
          return pattern.bias == 'Neutral';
        case PatternCategory.general:
          return pattern.category == 'General';
        case PatternCategory.all:
          return true;
      }
    }).toList();
  }

  /// Set the category filter
  void setCategory(PatternCategory category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// Get display name for category
  static String getCategoryDisplayName(PatternCategory category) {
    switch (category) {
      case PatternCategory.all:
        return 'All';
      case PatternCategory.bullish:
        return 'Bullish';
      case PatternCategory.bearish:
        return 'Bearish';
      case PatternCategory.neutral:
        return 'Neutral';
      case PatternCategory.general:
        return 'General';
    }
  }

  /// Get a pattern by its ID - used for deep linking
  CandlestickPattern? getPatternById(String id) {
    try {
      return _patterns.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Load patterns from repository
  /// Can be called multiple times for retry functionality
  Future<void> loadPatterns() async {
    // Prevent duplicate loading
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _patterns = await _repository.getPatterns();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      debugPrint('Pattern loading error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force reload patterns (clears cache)
  Future<void> reloadPatterns() async {
    _repository.clearCache();
    await loadPatterns();
  }
}
