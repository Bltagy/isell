import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/loading_skeleton_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/config/app_config.dart';
import '../../app_config/providers/app_config_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
// PERF changes vs. before:
//  1. authProvider watched once → single subscription instead of two.
//  2. Banner page-change setState() is isolated inside _BannerCarousel so it
//     no longer triggers a full HomeScreen rebuild.
//  3. _ProductCard is now a plain StatelessWidget (no WidgetRef needed).
//  4. RepaintBoundary wraps every featured-product card.
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // PageController lives here so it's disposed with the screen.
  final _bannerController = PageController();

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeProvider);
    // PERF: single watch — was two separate .valueOrNull chains before
    final authState = ref.watch(authProvider).valueOrNull;
    final isAuth = authState?.isAuthenticated ?? false;
    final userName = authState?.user?['name'] as String? ?? 'Guest';
    final config =
        ref.watch(appConfigProvider).valueOrNull ?? AppConfig.defaults;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: homeAsync.when(
        loading: () => const _HomeSkeleton(),
        error: (e, _) => ErrorStateWidget(
            message: e.toString(),
            onRetry: () => ref.invalidate(homeProvider)),
        data: (data) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(homeProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              // ── Orange header ────────────────────────────────
              SliverToBoxAdapter(
                child: _HomeHeader(
                  isAuth: isAuth,
                  userName: userName,
                  config: config,
                  l: l,
                ),
              ),

              // ── Categories ───────────────────────────────────
              if (data.categories.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l.categories,
                            style: Theme.of(context).textTheme.titleLarge),
                        TextButton(
                            onPressed: () => context.push(AppRoutes.products),
                            child: Text(l.seeAll)),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 96,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: data.categories.length,
                      itemBuilder: (context, i) =>
                          _CategoryChip(category: data.categories[i]),
                    ),
                  ),
                ),
              ],

              // ── Banners ──────────────────────────────────────
              // PERF: _BannerCarousel owns its own setState — page changes
              // no longer rebuild the entire HomeScreen.
              if (data.banners.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: _BannerCarousel(
                      banners: data.banners,
                      controller: _bannerController,
                    ),
                  ),
                ),

              // ── Popular Foods ────────────────────────────────
              if (data.featuredProducts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l.popularFoods,
                            style: Theme.of(context).textTheme.titleLarge),
                        TextButton(
                            onPressed: () => context.push(AppRoutes.products),
                            child: Text(l.viewAll)),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      // PERF: RepaintBoundary isolates each card's paint layer
                      (context, i) => RepaintBoundary(
                        child: _ProductCard(product: data.featuredProducts[i]),
                      ),
                      childCount: data.featuredProducts.length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
// Extracted so it can be const-constructed when inputs haven't changed.

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.isAuth,
    required this.userName,
    required this.config,
    required this.l,
  });

  final bool isAuth;
  final String userName;
  final AppConfig config;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Logo
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x1F000000), blurRadius: 6),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: config.logoUrl != null
                        ? AppImage(
                            url: config.logoUrl!,
                            fit: BoxFit.contain,
                            placeholderIcon: Icons.fastfood_rounded,
                          )
                        : Image.asset('assets/images/app_icon.png',
                            fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAuth
                              ? l.helloUser(userName.split(' ').first)
                              : l.helloGuest,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xD9FFFFFF), fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.whatToEat,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.2),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.notifications),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Tappable search bar (navigates to product list)
              GestureDetector(
                onTap: () => context.push(AppRoutes.products),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 12,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.search_rounded,
                          color: AppColors.textHint, size: 22),
                      const SizedBox(width: 10),
                      Text(l.searchFood,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textHint, fontSize: 14)),
                      const Spacer(),
                      Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.tune_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Banner carousel ───────────────────────────────────────────────────────────
// PERF: owns its own _page state — page swipes no longer rebuild HomeScreen.

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.banners, required this.controller});
  final List<Map<String, dynamic>> banners;
  final PageController controller;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        children: [
          PageView.builder(
            controller: widget.controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) =>
                _BannerCard(banner: widget.banners[i]),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.banners.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _page == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? AppColors.primary
                        : const Color(0x99FFFFFF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banner card ───────────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});
  final Map<String, dynamic> banner;

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        banner['image_url'] as String? ?? banner['image'] as String? ?? '';
    final title = banner['title_en'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppImage(
            url: imageUrl,
            fit: BoxFit.cover,
            placeholderIcon: Icons.local_offer_outlined,
            placeholderColor: const Color(0x33FF6B35),
          ),
          // Gradient overlay
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x99000000), Colors.transparent],
              ),
            ),
          ),
          if (title.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      AppLocalizations.of(context).specialOffer,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.2)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final Map<String, dynamic> category;

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        category['image_url'] as String? ?? category['image'] as String? ?? '';
    final locale = Localizations.localeOf(context).languageCode;
    final name = (locale == 'ar'
            ? (category['name_ar'] ?? category['name_en'])
            : (category['name_en'] ?? category['name_ar'])) as String? ??
        '';

    return GestureDetector(
      onTap: () => context
          .push('${AppRoutes.products}?category_id=${category['id']}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 8,
                      offset: Offset(0, 2)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: AppImage(
                  url: imageUrl,
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.category_outlined),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────
// PERF: downgraded from ConsumerWidget → StatelessWidget.
// It never needed WidgetRef — removing it saves a Riverpod subscription.

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
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
                          placeholderIcon: Icons.fastfood),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x14000000), blurRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.favorite_border_rounded,
                          size: 18, color: AppColors.textHint),
                    ),
                  ),
                  if (discountPrice != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '-${(((price - discountPrice) / price) * 100).round()}%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.star, size: 14),
                      Text(' 4.5',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                      const Spacer(),
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textHint),
                      Text(' ${prepTime}m',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (discountPrice != null)
                            Text(
                              'EGP ${(price / 100).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: AppColors.textHint,
                                  decoration: TextDecoration.lineThrough),
                            ),
                          Text(
                            'EGP ${((discountPrice ?? price) / 100).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
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

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header placeholder
        Container(
          height: 180,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              const LoadingSkeletonWidget(width: 100, height: 18, borderRadius: 6),
              const SizedBox(height: 16),
              // Category chips
              Row(
                children: List.generate(
                  4,
                  (_) => const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: LoadingSkeletonWidget(
                        width: 60, height: 60, borderRadius: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Banner placeholder
              const LoadingSkeletonWidget(height: 160, borderRadius: 20),
              const SizedBox(height: 20),
              // Section title
              const LoadingSkeletonWidget(width: 120, height: 18, borderRadius: 6),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: List.generate(
                    4, (_) => const LoadingSkeletonWidget(borderRadius: 16)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
