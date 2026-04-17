import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/storage_service.dart';

/// Fetches GET /api/v1/settings/app-config, caches in Hive, falls back to
/// cached data on network failure.
class AppConfigNotifier extends AsyncNotifier<AppConfig> {
  @override
  Future<AppConfig> build() async {
    return _fetchOrFallback();
  }

  Future<AppConfig> _fetchOrFallback() async {
    final storage = StorageService();
    try {
      final dio = ApiClient.create(baseUrl: _resolveBaseUrl());
      final response = await dio.get('/api/v1/settings/app-config');
      final data = (response.data as Map<String, dynamic>)['data']
              as Map<String, dynamic>? ??
          response.data as Map<String, dynamic>;
      await storage.saveAppConfig(data);
      return AppConfig.fromJson(data);
    } on DioException catch (_) {
      // Fall back to cached config
      final cached = storage.getAppConfig();
      if (cached.isNotEmpty) {
        return AppConfig.fromJson(cached);
      }
      return AppConfig.defaults;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchOrFallback);
  }

  /// Reads base URL from storage or falls back to the compiled default.
  String _resolveBaseUrl() {
    const fromEnv = String.fromEnvironment('BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return StorageService().getBaseUrl();
  }
}

final appConfigProvider =
    AsyncNotifierProvider<AppConfigNotifier, AppConfig>(AppConfigNotifier.new);
