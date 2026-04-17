import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_skeleton_widget.dart';
import '../providers/orders_provider.dart';

const _activeStatuses = {
  'pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery'
};

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  // PERF: single controller for the active list; past list uses its own
  // controller created once and stored here so it's properly disposed.
  final _activeScroll = ScrollController();
  final _pastScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _activeScroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activeScroll.dispose();
    _pastScroll.dispose(); // was leaking before
    super.dispose();
  }

  void _onScroll() {
    if (_activeScroll.position.pixels >=
        _activeScroll.position.maxScrollExtent - 200) {
      ref.read(ordersProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);
    final l = AppLocalizations.of(context);

    final active = state.orders
        .where((o) => _activeStatuses.contains(o['status'] as String? ?? ''))
        .toList();
    final past = state.orders
        .where((o) => !_activeStatuses.contains(o['status'] as String? ?? ''))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.myOrders),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: l.activeOrders),
            Tab(text: l.pastOrders),
          ],
        ),
      ),
      body: state.isLoading && state.orders.isEmpty
          ? const _OrdersSkeleton()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OrderList(
                    orders: active,
                    scrollController: _activeScroll,
                    hasMore: state.hasMore,
                    showReorder: false,
                    emptyLabel: l.noOrders,
                  ),
                  _OrderList(
                    orders: past,
                    scrollController: _pastScroll,
                    hasMore: false,
                    showReorder: true,
                    emptyLabel: l.noOrders,
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Order list ────────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.scrollController,
    required this.hasMore,
    required this.showReorder,
    required this.emptyLabel,
  });

  final List<Map<String, dynamic>> orders;
  final ScrollController scrollController;
  final bool hasMore;
  final bool showReorder;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(emptyLabel,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: orders.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == orders.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _OrderTile(order: orders[index], showReorder: showReorder);
      },
    );
  }
}

// ── Order tile ────────────────────────────────────────────────────────────────

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.showReorder});
  final Map<String, dynamic> order;
  final bool showReorder;

  static const _statusColors = {
    'pending':          Color(0xFFF59E0B),
    'confirmed':        Color(0xFF3B82F6),
    'preparing':        Color(0xFF8B5CF6),
    'ready':            Color(0xFF06B6D4),
    'out_for_delivery': Color(0xFFEC4899),
    'delivered':        Color(0xFF10B981),
    'cancelled':        Color(0xFFEF4444),
  };

  static const _statusLabels = {
    'pending':          'قيد الانتظار',
    'confirmed':        'مؤكد',
    'preparing':        'قيد التحضير',
    'ready':            'جاهز',
    'out_for_delivery': 'في الطريق',
    'delivered':        'تم التسليم',
    'cancelled':        'ملغي',
  };

  @override
  Widget build(BuildContext context) {
    final id = order['id']?.toString() ?? '';
    final status = order['status'] as String? ?? '';
    final total = order['total'] as int? ?? 0;
    final items = order['items'] as List? ?? [];
    final createdAt = order['created_at'] as String? ?? '';
    final color = _statusColors[status] ?? AppColors.textHint;
    final label = _statusLabels[status] ?? status.replaceAll('_', ' ');

    // Format date
    String dateStr = '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      dateStr = '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/orders/$id'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: order # + status badge
              Row(
                children: [
                  Text('طلب #$id',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Items summary
              if (items.isNotEmpty)
                Text(
                  items
                      .take(2)
                      .map((i) =>
                          '${i['quantity']}× ${i['name'] ?? i['product_name'] ?? ''}')
                      .join('، ') +
                      (items.length > 2 ? ' +${items.length - 2}' : ''),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 8),

              // Bottom row: total + date + reorder
              Row(
                children: [
                  Text(
                    'EGP ${(total / 100).toStringAsFixed(2)}',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  const Spacer(),
                  if (dateStr.isNotEmpty)
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint)),
                  if (showReorder) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _reorder(context, id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('إعادة الطلب',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reorder(BuildContext context, String orderId) async {
    try {
      final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
      await dio.post('/api/v1/orders/$orderId/reorder');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة العناصر إلى السلة')),
        );
      }
    } catch (_) {}
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LoadingSkeletonWidget(width: 80, height: 14, borderRadius: 6),
                LoadingSkeletonWidget(width: 70, height: 22, borderRadius: 11),
              ],
            ),
            SizedBox(height: 10),
            LoadingSkeletonWidget(height: 12, borderRadius: 6),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LoadingSkeletonWidget(width: 90, height: 14, borderRadius: 6),
                LoadingSkeletonWidget(width: 60, height: 12, borderRadius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
