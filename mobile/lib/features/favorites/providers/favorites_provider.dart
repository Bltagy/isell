import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';

/// Holds the list of favorited product IDs.
class FavoritesNotifier extends AsyncNotifier<List<int>> {
  late final Dio _dio;

  @override
  Future<List<int>> build() async {
    _dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
    return _fetchFavorites();
  }

  Future<List<int>> _fetchFavorites() async {
    final res = await _dio.get('/api/v1/favorites');
    // Backend returns paginated ProductResource — extract IDs
    final raw = res.data['data'];
    final items = raw is List
        ? raw
        : (raw is Map ? (raw['data'] as List? ?? []) : []);
    return List<Map<String, dynamic>>.from(items)
        .map((f) => f['id'] as int? ?? f['product_id'] as int? ?? 0)
        .where((id) => id != 0)
        .toList();
  }

  /// Optimistic toggle: updates local state immediately, then syncs with API.
  Future<void> toggle(int productId) async {
    final current = state.valueOrNull ?? [];
    final isFav = current.contains(productId);

    // Optimistic update
    if (isFav) {
      state = AsyncData(current.where((id) => id != productId).toList());
    } else {
      state = AsyncData([...current, productId]);
    }

    try {
      if (isFav) {
        await _dio.delete('/api/v1/favorites/$productId');
      } else {
        await _dio.post('/api/v1/favorites/$productId/toggle');
      }
    } catch (_) {
      // Revert on failure
      state = AsyncData(current);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFavorites);
  }
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<int>>(FavoritesNotifier.new);
