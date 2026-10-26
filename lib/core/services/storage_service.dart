// =============================================================================
// StorageService - SharedPreferences Wrapper for Gamification Data
// =============================================================================
// Provides JSON-based persistence for the GamificationData model.
// Enforces strict account isolation via user-scoped SharedPreferences keys.
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

  static const String _legacyGamificationKey = 'gamification_data';

  /// Derive user-scoped SharedPreferences storage key.
  static String gamificationKey([String? userId]) {
    final uid = (userId != null && userId.trim().isNotEmpty) ? userId.trim() : 'guest';
    return 'gamification_data_$uid';
  }

  /// Save gamification data to SharedPreferences as JSON scoped to a specific user.
  Future<bool> saveGamificationData(UserProgress data, {String? userId}) async {
    try {
      final targetUid = (userId != null && userId.trim().isNotEmpty)
          ? userId.trim()
          : (data.userId.trim().isNotEmpty ? data.userId.trim() : 'guest');
      final key = gamificationKey(targetUid);
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data.toJson());
      final success = await prefs.setString(key, jsonString);
      if (!success) {
        debugPrint('StorageService: SharedPreferences.setString returned false for key $key');
      }
      return success;
    } catch (e) {
      debugPrint('StorageService: Error saving gamification data - $e');
      return false;
    }
  }

  /// Load gamification data from SharedPreferences for a specific user.
  /// Returns default UserProgress if no data exists or on error.
  Future<UserProgress> loadGamificationData({String? userId}) async {
    try {
      final targetUid = (userId != null && userId.trim().isNotEmpty) ? userId.trim() : 'guest';
      final key = gamificationKey(targetUid);
      final prefs = await SharedPreferences.getInstance();
      var jsonString = prefs.getString(key);

      // Safe migration for legacy unauthenticated data:
      // If reading for 'guest' and no guest-specific key exists, check legacy un-scoped key once.
      // For signed-in users, never load legacy or unassociated data!
      if ((jsonString == null || jsonString.isEmpty) && targetUid == 'guest') {
        final legacyData = prefs.getString(_legacyGamificationKey);
        if (legacyData != null && legacyData.isNotEmpty) {
          jsonString = legacyData;
          await prefs.setString(key, legacyData);
          await prefs.remove(_legacyGamificationKey);
          debugPrint('StorageService: Migrated legacy gamification data to guest storage');
        }
      }

      if (jsonString == null || jsonString.isEmpty) {
        return UserProgress(userId: targetUid);
      }

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final loaded = UserProgress.fromJson(jsonMap);
      if (loaded.userId != targetUid) {
        return loaded.copyWith(userId: targetUid);
      }
      return loaded;
    } catch (e) {
      debugPrint('StorageService: Error loading gamification data - $e');
      final fallbackUid = (userId != null && userId.trim().isNotEmpty) ? userId.trim() : 'guest';
      return UserProgress(userId: fallbackUid);
    }
  }

  /// Clear gamification data for a specific user (or guest).
  Future<void> clearGamificationData({String? userId}) async {
    try {
      final key = gamificationKey(userId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      debugPrint('StorageService: Cleared gamification data for key $key');
    } catch (e) {
      debugPrint('StorageService: Error clearing gamification data - $e');
    }
  }
}
