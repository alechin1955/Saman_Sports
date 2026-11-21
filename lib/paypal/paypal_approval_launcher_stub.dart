import 'package:url_launcher/url_launcher.dart';

import 'paypal_approval_tab.dart';

PaypalApprovalTab? abrirVentanaPaypal() => null;

Future<bool> navegarPaypal(Uri uri, PaypalApprovalTab? ventana) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
