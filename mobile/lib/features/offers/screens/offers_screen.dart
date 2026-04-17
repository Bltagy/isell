import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';

final _offersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ApiClient.create(baseUrl: StorageService().getBaseUrl());
  final res = await dio.get('/api/v1/offers/active');
  final data = res.data['data'];
  if (data is List) return List<Map<String, dynamic>>.from(data);
  if (data is Map) {
    final offers = data['offers'] ?? data['data'] ?? [];
    return List<Map<String, dynamic>>.from(offers as List);
  }
  return [];
});

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(_offersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers & Promo Codes'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: offersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (offers) {
          if (offers.isEmpty) {
            return const Center(child: Text('No offers available'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Promo Codes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 12),
              ...offers.map((offer) => _PromoCodeTile(promo: offer)),
            ],
          );
        },
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});
  final Map<String, dynamic> offer;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              offer['code'] as String? ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              _describeOffer(offer),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _describeOffer(Map<String, dynamic> offer) {
    final type = offer['type'] as String? ?? '';
    final value = offer['value'] as int? ?? 0;
    switch (type) {
      case 'percentage':
        return '$value% off';
      case 'fixed':
        return 'EGP ${(value / 100).toStringAsFixed(2)} off';
      case 'free_delivery':
        return 'Free delivery';
      default:
        return '';
    }
  }
}

class _PromoCodeTile extends StatelessWidget {
  const _PromoCodeTile({required this.promo});
  final Map<String, dynamic> promo;

  @override
  Widget build(BuildContext context) {
    final code = promo['code'] as String? ?? '';
    return Card(
      child: ListTile(
        title: Text(code,
            style: const TextStyle(
                fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        subtitle: Text(_describeOffer(promo)),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          tooltip: 'Copy code',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code copied!')),
            );
          },
        ),
      ),
    );
  }

  String _describeOffer(Map<String, dynamic> offer) {
    final type = offer['type'] as String? ?? '';
    final value = offer['value'] as int? ?? 0;
    switch (type) {
      case 'percentage':
        return '$value% off';
      case 'fixed':
        return 'EGP ${(value / 100).toStringAsFixed(2)} off';
      case 'free_delivery':
        return 'Free delivery';
      default:
        return '';
    }
  }
}
