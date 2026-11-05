import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/services/pagos/paypal_verificador.dart';

void main() {
  test('un identificador vacío no se verifica', () async {
    final resultado = await PaypalVerificadorSimulado().verificar(
      orderId: '   ',
      montoEsperado: 25,
    );

    expect(resultado.verificado, isFalse);
    expect(resultado.error, 'Falta el identificador de PayPal');
    expect(resultado.fuente, 'simulado');
  });

  test('un identificador válido usa el reloj inyectado', () async {
    final reloj = DateTime(2026, 3, 2, 8);
    final resultado = await PaypalVerificadorSimulado(reloj: () => reloj)
        .verificar(orderId: ' ORD-1 ', montoEsperado: 25);

    expect(resultado.verificado, isTrue);
    expect(resultado.orderId, 'ORD-1');
    expect(resultado.fechaPago, reloj);
    expect(resultado.monto, 25);
    expect(resultado.fuente, 'simulado');
    expect(resultado.error, isNull);
  });
}
