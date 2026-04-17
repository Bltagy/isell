import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/debug/error_reporter.dart';
import '../../../core/api/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _paymentMethod = 'cash';
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Extracts a human-readable message from a DioException.
  String _extractError(DioException e) {
    // The _ErrorInterceptor wraps the error as ApiException in e.error
    if (e.error is ApiException) {
      return (e.error as ApiException).message;
    }
    // Fallback: read directly from response body
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
      final errors = data['errors'] as Map?;
      if (errors != null && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'لا يوجد اتصال بالإنترنت';
    }
    return 'فشل في إرسال الطلب، حاول مرة أخرى';
  }

  Future<void> _placeOrder() async {
    // Guard: must be authenticated
    final isAuth =
        ref.read(authProvider).valueOrNull?.isAuthenticated ?? false;
    if (!isAuth) {
      context.go(AppRoutes.auth);
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final cart = ref.read(cartProvider);
      final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());

      final orderRes = await dio.post('/api/v1/orders', data: {
        'items': cart.items
            .map((i) => {'product_id': i.productId, 'quantity': i.quantity})
            .toList(),
        if (cart.addressId != null) 'address_id': cart.addressId,
        'payment_method': _paymentMethod,
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
        if (cart.promoCode != null) 'offer_code': cart.promoCode,
      });

      // Response: { success, data: { order: { id, ... }, payment_url? } }
      final responseData = orderRes.data['data'] as Map<String, dynamic>;
      final order = responseData['order'] as Map<String, dynamic>;
      final orderId = order['id']?.toString() ?? '0';

      if (_paymentMethod == 'kashier') {
        final paymentUrl = responseData['payment_url'] as String? ?? '';
        if (mounted) {
          context.push(
            AppRoutes.checkoutPayment,
            extra: {'paymentUrl': paymentUrl, 'orderId': orderId},
          );
        }
      } else {
        ref.read(cartProvider.notifier).clear();
        if (mounted) {
          context.go('/checkout/success/$orderId');
        }
      }
    } on DioException catch (e) {
      final msg = _extractError(e);
      ErrorReporter.reportApiError(
        message: msg,
        route: '/api/v1/orders',
        extra: {'status': e.response?.statusCode, 'method': 'POST'},
      );
      setState(() => _errorMessage = msg);
    } catch (e, stack) {
      // Surface unexpected errors (e.g. type cast on response parsing)
      assert(() {
        // ignore: avoid_print
        print('[CheckoutScreen] unexpected error: $e\n$stack');
        return true;
      }());
      ErrorReporter.reportApiError(
        message: '${e.runtimeType}: $e',
        route: 'checkout._placeOrder',
        extra: {'stack': stack.toString().substring(0, 500)},
      );
      setState(() => _errorMessage = 'حدث خطأ غير متوقع: ${e.runtimeType}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.checkout),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Error banner ─────────────────────────────────────
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
            ),

          // ── Delivery address ──────────────────────────────────
          _SectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_outlined,
                    color: AppColors.primary, size: 20),
              ),
              title: Text(
                cart.addressId != null
                    ? 'عنوان التوصيل #${cart.addressId}'
                    : 'لم يتم اختيار عنوان',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: cart.addressId == null
                  ? const Text('اختياري — يمكنك الطلب بدون عنوان',
                      style: TextStyle(fontSize: 12))
                  : null,
              trailing: TextButton(
                onPressed: () => context.push(
                  AppRoutes.profileAddresses,
                  extra: {'selectMode': true},
                ),
                child: const Text('تغيير'),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Payment method ────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.checkout,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                RadioListTile<String>(
                  value: 'cash',
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الدفع عند الاستلام'),
                  secondary: const Icon(Icons.payments_outlined,
                      color: AppColors.success),
                ),
                RadioListTile<String>(
                  value: 'kashier',
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('بطاقة بنكية (Kashier)'),
                  secondary: const Icon(Icons.credit_card_outlined,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Order notes ───────────────────────────────────────
          _SectionCard(
            child: TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات الطلب (اختياري)',
                prefixIcon: Icon(Icons.note_outlined),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Order summary ─────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ملخص الطلب',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name} × ${item.quantity}',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'EGP ${(item.subtotal / 100).toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 20),
                _SummaryRow(
                    label: l.subtotal,
                    value:
                        'EGP ${(cart.subtotal / 100).toStringAsFixed(2)}'),
                if (cart.discount > 0)
                  _SummaryRow(
                      label: l.discount,
                      value:
                          '-EGP ${(cart.discount / 100).toStringAsFixed(2)}',
                      valueColor: AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Place order button ────────────────────────────────
          ElevatedButton(
            onPressed:
                _loading || cart.items.isEmpty ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(l.confirm,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

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
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
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
      ),
    );
  }
}
