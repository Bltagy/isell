import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/debug/error_reporter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';

class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.token,
    this.user,
    this.errorMessage,
  });

  final bool isAuthenticated;
  final String? token;
  final Map<String, dynamic>? user;
  /// Human-readable error from the last failed operation. Null when no error.
  final String? errorMessage;

  AuthState copyWithError(String message) => AuthState(
        isAuthenticated: isAuthenticated,
        token: token,
        user: user,
        errorMessage: message,
      );

  AuthState clearError() => AuthState(
        isAuthenticated: isAuthenticated,
        token: token,
        user: user,
      );
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  // Not late final — build() may be called again after logout/invalidation.
  Dio? _dio;
  StorageService? _storage;

  Dio get _client {
    _dio ??= ApiClient.create(baseUrl: _resolveBaseUrl());
    return _dio!;
  }

  StorageService get _store {
    _storage ??= StorageService();
    return _storage!;
  }

  static String _resolveBaseUrl() {
    const fromEnv = String.fromEnvironment('BASE_URL', defaultValue: '');
    return fromEnv.isNotEmpty ? fromEnv : StorageService().getBaseUrl();
  }

  @override
  Future<AuthState> build() async {
    // Reset on rebuild so a fresh client is created with the current base URL.
    _dio = null;
    _storage = null;
    final token = await _store.getToken();
    if (token != null) {
      // Restore persisted user data so name shows immediately without a network call
      final user = _store.getUser();
      return AuthState(isAuthenticated: true, token: token, user: user);
    }
    return const AuthState();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Extracts a user-friendly message from a DioException or any other error.
  String _extractError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'] as String?;
        if (msg != null && msg.isNotEmpty) return msg;
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'لا يوجد اتصال بالإنترنت';
      }
    }
    return e.toString();
  }

  // ── Auth actions ─────────────────────────────────────────────────────────

  Future<void> loginWithPhone(String phone, String password) async {
    // Set loading while keeping current data so the UI doesn't flash.
    state = const AsyncLoading<AuthState>().copyWithPrevious(state);
    try {
      final res = await _client.post('/api/v1/auth/login', data: {
        'phone': phone,
        'password': password,
      });
      final token = res.data['data']['token'] as String;
      await _store.saveToken(token);
      final user = res.data['data']['user'] as Map<String, dynamic>?;
      if (user != null) await _store.saveUser(user);
      state = AsyncData(AuthState(
        isAuthenticated: true,
        token: token,
        user: user,
      ));
    } catch (e) {
      // Stay on the auth screen — put error into state.value, not state.error,
      // so the router redirect (which only checks isAuthenticated) doesn't fire.
      final msg = _extractError(e);
      ErrorReporter.reportApiError(message: 'login failed: $msg', route: '/api/v1/auth/login');
      final current = state.valueOrNull ?? const AuthState();
      state = AsyncData(current.copyWithError(msg));
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    state = const AsyncLoading<AuthState>().copyWithPrevious(state);
    try {
      final res = await _client.post('/api/v1/auth/register', data: {
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
      });
      final token = res.data['data']['token'] as String;
      await _store.saveToken(token);
      final user = res.data['data']['user'] as Map<String, dynamic>?;
      if (user != null) await _store.saveUser(user);
      state = AsyncData(AuthState(
        isAuthenticated: true,
        token: token,
        user: user,
      ));
    } catch (e) {
      final msg = _extractError(e);
      ErrorReporter.reportApiError(message: 'register failed: $msg', route: '/api/v1/auth/register');
      final current = state.valueOrNull ?? const AuthState();
      state = AsyncData(current.copyWithError(msg));
    }
  }

  Future<void> logout() async {
    try {
      await _client.post('/api/v1/auth/logout');
    } catch (_) {}
    await _store.clearToken();
    await _store.clearUser();
    _dio = null;
    state = const AsyncData(AuthState());
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current != null) state = AsyncData(current.clearError());
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
