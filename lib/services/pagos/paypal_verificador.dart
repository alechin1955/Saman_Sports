// HOY LA VERIFICACIÓN ES SIMULADA. La verificación real con la API de PayPal
// (Orders v2: GET /v2/checkout/orders/{id}, estado COMPLETED, monto y moneda)
// requiere el client secret, que NO puede vivir en Flutter web. Se hará en una
// Cloud Function verificarPagoPaypal (Giancarlo) que escribirá verificado: true
// y verificadoPor: 'paypal' del lado del servidor. Para cambiar, se crea
// PaypalVerificadorCloudFunction implements PaypalVerificador y se inyecta en
// AdminPagoController; no cambia nada más.

class VerificacionPaypal {
  const VerificacionPaypal({
    required this.verificado,
    required this.orderId,
    required this.fuente,
    this.fechaPago,
    this.monto,
    this.error,
  });

  final bool verificado;
  final String orderId;
  final DateTime? fechaPago;
  final double? monto;
  final String fuente;
  final String? error;
}

abstract interface class PaypalVerificador {
  Future<VerificacionPaypal> verificar({
    required String orderId,
    required double montoEsperado,
  });
}

class PaypalVerificadorSimulado implements PaypalVerificador {
  PaypalVerificadorSimulado({DateTime Function()? reloj})
    : _reloj = reloj ?? DateTime.now;

  final DateTime Function() _reloj;

  @override
  Future<VerificacionPaypal> verificar({
    required String orderId,
    required double montoEsperado,
  }) async {
    final id = orderId.trim();
    if (id.isEmpty) {
      return const VerificacionPaypal(
        verificado: false,
        orderId: '',
        fuente: 'simulado',
        error: 'Falta el identificador de PayPal',
      );
    }
    return VerificacionPaypal(
      verificado: true,
      orderId: id,
      fechaPago: _reloj(),
      monto: montoEsperado,
      fuente: 'simulado',
    );
  }
}
