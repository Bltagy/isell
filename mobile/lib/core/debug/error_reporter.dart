import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/storage_service.dart';

/// Sends Flutter errors and events to the Laravel backend so they appear
/// in Telescope → Logs. Only active in debug builds.
class ErrorReporter {
  ErrorReporter._();

  static const String _appVersion = '1.0.0';

  static Dio? _dio;

  static Dio get _client {
    _dio ??= Dio(
      BaseOptions(
        baseUrl: StorageService().getBaseUrl(),
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      ),
    );
    return _dio!;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Call once in main() before runApp().
  static void init() {
    if (!kDebugMode) return;

    // Catch all Flutter framework errors (widget build errors, etc.)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details); // still print to console
      _send(
        type: 'flutter_error',
        message: details.exceptionAsString(),
        stack: details.stack?.toString(),
        context: {'library': details.library ?? 'unknown'},
      );
    };

    // Catch all async/zone errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _send(
        type: 'error',
        message: error.toString(),
        stack: stack.toString(),
      );
      return false; // let the default handler also run
    };
  }

  /// Report an API error manually (call from catch blocks).
  static void reportApiError({
    required String message,
    String? route,
    Map<String, dynamic>? extra,
  }) {
    if (!kDebugMode) return;
    _send(
      type: 'api_error',
      message: message,
      context: {'route': route, ...?extra},
    );
  }

  /// Report a named event (e.g. "order_placed", "login_failed").
  static void event(String name, [Map<String, dynamic>? data]) {
    if (!kDebugMode) return;
    _send(type: 'event', message: name, context: data);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static void _send({
    required String type,
    required String message,
    String? stack,
    Map<String, dynamic>? context,
  }) {
    // Fire-and-forget — never await, never throw
    unawaited(_doSend(type: type, message: message, stack: stack, context: context));
  }

  static Future<void> _doSend({
    required String type,
    required String message,
    String? stack,
    Map<String, dynamic>? context,
  }) async {
    try {
      await _client.post('/api/v1/debug/report', data: {
        'type': type,
        'message': message,
        if (stack != null) 'stack': stack,
        if (context != null) 'context': context,
        'app_version': _appVersion,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Silently ignore — reporter must never crash the app
    }
  }
}
