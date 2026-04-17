import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

// Maps API status values → localized label getter
String _statusLabel(String status, AppLocalizations l) => switch (status) {
      'pending'          => l.pending,
      'confirmed'        => l.confirmed,
      'preparing'        => l.preparing,
      'ready'            => l.ready,
      'out_for_delivery' => l.outForDelivery,
      'delivered'        => l.delivered,
      'cancelled'        => l.cancelled,
      _                  => status.replaceAll('_', ' '),
    };

const _statusColors = {
  'pending':          Color(0xFFF59E0B),
  'confirmed':        Color(0xFF3B82F6),
  'preparing':        Color(0xFF8B5CF6),
  'ready':            Color(0xFF06B6D4),
  'out_for_delivery': Color(0xFFEC4899),
  'delivered':        Color(0xFF10B981),
  'cancelled':        Color(0xFFEF4444),
};

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
      final res = await dio.get('/api/v1/orders/${widget.orderId}');
      final data = res.data['data'];
      if (data is Map<String, dynamic>) {
        setState(() { _order = data; _loading = false; });
      } else {
        setState(() { _error = 'Invalid response'; _loading = false; });
      }
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message'] as String? ?? 'Failed to load order')
          : 'Failed to load order';
      setState(() { _error = msg; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _reorder() async {
    try {
      final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
      await dio.post('/api/v1/orders/${widget.orderId}/reorder');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).addToCart)),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
        title: Text('${l.orderNumber}${widget.orderId}'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l.orders),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 56, color: AppColors.error),
                const SizedBox(height: 16),
                Text(_error ?? l.error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _fetchOrder,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final order = _order!;
    final items = (order['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final status = order['status'] as String? ?? '';
    final isDelivered = status == 'delivered';
    final isCancelled = status == 'cancelled';
    final isCancellable = order['is_cancellable'] as bool? ?? false;
    final statusHistory = (order['status_history'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final statusColor = _statusColors[status] ?? AppColors.textHint;
    final paymentMethod = order['payment_method'] as String? ?? '';
    final paymentStatus = order['payment_status'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${l.orderNumber}${widget.orderId}'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          if (isDelivered)
            TextButton(
              onPressed: _reorder,
              child: Text(l.reorder,
                  style: TextStyle(color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchOrder,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [

            // ── Status banner ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(_statusLabel(status, l),
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const Spacer(),
                  if (!isDelivered && !isCancelled)
                    GestureDetector(
                      onTap: () =>
                          context.push('/orders/${widget.orderId}/track'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(l.trackOrder,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Items ─────────────────────────────────────────────
            _Card(
              header: _CardHeader(
                icon: Icons.shopping_bag_outlined,
                title: l.orderItems,
              ),
              child: Column(
                children: [
                  ...items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final name = item['product_name'] as String?
                        ?? item['name'] as String?
                        ?? '—';
                    final qty = item['quantity'] as int? ?? 1;
                    final subtotal = item['subtotal'] as int?
                        ?? item['total_price'] as int?
                        ?? 0;
                    return Column(
                      children: [
                        if (i > 0)
                          const Divider(height: 1, color: AppColors.divider),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text('$qty',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14)),
                              ),
                              Text(
                                'EGP ${(subtotal / 100).toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Price breakdown ───────────────────────────────────
            _Card(
              child: Column(
                children: [
                  _PriceRow(l.subtotal,    order['subtotal']     as int? ?? 0),
                  _PriceRow(l.deliveryFee, order['delivery_fee'] as int? ?? 0),
                  if ((order['discount'] as int? ?? 0) > 0)
                    _PriceRow(l.discount, order['discount'] as int,
                        isDiscount: true),
                  _PriceRow(l.tax, order['tax'] as int? ?? 0),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),
                  _PriceRow(l.total, order['total'] as int? ?? 0, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Payment ───────────────────────────────────────────
            _Card(
              header: _CardHeader(
                icon: Icons.payment_outlined,
                title: l.paymentInfo,
              ),
              child: Column(
                children: [
                  _InfoRow(
                    l.paymentMethod,
                    paymentMethod == 'cash' ? l.cash
                        : paymentMethod == 'kashier' ? l.kashier
                        : paymentMethod.replaceAll('_', ' '),
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    l.paymentStatus,
                    paymentStatus == 'paid' ? l.paid
                        : paymentStatus == 'pending' ? l.pending
                        : paymentStatus.replaceAll('_', ' '),
                    valueColor: paymentStatus == 'paid'
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Status history ────────────────────────────────────
            if (statusHistory.isNotEmpty)
              _Card(
                header: _CardHeader(
                  icon: Icons.history_rounded,
                  title: l.orderStatus,
                ),
                child: Column(
                  children: statusHistory.reversed.toList().asMap().entries.map((entry) {
                    final i = entry.key;
                    final h = entry.value;
                    final s = h['status'] as String? ?? '';
                    final note = h['note'] as String?;
                    final at = h['created_at'] as String? ?? '';
                    String dateStr = '';
                    try {
                      final dt = DateTime.parse(at).toLocal();
                      dateStr =
                          '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (_) {}
                    final isFirst = i == 0;
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline line + dot
                          SizedBox(
                            width: 24,
                            child: Column(
                              children: [
                                Container(
                                  width: 10, height: 10,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: isFirst
                                        ? AppColors.primary
                                        : AppColors.divider,
                                    shape: BoxShape.circle,
                                    border: isFirst
                                        ? Border.all(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.3),
                                            width: 3)
                                        : null,
                                  ),
                                ),
                                if (i < statusHistory.length - 1)
                                  Expanded(
                                    child: Container(
                                      width: 1.5,
                                      color: AppColors.divider,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_statusLabel(s, l),
                                      style: TextStyle(
                                          fontWeight: isFirst
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 13,
                                          color: isFirst
                                              ? AppColors.primary
                                              : AppColors.textPrimary)),
                                  if (note != null && note.isNotEmpty)
                                    Text(note,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                          Text(dateStr,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            // ── Notes ─────────────────────────────────────────────
            if ((order['notes'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              _Card(
                header: _CardHeader(
                    icon: Icons.note_outlined, title: l.notes),
                child: Text(order['notes'] as String,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary,
                        height: 1.5)),
              ),
            ],

            // ── Cancel ────────────────────────────────────────────
            if (isCancellable) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {/* TODO */},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l.cancelOrder),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.header});
  final Widget child;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) header!,
          child,
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.amount,
      {this.isBold = false, this.isDiscount = false});
  final String label;
  final int amount;
  final bool isBold;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isBold ? 15 : 13,
                  fontWeight:
                      isBold ? FontWeight.w700 : FontWeight.w400,
                  color: isBold
                      ? AppColors.textPrimary
                      : AppColors.textSecondary)),
          Text(
            '${isDiscount ? '-' : ''}EGP ${(amount.abs() / 100).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: isDiscount
                  ? AppColors.success
                  : isBold
                      ? AppColors.primary
                      : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}
