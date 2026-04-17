import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../locale/providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Navigate to home only when truly authenticated — NOT on loading/error.
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
      if (next.valueOrNull?.isAuthenticated == true) {
        context.go(AppRoutes.home);
      }
    });

    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Orange header ────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Image.asset('assets/images/app_icon.png', fit: BoxFit.contain),
                        ),
                        const Spacer(),
                        Consumer(builder: (context, ref, _) {
                          final locale = ref.watch(localeProvider);
                          return GestureDetector(
                            onTap: () => ref.read(localeProvider.notifier).toggle(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.language_rounded, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    locale.languageCode == 'ar' ? 'EN' : 'عربي',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(l.welcomeBack,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, height: 1.1)),
                    const SizedBox(height: 6),
                    Text(l.signInSubtitle,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
                    const SizedBox(height: 28),
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: Colors.white,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        dividerColor: Colors.transparent,
                        onTap: (_) {
                          // Clear any lingering error when switching tabs
                          ref.read(authProvider.notifier).clearError();
                        },
                        tabs: [Tab(text: l.signIn), Tab(text: l.register)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Tab content ──────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_LoginTab(), _RegisterTab()],
            ),
          ),

          // ── Guest button ─────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                children: [
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.home),
                      icon: const Icon(Icons.explore_outlined, size: 20),
                      label: Text(l.browseAsGuest),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared error banner ───────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.error, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ── Login tab ─────────────────────────────────────────────────────────────────

class _LoginTab extends ConsumerStatefulWidget {
  const _LoginTab();
  @override
  ConsumerState<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends ConsumerState<_LoginTab> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone => '+2${_phoneCtrl.text.trim()}';

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    final loading = authAsync.isLoading;
    // Error lives in state.value.errorMessage — never in state.error
    final errorMsg = authAsync.valueOrNull?.errorMessage;
    final l = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMsg != null) _ErrorBanner(errorMsg),

          _PhoneField(controller: _phoneCtrl, label: l.phone),
          const SizedBox(height: 16),
          _AppTextField(
            controller: _passCtrl,
            label: l.password,
            hint: l.passwordHint,
            icon: Icons.lock_outline,
            obscureText: _obscure,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20, color: AppColors.textHint,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/auth/forgot-password'),
              child: Text(l.forgotPassword),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: loading
                ? null
                : () {
                    ref.read(authProvider.notifier).clearError();
                    ref.read(authProvider.notifier).loginWithPhone(
                          _fullPhone,
                          _passCtrl.text,
                        );
                  },
            child: loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(l.signIn),
          ),
        ],
      ),
    );
  }
}

// ── Register tab ──────────────────────────────────────────────────────────────

class _RegisterTab extends ConsumerStatefulWidget {
  const _RegisterTab();
  @override
  ConsumerState<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends ConsumerState<_RegisterTab> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone => '+2${_phoneCtrl.text.trim()}';

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    final loading = authAsync.isLoading;
    final errorMsg = authAsync.valueOrNull?.errorMessage;
    final l = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMsg != null) _ErrorBanner(errorMsg),

          _AppTextField(
            controller: _nameCtrl,
            label: l.fullName,
            hint: 'Ahmed Mohamed',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _PhoneField(controller: _phoneCtrl, label: l.phone),
          const SizedBox(height: 16),
          _AppTextField(
            controller: _passCtrl,
            label: l.password,
            hint: l.passwordHint,
            icon: Icons.lock_outline,
            obscureText: _obscure,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20, color: AppColors.textHint,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: loading
                ? null
                : () {
                    ref.read(authProvider.notifier).clearError();
                    ref.read(authProvider.notifier).register(
                          name: _nameCtrl.text.trim(),
                          phone: _fullPhone,
                          password: _passCtrl.text,
                        );
                  },
            child: loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(l.createAccount),
          ),
        ],
      ),
    );
  }
}

// ── Phone field ───────────────────────────────────────────────────────────────

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              hintText: '01152229464',
              hintTextDirection: TextDirection.ltr,
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('+2',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    Container(width: 1, height: 20, color: AppColors.divider),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Generic text field ────────────────────────────────────────────────────────

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: AppColors.textHint),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
