// =============================================================================
// FirestoreService - Cloud Firestore User Profiles, Stats & Data Sync
// =============================================================================
// Manages reading/writing user data to Cloud Firestore for cross-device sync.
//
// Structured Collection Hierarchy:
//   users/{uid} (root user profile document)
//     ├── stats/
//     │     ├── learning (learning progress summary: XP, levels, streaks, counts)
//     │     ├── trading  (trading journal analytics: win rate, P/L, counts)
//     │     └── activity (engagement timestamps & session recency)
//     ├── patternProgress/{patternId} (individual candlestick pattern status)
//     ├── indicatorProgress/{indicatorId} (individual indicator status)
//     ├── quizAttempts/{attemptId} (quiz results & accuracy)
//     ├── challengeAttempts/{attemptId} (daily/library challenge completions)
//     ├── trades/{tradeId} (user Trading Journal records)
//     ├── journal/{tradeId} (backward-compatible mirror for legacy trades)
//     └── data/progress (backward-compatible UserProgress document)
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
  // User Profile (users/{uid})
  // ============================================

  DocumentReference _userDoc(String uid) => _db.collection('users').doc(uid);

  /// Save or update user profile under users/{uid}.
  /// Never stores passwords, hashes, or sensitive tokens.
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String preferredTheme = 'dark',
    bool onboardingCompleted = true,
  }) async {
    try {
      final docRef = _userDoc(uid);
      final docSnapshot = await docRef.get();

      final data = <String, dynamic>{
        'uid': uid,
        'email': email,
        'preferredTheme': preferredTheme,
        'accountStatus': 'active',
        'onboardingCompleted': onboardingCompleted,
        'schemaVersion': 2,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null && displayName.trim().isNotEmpty) {
        data['displayName'] = displayName.trim();
      }

      if (!docSnapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(data, SetOptions(merge: true));
      debugPrint('FirestoreService: Profile saved under users/$uid');
    } catch (e) {
      debugPrint('FirestoreService: Failed to save user profile – $e');
    }
  }

  /// Get user profile document.
  Future<Map<String, dynamic>?> getUserProfile({required String uid}) async {
    try {
      final snapshot = await _userDoc(uid).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return snapshot.data() as Map<String, dynamic>;
    } catch (e) {
      debugPrint('FirestoreService: Failed to get user profile – $e');
      return null;
    }
  }

  // ============================================
  // Activity Tracking (users/{uid}/stats/activity)
  // ============================================

  DocumentReference _activityDoc(String uid) =>
      _db.collection('users').doc(uid).collection('stats').doc('activity');

  /// Update last active timestamp for engagement tracking.
  Future<void> updateLastActive({required String uid}) async {
    try {
      await _userDoc(uid).set({
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _activityDoc(uid).set({
        'lastActiveAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ============================================
  // Learning Progress & Summary (users/{uid}/stats/learning)
  // ============================================

  DocumentReference _learningStatsDoc(String uid) =>
      _db.collection('users').doc(uid).collection('stats').doc('learning');

  DocumentReference _progressDoc(String uid) =>
      _db.collection('users').doc(uid).collection('data').doc('progress');

  /// Save user progress to Firestore and maintain structured stats/learning document.
  Future<void> saveUserProgress({
    required String uid,
    required UserProgress data,
    int totalQuizzes = 0,
  }) async {
    try {
      // 1. Maintain backward-compatible data/progress doc
      await _progressDoc(uid).set(
        {
          ...data.toJson(),
          'lastSyncedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 2. Save structured stats/learning document
      await saveLearningStats(
        uid: uid,
        progress: data,
        totalQuizzes: totalQuizzes,
      );

      // 3. Batch write individual pattern progress
      final batch = _db.batch();
      for (final patternId in data.completedLessons) {
        if (patternId.trim().isEmpty) continue;
        final docRef = _patternDoc(uid, patternId);
        batch.set(
          docRef,
          {
            'patternId': patternId,
            'isCompleted': true,
            'completedAt': FieldValue.serverTimestamp(),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // 4. Batch write individual indicator progress
      for (final indicatorId in data.completedIndicators) {
        if (indicatorId.trim().isEmpty) continue;
        final docRef = _indicatorDoc(uid, indicatorId);
        batch.set(
          docRef,
          {
            'indicatorId': indicatorId,
            'isCompleted': true,
            'completedAt': FieldValue.serverTimestamp(),
            'lastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      // 5. Update activity doc
      await _activityDoc(uid).set({
        'lastLessonCompletedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FirestoreService: User progress and subcollections synced for $uid');
    } catch (e) {
      debugPrint('FirestoreService: Failed to save progress – $e');
    }
  }

  /// Save structured learning summary under users/{uid}/stats/learning.
  Future<void> saveLearningStats({
    required String uid,
    required UserProgress progress,
    int totalQuizzes = 0,
  }) async {
    try {
      await _learningStatsDoc(uid).set({
        'totalPatternsCompleted': progress.completedLessons.length,
        'totalIndicatorsCompleted': progress.completedIndicators.length,
        'totalQuizzesCompleted': totalQuizzes,
        'totalChallengesCompleted': progress.completedChallenges.length,
        'totalXp': progress.xp,
        'currentLevel': progress.level,
        'currentStreak': progress.streak,
        'longestStreak': progress.bestStreak,
        'coins': progress.coins,
        'lastLearningDate': progress.lastActiveDate,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: Failed to save learning stats – $e');
    }
  }

  /// Load user progress from Firestore.
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
  // Individual Pattern & Indicator Progress
  // ============================================

  DocumentReference _patternDoc(String uid, String patternId) =>
      _db.collection('users').doc(uid).collection('patternProgress').doc(patternId);

  DocumentReference _indicatorDoc(String uid, String indicatorId) =>
      _db.collection('users').doc(uid).collection('indicatorProgress').doc(indicatorId);

  /// Record completion or study of a specific candlestick pattern.
  Future<void> savePatternProgress({
    required String uid,
    required String patternId,
    String? patternName,
    required bool isCompleted,
  }) async {
    try {
      await _patternDoc(uid, patternId).set({
        'patternId': patternId,
        if (patternName != null && patternName.isNotEmpty) 'patternName': patternName,
        'isCompleted': isCompleted,
        if (isCompleted) 'completedAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _activityDoc(uid).set({
        'lastLessonCompletedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: Failed to save pattern progress – $e');
    }
  }

  /// Record completion or study of a specific technical indicator.
  Future<void> saveIndicatorProgress({
    required String uid,
    required String indicatorId,
    String? indicatorName,
    required bool isCompleted,
  }) async {
    try {
      await _indicatorDoc(uid, indicatorId).set({
        'indicatorId': indicatorId,
        if (indicatorName != null && indicatorName.isNotEmpty) 'indicatorName': indicatorName,
        'isCompleted': isCompleted,
        if (isCompleted) 'completedAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _activityDoc(uid).set({
        'lastActiveAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: Failed to save indicator progress – $e');
    }
  }

  // ============================================
  // Quiz & Challenge Attempts
  // ============================================

  /// Record a completed quiz attempt under users/{uid}/quizAttempts/{attemptId}.
  Future<void> saveQuizAttempt({
    required String uid,
    required String attemptId,
    required String difficulty,
    required int score,
    required int totalQuestions,
    required int correctAnswers,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('quizAttempts')
          .doc(attemptId)
          .set({
        'attemptId': attemptId,
        'difficulty': difficulty,
        'score': score,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'completed': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _activityDoc(uid).set({
        'lastQuizCompletedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('FirestoreService: Quiz attempt $attemptId saved for $uid');
    } catch (e) {
      debugPrint('FirestoreService: Failed to save quiz attempt – $e');
    }
  }

  /// Record a challenge attempt under users/{uid}/challengeAttempts/{attemptId}.
  Future<void> saveChallengeAttempt({
    required String uid,
    required String attemptId,
    required String challengeId,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('challengeAttempts')
          .doc(attemptId)
          .set({
        'attemptId': attemptId,
        'challengeId': challengeId,
        'completed': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _activityDoc(uid).set({
        'lastActiveAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('FirestoreService: Challenge attempt $attemptId saved for $uid');
    } catch (e) {
      debugPrint('FirestoreService: Failed to save challenge attempt – $e');
    }
  }

  // ============================================
  // Trading Journal (users/{uid}/trades) & Summary
  // ============================================

  CollectionReference _tradesCollection(String uid) =>
      _db.collection('users').doc(uid).collection('trades');

  CollectionReference _journalCollection(String uid) =>
      _db.collection('users').doc(uid).collection('journal');

  DocumentReference _tradingStatsDoc(String uid) =>
      _db.collection('users').doc(uid).collection('stats').doc('trading');

  /// Save a single trade to users/{uid}/trades/{tradeId} and mirror to journal for backward compatibility.
  Future<void> saveTrade({
    required String uid,
    required Trade trade,
  }) async {
    try {
      final data = trade.toJson();
      // Primary structured collection
      await _tradesCollection(uid).doc(trade.id).set(
            data,
            SetOptions(merge: true),
          );
      // Mirror to legacy journal collection
      await _journalCollection(uid).doc(trade.id).set(
            data,
            SetOptions(merge: true),
          );

      await _activityDoc(uid).set({
        'lastTradeCreatedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FirestoreService: Trade ${trade.id} saved in trades & journal');
    } catch (e) {
      debugPrint('FirestoreService: Failed to save trade – $e');
    }
  }

  /// Delete a trade from both trades and legacy journal collections.
  Future<void> deleteTrade({
    required String uid,
    required String tradeId,
  }) async {
    try {
      await _tradesCollection(uid).doc(tradeId).delete();
      await _journalCollection(uid).doc(tradeId).delete();
      debugPrint('FirestoreService: Trade $tradeId deleted from cloud');
    } catch (e) {
      debugPrint('FirestoreService: Failed to delete trade – $e');
    }
  }

  /// Load all trades for a user from Firestore (primary: trades, fallback: journal).
  Future<List<Trade>> loadTrades({required String uid}) async {
    try {
      // 1. Try reading from primary 'trades' collection
      var snapshot = await _tradesCollection(uid)
          .orderBy('createdAt', descending: true)
          .get();

      // 2. If empty, check legacy 'journal' collection
      if (snapshot.docs.isEmpty) {
        snapshot = await _journalCollection(uid)
            .orderBy('createdAt', descending: true)
            .get();

        // Migrate legacy journal docs to primary trades collection
        if (snapshot.docs.isNotEmpty) {
          final batch = _db.batch();
          for (final doc in snapshot.docs) {
            batch.set(
              _tradesCollection(uid).doc(doc.id),
              doc.data() as Map<String, dynamic>,
              SetOptions(merge: true),
            );
          }
          await batch.commit();
          debugPrint(
              'FirestoreService: Migrated ${snapshot.docs.length} legacy journal trades to trades collection');
        }
      }

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

  /// Batch-upload trades to Firestore and update stats/trading.
  Future<void> syncAllTrades({
    required String uid,
    required List<Trade> trades,
  }) async {
    try {
      final batch = _db.batch();
      for (final trade in trades) {
        batch.set(
          _tradesCollection(uid).doc(trade.id),
          trade.toJson(),
          SetOptions(merge: true),
        );
        batch.set(
          _journalCollection(uid).doc(trade.id),
          trade.toJson(),
          SetOptions(merge: true),
        );
      }
      await batch.commit();

      // Save summary statistics
      await saveTradingStats(uid: uid, trades: trades);

      debugPrint('FirestoreService: Batch-synced ${trades.length} trades for $uid');
    } catch (e) {
      debugPrint('FirestoreService: Batch trade sync failed – $e');
    }
  }

  /// Calculate and save Trading Journal summary under users/{uid}/stats/trading.
  Future<void> saveTradingStats({
    required String uid,
    required List<Trade> trades,
  }) async {
    try {
      final closedTrades = trades
          .where((t) => t.status == TradeStatus.closed && t.exitPrice != null)
          .toList();
      final openTrades =
          trades.where((t) => t.status == TradeStatus.open).toList();

      final winningTrades =
          closedTrades.where((t) => (t.pnl ?? 0) > 0).toList();
      final losingTrades =
          closedTrades.where((t) => (t.pnl ?? 0) < 0).toList();

      final grossProfit = winningTrades.fold<double>(
          0.0, (acc, t) => acc + (t.pnl ?? 0));
      final grossLoss = losingTrades.fold<double>(
          0.0, (acc, t) => acc + (t.pnl ?? 0).abs());
      final netPnl = closedTrades.fold<double>(
          0.0, (acc, t) => acc + (t.pnl ?? 0));

      final winRate = closedTrades.isNotEmpty
          ? (winningTrades.length / closedTrades.length) * 100
          : 0.0;
      final averageWin = winningTrades.isNotEmpty
          ? grossProfit / winningTrades.length
          : 0.0;
      final averageLoss = losingTrades.isNotEmpty
          ? grossLoss / losingTrades.length
          : 0.0;

      await _tradingStatsDoc(uid).set({
        'totalTrades': trades.length,
        'openTrades': openTrades.length,
        'closedTrades': closedTrades.length,
        'winningTrades': winningTrades.length,
        'losingTrades': losingTrades.length,
        'winRate': double.parse(winRate.toStringAsFixed(2)),
        'grossProfit': double.parse(grossProfit.toStringAsFixed(2)),
        'grossLoss': double.parse(grossLoss.toStringAsFixed(2)),
        'netProfitLoss': double.parse(netPnl.toStringAsFixed(2)),
        'averageWin': double.parse(averageWin.toStringAsFixed(2)),
        'averageLoss': double.parse(averageLoss.toStringAsFixed(2)),
        'lastTradeAt': trades.isNotEmpty
            ? trades.first.createdAt.toIso8601String()
            : null,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FirestoreService: Trading stats saved for $uid');
    } catch (e) {
      debugPrint('FirestoreService: Failed to save trading stats – $e');
    }
  }

  // ============================================
  // Legacy Migration Helper
  // ============================================

  /// Inspect users collection and safely migrate any random-ID documents containing 'uid'.
  Future<void> migrateLegacyUserDocuments() async {
    try {
      final snapshot = await _db.collection('users').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawUid = data['uid'] as String?;
        // If document contains a uid field and doc ID is a random generated ID
        if (rawUid != null && rawUid.isNotEmpty && doc.id != rawUid) {
          debugPrint('FirestoreService: Found legacy doc ${doc.id} for user $rawUid. Migrating...');
          await _userDoc(rawUid).set(data, SetOptions(merge: true));
          await doc.reference.set({
            'migratedTo': rawUid,
            'migratedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('FirestoreService: Legacy migration check completed – $e');
    }
  }

  // ============================================
  // Account Cleanup & Deletion
  // ============================================

  /// Delete all user data from Firestore (for account deletion).
  Future<void> deleteAllUserData({required String uid}) async {
    try {
      final batch = _db.batch();

      // Delete trades
      final tradeDocs = await _tradesCollection(uid).get();
      for (final doc in tradeDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete legacy journal entries
      final journalDocs = await _journalCollection(uid).get();
      for (final doc in journalDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete patternProgress
      final patternDocs = await _db.collection('users').doc(uid).collection('patternProgress').get();
      for (final doc in patternDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete indicatorProgress
      final indicatorDocs = await _db.collection('users').doc(uid).collection('indicatorProgress').get();
      for (final doc in indicatorDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete quizAttempts
      final quizDocs = await _db.collection('users').doc(uid).collection('quizAttempts').get();
      for (final doc in quizDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete challengeAttempts
      final challengeDocs = await _db.collection('users').doc(uid).collection('challengeAttempts').get();
      for (final doc in challengeDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete stats docs
      final statsDocs = await _db.collection('users').doc(uid).collection('stats').get();
      for (final doc in statsDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete progress document
      batch.delete(_progressDoc(uid));

      // Delete root user profile document
      batch.delete(_userDoc(uid));

      await batch.commit();
      debugPrint('FirestoreService: All user data permanently deleted for $uid');
    } catch (e) {
      debugPrint('FirestoreService: Failed to delete user data – $e');
    }
  }
}
