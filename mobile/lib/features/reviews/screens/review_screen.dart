import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({
    super.key,
    required this.orderId,
    required this.products,
  });

  final String orderId;
  final List<Map<String, dynamic>> products;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  // productId -> rating
  final Map<int, int> _ratings = {};
  // productId -> comment
  final Map<int, TextEditingController> _comments = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final p in widget.products) {
      final id = p['id'] as int;
      _ratings[id] = 5;
      _comments[id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final box = StorageService().appConfigBox;
      final baseUrl =
          box.get('base_url', defaultValue: 'http://localhost') as String;
      final dio = ApiClient.create(baseUrl: baseUrl);

      for (final p in widget.products) {
        final id = p['id'] as int;
        await dio.post('/api/v1/reviews', data: {
          'order_id': int.tryParse(widget.orderId) ?? widget.orderId,
          'product_id': id,
          'rating': _ratings[id] ?? 5,
          'comment': _comments[id]?.text.trim(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reviews submitted. Thank you!')),
        );
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.error?.toString() ?? 'Failed to submit')),
        );
      }
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Your Order')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...widget.products.map((p) {
            final id = p['id'] as int;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name_en'] as String? ?? 'Product',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Star rating
                    Row(
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        return IconButton(
                          icon: Icon(
                            star <= (_ratings[id] ?? 5)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () =>
                              setState(() => _ratings[id] = star),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _comments[id],
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Leave a comment (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: _submitting
                ? const CircularProgressIndicator()
                : const Text('Submit Reviews'),
          ),
        ],
      ),
    );
  }
}
