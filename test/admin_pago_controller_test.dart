import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/admin/admin_pago_controller.dart';
import 'package:saman_sports/models/configuracion_pagos.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/models/pago.dart';
import 'package:saman_sports/repositories/admin/admin_pago_repository.dart';
import 'package:saman_sports/services/pagos/paypal_verificador.dart';

void main() {
  final config = ConfiguracionPagos(
    periodo: '2026-II',
    fechaInicio: DateTime(2026, 3, 1),
    fechaCorte: DateTime(2026, 3, 31),
    monto: 25,
  );

  Pago pago({
    String uid = 'est-1',
    DateTime? fechaPago,
    bool verificado = true,
    EstadoPago estado = EstadoPago.realizado,
  }) {
    return Pago(
      id: 'p1',
      inscripcionId: 'i1',
      estudianteUid: uid,
      monto: 25,
      idTransaccion: 'ORD-1',
      estado: estado,
      fecha: DateTime(2026, 3, 2),
      fechaPago: fechaPago,
      verificado: verificado,
      paypalOrderId: 'ORD-1',
    );
  }

  test('esSolvente respeta corte, verificación y el estudiante', () {
    expect(
      AdminPagoController.esSolvente(
        uid: 'est-1',
        pagos: [pago(fechaPago: DateTime(2026, 3, 10))],
        config: config,
      ),
      isTrue,
    );
    expect(
      AdminPagoController.esSolvente(
        uid: 'est-1',
        pagos: [pago(fechaPago: DateTime(2026, 3, 31, 20))],
        config: config,
      ),
      isTrue,
    );
    expect(
      AdminPagoController.esSolvente(
        uid: 'est-1',
        pagos: [pago(fechaPago: DateTime(2026, 4, 1))],
        config: config,
      ),
      isFalse,
    );
    expect(
      AdminPagoController.esSolvente(
        uid: 'est-1',
        pagos: [pago(fechaPago: DateTime(2026, 3, 10), verificado: false)],
        config: config,
      ),
      isFalse,
    );
    expect(
      AdminPagoController.esSolvente(
        uid: 'est-1',
        pagos: [pago(uid: 'otro', fechaPago: DateTime(2026, 3, 10))],
        config: config,
      ),
      isFalse,
    );
  });

  test('aplicar corte antes de tiempo no toca el repositorio', () async {
    final repo = _FalsoPagos();
    final controller = AdminPagoController(
      repository: repo,
      verificador: PaypalVerificadorSimulado(),
      reloj: () => DateTime(2026, 3, 31, 20),
    );
    repo.config = config;
    controller.iniciar();
    await Future<void>.delayed(Duration.zero);

    final resultado = await controller.aplicarCorte();

    expect(resultado, AdminPagoController.cortePendiente);
    expect(repo.solvencias, 0);
    expect(repo.avisos, 0);
    controller.dispose();
  });

  test(
    'después del corte actualiza solvencia y avisa solo a los pendientes',
    () async {
      final repo = _FalsoPagos();
      final controller = AdminPagoController(
        repository: repo,
        verificador: PaypalVerificadorSimulado(),
        reloj: () => DateTime(2026, 4, 1, 8),
      );
      repo.config = config;
      repo.listaPagos = [pago(fechaPago: DateTime(2026, 3, 10))];
      repo.listaEstudiantes = [
        _estudiante('est-1', solvente: false),
        _estudiante('est-2', solvente: true),
      ];
      controller.iniciar();
      await Future<void>.delayed(Duration.zero);

      final resultado = await controller.aplicarCorte();

      expect(resultado, isNull);
      expect(controller.mensaje, '1 solventes, 1 notificados');
      expect(repo.solvencias, 2);
      expect(repo.avisos, 1);
      expect(repo.ultimoAviso, 'est-2');
      controller.dispose();
    },
  );

  test('verificar un pago simulado registra la fuente simulada', () async {
    final repo = _FalsoPagos();
    final reloj = DateTime(2026, 3, 2, 8);
    final controller = AdminPagoController(
      repository: repo,
      verificador: PaypalVerificadorSimulado(reloj: () => reloj),
    );

    final resultado = await controller.verificarPago(pago());

    expect(resultado, isNull);
    expect(repo.ultimoVerificadoPor, 'simulado');
    expect(repo.ultimaFechaPago, reloj);
    expect(controller.verificacionSimulada, isTrue);
    controller.dispose();
  });
}

Estudiante _estudiante(String uid, {required bool solvente}) {
  return Estudiante(
    uid: uid,
    cedula: 'V-1',
    nombre: 'Ana',
    apellido: 'Pérez',
    correo: 'ana@correo.unimet.edu.ve',
    carnet: '20231111',
    telefono: '04141234567',
    activo: true,
    solvente: solvente,
  );
}

class _FalsoPagos implements AdminPagoRepository {
  ConfiguracionPagos? config;
  List<Pago> listaPagos = [];
  List<Estudiante> listaEstudiantes = [];
  int solvencias = 0;
  int avisos = 0;
  String? ultimoAviso;
  String? ultimoVerificadoPor;
  DateTime? ultimaFechaPago;

  @override
  Stream<List<Pago>> pagos() => Stream.value(listaPagos);

  @override
  Stream<ConfiguracionPagos?> configuracion() => Stream.value(config);

  @override
  Stream<List<Estudiante>> estudiantes() => Stream.value(listaEstudiantes);

  @override
  Future<String?> registrarPagoPaypal({
    required String pagoId,
    required String paypalOrderId,
    required DateTime fechaPago,
    required bool verificado,
    required String verificadoPor,
  }) async {
    ultimoVerificadoPor = verificadoPor;
    ultimaFechaPago = fechaPago;
    return null;
  }

  @override
  Future<String?> guardarFechaCorte({
    required String periodo,
    required DateTime fechaInicio,
    required DateTime fechaCorte,
    required double monto,
  }) async => null;

  @override
  Future<String?> actualizarSolvencia({
    required String uid,
    required bool solvente,
  }) async {
    solvencias++;
    return null;
  }

  @override
  Future<String?> crearNotificacionPago({
    required String uid,
    required String periodo,
    required DateTime fechaCorte,
  }) async {
    avisos++;
    ultimoAviso = uid;
    return null;
  }
}
