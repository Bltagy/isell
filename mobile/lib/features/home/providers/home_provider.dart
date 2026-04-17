import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';

class HomeData {
  const HomeData({
    this.banners = const [],
    this.categories = const [],
    this.featuredProducts = const [],
  });

  final List<Map<String, dynamic>> banners;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> featuredProducts;
}

class HomeNotifier extends AsyncNotifier<HomeData> {
  // PERF: Dio instance is created once per provider lifetime, not on every
  // build() / refresh() call. build() is re-invoked on locale invalidation,
  // so we lazily initialise and reset only when needed.
  Dio? _dio;

  Dio get _client {
    _dio ??= ApiClient.create(baseUrl: StorageService().getBaseUrl());
    return _dio!;
  }

  @override
  Future<HomeData> build() {
    // Reset client so a fresh base-URL is picked up after locale/config change.
    _dio = null;
    return _fetch();
  }

  Future<HomeData> _fetch() async {
    final res = await _client.get('/api/v1/home');
    final data = res.data['data'] as Map<String, dynamic>;
    return HomeData(
      banners:
          List<Map<String, dynamic>>.from(data['banners'] ?? []),
      categories:
          List<Map<String, dynamic>>.from(data['categories'] ?? []),
      featuredProducts:
          List<Map<String, dynamic>>.from(data['featured_products'] ?? []),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final homeProvider =
    AsyncNotifierProvider<HomeNotifier, HomeData>(HomeNotifier.new);
