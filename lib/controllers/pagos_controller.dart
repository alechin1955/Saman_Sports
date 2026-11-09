import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/configuracion_pagos.dart';
import 'package:saman_sports/models/pago.dart';

/// Configuración del período (configuracion/pagos), en vivo.
typedef OrigenConfiguracionPagos = Stream<Map<String, dynamic>?> Function();

/// Pagos de un estudiante, en vivo.
typedef OrigenPagos = Stream<List<Map<String, dynamic>>> Function(String uid);

/// Guarda el pago del período con su id de orden de PayPal.
typedef RegistrarPago =
    Future<AuthResponse> Function(double monto, String periodo, String orden);

/// Controlador de "Estatus y pagos" (RF-15, PayPal simulado).
///
/// Observer: escucha la configuración del período que guarda el
/// administrador y los pagos del estudiante. Simula el cobro de PayPal:
/// genera un id de orden, espera unos segundos y registra el pago como
/// pendiente para que el administrador lo verifique.
class PagosController extends ChangeNotifier {
  PagosController({
    String? Function()? uidActual,
    OrigenConfiguracionPagos? origenConfiguracion,
    OrigenPagos? origenPagos,
    RegistrarPago? registrar,
    String Function()? generarOrden,
    this.esperaPaypal = const Duration(seconds: 2),
  }) : _uidActual = uidActual ?? (() => FirebaseServices.currentUser?.uid),
       _origenConfiguracion =
           origenConfiguracion ?? FirebaseServices.streamConfiguracionPagos,
       _origenPagos =
           origenPagos ??
           ((uid) => FirebaseServices.streamMisPagos(estudianteUid: uid)),
       _registrar =
           registrar ??
           ((monto, periodo, orden) =>
               FirebaseServices.registrarPagoEstudiante(
                 monto: monto,
                 periodo: periodo,
                 paypalOrderId: orden,
               )),
       _generarOrden = generarOrden ?? ordenSimulada;

  final String? Function() _uidActual;
  final OrigenConfiguracionPagos _origenConfiguracion;
  final OrigenPagos _origenPagos;
  final RegistrarPago _registrar;
  final String Function() _generarOrden;

  /// Lo que tarda la "conexión" simulada con PayPal.
  final Duration esperaPaypal;

  ConfiguracionPagos? configuracion;
  List<Pago> pagos = [];
  bool cargando = true;
  bool procesando = false;
  String? error;

  StreamSubscription<Map<String, dynamic>?>? _subConfig;
  StreamSubscription<List<Map<String, dynamic>>>? _subPagos;
  String? _uidEscuchado;
  bool _configLista = false;
  bool _pagosListos = false;

  /// Id de orden con el formato de PayPal, marcado como simulado: SIM-XXXXXXXXXX.
  static String ordenSimulada() {
    const letras = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final azar = Random.secure();
    final codigo = List.generate(
      10,
      (_) => letras[azar.nextInt(letras.length)],
    ).join();
    return 'SIM-$codigo';
  }

  /// Se suscribe a la configuración del período y a los pagos del estudiante.
  void iniciar() {
    final uid = _uidActual();
    if (uid == null) {
      _cancelarSubs();
      _uidEscuchado = null;
      cargando = false;
      error = AppStrings.sesionNoIniciada;
      notifyListeners();
      return;
    }
    if (uid == _uidEscuchado && _subPagos != null) return;

    _cancelarSubs();
    _uidEscuchado = uid;
    _configLista = false;
    _pagosListos = false;
    cargando = true;
    error = null;
    notifyListeners();
    try {
      _subConfig = _origenConfiguracion().listen((datos) {
        configuracion = datos == null ? null : ConfiguracionPagos.fromMap(datos);
        _configLista = true;
        _actualizar();
      }, onError: (_) => _fallar());
      _subPagos = _origenPagos(uid).listen((lista) {
        pagos = lista.map(Pago.fromMap).toList()
          ..sort((a, b) => b.fecha.compareTo(a.fecha));
        _pagosListos = true;
        _actualizar();
      }, onError: (_) => _fallar());
    } catch (_) {
      _fallar();
    }
  }

  void _actualizar() {
    cargando = !(_configLista && _pagosListos);
    error = null;
    notifyListeners();
  }

  void _fallar() {
    cargando = false;
    error = AppStrings.errorConexion;
    notifyListeners();
  }

  /// El administrador ya abrió un período con monto.
  bool get hayPeriodo =>
      configuracion != null &&
      configuracion!.periodo.isNotEmpty &&
      configuracion!.monto > 0;

  /// Pago del período actual que no fue rechazado, o null si falta pagar.
  Pago? get pagoDelPeriodo {
    if (!hayPeriodo) return null;
    for (final pago in pagos) {
      if (pago.periodo == configuracion!.periodo &&
          pago.estado != EstadoPago.rechazado) {
        return pago;
      }
    }
    return null;
  }

  bool get puedePagar => hayPeriodo && pagoDelPeriodo == null && !procesando;

  /// Simula el pago con PayPal. Devuelve el id de la orden si salió bien;
  /// si falla lanza un [StateError] con el mensaje para el estudiante.
  Future<String> pagarConPaypal() async {
    if (procesando) throw StateError(AppStrings.esperaUnMomento);
    if (!hayPeriodo) throw StateError(AppStrings.sinPeriodoPago);
    if (pagoDelPeriodo != null) throw StateError(AppStrings.pagoYaRegistrado);

    procesando = true;
    notifyListeners();
    try {
      final orden = _generarOrden();
      await Future<void>.delayed(esperaPaypal);
      final respuesta = await _registrar(
        configuracion!.monto,
        configuracion!.periodo,
        orden,
      ).timeout(const Duration(seconds: 15));
      if (!respuesta.isSuccess) {
        throw StateError(respuesta.errorMessage ?? AppStrings.errorInesperado);
      }
      return orden;
    } on TimeoutException {
      throw StateError(AppStrings.errorConexion);
    } finally {
      procesando = false;
      notifyListeners();
    }
  }

  void _cancelarSubs() {
    _subConfig?.cancel();
    _subPagos?.cancel();
    _subConfig = null;
    _subPagos = null;
  }

  @override
  void dispose() {
    _cancelarSubs();
    super.dispose();
  }
}