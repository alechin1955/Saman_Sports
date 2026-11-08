import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/models/configuracion_pagos.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/models/pago.dart';
import 'package:saman_sports/repositories/admin/admin_pago_repository.dart';
import 'package:saman_sports/repositories/admin/admin_solvencia.dart';
import 'package:saman_sports/services/pagos/paypal_verificador.dart';

enum FiltroPago { todos, pendientes, realizados, verificados, rechazados }

class AdminPagoController extends ChangeNotifier {
  AdminPagoController({
    AdminPagoRepository? repository,
    PaypalVerificador? verificador,
    DateTime Function()? reloj,
  }) : _repository = repository ?? FirebaseAdminPagoAdapter(),
       _verificador = verificador ?? PaypalVerificadorSimulado(),
       _reloj = reloj ?? DateTime.now;

  static const String cortePendiente = 'Aún no pasa la fecha de corte';
  static const String sinConfiguracion = 'Configura primero la fecha de corte.';
  static const String pagoSinIdentificador = 'Falta el identificador de PayPal';

  final AdminPagoRepository _repository;
  final PaypalVerificador _verificador;
  final DateTime Function() _reloj;
  List<Pago> pagos = [];
  ConfiguracionPagos? configuracion;
  List<Estudiante> estudiantes = [];
  FiltroPago filtro = FiltroPago.todos;
  bool cargando = false;
  bool guardando = false;
  String? error;
  String? mensaje;
  bool _cerrado = false;
  bool _iniciado = false;
  StreamSubscription<List<Pago>>? _pagosSub;
  StreamSubscription<ConfiguracionPagos?>? _configSub;
  StreamSubscription<List<Estudiante>>? _estudiantesSub;

  bool get verificacionSimulada => _verificador is PaypalVerificadorSimulado;

  List<Pago> get pagosFiltrados {
    return pagos.where((pago) {
      return switch (filtro) {
        FiltroPago.pendientes => pago.estado == EstadoPago.pendiente,
        FiltroPago.realizados => pago.estado == EstadoPago.realizado,
        FiltroPago.verificados => pago.verificado,
        FiltroPago.rechazados => pago.estado == EstadoPago.rechazado,
        FiltroPago.todos => true,
      };
    }).toList();
  }

  static bool esSolvente({
    required String uid,
    required List<Pago> pagos,
    required ConfiguracionPagos config,
  }) {
    return AdminSolvencia.esSolvente(uid: uid, pagos: pagos, config: config);
  }

  static AdminPuntualidad puntualidad(Pago pago, ConfiguracionPagos config) {
    return AdminSolvencia.puntualidad(pago: pago, config: config);
  }

  void iniciar() {
    if (_iniciado || _cerrado) return;
    _iniciado = true;
    cargando = true;
    _avisar();
    _pagosSub = _repository.pagos().listen((lista) {
      pagos = lista;
      cargando = false;
      _avisar();
    }, onError: (_) => _fallo('No se pudieron cargar los pagos.'));
    _configSub = _repository.configuracion().listen((valor) {
      configuracion = valor;
      _avisar();
    }, onError: (_) => _fallo('No se pudo cargar la configuración de pagos.'));
    _estudiantesSub = _repository.estudiantes().listen((lista) {
      estudiantes = lista;
      _avisar();
    }, onError: (_) => _fallo('No se pudieron cargar los estudiantes.'));
  }

  void cambiarFiltro(FiltroPago valor) {
    filtro = valor;
    _avisar();
  }

  Future<String?> verificarPago(Pago pago) {
    return _guardar(
      () async {
        final orderId = pago.paypalOrderId.isNotEmpty
            ? pago.paypalOrderId
            : pago.idTransaccion;
        final resultado = await _verificador.verificar(
          orderId: orderId,
          montoEsperado: pago.monto,
        );
        if (!resultado.verificado || resultado.fechaPago == null) {
          return resultado.error ?? pagoSinIdentificador;
        }
        return _repository.registrarPagoPaypal(
          pagoId: pago.id,
          paypalOrderId: resultado.orderId,
          fechaPago: resultado.fechaPago!,
          verificado: resultado.verificado,
          verificadoPor: resultado.fuente,
          periodo: configuracion?.periodo,
        );
      },
      verificacionSimulada ? 'Pago verificado (simulado).' : 'Pago verificado.',
    );
  }

  Future<String?> rechazarPago(Pago pago) {
    return _guardar(
      () => _repository.cambiarEstadoPago(
        pagoId: pago.id,
        estado: EstadoPago.rechazado.name,
      ),
      'Pago rechazado.',
    );
  }

  Future<String?> marcarPendiente(Pago pago) {
    return _guardar(
      () => _repository.cambiarEstadoPago(
        pagoId: pago.id,
        estado: EstadoPago.pendiente.name,
      ),
      'Pago marcado como pendiente.',
    );
  }

  Future<String?> guardarFechaCorte({
    required String periodo,
    required DateTime fechaInicio,
    required DateTime fechaCorte,
    required double monto,
  }) {
    return _guardar(
      () => _repository.guardarFechaCorte(
        periodo: periodo,
        fechaInicio: fechaInicio,
        fechaCorte: fechaCorte,
        monto: monto,
      ),
      'Fecha de corte guardada.',
    );
  }

  /// El administrador lo dispara con un botón. No hay programador ni correo.
  Future<String?> aplicarCorte() {
    return _guardar(() async {
      if (_cerrado) return 'La operación ya no está disponible.';
      final config = configuracion;
      if (config == null || config.periodo.trim().isEmpty) {
        return sinConfiguracion;
      }
      if (!AdminSolvencia.corteVencido(_reloj(), config.fechaCorte)) {
        return cortePendiente;
      }
      var solventes = 0;
      var notificados = 0;
      for (final estudiante in estudiantes.where((item) => item.activo)) {
        if (_cerrado) return 'La operación ya no está disponible.';
        final resultado = await _repository.aplicarCorteEstudiante(
          uid: estudiante.uid,
          periodo: config.periodo,
          fechaCorte: config.fechaCorte,
          monto: config.monto,
        );
        if (_cerrado) return 'La operación ya no está disponible.';
        if (resultado.error != null) return resultado.error;
        if (resultado.solvente) solventes++;
        if (resultado.avisoCreado) notificados++;
      }
      mensaje = '$solventes solventes, $notificados notificados';
      return null;
    }, '');
  }

  Future<String?> _guardar(
    Future<String?> Function() accion,
    String exito,
  ) async {
    if (_cerrado) return 'La operación ya no está disponible.';
    if (guardando) return 'Espera a que termine la operación.';
    guardando = true;
    error = null;
    mensaje = null;
    _avisar();
    try {
      final resultado = await accion();
      if (_cerrado) return resultado;
      if (resultado == null) {
        mensaje ??= exito;
      } else {
        error = resultado;
      }
      return resultado;
    } finally {
      if (!_cerrado) {
        guardando = false;
        _avisar();
      }
    }
  }

  void _fallo(String texto) {
    if (_cerrado) return;
    cargando = false;
    error = texto;
    _avisar();
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _pagosSub?.cancel();
    _configSub?.cancel();
    _estudiantesSub?.cancel();
    super.dispose();
  }
}
