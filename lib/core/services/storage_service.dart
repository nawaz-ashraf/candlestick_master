// =============================================================================
// StorageService - SharedPreferences Wrapper for Gamification Data
// =============================================================================
// Provides JSON-based persistence for the GamificationData model.
// Uses a single SharedPreferences key to store the entire gamification state.
// =============================================================================

import 'dart:convert';

import 'package:candlestick_master/models/habit_user_progress.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _gamificationKey = 'gamification_data';

  /// Save gamification data to SharedPreferences as JSON
  Future<void> saveGamificationData(UserProgress data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data.toJson());
      await prefs.setString(_gamificationKey, jsonString);
    } catch (e) {
      debugPrint('StorageService: Error saving gamification data - $e');
    }
  }

  /// Load gamification data from SharedPreferences
  /// Returns default UserProgress if no data exists or on error
  Future<UserProgress> loadGamificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_gamificationKey);

      if (jsonString == null || jsonString.isEmpty) {
        return const UserProgress();
      }

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProgress.fromJson(jsonMap);
    } catch (e) {
      debugPrint('StorageService: Error loading gamification data - $e');
      return const UserProgress();
    }
  }

  /// Clear all gamification data (for reset functionality)
  Future<void> clearGamificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_gamificationKey);
    } catch (e) {
      debugPrint('StorageService: Error clearing gamification data - $e');
    }
  }
}
