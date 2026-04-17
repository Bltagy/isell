import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/checkout/screens/kashier_payment_screen.dart';
import '../../features/checkout/screens/order_failure_screen.dart';
import '../../features/checkout/screens/order_success_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/offers/screens/offers_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/order_tracking_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/products/screens/product_list_screen.dart';
import '../../features/profile/screens/addresses_screen.dart';
import '../../features/profile/screens/about_screen.dart';
import '../../features/profile/screens/help_support_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../shared/widgets/main_shell.dart';

class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const forgotPassword = '/auth/forgot-password';
  static const home = '/home';
  static const products = '/products';
  static const productDetail = '/products/:id';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const checkoutPayment = '/checkout/payment';
  static const checkoutSuccess = '/checkout/success/:orderId';
  static const checkoutFailure = '/checkout/failure/:orderId';
  static const orders = '/orders';
  static const orderDetail = '/orders/:id';
  static const orderTracking = '/orders/:id/track';
  static const offers = '/offers';
  static const profile = '/profile';
  // Top-level so it can be pushed from any navigator context (e.g. checkout)
  static const profileAddresses = '/addresses';
  static const favorites = '/favorites';
  static const about = '/about';
  static const helpSupport = '/help';
  static const notifications = '/notifications';
}

const _guestRoutes = [
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.auth,
  AppRoutes.forgotPassword,
  AppRoutes.home,
  AppRoutes.products,
  AppRoutes.offers,
];

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = notifier.isAuthenticated;
      final location = state.matchedLocation;
      final isGuest = _guestRoutes.any((r) => location.startsWith(r));
      if (!isAuthenticated && !isGuest) return AppRoutes.auth;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash,     builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(
        path: AppRoutes.auth,
        builder: (_, __) => const AuthScreen(),
        routes: [
          GoRoute(path: 'forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
        ],
      ),

      // ── Shell routes (bottom nav) ──────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.home,     builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.products, builder: (_, __) => const ProductListScreen()),
          GoRoute(
            path: AppRoutes.productDetail,
            builder: (context, state) =>
                ProductDetailScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(path: AppRoutes.cart,   builder: (_, __) => const CartScreen()),
          GoRoute(path: AppRoutes.offers, builder: (_, __) => const OffersScreen()),
          GoRoute(
            path: AppRoutes.orders,
            builder: (_, __) => const OrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: OrderDetailScreen(orderId: state.pathParameters['id']!),
                ),
                routes: [
                  GoRoute(
                    path: 'track',
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: OrderTrackingScreen(orderId: state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (_, __) => const NotificationsScreen(),
          ),
        ],
      ),

      // ── Full-screen routes (no bottom nav) ─────────────────────────────────
      // Addresses — top-level so it can be pushed from checkout OR profile
      // without hitting the ShellRoute navigator boundary.
      GoRoute(
        path: AppRoutes.profileAddresses,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final selectMode = extra['selectMode'] as bool? ?? false;
          return AddressesScreen(selectMode: selectMode);
        },
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (_, __) => const FavoritesScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (_, __) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.helpSupport,
        builder: (_, __) => const HelpSupportScreen(),
      ),

      GoRoute(
        path: AppRoutes.checkout,
        builder: (_, __) => const CheckoutScreen(),
        routes: [
          GoRoute(
            path: 'payment',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return KashierPaymentScreen(
                paymentUrl: extra['paymentUrl'] as String? ?? '',
                orderId:    extra['orderId']    as String? ?? '0',
              );
            },
          ),
          GoRoute(
            path: 'success/:orderId',
            builder: (context, state) =>
                OrderSuccessScreen(orderId: state.pathParameters['orderId']!),
          ),
          GoRoute(
            path: 'failure/:orderId',
            builder: (context, state) =>
                OrderFailureScreen(orderId: state.pathParameters['orderId']!),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );

  ref.onDispose(notifier.dispose);
  return router;
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<AuthState>>(
      authProvider,
      (_, next) {
        _isAuthenticated = next.valueOrNull?.isAuthenticated ?? false;
        notifyListeners();
      },
    );
    _isAuthenticated =
        _ref.read(authProvider).valueOrNull?.isAuthenticated ?? false;
  }

  final Ref _ref;
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
}
