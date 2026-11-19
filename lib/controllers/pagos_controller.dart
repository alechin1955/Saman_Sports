import 'dart:async';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/configuracion_pagos.dart';
import 'package:saman_sports/models/pago.dart';
import 'package:url_launcher/url_launcher.dart';

/// Configuración del período (configuracion/pagos), en vivo.
typedef OrigenConfiguracionPagos = Stream? Function();

/// Pagos de un estudiante, en vivo.
typedef OrigenPagos = Stream<List> Function(String uid);

/// Guarda el pago del período con su id de orden de PayPal.
typedef RegistrarPago =
    Future<AuthResponse> Function(double monto, String periodo, String orden);

/// Ejecuta el flujo de cobro en PayPal y devuelve el orderId real.
typedef CobrarPaypal =
    Future<String> Function(BuildContext context, double monto);

/// Controlador de "Estatus y pagos" (RF-15, PayPal Sandbox).
class PagosController extends ChangeNotifier {
  PagosController({
    String? Function()? uidActual,
    OrigenConfiguracionPagos? origenConfiguracion,
    OrigenPagos? origenPagos,
    RegistrarPago? registrar,
    CobrarPaypal? cobrarPaypal,
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
       _cobrarPaypal = cobrarPaypal ?? _cobroPaypalReal;

  final String? Function() _uidActual;
  final OrigenConfiguracionPagos _origenConfiguracion;
  final OrigenPagos _origenPagos;
  final RegistrarPago _registrar;
  final CobrarPaypal _cobrarPaypal;

  ConfiguracionPagos? configuracion;
  List<Pago> pagos = [];
  bool cargando = true;
  bool procesando = false;
  String? error;

  StreamSubscription? _subConfig;
  StreamSubscription<List>? _subPagos;
  String? _uidEscuchado;
  bool _configLista = false;
  bool _pagosListos = false;

  /// Flujo real con Firebase Cloud Functions + navegador externo (url_launcher).
  static Future<String> _cobroPaypalReal(
    BuildContext context,
    double monto,
  ) async {
    final functions = FirebaseFunctions.instance;

    // 1. Crear la orden en Firebase Functions
    final createCallable = functions.httpsCallable('createPaypalOrder');
    final createRes = await createCallable
        .call({
          'amount': monto.toStringAsFixed(2),
          'currency': 'USD',
        })
        .timeout(const Duration(seconds: 20));

    final String orderId = createRes.data['orderId'] as String;
    final String approvalUrl = createRes.data['approvalUrl'] as String;

    // 2. Abrir PayPal Sandbox en una nueva pestaña / navegador externo
    final uri = Uri.parse(approvalUrl);
    final lanzado = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!lanzado) {
      throw StateError('No se pudo abrir la ventana de PayPal.');
    }

    if (!context.mounted) {
      throw StateError('Operación cancelada.');
    }

    // 3. Esperar a que el usuario apruebe en la pestaña de PayPal y vuelva a la app
    final confirmo = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Completar pago en PayPal'),
        content: const Text(
          'Se abrió PayPal en una nueva ventana.\n\n'
          '1. Inicia sesión con tu cuenta Sandbox y aprueba el pago.\n'
          '2. Regresa aquí y presiona "Ya aprobé el pago".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya aprobé el pago'),
          ),
        ],
      ),
    );

    if (confirmo != true) {
      throw StateError('CANCELADO_POR_USUARIO');
    }

    // 4. Capturar el cobro en Firebase Functions usando el orderId creado arriba
    final captureCallable = functions.httpsCallable('capturePaypalOrder');
    final captureRes = await captureCallable
        .call({'orderId': orderId})
        .timeout(const Duration(seconds: 20));

    if (captureRes.data['success'] != true) {
      throw StateError(
        'PayPal aún no reporta el pago como aprobado. Intenta de nuevo.',
      );
    }

    return orderId;
  }

  /// Id de orden simulado (conservado por compatibilidad con tests).
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
      _subConfig = _origenConfiguracion()?.listen((datos) {
        configuracion = datos == null
            ? null
            : ConfiguracionPagos.fromMap(Map<String, dynamic>.from(datos as Map));
        _configLista = true;
        _actualizar();
      }, onError: (_) => _fallar());
      _subPagos = _origenPagos(uid).listen((lista) {
        pagos = lista
            .map<Pago>((item) => Pago.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList()
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

  /// Ejecuta el cobro con PayPal y registra el pago en Firestore.
  /// Devuelve el id de la orden real de PayPal si salió bien.
  Future<String> pagarConPaypal(BuildContext context) async {
    if (procesando) throw StateError(AppStrings.esperaUnMomento);
    if (!hayPeriodo) throw StateError(AppStrings.sinPeriodoPago);
    if (pagoDelPeriodo != null) throw StateError(AppStrings.pagoYaRegistrado);

    procesando = true;
    notifyListeners();
    try {
      final monto = configuracion!.monto;
      final periodo = configuracion!.periodo;

      // 1. Cobrar en PayPal (abre navegador y captura la orden)
      final orden = await _cobrarPaypal(context, monto);

      // 2. Guardar en Firestore usando tu FirebaseServices existente
      final respuesta = await _registrar(
        monto,
        periodo,
        orden,
      ).timeout(const Duration(seconds: 15));

      if (!respuesta.isSuccess) {
        throw StateError(respuesta.errorMessage ?? AppStrings.errorInesperado);
      }
      return orden;
    } on TimeoutException {
      throw StateError(AppStrings.errorConexion);
    } on FirebaseFunctionsException catch (e) {
      throw StateError(e.message ?? AppStrings.errorConexion);
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