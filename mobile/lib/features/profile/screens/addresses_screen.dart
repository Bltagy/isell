import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_skeleton_widget.dart';
import '../../cart/providers/cart_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final addressesProvider =
    AsyncNotifierProvider<AddressesNotifier, List<Map<String, dynamic>>>(
        AddressesNotifier.new);

class AddressesNotifier
    extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() => _fetch();

  Future<List<Map<String, dynamic>>> _fetch() async {
    final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
    final res = await dio.get('/api/v1/addresses');
    final data = res.data['data'];
    if (data is List) return List<Map<String, dynamic>>.from(data);
    return [];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> save(Map<String, dynamic> payload, {int? id}) async {
    try {
      final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
      if (id != null) {
        await dio.put('/api/v1/addresses/$id', data: payload);
      } else {
        await dio.post('/api/v1/addresses', data: payload);
      }
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
      await dio.delete('/api/v1/addresses/$id');
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key, this.selectMode = false});

  /// When true (pushed from checkout), tapping an address saves it to the
  /// cart and pops back. When false (from profile), shows edit/delete actions.
  final bool selectMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final addressesAsync = ref.watch(addressesProvider);
    final selectedId = ref.watch(cartProvider.select((s) => s.addressId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(selectMode ? l.selectAddress : l.myAddresses),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref, l),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(l.addAddress,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: addressesAsync.when(
        loading: () => const _Skeleton(),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(addressesProvider),
        ),
        data: (addresses) => addresses.isEmpty
            ? _Empty(label: l.noAddresses,
                subtitle: l.noAddressesSubtitle,
                onAdd: () => _showForm(context, ref, l))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref.read(addressesProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: addresses.length,
                  itemBuilder: (context, i) {
                    final addr = addresses[i];
                    final id = addr['id'] as int?;
                    final isSelected = id != null && id == selectedId;
                    return _Tile(
                      address: addr,
                      isSelected: isSelected,
                      selectMode: selectMode,
                      l: l,
                      onTap: () {
                        if (selectMode && id != null) {
                          ref.read(cartProvider.notifier).setAddress(id);
                          context.pop();
                        }
                      },
                      onEdit: () => _showForm(context, ref, l, existing: addr),
                      onDelete: () => _confirmDelete(context, ref, l, id!),
                    );
                  },
                ),
              ),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, AppLocalizations l,
      {Map<String, dynamic>? existing}) {
    // Result is set inside the sheet and read after it closes.
    // This guarantees the snackbar shows AFTER the sheet is fully dismissed,
    // so it's always on top — no overlay ordering issues.
    bool? saveResult;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormSheet(
        existing: existing,
        l: l,
        onSave: (payload) async {
          final ok = await ref
              .read(addressesProvider.notifier)
              .save(payload, id: existing?['id'] as int?);
          saveResult = ok;
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    ).then((_) {
      // Sheet is now fully closed — safe to show snackbar on top.
      if (saveResult != null && context.mounted) {
        _showSnack(
          context,
          saveResult! ? l.addressSaved : l.addressSaveFailed,
          isError: !saveResult!,
        );
      }
    });
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l, int id) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.deleteAddress),
        content: Text(l.deleteAddressConfirm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      final ok = await ref.read(addressesProvider.notifier).delete(id);
      if (context.mounted) {
        _showSnack(
          context,
          ok ? l.addressDeleted : l.addressDeleteFailed,
          isError: !ok,
        );
      }
    });
  }

  static void _showSnack(BuildContext context, String msg,
      {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : null,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));
  }
}

// ── Address tile ──────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  const _Tile({
    required this.address,
    required this.isSelected,
    required this.selectMode,
    required this.l,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> address;
  final bool isSelected;
  final bool selectMode;
  final AppLocalizations l;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final label = address['label'] as String? ?? l.myAddresses;
    final street = address['street'] as String? ?? '';
    final city = address['city'] as String? ?? '';
    final building = address['building'] as String? ?? '';
    final floor = address['floor'] as String? ?? '';
    final parts = [street, building, floor, city]
        .where((s) => s.isNotEmpty)
        .toList();
    final details = parts.join('، ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: selectMode ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on_rounded,
                    color:
                        isSelected ? AppColors.primary : AppColors.textHint,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(l.selected,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(details,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              if (!selectMode) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.textSecondary),
                  onPressed: onEdit,
                  tooltip: l.editAddress,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.error),
                  onPressed: onDelete,
                  tooltip: l.delete,
                ),
              ] else
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color:
                      isSelected ? AppColors.primary : AppColors.textHint,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add / Edit form sheet ─────────────────────────────────────────────────────

class _FormSheet extends StatefulWidget {
  const _FormSheet(
      {this.existing, required this.l, required this.onSave});
  final Map<String, dynamic>? existing;
  final AppLocalizations l;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  late final TextEditingController _label;
  late final TextEditingController _street;
  late final TextEditingController _city;
  late final TextEditingController _building;
  late final TextEditingController _floor;
  late final TextEditingController _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label    = TextEditingController(text: e?['label']    as String? ?? '');
    _street   = TextEditingController(text: e?['street']   as String? ?? '');
    _city     = TextEditingController(text: e?['city']     as String? ?? '');
    _building = TextEditingController(text: e?['building'] as String? ?? '');
    _floor    = TextEditingController(text: e?['floor']    as String? ?? '');
    _notes    = TextEditingController(text: e?['notes']    as String? ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _street.dispose();
    _city.dispose();
    _building.dispose();
    _floor.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_street.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.l.addressStreetRequired),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    await widget.onSave({
      'label':    _label.text.trim().isEmpty ? 'Home' : _label.text.trim(),
      'street':   _street.text.trim(),
      'city':     _city.text.trim(),
      'building': _building.text.trim(),
      'floor':    _floor.text.trim(),
      'notes':    _notes.text.trim(),
    });
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final isEdit = widget.existing != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEdit ? l.editAddress : l.newAddress,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    _F(ctrl: _label,    hint: l.addressLabel,    icon: Icons.label_outline),
                    const SizedBox(height: 12),
                    _F(ctrl: _street,   hint: '${l.addressStreet} *', icon: Icons.edit_road_outlined),
                    const SizedBox(height: 12),
                    _F(ctrl: _city,     hint: l.addressCity,     icon: Icons.location_city_outlined),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _F(ctrl: _building, hint: l.addressBuilding, icon: Icons.apartment_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _F(ctrl: _floor,    hint: l.addressFloor,    icon: Icons.stairs_outlined)),
                    ]),
                    const SizedBox(height: 12),
                    _F(ctrl: _notes, hint: l.addressNotes,
                        icon: Icons.note_outlined, maxLines: 2),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(isEdit ? l.saveChanges : l.addAddress),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _F extends StatelessWidget {
  const _F(
      {required this.ctrl,
      required this.hint,
      required this.icon,
      this.maxLines = 1});
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
            labelText: hint, prefixIcon: Icon(icon, size: 20)),
      );
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  const _Empty(
      {required this.label,
      required this.subtitle,
      required this.onAdd});
  final String label;
  final String subtitle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_off_outlined,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(label,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle,
              style:
                  const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(l.addAddress),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            LoadingSkeletonWidget(width: 44, height: 44, borderRadius: 12),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeletonWidget(
                      width: 80, height: 14, borderRadius: 6),
                  SizedBox(height: 8),
                  LoadingSkeletonWidget(height: 12, borderRadius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
