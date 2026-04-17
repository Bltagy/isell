import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Top-level background message handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background/terminated: handled by system tray; navigation on tap
  // is handled via getInitialMessage / onMessageOpenedApp in FcmHandler.init()
}

/// Handles FCM messages for foreground, background, and terminated states.
class FcmHandler {
  FcmHandler._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission
    await FirebaseMessaging.instance.requestPermission();

    // Foreground messages → show SnackBar
    FirebaseMessaging.onMessage.listen((message) {
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body.isNotEmpty) Text(body),
            ],
          ),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _handleNavigation(message.data),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    });

    // Background tap → navigate
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNavigation(message.data);
    });

    // Terminated tap → navigate
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleNavigation(initial.data);
    }
  }

  static void _handleNavigation(Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final type = data['type'] as String?;
    final rawJson = data['data_json'] as String?;
    Map<String, dynamic> payload = {};
    if (rawJson != null) {
      try {
        payload = jsonDecode(rawJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    switch (type) {
      case 'order_status':
        final orderId = data['order_id'] as String? ??
            payload['order_id']?.toString();
        if (orderId != null) {
          navigator.pushNamed('/orders/$orderId/track');
        }
        break;
      case 'new_order':
        navigator.pushNamed('/orders');
        break;
      default:
        navigator.pushNamed('/notifications');
    }
  }
}
