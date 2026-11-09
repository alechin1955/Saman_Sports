import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/admin/admin_pago_controller.dart';
import 'package:saman_sports/models/configuracion_pagos.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/models/pago.dart';
import 'package:saman_sports/repositories/admin/admin_pago_repository.dart';
import 'package:saman_sports/repositories/admin/admin_solvencia.dart';
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
    String? periodo = '2026-II',
    double monto = 25,
  }) {
    return Pago(
      id: 'p1',
      inscripcionId: 'i1',
      estudianteUid: uid,
      monto: monto,
      idTransaccion: 'ORD-1',
      estado: estado,
      fecha: DateTime(2026, 3, 2),
      fechaPago: fechaPago,
      verificado: verificado,
      paypalOrderId: 'ORD-1',
      periodo: periodo,
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
        pagos: [pago(fechaPago: DateTime(2026, 4, 2))],
        config: config,
      ),
      isTrue,
    );
    expect(
      AdminPagoController.puntualidad(
        pago(fechaPago: DateTime(2026, 4, 2)),
        config,
      ),
      AdminPuntualidad.tardio,
    );
    expect(
      AdminPagoController.esSolvente(
        uid: 'est-1',
        pagos: [pago(fechaPago: DateTime(2026, 4, 2), periodo: null)],
        config: config,
      ),
      isFalse,
    );
    expect(
      AdminPagoController.esSolvente(
        uid: 'est-1',
        pagos: [pago(fechaPago: DateTime(2026, 3, 10), periodo: '2025-I')],
        config: config,
      ),
      isFalse,
    );
    expect(
      AdminPagoController.esSolvente(
        uid: 'est-1',
        pagos: [
          pago(
            fechaPago: DateTime(2026, 3, 10),
            estado: EstadoPago.rechazado,
            verificado: false,
          ),
        ],
        config: config,
      ),
      isFalse,
    );
    expect(
      AdminPagoController.esSolvente(
        uid: 'est-1',
        pagos: [pago(fechaPago: DateTime(2026, 3, 10), monto: 1)],
        config: config,
      ),
      isFalse,
    );
    expect(
      AdminPagoController.esSolvente(
        uid: 'est-1',
        pagos: [pago(fechaPago: null)],
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
    expect(repo.cortes, 0);
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
      expect(repo.cortes, 2);
      expect(repo.avisos, 1);
      expect(repo.ultimoAviso, 'est-2');
      expect(repo.solventes['est-1'], isTrue);
      expect(repo.solventes['est-2'], isFalse);
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

  test('rechazar y marcar pendiente pasan por el repositorio', () async {
    final repo = _FalsoPagos();
    final controller = AdminPagoController(repository: repo);
    final pendiente = pago(estado: EstadoPago.pendiente, verificado: false);

    expect(await controller.rechazarPago(pendiente), isNull);
    expect(repo.ultimoEstadoPago, EstadoPago.rechazado.name);

    expect(await controller.marcarPendiente(pago()), isNull);
    expect(repo.ultimoEstadoPago, EstadoPago.pendiente.name);
    controller.dispose();
  });

  test(
    'reaplicar el corte no duplica el aviso ni quita la solvencia',
    () async {
      final repo = _FalsoPagos();
      final controller = AdminPagoController(
        repository: repo,
        reloj: () => DateTime(2026, 4, 2),
      );
      repo.config = config;
      repo.listaPagos = [pago(fechaPago: DateTime(2026, 4, 2))];
      repo.listaEstudiantes = [_estudiante('est-1', solvente: false)];
      controller.iniciar();
      await Future<void>.delayed(Duration.zero);

      expect(await controller.aplicarCorte(), isNull);
      expect(repo.avisos, 0);
      expect(repo.solventes['est-1'], isTrue);

      repo.listaEstudiantes = [_estudiante('est-1', solvente: true)];
      expect(await controller.aplicarCorte(), isNull);
      expect(repo.avisos, 0);
      expect(repo.solventes['est-1'], isTrue);
      controller.dispose();
    },
  );

  test('sin configuración o estudiante inactivo no aplica corte', () async {
    final repo = _FalsoPagos();
    final controller = AdminPagoController(
      repository: repo,
      reloj: () => DateTime(2026, 4, 2),
    );
    controller.iniciar();
    await Future<void>.delayed(Duration.zero);
    expect(
      await controller.aplicarCorte(),
      AdminPagoController.sinConfiguracion,
    );
    controller.dispose();

    final conConfig = AdminPagoController(
      repository: repo,
      reloj: () => DateTime(2026, 4, 2),
    );
    repo.config = config;
    repo.listaEstudiantes = [_estudiante('off', solvente: true, activo: false)];
    conConfig.iniciar();
    await Future<void>.delayed(Duration.zero);
    expect(await conConfig.aplicarCorte(), isNull);
    expect(repo.cortes, 0);
    conConfig.dispose();
  });

  test('dispose corta el corte', () async {
    final repo = _FalsoPagos()..espera = true;
    final controller = AdminPagoController(
      repository: repo,
      reloj: () => DateTime(2026, 4, 2),
    );
    repo.config = config;
    repo.listaEstudiantes = [_estudiante('est-1', solvente: true)];
    controller.iniciar();
    await Future<void>.delayed(Duration.zero);
    final futuro = controller.aplicarCorte();
    controller.dispose();
    repo.soltar();
    expect(await futuro, 'La operación ya no está disponible.');
  });
}

Estudiante _estudiante(
  String uid, {
  required bool solvente,
  bool activo = true,
}) {
  return Estudiante(
    uid: uid,
    cedula: 'V-1',
    nombre: 'Ana',
    apellido: 'Pérez',
    correo: 'ana@correo.unimet.edu.ve',
    carnet: '20231111',
    telefono: '04141234567',
    activo: activo,
    solvente: solvente,
  );
}

class _FalsoPagos implements AdminPagoRepository {
  ConfiguracionPagos? config;
  List<Pago> listaPagos = [];
  List<Estudiante> listaEstudiantes = [];
  int solvencias = 0;
  int avisos = 0;
  int cortes = 0;
  final avisosHechos = <String>{};
  final solventes = <String, bool>{};
  String? ultimoAviso;
  String? ultimoEstadoPago;
  String? ultimoVerificadoPor;
  String? ultimoPeriodo;
  DateTime? ultimaFechaPago;
  bool espera = false;
  Completer<void>? _compuerta;

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
    String? periodo,
  }) async {
    ultimoVerificadoPor = verificadoPor;
    ultimaFechaPago = fechaPago;
    ultimoPeriodo = periodo;
    return null;
  }

  void soltar() => _compuerta?.complete();

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

  @override
  Future<String?> cambiarEstadoPago({
    required String pagoId,
    required String estado,
  }) async {
    ultimoEstadoPago = estado;
    return null;
  }

  @override
  Future<AdminCorteEstudiante> aplicarCorteEstudiante({
    required String uid,
    required String periodo,
    required DateTime fechaCorte,
    required double monto,
  }) async {
    if (espera) {
      _compuerta = Completer<void>();
      await _compuerta!.future;
    }
    cortes++;
    final configActual = config;
    if (configActual == null) {
      return const AdminCorteEstudiante(error: 'Sin configuración');
    }
    final estudiante = listaEstudiantes.cast<Estudiante?>().firstWhere(
      (item) => item?.uid == uid,
      orElse: () => null,
    );
    if (estudiante == null || !estudiante.activo) {
      return const AdminCorteEstudiante();
    }
    final solvente = AdminSolvencia.esSolvente(
      uid: uid,
      pagos: listaPagos,
      config: configActual,
    );
    solventes[uid] = solvente;
    var creado = false;
    if (!solvente && avisosHechos.add('pago-$periodo-$uid')) {
      avisos++;
      ultimoAviso = uid;
      creado = true;
    }
    return AdminCorteEstudiante(solvente: solvente, avisoCreado: creado);
  }
}
