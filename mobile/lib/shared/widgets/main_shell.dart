import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/cart/providers/cart_provider.dart';
import '../../l10n/app_localizations.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static int _indexFromLocation(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/cart')) return 2;
    if (location.startsWith('/orders')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFromLocation(location);
    // PERF: select() — only rebuilds when the total count changes, not on any
    // CartState mutation (e.g. address or promo code updates).
    final cartCount = ref.watch(
      cartProvider.select((s) => s.items.fold(0, (sum, i) => sum + i.quantity)),
    );
    // PERF: select() — only rebuilds when isAuthenticated flips
    final isAuth = ref.watch(
      authProvider.select((a) => a.valueOrNull?.isAuthenticated ?? false),
    );
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: _NavBar(
        currentIndex: currentIndex,
        cartCount: cartCount,
        isAuth: isAuth,
        l: l,
        onHome:    () => context.go(AppRoutes.home),
        onMenu:    () => context.go(AppRoutes.products),
        onCart:    () => context.go(AppRoutes.cart),
        onOrders:  () => isAuth ? context.go(AppRoutes.orders)  : context.go(AppRoutes.auth),
        onProfile: () => isAuth ? context.go(AppRoutes.profile) : context.go(AppRoutes.auth),
      ),
    );
  }
}

// ── Nav bar with floating center cart button ──────────────────────────────────

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.currentIndex,
    required this.cartCount,
    required this.isAuth,
    required this.l,
    required this.onHome,
    required this.onMenu,
    required this.onCart,
    required this.onOrders,
    required this.onProfile,
  });

  final int currentIndex;
  final int cartCount;
  final bool isAuth;
  final AppLocalizations l;
  final VoidCallback onHome;
  final VoidCallback onMenu;
  final VoidCallback onCart;
  final VoidCallback onOrders;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 72,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // White bar
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
              ),
            ),

            // Four nav items + center gap
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(icon: Icons.home_rounded,         label: l.home,    index: 0, current: currentIndex, onTap: onHome),
                  _NavItem(icon: Icons.grid_view_rounded,    label: l.ourMenu, index: 1, current: currentIndex, onTap: onMenu),
                  const SizedBox(width: 72), // gap for FAB
                  _NavItem(icon: Icons.receipt_long_rounded, label: l.orders,  index: 3, current: currentIndex, onTap: onOrders),
                  _NavItem(icon: Icons.person_rounded,       label: l.profile, index: 4, current: currentIndex, onTap: onProfile),
                ],
              ),
            ),

            // Floating cart button — sits above the bar
            Positioned(
              top: -22,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onCart,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 26),
                        if (cartCount > 0)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 17,
                              height: 17,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  cartCount > 9 ? '9+' : '$cartCount',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single nav item ───────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: selected ? AppColors.primary : AppColors.textHint),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 68,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? AppColors.primary : AppColors.textHint,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
