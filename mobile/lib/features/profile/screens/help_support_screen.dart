import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_skeleton_widget.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _helpProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
  try {
    final res = await dio.get('/api/v1/settings/help');
    final data = res.data['data'];
    if (data is Map<String, dynamic>) return data;
  } catch (_) {}
  return {};
});

// ── Screen ────────────────────────────────────────────────────────────────────

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final helpAsync = ref.watch(_helpProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.helpSupportTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: helpAsync.when(
        loading: () => const _HelpSkeleton(),
        error: (_, __) =>
            _HelpContent(data: const {}, l: l),
        data: (data) => _HelpContent(data: data, l: l),
      ),
    );
  }
}

class _HelpContent extends StatelessWidget {
  const _HelpContent({required this.data, required this.l});
  final Map<String, dynamic> data;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final email = data['support_email'] as String? ?? '';
    final phone = data['support_phone'] as String? ?? '';
    final whatsapp = data['whatsapp'] as String? ?? '';
    final rawFaq = data['faq'] as List? ?? [];
    final faqItems = rawFaq
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Contact card ──────────────────────────────────────
        if (email.isNotEmpty || phone.isNotEmpty || whatsapp.isNotEmpty) ...[
          _SectionTitle(l.contactSupport),
          const SizedBox(height: 10),
          if (email.isNotEmpty)
            _ContactTile(
              icon: Icons.email_outlined,
              label: l.email,
              value: email,
              color: AppColors.primary,
            ),
          if (phone.isNotEmpty)
            _ContactTile(
              icon: Icons.phone_outlined,
              label: l.phone,
              value: phone,
              color: AppColors.success,
            ),
          if (whatsapp.isNotEmpty)
            _ContactTile(
              icon: Icons.chat_outlined,
              label: 'WhatsApp',
              value: whatsapp,
              color: const Color(0xFF25D366),
            ),
          const SizedBox(height: 24),
        ],

        // ── FAQ ───────────────────────────────────────────────
        _SectionTitle(l.faq),
        const SizedBox(height: 10),
        if (faqItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(l.noFaqItems,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...faqItems.map((item) {
            final question = (locale == 'ar'
                ? (item['question_ar'] ?? item['question_en'])
                : (item['question_en'] ?? item['question_ar'])) as String? ?? '';
            final answer = (locale == 'ar'
                ? (item['answer_ar'] ?? item['answer_en'])
                : (item['answer_en'] ?? item['answer_ar'])) as String? ?? '';
            return _FaqTile(question: question, answer: answer);
          }),
      ],
    );
  }
}

// ── FAQ expandable tile ───────────────────────────────────────────────────────

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.help_outline_rounded,
                color: AppColors.primary, size: 18),
          ),
          title: Text(
            widget.question,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
          ),
          trailing: AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textHint),
          ),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          children: [
            Text(
              widget.answer,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Contact tile ──────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

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
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        subtitle: Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        trailing: Icon(Icons.open_in_new_rounded, color: color, size: 18),
        onTap: () {/* TODO: launch URL/phone/email */},
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
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

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _HelpSkeleton extends StatelessWidget {
  const _HelpSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingSkeletonWidget(width: 120, height: 14, borderRadius: 6),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: const [
                  LoadingSkeletonWidget(
                      width: 40, height: 40, borderRadius: 10),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LoadingSkeletonWidget(
                            width: 60, height: 11, borderRadius: 4),
                        SizedBox(height: 6),
                        LoadingSkeletonWidget(height: 14, borderRadius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const LoadingSkeletonWidget(width: 80, height: 14, borderRadius: 6),
          const SizedBox(height: 12),
          ...List.generate(
            4,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const LoadingSkeletonWidget(height: 14, borderRadius: 6),
            ),
          ),
        ],
      ),
    );
  }
}
