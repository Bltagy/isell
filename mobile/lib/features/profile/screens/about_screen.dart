import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/loading_skeleton_widget.dart';
import '../../app_config/providers/app_config_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _aboutProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
  try {
    final res = await dio.get('/api/v1/settings/about');
    final data = res.data['data'];
    if (data is Map<String, dynamic>) return data;
  } catch (_) {}
  return {};
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final aboutAsync = ref.watch(_aboutProvider);
    final config = ref.watch(appConfigProvider).valueOrNull ?? AppConfig.defaults;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.aboutApp),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: aboutAsync.when(
        loading: () => const _AboutSkeleton(),
        error: (_, __) => _AboutContent(data: const {}, config: config, locale: locale, l: l),
        data: (data) => _AboutContent(data: data, config: config, locale: locale, l: l),
      ),
    );
  }
}

class _AboutContent extends StatelessWidget {
  const _AboutContent({
    required this.data,
    required this.config,
    required this.locale,
    required this.l,
  });

  final Map<String, dynamic> data;
  final AppConfig config;
  final String locale;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final appName = data['app_name'] as String? ?? config.appName;
    final version = data['version'] as String? ?? '1.0.0';
    final description = (locale == 'ar'
        ? (data['description_ar'] ?? data['description_en'])
        : (data['description_en'] ?? data['description_ar'])) as String? ?? '';
    final email = data['contact_email'] as String? ?? '';
    final phone = data['contact_phone'] as String? ?? '';
    final privacyEn = data['privacy_policy_en'] as String? ?? '';
    final privacyAr = data['privacy_policy_ar'] as String? ?? '';
    final termsEn   = data['terms_en'] as String? ?? '';
    final termsAr   = data['terms_ar'] as String? ?? '';
    final privacyText = locale == 'ar'
        ? (privacyAr.isNotEmpty ? privacyAr : privacyEn)
        : (privacyEn.isNotEmpty ? privacyEn : privacyAr);
    final termsText = locale == 'ar'
        ? (termsAr.isNotEmpty ? termsAr : termsEn)
        : (termsEn.isNotEmpty ? termsEn : termsAr);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── App identity card ─────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10)
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
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
              const SizedBox(height: 16),
              Text(appName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('v$version',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.6,
                        fontSize: 14)),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Info rows ─────────────────────────────────────────
        if (email.isNotEmpty || phone.isNotEmpty) ...[
          _SectionTitle(l.contactUs),
          const SizedBox(height: 10),
          if (email.isNotEmpty)
            _InfoTile(
              icon: Icons.email_outlined,
              label: l.email,
              value: email,
            ),
          if (phone.isNotEmpty)
            _InfoTile(
              icon: Icons.phone_outlined,
              label: l.phone,
              value: phone,
            ),
          const SizedBox(height: 20),
        ],

        // ── Legal content ─────────────────────────────────────
        if (privacyText.isNotEmpty || termsText.isNotEmpty) ...[
          _SectionTitle(l.about),
          const SizedBox(height: 10),
          if (privacyText.isNotEmpty)
            _ExpandableTile(
              icon: Icons.privacy_tip_outlined,
              label: l.privacyPolicy,
              content: privacyText,
            ),
          if (termsText.isNotEmpty)
            _ExpandableTile(
              icon: Icons.gavel_outlined,
              label: l.termsConditions,
              content: termsText,
            ),
          const SizedBox(height: 20),
        ],

        const SizedBox(height: 32),
        Center(
          child: Text(
            '© ${DateTime.now().year} $appName',
            style: const TextStyle(
                color: AppColors.textHint, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5));
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableTile extends StatefulWidget {
  const _ExpandableTile(
      {required this.icon, required this.label, required this.content});
  final IconData icon;
  final String label;
  final String content;

  @override
  State<_ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<_ExpandableTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: AppColors.primary, size: 20),
          ),
          title: Text(widget.label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          trailing: AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textHint),
          ),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          children: [
            Text(widget.content,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.6)),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _AboutSkeleton extends StatelessWidget {
  const _AboutSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                LoadingSkeletonWidget(width: 80, height: 80, borderRadius: 20),
                SizedBox(height: 16),
                LoadingSkeletonWidget(width: 140, height: 22, borderRadius: 8),
                SizedBox(height: 10),
                LoadingSkeletonWidget(width: 60, height: 24, borderRadius: 12),
                SizedBox(height: 16),
                LoadingSkeletonWidget(height: 14, borderRadius: 6),
                SizedBox(height: 8),
                LoadingSkeletonWidget(height: 14, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
