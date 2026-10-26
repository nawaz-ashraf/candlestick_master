// =============================================================================
// AuthNotifier - Authentication State Management
// =============================================================================
// ChangeNotifier wrapping AuthService for Provider-based state management.
// Listens to Firebase auth state changes and triggers Firestore sync.
// =============================================================================

import 'dart:async';

import 'package:candlestick_master/core/services/auth_service.dart';
import 'package:candlestick_master/core/services/firestore_service.dart';
import 'package:candlestick_master/providers/gamification_notifier.dart';
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

  /// Delete user account and all associated cloud data.
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _error = null;

    try {
      final uid = _user?.uid;
      if (uid != null) {
        await FirestoreService().deleteAllUserData(uid: uid);
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

  /// Sign out.
  Future<void> signOut() async {
    _setLoading(true);
    _error = null;

    try {
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

  /// Sync local progress to Firestore on login.
  Future<void> syncOnLogin(GamificationNotifier gamification) async {
    if (!isAuthenticated || _user == null) return;

    try {
      debugPrint('AuthNotifier: Syncing data for ${_user!.uid}');
      final firestoreService = FirestoreService();

      // Upload local progress to cloud
      await firestoreService.saveUserProgress(
        uid: _user!.uid,
        data: gamification.data,
      );

      // Try to merge cloud data (cloud wins for higher values)
      final cloudData = await firestoreService.loadUserProgress(
        uid: _user!.uid,
      );

      if (cloudData != null) {
        await gamification.mergeFromCloud(cloudData);
      }

      debugPrint('AuthNotifier: Sync completed');
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
