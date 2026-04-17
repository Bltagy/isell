import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/storage/storage_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _success = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final box = StorageService().appConfigBox;
      final baseUrl =
          box.get('base_url', defaultValue: 'http://localhost') as String;
      final dio = ApiClient.create(baseUrl: baseUrl);
      await dio.post('/api/v1/auth/forgot-password', data: {
        'email': _emailCtrl.text.trim(),
      });
      setState(() {
        _success = true;
        _message = 'Password reset link sent to your email.';
      });
    } on DioException catch (e) {
      setState(() {
        _message = e.error?.toString() ?? 'Something went wrong.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: TextStyle(
                  color: _success
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading || _success ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Send Reset Link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
