// =============================================================================
// FirestoreService - Cloud Firestore Data Sync
// =============================================================================
// Manages reading/writing user data to Cloud Firestore for cross-device sync.
//
// Collection structure:
//   users/{uid}/
//     - progress (document): UserProgress data
//     - journal (subcollection): Trading Journal entries
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:candlestick_master/models/habit_user_progress.dart';
import 'package:candlestick_master/models/trade_model.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  // Singleton
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ============================================
  // User Progress
  // ============================================

  /// Reference to the user's progress document.
  DocumentReference _progressDoc(String uid) =>
      _db.collection('users').doc(uid).collection('data').doc('progress');

  /// Save user progress to Firestore (merge to avoid overwriting).
  Future<void> saveUserProgress({
    required String uid,
    required UserProgress data,
  }) async {
    try {
      await _progressDoc(uid).set(
        {
          ...data.toJson(),
          'lastSyncedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('FirestoreService: Progress saved for $uid');
    } catch (e) {
      debugPrint('FirestoreService: Failed to save progress – $e');
    }
  }

  /// Load user progress from Firestore.
  ///
  /// Returns null if no data exists.
  Future<UserProgress?> loadUserProgress({required String uid}) async {
    try {
      final doc = await _progressDoc(uid).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data() as Map<String, dynamic>;
      debugPrint('FirestoreService: Progress loaded for $uid');
      return UserProgress.fromJson(data);
    } catch (e) {
      debugPrint('FirestoreService: Failed to load progress – $e');
      return null;
    }
  }

  // ============================================
  // Trading Journal
  // ============================================

  /// Reference to the user's journal subcollection.
  CollectionReference _journalCollection(String uid) =>
      _db.collection('users').doc(uid).collection('journal');

  /// Save a single trade to Firestore.
  Future<void> saveTrade({
    required String uid,
    required Trade trade,
  }) async {
    try {
      await _journalCollection(uid).doc(trade.id).set(
            trade.toJson(),
            SetOptions(merge: true),
          );
      debugPrint('FirestoreService: Trade ${trade.id} saved');
    } catch (e) {
      debugPrint('FirestoreService: Failed to save trade – $e');
    }
  }

  /// Delete a trade from Firestore.
  Future<void> deleteTrade({
    required String uid,
    required String tradeId,
  }) async {
    try {
      await _journalCollection(uid).doc(tradeId).delete();
      debugPrint('FirestoreService: Trade $tradeId deleted');
    } catch (e) {
      debugPrint('FirestoreService: Failed to delete trade – $e');
    }
  }

  /// Load all trades for a user from Firestore.
  Future<List<Trade>> loadTrades({required String uid}) async {
    try {
      final snapshot = await _journalCollection(uid)
          .orderBy('createdAt', descending: true)
          .get();

      final trades = snapshot.docs
          .map((doc) => Trade.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      debugPrint('FirestoreService: Loaded ${trades.length} trades for $uid');
      return trades;
    } catch (e) {
      debugPrint('FirestoreService: Failed to load trades – $e');
      return [];
    }
  }

  /// Batch-upload all local trades to Firestore.
  Future<void> syncAllTrades({
    required String uid,
    required List<Trade> trades,
  }) async {
    try {
      final batch = _db.batch();
      for (final trade in trades) {
        batch.set(
          _journalCollection(uid).doc(trade.id),
          trade.toJson(),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      debugPrint(
          'FirestoreService: Batch-synced ${trades.length} trades for $uid');
    } catch (e) {
      debugPrint('FirestoreService: Batch trade sync failed – $e');
    }
  }

  // ============================================
  // Account Cleanup
  // ============================================

  /// Delete all user data from Firestore (for account deletion).
  Future<void> deleteAllUserData({required String uid}) async {
    try {
      // Delete journal entries
      final journalDocs = await _journalCollection(uid).get();
      final batch = _db.batch();
      for (final doc in journalDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete progress document
      batch.delete(_progressDoc(uid));

      await batch.commit();
      debugPrint('FirestoreService: All data deleted for $uid');
    } catch (e) {
      debugPrint('FirestoreService: Failed to delete user data – $e');
    }
  }
}
