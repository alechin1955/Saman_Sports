import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'paypal_webview_screen.dart';

class PaypalService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<bool> procesarPago({
    required BuildContext context,
    required double monto,
    String moneda = 'USD',
  }) async {
    try {
      // 1. Crear la orden en Firebase Functions
      final createCallable = _functions.httpsCallable('createPaypalOrder');
      final response = await createCallable.call({
        'amount': monto.toStringAsFixed(2),
        'currency': moneda,
      });

      final String approvalUrl = response.data['approvalUrl'];

      if (!context.mounted) return false;

      // 2. Abrir el WebView para que el usuario inicie sesión y apruebe
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaypalWebviewScreen(approvalUrl: approvalUrl),
        ),
      );

      // 3. Si aprobó, capturar el dinero en Firebase Functions
      if (result != null && result['status'] == 'success') {
        final String orderId = result['orderId'];

        final captureCallable = _functions.httpsCallable('capturePaypalOrder');
        final captureResponse = await captureCallable.call({
          'orderId': orderId,
        });

        return captureResponse.data['success'] == true;
      }

      return false; // Usuario canceló o cerró la ventana
    } catch (e) {
      debugPrint('Error en PayPal: $e');
      return false;
    }
  }
}