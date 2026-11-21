import 'paypal_approval_tab.dart';
import 'paypal_approval_launcher_stub.dart'
    if (dart.library.js_interop) 'paypal_approval_launcher_web.dart'
    as implementation;

export 'paypal_approval_tab.dart';

PaypalApprovalTab? abrirVentanaPaypal() =>
    implementation.abrirVentanaPaypal();

Future<bool> navegarPaypal(Uri uri, PaypalApprovalTab? ventana) =>
    implementation.navegarPaypal(uri, ventana);

void cerrarVentanaPaypal(PaypalApprovalTab? ventana) =>
    ventana?.cerrar();
