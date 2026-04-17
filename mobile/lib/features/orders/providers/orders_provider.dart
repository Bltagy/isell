import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';

class OrdersState {
  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
  });

  final List<Map<String, dynamic>> orders;
  final bool isLoading;
  final bool hasMore;
  final int page;

  OrdersState copyWith({
    List<Map<String, dynamic>>? orders,
    bool? isLoading,
    bool? hasMore,
    int? page,
  }) =>
      OrdersState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
      );
}

class OrdersNotifier extends Notifier<OrdersState> {
  // Nullable — build() may be called multiple times (locale change, etc.)
  Dio? _dio;

  Dio get _client {
    _dio ??= ApiClient.create(baseUrl: StorageService().getBaseUrl());
    return _dio!;
  }

  @override
  OrdersState build() {
    _dio = null;
    // Defer first load so `state` is accessible
    Future.microtask(_loadMore);
    return const OrdersState();
  }

  Future<void> _loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final res = await _client.get(
        '/api/v1/orders',
        queryParameters: {'page': state.page},
      );

      // Response shape: { success, data: [...], meta: { last_page, ... } }
      final body = res.data as Map<String, dynamic>;
      final rawList = body['data'];
      final meta = body['meta'] as Map<String, dynamic>? ?? {};

      final items = (rawList is List)
          ? rawList.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      final lastPage = meta['last_page'] as int? ?? 1;

      state = state.copyWith(
        orders: [...state.orders, ...items],
        isLoading: false,
        hasMore: state.page < lastPage,
        page: state.page + 1,
      );
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[OrdersNotifier] error: $e');
        return true;
      }());
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }

  void loadMore() => _loadMore();

  Future<void> refresh() async {
    _dio = null; // force fresh client
    state = const OrdersState();
    await _loadMore();
  }
}

final ordersProvider =
    NotifierProvider<OrdersNotifier, OrdersState>(OrdersNotifier.new);
