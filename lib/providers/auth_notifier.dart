// =============================================================================
// AuthNotifier - Authentication State Management
// =============================================================================
// ChangeNotifier wrapping AuthService for Provider-based state management.
// Listens to Firebase auth state changes and triggers Firestore sync.
// =============================================================================

import 'dart:async';

import 'package:candlestick_master/core/services/auth_service.dart';
import 'package:candlestick_master/core/services/firestore_service.dart';
import 'package:candlestick_master/core/services/storage_service.dart';
import 'package:candlestick_master/data/repositories/trade_repository.dart';
import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:candlestick_master/providers/trade_notifier.dart';
import 'package:candlestick_master/providers/user_progress_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthNotifier extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSub;

  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthNotifier() {
    try {
      _user = _authService.currentUser;
      _authSub = _authService.authStateChanges.listen(_onAuthStateChanged);
    } catch (_) {}
  }

  // ============================================
  // Getters
  // ============================================

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get displayName =>
      _user?.displayName?.isNotEmpty == true
          ? _user!.displayName!
          : _user?.email?.split('@').first ?? 'Guest';
  String get email => _user?.email ?? '';
  String? get uid => _user?.uid;

  // ============================================
  // Auth State Listener
  // ============================================

  void _onAuthStateChanged(User? user) {
    _user = user;
    notifyListeners();
  }

  // ============================================
  // Actions
  // ============================================

  /// Sign up with email and password.
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
      );

      if (user != null && displayName != null && displayName.isNotEmpty) {
        await _authService.updateDisplayName(displayName);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _error = AuthService.friendlyError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.signIn(email: email, password: password);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = AuthService.friendlyError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Delete user account and all associated cloud and local data.
  Future<bool> deleteAccount({
    GamificationNotifier? gamification,
    TradeNotifier? tradeNotifier,
    UserProgressNotifier? userProgress,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final uid = _user?.uid;
      if (uid != null) {
        await FirestoreService().deleteAllUserData(uid: uid);
        await TradeRepository().deleteAll(userId: uid);
        await StorageService().clearGamificationData(userId: uid);
        tradeNotifier?.clearOnSignOut();
        await gamification?.clearOnSignOut();
        userProgress?.clearOnSignOut();
      }
      await _authService.deleteAccount();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = AuthService.friendlyError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Sign out and clear all user-specific in-memory and listener state.
  Future<void> signOut({
    GamificationNotifier? gamification,
    TradeNotifier? tradeNotifier,
    UserProgressNotifier? userProgress,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // Stop user-specific data from persisting or remaining in active memory
      tradeNotifier?.clearOnSignOut();
      await gamification?.clearOnSignOut();
      userProgress?.clearOnSignOut();

      await _authService.signOut();
    } catch (e) {
      _error = AuthService.friendlyError(e);
    }

    _setLoading(false);
  }

  /// Send password reset email.
  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.resetPassword(email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = AuthService.friendlyError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Sync user progress and trading journal with Firestore on login.
  /// Enforces strict account isolation: switches notifiers to the active user's UID
  /// before touching any data, preventing cross-account contamination.
  Future<void> syncOnLogin(
    GamificationNotifier gamification, {
    TradeNotifier? tradeNotifier,
    UserProgressNotifier? userProgress,
  }) async {
    if (!isAuthenticated || _user == null) return;
    final targetUid = _user!.uid;

    try {
      debugPrint('AuthNotifier: Syncing isolated data for $targetUid');

      // 1. Switch all state notifiers to active user UID immediately
      await gamification.switchUser(targetUid);
      if (tradeNotifier != null) {
        await tradeNotifier.switchUser(targetUid);
      }
      if (userProgress != null) {
        await userProgress.switchUser(targetUid);
      }

      final firestoreService = FirestoreService();

      // 2. Fetch cloud data for this specific user
      final cloudData = await firestoreService.loadUserProgress(
        uid: targetUid,
      );

      if (cloudData != null) {
        // Existing user: merge their own cloud progress into their local state
        await gamification.mergeFromCloud(cloudData);
      } else {
        // First cloud sync for this user: initialize cloud with this user's state
        await firestoreService.saveUserProgress(
          uid: targetUid,
          data: gamification.data.copyWith(userId: targetUid),
        );
      }

      // 3. Load user's cloud trades into isolated local repository
      if (tradeNotifier != null) {
        await tradeNotifier.syncFromCloud();
      }

      debugPrint('AuthNotifier: Sync completed safely for $targetUid');
    } catch (e) {
      debugPrint('AuthNotifier: Sync failed – $e');
    }
  }

  /// Clear error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
