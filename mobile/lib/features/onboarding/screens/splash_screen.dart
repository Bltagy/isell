import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../app_config/providers/app_config_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6)),
    );
    _ctrl.forward();
    _navigate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    final config = await ref
        .read(appConfigProvider.future)
        .catchError((_) => AppConfig.defaults);
    debugPrint('=== APP CONFIG ===');
    debugPrint('appName: ${config.appName}');
    debugPrint('logoUrl: ${config.logoUrl}');

    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final storage = StorageService();
    final onboardingDone = storage.getOnboardingDone();
    final authState = ref.read(authProvider);
    final isLoggedIn = authState.valueOrNull?.isAuthenticated ?? false;

    if (isLoggedIn) {
      context.go(AppRoutes.home);
    } else {
      context.go(onboardingDone ? AppRoutes.home : AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appConfigProvider);
    final appName = configAsync.valueOrNull?.appName ?? 'Food App';

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Opacity(
            opacity: _fade.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/images/app_icon.png',
                        fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Delicious food, delivered fast',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
