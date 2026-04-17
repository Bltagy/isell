import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_image.dart';
import '../providers/cart_provider.dart';
import '../../../l10n/app_localizations.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promoCtrl = TextEditingController();
  bool _applyingPromo = false;

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    setState(() => _applyingPromo = true);
    try {
      final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
      final res = await dio.post('/api/v1/offers/validate-code', data: {
        'code': _promoCtrl.text.trim().toUpperCase(),
        'subtotal': ref.read(cartProvider).subtotal,
      });
      final discount = res.data['data']['discount'] as int? ?? 0;
      ref.read(cartProvider.notifier).setPromoCode(_promoCtrl.text.trim(), discount: discount);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).promoApplied)));
    } on DioException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.error?.toString() ?? 'Invalid code')));
    } finally {
      setState(() => _applyingPromo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    const deliveryFee = 2000;
    final tax = (cart.subtotal * 0.14).round();
    final total = cart.subtotal + deliveryFee - cart.discount + tax;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(l.myCart, style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  if (cart.items.isNotEmpty)
                    TextButton(
                      onPressed: () => ref.read(cartProvider.notifier).clear(),
                      child: Text(l.clear, style: TextStyle(color: AppColors.error)),
                    ),
                ],
              ),
            ),

            if (cart.items.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(l.cartEmpty, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(l.cartEmptySubtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go(AppRoutes.products),
                        child: Text(l.browseMenu),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Items list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  children: [
                    ...cart.items.map((item) => _CartItemCard(item: item)),
                    const SizedBox(height: 16),

                    // Promo code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _promoCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: l.promoCode,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                fillColor: Colors.transparent,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _applyingPromo ? null : _applyPromo,
                            child: _applyingPromo
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(l.applyCode, style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                      ),
                      child: Column(
                        children: [
                          _PriceRow(label: l.subtotal, amount: cart.subtotal),
                          const SizedBox(height: 8),
                          _PriceRow(label: l.deliveryFee, amount: deliveryFee),
                          if (cart.discount > 0) ...[
                            const SizedBox(height: 8),
                            _PriceRow(label: l.discount, amount: -cart.discount, isDiscount: true),
                          ],
                          const SizedBox(height: 8),
                          _PriceRow(label: l.tax, amount: tax),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                          _PriceRow(label: l.total, amount: total, isBold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Checkout button
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
                ),
                child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.checkout),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l.checkout),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
                        child: Text('EGP ${(total / 100).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends ConsumerWidget {
  const _CartItemCard({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppImage(
              url: item.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              placeholderIcon: Icons.fastfood_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('EGP ${(item.price / 100).toStringAsFixed(2)}',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyButton(
                  icon: Icons.remove_rounded,
                  onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity - 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                _QtyButton(
                  icon: Icons.add_rounded,
                  onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity + 1),
                  filled: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap, this.filled = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: filled ? Colors.white : AppColors.textPrimary),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.amount, this.isBold = false, this.isDiscount = false});
  final String label;
  final int amount;
  final bool isBold;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: isBold ? 16 : 14,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
        )),
        Text(
          '${isDiscount ? '-' : ''}EGP ${(amount.abs() / 100).toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isDiscount ? AppColors.success : (isBold ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
