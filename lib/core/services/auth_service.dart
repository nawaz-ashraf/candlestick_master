// =============================================================================
// AuthService - Firebase Authentication Wrapper
// =============================================================================
// Provides a clean API over FirebaseAuth for email/password authentication.
// Singleton pattern ensures consistent state throughout the app.
// =============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  // ============================================
  // Getters
  // ============================================

  /// The currently signed-in user, or null if signed out.
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => currentUser != null;

  /// Stream of authentication state changes (login/logout).
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// The UID of the current user, or null.
  String? get uid => currentUser?.uid;

  // ============================================
  // Email / Password Authentication
  // ============================================

  /// Create a new account with email and password.
  ///
  /// Returns the created [User] on success.
  /// Throws [FirebaseAuthException] on failure.
  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('AuthService: Account created for ${credential.user?.email}');
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Sign-up failed – ${e.code}: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Unexpected sign-up error – $e');
      rethrow;
    }
  }

  /// Sign in with email and password.
  ///
  /// Returns the signed-in [User] on success.
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('AuthService: Signed in as ${credential.user?.email}');
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: Sign-in failed – ${e.code}: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('AuthService: Unexpected sign-in error – $e');
      rethrow;
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('AuthService: Signed out');
    } catch (e) {
      debugPrint('AuthService: Sign-out error – $e');
      rethrow;
    }
  }

  /// Send a password-reset email.
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('AuthService: Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'AuthService: Password reset failed – ${e.code}: ${e.message}');
      rethrow;
    }
  }

  /// Update the user's display name.
  Future<void> updateDisplayName(String name) async {
    try {
      await _auth.currentUser?.updateDisplayName(name.trim());
      await _auth.currentUser?.reload();
      debugPrint('AuthService: Display name updated to $name');
    } catch (e) {
      debugPrint('AuthService: Failed to update display name – $e');
      rethrow;
    }
  }

  /// Delete the current user's account.
  ///
  /// Requires recent authentication — caller should handle
  /// [FirebaseAuthException] with code `requires-recent-login`.
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      debugPrint('AuthService: Account deleted');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'AuthService: Account deletion failed – ${e.code}: ${e.message}');
      rethrow;
    }
  }

  /// Re-authenticate the current user (required before sensitive operations).
  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
      debugPrint('AuthService: Re-authenticated successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'AuthService: Re-authentication failed – ${e.code}: ${e.message}');
      rethrow;
    }
  }

  // ============================================
  // Helpers
  // ============================================

  /// Convert a [FirebaseAuthException] code to a user-friendly message.
  static String friendlyError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Try signing in.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'requires-recent-login':
          return 'Please sign in again before performing this action.';
        case 'invalid-credential':
          return 'Invalid email or password. Please check and try again.';
        default:
          return error.message ?? 'An authentication error occurred.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
