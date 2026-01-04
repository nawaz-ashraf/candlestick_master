// =============================================================================
// Patterns Notifier - State Management for Pattern Library
// =============================================================================
// Manages the state of candlestick patterns for the UI.
// Features:
// - Automatic loading on initialization
// - Error state with retry capability
// - Pattern lookup by ID for deep linking
// =============================================================================

import 'package:flutter/foundation.dart';
import '../../data/repositories/pattern_repository.dart';
import '../../data/models/pattern_model.dart';

class PatternsNotifier extends ChangeNotifier {
  final PatternRepository _repository;
  
  List<CandlestickPattern> _patterns = [];
  bool _isLoading = false;
  String? _error;

  PatternsNotifier(this._repository) {
    // Load patterns on initialization
    loadPatterns();
  }

  // Getters
  List<CandlestickPattern> get patterns => _patterns;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
