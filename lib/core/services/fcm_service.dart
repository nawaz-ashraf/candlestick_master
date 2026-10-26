// =============================================================================
// FCMService - Firebase Cloud Messaging (Push Notifications)
// =============================================================================
// Handles push notifications for user re-engagement and marketing.
// Features:
// - Permission request
// - Token management (for targeted notifications)
// - Foreground message handling
// - Background message handling
// - Notification tap navigation (deep linking)
//
// TODO: Implement server-side notification sending using the FCM token
// =============================================================================

import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/foundation.dart";

/// Background message handler - must be top-level function
/// This is called when app is in background or terminated
@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Background message received: ${message.messageId}");
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Callback for handling notification taps
  static Function(Map<String, dynamic>)? onNotificationTap;

  Future<void> initialize() async {
    try {
      // Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission (iOS and Android 13+)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint("User granted notification permission");

        // Safely retrieve token without crashing if FIS_AUTH_ERROR occurs
        try {
          String? token = await _firebaseMessaging.getToken();
          debugPrint("FCM Token: $token");
        } catch (e) {
          debugPrint(
            "FCMService: Could not retrieve FCM token ($e). "
            "Ensure Firebase Installations API is enabled and SHA-1 is added in Firebase Console.",
          );
        }

        try {
          _firebaseMessaging.onTokenRefresh.listen((newToken) {
            debugPrint("FCM Token refreshed: $newToken");
          });
        } catch (e) {
          debugPrint("FCMService: Token refresh listener error: $e");
        }

        // ========================================
        // Foreground Messages
        // ========================================
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint("Foreground message received: ${message.messageId}");

          if (message.notification != null) {
            debugPrint(
              "Notification: ${message.notification!.title} - ${message.notification!.body}",
            );
          }

          if (message.data.isNotEmpty) {
            debugPrint("Data payload: ${message.data}");
          }
        });

        // ========================================
        // Notification Tap Handling
        // ========================================
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint("User tapped notification (from background): ${message.messageId}");
          _handleNotificationTap(message);
        });

        RemoteMessage? initialMessage =
            await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint("App opened from notification (terminated state)");
          _handleNotificationTap(initialMessage);
        }
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint("User granted provisional permission");
      } else {
        debugPrint("User declined notification permission");
      }
    } catch (e) {
      debugPrint("FCMService initialization error: $e");
    }
  }

  /// Handle notification tap - navigate to appropriate screen
  void _handleNotificationTap(RemoteMessage message) {
    if (message.data.isNotEmpty && onNotificationTap != null) {
      onNotificationTap!(message.data);
    }
  }
}
