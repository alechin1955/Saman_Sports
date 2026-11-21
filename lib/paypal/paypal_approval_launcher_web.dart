import 'package:web/web.dart' as web;

import 'paypal_approval_tab.dart';

PaypalApprovalTab? abrirVentanaPaypal() {
  final window = web.window.open('about:blank', '_blank');
  return window == null ? null : _PaypalApprovalTab(window);
}

Future<bool> navegarPaypal(Uri uri, PaypalApprovalTab? ventana) async {
  if (ventana == null) return false;
  ventana.navegar(uri);
  return true;
}

class _PaypalApprovalTab implements PaypalApprovalTab {
  _PaypalApprovalTab(this._window);

  final web.Window _window;

  @override
  void navegar(Uri uri) {
    _window.location.href = uri.toString();
  }

  @override
  void cerrar() {
    _window.close();
  }
}
