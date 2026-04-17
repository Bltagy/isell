import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../locale/providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _profileLoading = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadProfile());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _maybeLoadProfile() {
    final authState = ref.read(authProvider).valueOrNull;
    final isAuth = authState?.isAuthenticated ?? false;
    if (!isAuth) return;

    // Use user data already in auth state if available (avoids extra API call)
    if (authState?.user != null && _profile == null) {
      final u = authState!.user!;
      setState(() {
        _profile = u;
        _nameCtrl.text = u['name'] as String? ?? '';
        _emailCtrl.text = u['email'] as String? ?? '';
      });
    } else if (_profile == null) {
      _fetchProfile();
    }
  }

  Future<void> _fetchProfile() async {
    setState(() => _profileLoading = true);
    try {
      final baseUrl = StorageService().getBaseUrl();
      final dio = ApiClient.create(baseUrl: baseUrl);
      final res = await dio.get('/api/v1/profile');
      final profile = res.data['data'] as Map<String, dynamic>;
      if (mounted) setState(() {
        _profile = profile;
        _nameCtrl.text = profile['name'] as String? ?? '';
        _emailCtrl.text = profile['email'] as String? ?? '';
        _profileLoading = false;
      });
    } on DioException catch (_) {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final authAsync = ref.watch(authProvider);
    final isAuth = authAsync.valueOrNull?.isAuthenticated ?? false;
    final l = AppLocalizations.of(context);

    // When auth state transitions to authenticated, load profile once.
    ref.listen<AsyncValue<AuthState>>(authProvider, (prev, next) {
      final wasAuth = prev?.valueOrNull?.isAuthenticated ?? false;
      final nowAuth = next.valueOrNull?.isAuthenticated ?? false;
      if (!wasAuth && nowAuth && _profile == null) {
        _maybeLoadProfile();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.person_rounded, size: 48, color: Colors.white),
                      ),
                      if (isAuth)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 28, height: 28,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _profileLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          isAuth ? (_profile?['name'] as String? ?? 'User') : l.guestUser,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    isAuth ? (_profile?['email'] as String? ?? '') : l.signInToAccess,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Sign in button (guests only) ─────────────────
            if (!isAuth) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.auth),
                  child: Text(l.signIn),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Menu items ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (isAuth) ...[
                    _ProfileMenuItem(icon: Icons.location_on_outlined, label: l.myAddresses, onTap: () => context.push(AppRoutes.profileAddresses)),
                    _ProfileMenuItem(icon: Icons.receipt_long_outlined, label: l.orders, onTap: () => context.go(AppRoutes.orders)),
                    _ProfileMenuItem(icon: Icons.favorite_outline_rounded, label: l.favorites, onTap: () => context.push(AppRoutes.favorites)),
                    const SizedBox(height: 8),
                  ],

                  // ── Language switcher — always visible ───────
                  _ProfileMenuItem(
                    icon: Icons.language_rounded,
                    label: l.language,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        locale.languageCode == 'ar' ? '🇸🇦 العربية' : '🇺🇸 English',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    onTap: () => ref.read(localeProvider.notifier).toggle(),
                  ),

                  _ProfileMenuItem(icon: Icons.notifications_outlined, label: l.notifications, onTap: () => context.push(AppRoutes.notifications)),
                  _ProfileMenuItem(icon: Icons.help_outline_rounded, label: l.helpSupport, onTap: () => context.push(AppRoutes.helpSupport)),
                  _ProfileMenuItem(icon: Icons.info_outline_rounded, label: l.aboutApp, onTap: () => context.push(AppRoutes.about)),

                  if (isAuth) ...[
                    const SizedBox(height: 8),
                    _ProfileMenuItem(
                      icon: Icons.logout_rounded,
                      label: l.logout,
                      labelColor: AppColors.error,
                      iconColor: AppColors.error,
                      onTap: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go(AppRoutes.home);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Menu item ─────────────────────────────────────────────────────────────────

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon, required this.label, required this.onTap,
    this.trailing, this.labelColor, this.iconColor,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? labelColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
        ),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: labelColor ?? AppColors.textPrimary)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
