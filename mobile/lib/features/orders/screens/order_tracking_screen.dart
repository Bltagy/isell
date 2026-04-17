import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

// All non-cancelled statuses in order
const _steps = [
  'pending',
  'confirmed',
  'preparing',
  'ready',
  'out_for_delivery',
  'delivered',
];

class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  String _status = 'pending';
  String? _driverName;
  String? _driverPhone;
  int? _estimatedMinutes;
  bool _loading = true;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _loadInitialStatus();
  }

  /// Fetch current order status from REST API first, then connect WebSocket
  Future<void> _loadInitialStatus() async {
    try {
      final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
      final res = await dio.get('/api/v1/orders/${widget.orderId}/track');
      final data = res.data['data'] as Map<String, dynamic>? ?? {};
      if (mounted) {
        setState(() {
          _status = data['current_status'] as String? ?? 'pending';
          _estimatedMinutes = data['estimated_minutes'] as int?;
          final driver = data['driver'] as Map<String, dynamic>?;
          _driverName = driver?['name'] as String?;
          _driverPhone = driver?['phone'] as String?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      final baseUrl = StorageService().getBaseUrl();
      // Convert http://host to ws://host:8080
      final wsHost = Uri.parse(baseUrl).host;
      final wsUrl = 'ws://$wsHost:8080/app/foodapp-key'
          '?protocol=7&client=flutter&version=1.0';

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Subscribe to the order channel
      _channel!.sink.add(jsonEncode({
        'event': 'pusher:subscribe',
        'data': {'channel': 'order.${widget.orderId}'},
      }));

      _sub = _channel!.stream.listen(
        (message) {
          try {
            final data =
                jsonDecode(message as String) as Map<String, dynamic>;
            if (data['event'] == 'App\\Events\\OrderStatusUpdated') {
              final payload = data['data'] is String
                  ? jsonDecode(data['data'] as String) as Map<String, dynamic>
                  : data['data'] as Map<String, dynamic>;
              if (mounted) {
                setState(() {
                  _status = payload['status'] as String? ?? _status;
                  _estimatedMinutes =
                      payload['estimated_delivery_minutes'] as int?;
                  final driver =
                      payload['driver'] as Map<String, dynamic>?;
                  _driverName = driver?['name'] as String?;
                  _driverPhone = driver?['phone'] as String?;
                });
              }
            }
          } catch (_) {}
        },
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {
      // WebSocket unavailable — REST polling is enough
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currentIndex = _steps.indexOf(_status);
    final isCancelled = _status == 'cancelled';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${l.trackOrder} #${widget.orderId}'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Estimated delivery card ───────────────────────
                if (_estimatedMinutes != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.estimatedDelivery(_estimatedMinutes!),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Driver card ───────────────────────────────────
                if (_driverName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8)
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delivery_dining_rounded,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.yourDriver,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                              Text(_driverName!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                        if (_driverPhone != null)
                          GestureDetector(
                            onTap: () {/* TODO: launch phone */},
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.phone_rounded,
                                  color: AppColors.success, size: 18),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Status timeline ───────────────────────────────
                if (isCancelled)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_outlined,
                            color: AppColors.error),
                        const SizedBox(width: 10),
                        Text(l.cancelled,
                            style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8)
                      ],
                    ),
                    child: Column(
                      children: _steps.asMap().entries.map((entry) {
                        final i = entry.key;
                        final step = entry.value;
                        final isDone = i < currentIndex;
                        final isActive = i == currentIndex;
                        final isLast = i == _steps.length - 1;
                        final stepLabel = _stepLabel(step, l);
                        final stepColor = isActive || isDone
                            ? AppColors.primary
                            : AppColors.divider;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dot + line
                            SizedBox(
                              width: 24,
                              child: Column(
                                children: [
                                  Container(
                                    width: isActive ? 14 : 10,
                                    height: isActive ? 14 : 10,
                                    margin: EdgeInsets.only(
                                        top: isActive ? 1 : 3),
                                    decoration: BoxDecoration(
                                      color: isDone || isActive
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: stepColor, width: 2),
                                    ),
                                    child: isDone
                                        ? const Icon(Icons.check,
                                            size: 7,
                                            color: Colors.white)
                                        : null,
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 32,
                                      color: isDone
                                          ? AppColors.primary
                                          : AppColors.divider,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    bottom: isLast ? 0 : 20,
                                    top: 0),
                                child: Text(
                                  stepLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isActive
                                        ? AppColors.primary
                                        : isDone
                                            ? AppColors.textPrimary
                                            : AppColors.textHint,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
    );
  }

  String _stepLabel(String step, AppLocalizations l) => switch (step) {
        'pending'          => l.pending,
        'confirmed'        => l.confirmed,
        'preparing'        => l.preparing,
        'ready'            => l.ready,
        'out_for_delivery' => l.outForDelivery,
        'delivered'        => l.delivered,
        _                  => step.replaceAll('_', ' '),
      };
}
