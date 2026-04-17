import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';

class ProductsState {
  const ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.search = '',
  });

  final List<Map<String, dynamic>> products;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String search;

  ProductsState copyWith({
    List<Map<String, dynamic>>? products,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? search,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      search: search ?? this.search,
    );
  }
}

class ProductsNotifier extends Notifier<ProductsState> {
  // Not final — build() can be called multiple times when the provider is
  // invalidated (e.g. on locale change), so we must allow reassignment.
  Dio? _dio;

  Dio get _client {
    _dio ??= ApiClient.create(baseUrl: _resolveBaseUrl());
    return _dio!;
  }

  static String _resolveBaseUrl() {
    const fromEnv = String.fromEnvironment('BASE_URL', defaultValue: '');
    return fromEnv.isNotEmpty ? fromEnv : StorageService().getBaseUrl();
  }

  @override
  ProductsState build() {
    // Reset the client so a fresh one is created with the current base URL.
    _dio = null;
    // Schedule the first load after build() returns so `state` is accessible.
    Future.microtask(_loadMore);
    return const ProductsState();
  }

  Future<void> _loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final res = await _client.get('/api/v1/products', queryParameters: {
        'page': state.page,
        if (state.search.isNotEmpty) 'search': state.search,
      });

      // Actual response shape: { success, data: [...], meta: { last_page } }
      final rawData = res.data;
      final List<dynamic> rawList;
      final Map<String, dynamic> meta;

      if (rawData is Map) {
        // Standard paginated response: data is the items array, meta is top-level
        final dataField = rawData['data'];
        if (dataField is List) {
          rawList = dataField;
        } else if (dataField is Map && dataField['data'] is List) {
          // Fallback: nested { data: { data: [...], meta: {} } }
          rawList = dataField['data'] as List;
        } else {
          rawList = [];
        }
        meta = (rawData['meta'] as Map<String, dynamic>?) ?? {};
      } else {
        rawList = [];
        meta = {};
      }

      final items = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final lastPage = meta['last_page'] as int? ?? 1;

      state = state.copyWith(
        products: [...state.products, ...items],
        isLoading: false,
        hasMore: state.page < lastPage,
        page: state.page + 1,
      );
    } catch (e) {
      // Surface the error so it's visible during development
      assert(() {
        // ignore: avoid_print
        print('[ProductsNotifier] _loadMore error: $e');
        return true;
      }());
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }

  void loadMore() => _loadMore();

  Future<void> search(String query) async {
    state = ProductsState(search: query);
    await _loadMore();
  }

  Future<void> refresh() async {
    state = ProductsState(search: state.search);
    await _loadMore();
  }
}

final productsProvider =
    NotifierProvider<ProductsNotifier, ProductsState>(ProductsNotifier.new);
