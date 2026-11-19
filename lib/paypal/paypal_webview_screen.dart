import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaypalWebviewScreen extends StatefulWidget {
  final String approvalUrl;

  const PaypalWebviewScreen({super.key, required this.approvalUrl});

  @override
  State<PaypalWebviewScreen> createState() => _PaypalWebviewScreenState();
}

class _PaypalWebviewScreenState extends State<PaypalWebviewScreen> {
  late final WebViewController _controller;

  // Deben coincidir exactamente con las de tu functions/index.js
  final String _returnUrl = 'https://tu-app.com/paypal-success';
  final String _cancelUrl = 'https://tu-app.com/paypal-cancel';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // 1. Pago aprobado por el usuario
            if (request.url.startsWith(_returnUrl)) {
              final uri = Uri.parse(request.url);
              final orderId = uri.queryParameters['token'];
              Navigator.pop(context, {'status': 'success', 'orderId': orderId});
              return NavigationDecision.prevent;
            }

            // 2. Pago cancelado por el usuario
            if (request.url.startsWith(_cancelUrl)) {
              Navigator.pop(context, {'status': 'cancelled'});
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.approvalUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagar con PayPal')),
      body: WebViewWidget(controller: _controller),
    );
  }
}