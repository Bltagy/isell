import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KashierPaymentScreen extends StatefulWidget {
  const KashierPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.orderId,
  });

  final String paymentUrl;
  final String orderId;

  @override
  State<KashierPaymentScreen> createState() => _KashierPaymentScreenState();
}

class _KashierPaymentScreenState extends State<KashierPaymentScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.contains('/payment/success') ||
                url.contains('payment_status=SUCCESS')) {
              context.go('/checkout/success/${widget.orderId}');
              return NavigationDecision.prevent;
            }
            if (url.contains('/payment/failure') ||
                url.contains('payment_status=FAILURE') ||
                url.contains('payment_status=CANCEL')) {
              context.go('/checkout/failure/${widget.orderId}');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/checkout/failure/${widget.orderId}'),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
