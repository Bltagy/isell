import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/loading_skeleton_widget.dart';
import '../../cart/providers/cart_provider.dart';
import '../../favorites/providers/favorites_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Map<String, dynamic>? _product;
  bool _loading = true;
  bool _hasError = false;
  int _quantity = 1;
  // option_id -> selected item ids
  final Map<int, Set<int>> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
      final res = await dio.get('/api/v1/products/${widget.productId}');
      if (mounted) {
        setState(() {
          _product = res.data['data'] as Map<String, dynamic>;
          _loading = false;
        });
      }
    } on DioException catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  void _addToCart() {
    if (_product == null) return;
    HapticFeedback.mediumImpact();
    final locale = Localizations.localeOf(context).languageCode;
    final name = (locale == 'ar'
        ? (_product!['name_ar'] ?? _product!['name_en'])
        : (_product!['name_en'] ?? _product!['name_ar'])) as String? ?? '';
    ref.read(cartProvider.notifier).addItem(
          productId: _product!['id'] as int,
          name: name,
          price: _product!['price'] as int? ?? 0,
          quantity: _quantity,
          options: _selectedOptions,
          imageUrl: _product!['image_url'] as String? ?? _product!['image'] as String?,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).addToCart),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _DetailSkeleton();

    if (_hasError || _product == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).emptyStateTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _fetchProduct,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;
    final options = List<Map<String, dynamic>>.from(product['options'] ?? []);
    final locale = Localizations.localeOf(context).languageCode;
    final name = (locale == 'ar'
        ? (product['name_ar'] ?? product['name_en'])
        : (product['name_en'] ?? product['name_ar'])) as String? ?? '';
    final nameAlt = (locale == 'ar'
        ? (product['name_en'] as String?)
        : (product['name_ar'] as String?));
    final description = (locale == 'ar'
        ? (product['description_ar'] ?? product['description_en'])
        : (product['description_en'] ?? product['description_ar'])) as String? ?? '';
    final price = product['price'] as int? ?? 0;
    final discountPrice = product['discount_price'] as int?;
    final displayPrice = (discountPrice ?? price) / 100;
    final prepTime = product['preparation_time_minutes'] as int? ?? 20;

    // PERF: select() — only rebuilds when this product's fav status changes
    final isFav = ref
        .watch(favoritesProvider.select(
            (v) => v.valueOrNull?.contains(product['id'] as int) ?? false));

    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing image header ──────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            surfaceTintColor: Colors.transparent,
            actions: [
              // PERF: RepaintBoundary isolates the fav icon repaint
              RepaintBoundary(
                child: Semantics(
                  label: isFav ? 'Remove from favourites' : 'Add to favourites',
                  button: true,
                  child: IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        key: ValueKey(isFav),
                        color: isFav ? Colors.red : AppColors.textPrimary,
                      ),
                    ),
                    onPressed: () => ref
                        .read(favoritesProvider.notifier)
                        .toggle(product['id'] as int),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${product['id']}',
                child: AppImage(
                  url: product['image_url'] as String? ??
                      product['image'] as String? ?? '',
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.fastfood_rounded,
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + meta row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: Theme.of(context).textTheme.headlineMedium),
                              if (nameAlt != null && nameAlt.isNotEmpty)
                                Text(nameAlt,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (discountPrice != null)
                              Text(
                                'EGP ${(price / 100).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textHint,
                                    decoration: TextDecoration.lineThrough),
                              ),
                            Text(
                              'EGP ${displayPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Meta chips
                    Row(
                      children: [
                        _MetaChip(
                          icon: Icons.star_rounded,
                          label: '4.5',
                          color: AppColors.star,
                        ),
                        const SizedBox(width: 8),
                        _MetaChip(
                          icon: Icons.access_time_rounded,
                          label: '${prepTime}m',
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(l.notes,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.6)),
                    ],

                    // Options
                    if (options.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      for (final option in options) ...[
                        _OptionSelector(
                          option: option,
                          selected: _selectedOptions[option['id'] as int] ?? {},
                          onChanged: (id, selected) {
                            setState(() {
                              final optId = option['id'] as int;
                              final type =
                                  option['type'] as String? ?? 'single';
                              if (type == 'single') {
                                _selectedOptions[optId] = {id};
                              } else {
                                final set = Set<int>.from(
                                    _selectedOptions[optId] ?? {});
                                selected ? set.add(id) : set.remove(id);
                                _selectedOptions[optId] = set;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],

                    // Quantity control
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(l.quantity,
                            style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        _QuantityControl(
                          quantity: _quantity,
                          onDecrement: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          onIncrement: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ElevatedButton.icon(
            onPressed: _addToCart,
            icon: const Icon(Icons.shopping_bag_rounded),
            label: Text(l.addToCart),
          ),
        ),
      ),
    );
  }
}

class _OptionSelector extends StatelessWidget {
  const _OptionSelector({
    required this.option,
    required this.selected,
    required this.onChanged,
  });

  final Map<String, dynamic> option;
  final Set<int> selected;
  final void Function(int itemId, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final type = option['type'] as String? ?? 'single';
    final items = List<Map<String, dynamic>>.from(option['items'] ?? []);
    final locale = Localizations.localeOf(context).languageCode;
    final optionName = (locale == 'ar'
        ? (option['name_ar'] ?? option['name_en'])
        : (option['name_en'] ?? option['name_ar'])) as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(optionName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...items.map((item) {
          final id = item['id'] as int;
          final isSelected = selected.contains(id);
          final itemName = (locale == 'ar'
              ? (item['name_ar'] ?? item['name_en'])
              : (item['name_en'] ?? item['name_ar'])) as String? ?? '';
          final extraPrice = item['extra_price'] as int? ?? 0;
          final subtitle = extraPrice > 0
              ? '+EGP ${(extraPrice / 100).toStringAsFixed(2)}'
              : null;

          if (type == 'single') {
            return RadioListTile<int>(
              value: id,
              groupValue: selected.isEmpty ? null : selected.first,
              onChanged: (_) => onChanged(id, true),
              title: Text(itemName),
              subtitle: subtitle != null ? Text(subtitle) : null,
              dense: true,
              activeColor: AppColors.primary,
            );
          } else {
            return CheckboxListTile(
              value: isSelected,
              onChanged: (v) => onChanged(id, v ?? false),
              title: Text(itemName),
              subtitle: subtitle != null ? Text(subtitle) : null,
              dense: true,
              activeColor: AppColors.primary,
            );
          }
        }),
      ],
    );
  }
}

// ── Meta chip ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── Quantity control ──────────────────────────────────────────────────────────

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove_rounded, onTap: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$quantity',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          _QtyBtn(icon: Icons.add_rounded, onTap: onIncrement, filled: true),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap, this.filled = false});
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 18,
            color: onTap == null
                ? AppColors.textHint
                : (filled ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const LoadingSkeletonWidget(height: 300, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                LoadingSkeletonWidget(height: 28, borderRadius: 8),
                SizedBox(height: 10),
                LoadingSkeletonWidget(width: 160, height: 18, borderRadius: 8),
                SizedBox(height: 20),
                LoadingSkeletonWidget(height: 14, borderRadius: 6),
                SizedBox(height: 8),
                LoadingSkeletonWidget(height: 14, borderRadius: 6),
                SizedBox(height: 8),
                LoadingSkeletonWidget(width: 200, height: 14, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
