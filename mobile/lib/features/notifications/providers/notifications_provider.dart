import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';

class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
  });

  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final bool isLoading;
  final bool hasMore;
  final int page;

  NotificationsState copyWith({
    List<Map<String, dynamic>>? notifications,
    int? unreadCount,
    bool? isLoading,
    bool? hasMore,
    int? page,
  }) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
      );
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  late final Dio _dio;

  @override
  NotificationsState build() {
    final box = StorageService().appConfigBox;
    final baseUrl =
        box.get('base_url', defaultValue: 'http://localhost') as String;
    _dio = ApiClient.create(baseUrl: baseUrl);
    _loadMore();
    return const NotificationsState();
  }

  Future<void> _loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final res = await _dio.get('/api/v1/notifications',
          queryParameters: {'page': state.page});
      final data = res.data['data'] as Map<String, dynamic>;
      final items =
          List<Map<String, dynamic>>.from(data['data'] ?? []);
      final lastPage = data['last_page'] as int? ?? 1;
      final unread = items.where((n) => n['is_read'] == false).length;
      state = state.copyWith(
        notifications: [...state.notifications, ...items],
        unreadCount: state.unreadCount + unread,
        isLoading: false,
        hasMore: state.page < lastPage,
        page: state.page + 1,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void loadMore() => _loadMore();

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch('/api/v1/notifications/$id/read');
      final updated = state.notifications.map((n) {
        if (n['id']?.toString() == id) {
          return {...n, 'is_read': true};
        }
        return n;
      }).toList();
      final unread = updated.where((n) => n['is_read'] == false).length;
      state = state.copyWith(notifications: updated, unreadCount: unread);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.post('/api/v1/notifications/read-all');
      final updated = state.notifications
          .map((n) => {...n, 'is_read': true})
          .toList();
      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (_) {}
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
        NotificationsNotifier.new);
