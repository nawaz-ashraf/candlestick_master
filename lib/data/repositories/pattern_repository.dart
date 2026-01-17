// =============================================================================
// Pattern Repository - Data Access Layer
// =============================================================================
// Handles loading candlestick patterns from local JSON asset.
// Features:
// - Timeout handling (prevents infinite loading)
// - Error handling with meaningful messages
// - Caching for performance
// =============================================================================
//TODO: Commenting and documentation
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/pattern_model.dart';

class PatternRepository {
  // Cache patterns after first load
  List<CandlestickPattern>? _cachedPatterns;

  /// Loads patterns from the local JSON asset
  /// Throws exception if loading fails or times out
  Future<List<CandlestickPattern>> getPatterns() async {
    // Return cached data if available
    if (_cachedPatterns != null && _cachedPatterns!.isNotEmpty) {
      return _cachedPatterns!;
    }

    try {
      // Add timeout to prevent infinite loading
      final String response =
          await rootBundle.loadString('assets/patterns.json').timeout(
                const Duration(seconds: 10),
                onTimeout: () =>
                    throw TimeoutException('Failed to load patterns: timeout'),
              );

      final List<dynamic> data = json.decode(response);
      _cachedPatterns =
          data.map((json) => CandlestickPattern.fromJson(json)).toList();
      return _cachedPatterns!;
    } on TimeoutException {
      throw Exception('Loading patterns timed out. Please try again.');
    } on FormatException catch (e) {
      throw Exception('Invalid pattern data format: $e');
    } catch (e) {
      throw Exception('Failed to load patterns: $e');
    }
  }

  /// Clear cache to force reload
  void clearCache() {
    _cachedPatterns = null;
  }
}
