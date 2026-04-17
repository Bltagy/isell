import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/loading_skeleton_widget.dart';
import '../providers/products_provider.dart';
import '../../../l10n/app_localizations.dart';

// ── Selectors — widgets only rebuild when their specific slice changes ─────────

/// Rebuilds only when the product list or hasMore flag changes.
final _productsListSelector = (ProductsState s) =>
    (products: s.products, hasMore: s.hasMore);

/// Rebuilds only when the initial-loading state changes.
final _initialLoadingSelector = (ProductsState s) =>
    s.isLoading && s.products.isEmpty;

// ─────────────────────────────────────────────────────────────────────────────

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});
  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(productsProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(productsProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header — const-safe, never rebuilds ──────────────────────────
            _ProductListHeader(l: l),
            const SizedBox(height: 12),

            // ── Search bar ───────────────────────────────────────────────────
            _SearchBar(controller: _searchCtrl, onChanged: _onSearchChanged, l: l),
            const SizedBox(height: 16),

            // ── Grid — only rebuilds when list/hasMore changes ───────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref.read(productsProvider.notifier).refresh(),
                child: _ProductGrid(
                  scrollController: _scrollCtrl,
                  l: l,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProductListHeader extends StatelessWidget {
  const _ProductListHeader({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(l.ourMenu, style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          _FilterButton(),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 8),
        ],
      ),
      child: const Icon(Icons.tune_rounded, color: AppColors.textPrimary, size: 20),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.l,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 8),
          ],
        ),
        child: SizedBox(
          height: 50,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: l.searchFoodHint,
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textHint, size: 22),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Grid — granular selector so only list changes trigger a rebuild ────────────

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid({required this.scrollController, required this.l});

  final ScrollController scrollController;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // PERF: select() — only rebuilds when isLoading+isEmpty slice changes
    final isInitialLoading =
        ref.watch(productsProvider.select(_initialLoadingSelector));

    if (isInitialLoading) {
      return GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: List.generate(6, (_) => const _SkeletonCard()),
      );
    }

    // PERF: select() — only rebuilds when products list or hasMore changes
    final (:products, :hasMore) =
        ref.watch(productsProvider.select(_productsListSelector));

    if (products.isEmpty) {
      return _EmptyState(l: l,
          onRetry: () => ref.read(productsProvider.notifier).refresh());
    }

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length + (hasMore ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= products.length) return const _SkeletonCard();
        // PERF: RepaintBoundary isolates each card's repaint layer
        return RepaintBoundary(
          child: _ProductGridCard(product: products[index]),
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l, required this.onRetry});
  final AppLocalizations l;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.restaurant_menu_rounded,
            size: 64, color: AppColors.textHint),
        const SizedBox(height: 16),
        Text(l.emptyStateTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(l.retry,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l.retry),
          ),
        ),
      ],
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    // PERF: all field extraction is O(1) map lookups — fine in build()
    final id = product['id']?.toString() ?? '';
    final imageUrl =
        product['image_url'] as String? ?? product['image'] as String? ?? '';
    final locale = Localizations.localeOf(context).languageCode;
    final name = (locale == 'ar'
            ? (product['name_ar'] ?? product['name_en'])
            : (product['name_en'] ?? product['name_ar'])) as String? ??
        '';
    final price = product['price'] as int? ?? 0;
    final discountPrice = product['discount_price'] as int?;
    final prepTime = product['preparation_time_minutes'] as int? ?? 20;
    final categoryMap = product['category'] as Map<String, dynamic>?;
    final category = (locale == 'ar'
            ? (categoryMap?['name_ar'] ?? categoryMap?['name_en'])
            : (categoryMap?['name_en'] ?? categoryMap?['name_ar'])) as String? ??
        '';
    final displayPrice = (discountPrice ?? price) / 100;

    return GestureDetector(
      onTap: () => context.push('/products/$id'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: 'product-$id',
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: AppImage(
                        url: imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholderIcon: Icons.fastfood,
                      ),
                    ),
                  ),
                  // Favourite button
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: _FavouriteButton(),
                  ),
                  // Category badge
                  if (category.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _CategoryBadge(label: category),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.star, size: 13),
                      const Text(' 4.5',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const Spacer(),
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: AppColors.textHint),
                      Text(' ${prepTime}m',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textHint)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EGP ${displayPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                      const _AddButton(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small const sub-widgets (zero rebuild cost) ───────────────────────────────

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.favorite_border_rounded,
          size: 16, color: AppColors.textHint),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
          color: AppColors.primary, borderRadius: BorderRadius.circular(7)),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) =>
      const LoadingSkeletonWidget(borderRadius: 16);
}
