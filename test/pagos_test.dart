import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart';
import 'package:saman_sports/controllers/pagos_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/views/estudiante/estatus_pagos_view.dart';

/// Configuración que guarda el administrador en configuracion/pagos.
final Map<String, dynamic> configuracion = {
  'periodo': '2026-11',
  'fechaInicio': DateTime(2026, 11, 1),
  'fechaCorte': DateTime(2026, 11, 30),
  'monto': 25,
};

Map<String, dynamic> pago(
  String id,
  String periodo,
  String estado, {
  int dia = 1,
}) {
  return {
    'id': id,
    'estudianteUid': 'u1',
    'monto': 25,
    'periodo': periodo,
    'estado': estado,
    'paypalOrderId': 'SIM-$id',
    'fecha': DateTime(2026, 11, dia),
  };
}

void main() {
  group('PagosController', () {
    late StreamController<Map<String, dynamic>?> fuenteConfig;
    late StreamController<List<Map<String, dynamic>>> fuentePagos;
    late List<String> registrados;

    PagosController crear({AuthResponse? respuesta}) {
      fuenteConfig = StreamController<Map<String, dynamic>?>();
      fuentePagos = StreamController<List<Map<String, dynamic>>>();
      registrados = [];
      return PagosController(
        uidActual: () => 'u1',
        origenConfiguracion: () => fuenteConfig.stream,
        origenPagos: (_) => fuentePagos.stream,
        registrar: (monto, periodo, orden) async {
          registrados.add('$monto $periodo $orden');
          return respuesta ?? AuthResponse(isSuccess: true);
        },
        generarOrden: () => 'SIM-PRUEBA',
        esperaPaypal: Duration.zero,
      );
    }

    Future<void> cargar(
      Map<String, dynamic>? config,
      List<Map<String, dynamic>> lista,
    ) async {
      fuenteConfig.add(config);
      fuentePagos.add(lista);
      await Future<void>.delayed(Duration.zero);
    }

    test('la orden simulada tiene el formato SIM- y 10 caracteres', () {
      final orden = PagosController.ordenSimulada();
      expect(orden, startsWith('SIM-'));
      expect(orden.length, 14);
    });

    test('sigue cargando hasta recibir la configuración y los pagos',
        () async {
      final c = crear()..iniciar();
      fuenteConfig.add(configuracion);
      await Future<void>.delayed(Duration.zero);
      expect(c.cargando, isTrue);

      fuentePagos.add([]);
      await Future<void>.delayed(Duration.zero);
      expect(c.cargando, isFalse);
      expect(c.configuracion?.monto, 25);
      c.dispose();
    });

    test('sin período abierto no deja pagar', () async {
      final c = crear()..iniciar();
      await cargar(null, []);

      expect(c.hayPeriodo, isFalse);
      expect(c.puedePagar, isFalse);
      expect(
        () => c.pagarConPaypal(),
        throwsA(isA<StateError>()),
      );
      c.dispose();
    });

    test('paga el período y registra monto, período y orden', () async {
      final c = crear()..iniciar();
      await cargar(configuracion, []);

      expect(c.puedePagar, isTrue);
      final orden = await c.pagarConPaypal();
      expect(orden, 'SIM-PRUEBA');
      expect(registrados, ['25.0 2026-11 SIM-PRUEBA']);
      expect(c.procesando, isFalse);
      c.dispose();
    });

    test('si ya pagó el período no deja pagar otra vez', () async {
      final c = crear()..iniciar();
      await cargar(configuracion, [pago('p1', '2026-11', 'pendiente')]);

      expect(c.pagoDelPeriodo?.id, 'p1');
      expect(c.puedePagar, isFalse);
      c.dispose();
    });

    test('un pago rechazado o de otro período no cuenta', () async {
      final c = crear()..iniciar();
      await cargar(configuracion, [
        pago('p1', '2026-11', 'rechazado', dia: 3),
        pago('p2', '2026-10', 'realizado', dia: 2),
      ]);

      expect(c.pagoDelPeriodo, isNull);
      expect(c.puedePagar, isTrue);
      expect(c.pagos.first.id, 'p1');
      c.dispose();
    });

    test('si la fachada falla devuelve su mensaje', () async {
      final c = crear(
        respuesta: AuthResponse(
          isSuccess: false,
          errorMessage: AppStrings.errorConexion,
        ),
      )..iniciar();
      await cargar(configuracion, []);

      await expectLater(
        c.pagarConPaypal(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            AppStrings.errorConexion,
          ),
        ),
      );
      expect(c.procesando, isFalse);
      c.dispose();
    });
  });

  group('EstatusPagosView', () {
    Widget pantalla(PagosController pagos) => MaterialApp(
      home: EstatusPagosView(
        auth: AuthController(),
        controller: EstudianteController(
          uidActual: () => 'u1',
          leer: (_) async => {
            'nombre': 'María',
            'apellido': 'González',
            'rol': 'estudiante',
            'estado': 'activo',
          },
        ),
        pagos: pagos,
      ),
    );

    PagosController conDatos(
      List<Map<String, dynamic>> lista, {
      List<String>? registrados,
    }) {
      return PagosController(
        uidActual: () => 'u1',
        origenConfiguracion: () => Stream.value(configuracion),
        origenPagos: (_) => Stream.value(lista),
        registrar: (monto, periodo, orden) async {
          registrados?.add(orden);
          return AuthResponse(isSuccess: true);
        },
        generarOrden: () => 'SIM-PRUEBA',
        esperaPaypal: Duration.zero,
      );
    }

    const tamanos = [Size(390, 844), Size(768, 1024), Size(1440, 900)];
    for (final tamano in tamanos) {
      testWidgets('muestra el período y el botón de PayPal en '
          '${tamano.width.toInt()} px', (tester) async {
        await tester.binding.setSurfaceSize(tamano);
        await tester.pumpWidget(pantalla(conDatos([])));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('2026-11'), findsOneWidget);
        expect(find.text(r'$25.00'), findsOneWidget);
        expect(find.text(AppStrings.pagarConPaypal), findsOneWidget);
        expect(find.text(AppStrings.sinPagos), findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });
    }

    testWidgets('pagar con PayPal muestra el comprobante con el ID', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      final registrados = <String>[];
      await tester.pumpWidget(
        pantalla(conDatos([], registrados: registrados)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.pagarConPaypal));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.pagoSimuladoNota), findsOneWidget);

      await tester.tap(find.text(AppStrings.pagarConPaypal).last);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.pagoEnviado), findsOneWidget);
      expect(find.text('SIM-PRUEBA'), findsOneWidget);
      expect(registrados, ['SIM-PRUEBA']);

      await tester.tap(find.text(AppStrings.listo));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.pagoEnviado), findsNothing);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('si ya pagó muestra el estado y no el botón', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(
        pantalla(conDatos([pago('p1', '2026-11', 'pendiente')])),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.pagarConPaypal), findsNothing);
      expect(
        find.text(AppStrings.pagoPendienteVerificacion),
        findsNWidgets(2),
      );
      expect(
        find.text('${AppStrings.idTransaccion}: SIM-p1'),
        findsOneWidget,
      );
      await tester.binding.setSurfaceSize(null);
    });
  });
}
