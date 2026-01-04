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

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Background message handler - must be top-level function
/// This is called when app is in background or terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
  debugPrint('Background message received: ${message.messageId}');
  // Note: You can't navigate from here, but you can store data for later
}

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Callback for handling notification taps - set this from your app
  // Usage: FCMService().onNotificationTap = (data) => navigate(data['route']);
  static Function(Map<String, dynamic>)? onNotificationTap;

  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Request permission (iOS and Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
      
      // Get FCM token for this device
      // TODO: Send this token to your server for targeted notifications
      String? token = await _firebaseMessaging.getToken();
      debugPrint("FCM Token: $token");
      
      // Listen for token refresh (happens periodically)
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint("FCM Token refreshed: $newToken");
        // TODO: Send new token to your server
      });
      
      // ========================================
      // Foreground Messages
      // ========================================
      // When app is in foreground, messages arrive here
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message received: ${message.messageId}');
        
        if (message.notification != null) {
          debugPrint('Notification: ${message.notification!.title} - ${message.notification!.body}');
          // TODO: Show in-app notification banner if desired
        }
        
        if (message.data.isNotEmpty) {
          debugPrint('Data payload: ${message.data}');
        }
      });
      
      // ========================================
      // Notification Tap Handling
      // ========================================
      
      // Handle notification tap when app was in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('User tapped notification (from background): ${message.messageId}');
        _handleNotificationTap(message);
      });
      
      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App opened from notification (terminated state)');
        _handleNotificationTap(initialMessage);
      }
      
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined notification permission');
    }
  }
  
  /// Handle notification tap - navigate to appropriate screen
  void _handleNotificationTap(RemoteMessage message) {
    // The notification data can contain routing information
    // Example: {"route": "/pattern", "patternId": "1"}
    if (message.data.isNotEmpty && onNotificationTap != null) {
      onNotificationTap!(message.data);
    }
  }
}
