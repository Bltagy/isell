import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/loading_skeleton_widget.dart';
import '../../favorites/providers/favorites_provider.dart';

// ── Provider: full product data for favorited IDs ─────────────────────────────

// The backend's GET /api/v1/favorites already returns full ProductResource
// objects (with id, name_en, name_ar, price, image_url, etc.).
// We reuse the same Dio instance with auth interceptor so the token is sent.
final _favProductsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  // Watch favoritesProvider so this refreshes when favorites change
  final _ = await ref.watch(favoritesProvider.future);
  final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
  final res = await dio.get('/api/v1/favorites');
  final raw = res.data['data'];
  // Backend returns paginated: { data: [...], meta: {...} }
  // or flat list depending on version
  if (raw is List) return List<Map<String, dynamic>>.from(raw);
  if (raw is Map) {
    final inner = raw['data'];
    if (inner is List) return List<Map<String, dynamic>>.from(inner);
  }
  return [];
});

// ── Screen ────────────────────────────────────────────────────────────────────

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final productsAsync = ref.watch(_favProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.favorites),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: productsAsync.when(
        loading: () => const _FavSkeleton(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 56, color: AppColors.error),
              const SizedBox(height: 12),
              Text(e.toString(),
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(_favProductsProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l.retry),
              ),
            ],
          ),
        ),
        data: (products) => products.isEmpty
            ? _EmptyFavorites(l: l)
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(_favProductsProvider);
                },
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, i) => RepaintBoundary(
                    child: _FavCard(product: products[i], ref: ref),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Favorite product card ─────────────────────────────────────────────────────

class _FavCard extends StatelessWidget {
  const _FavCard({required this.product, required this.ref});
  final Map<String, dynamic> product;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    // Support both flat product and nested product_id/product structures
    final prod = product['product'] as Map<String, dynamic>? ?? product;
    final id = prod['id']?.toString() ?? '';
    final imageUrl =
        prod['image_url'] as String? ?? prod['image'] as String? ?? '';
    final name = (locale == 'ar'
            ? (prod['name_ar'] ?? prod['name_en'])
            : (prod['name_en'] ?? prod['name_ar'])) as String? ??
        '';
    final price = prod['price'] as int? ?? 0;
    final discountPrice = prod['discount_price'] as int?;
    final displayPrice = (discountPrice ?? price) / 100;
    final productId = prod['id'] as int? ?? 0;

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
                offset: Offset(0, 3)),
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
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: AppImage(
                        url: imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholderIcon: Icons.fastfood_rounded,
                      ),
                    ),
                  ),
                  // Remove from favorites button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => ref
                          .read(favoritesProvider.notifier)
                          .toggle(productId),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x14000000), blurRadius: 4)
                          ],
                        ),
                        child: const Icon(Icons.favorite_rounded,
                            size: 18, color: Colors.red),
                      ),
                    ),
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
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (discountPrice != null)
                            Text(
                              'EGP ${(price / 100).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textHint,
                                  decoration: TextDecoration.lineThrough),
                            ),
                          Text(
                            'EGP ${displayPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 18),
                      ),
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border_rounded,
                  size: 52, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text(l.noFavorites,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(l.noFavoritesSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.go('/products'),
              icon: const Icon(Icons.restaurant_menu_rounded),
              label: Text(l.browseMenu),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _FavSkeleton extends StatelessWidget {
  const _FavSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 0.72,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      padding: const EdgeInsets.all(16),
      children: List.generate(
          6, (_) => const LoadingSkeletonWidget(borderRadius: 16)),
    );
  }
}
