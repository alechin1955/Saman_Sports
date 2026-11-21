import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/configuracion_pagos.dart';
import 'package:saman_sports/models/pago.dart';
import 'package:saman_sports/paypal/paypal_approval_launcher.dart';

/// Configuración del período (configuracion/pagos), en vivo.
typedef OrigenConfiguracionPagos = Stream? Function();

/// Pagos de un estudiante, en vivo.
typedef OrigenPagos = Stream<List> Function(String uid);

/// Ejecuta el flujo de cobro en PayPal y devuelve el orderId real.
typedef CobrarPaypal = Future<String> Function(BuildContext context);

/// Controlador de "Estatus y pagos" (RF-15, PayPal Sandbox).
class PagosController extends ChangeNotifier {
  PagosController({
    String? Function()? uidActual,
    OrigenConfiguracionPagos? origenConfiguracion,
    OrigenPagos? origenPagos,
    CobrarPaypal? cobrarPaypal,
  }) : _uidActual = uidActual ?? (() => FirebaseServices.currentUser?.uid),
       _origenConfiguracion =
           origenConfiguracion ?? FirebaseServices.streamConfiguracionPagos,
       _origenPagos =
           origenPagos ??
           ((uid) => FirebaseServices.streamMisPagos(estudianteUid: uid)),
       _cobrarPaypal = cobrarPaypal ?? _cobroPaypalReal;

  final String? Function() _uidActual;
  final OrigenConfiguracionPagos _origenConfiguracion;
  final OrigenPagos _origenPagos;
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

  static Future<String> _cobroPaypalReal(BuildContext context) async {
    final functions = FirebaseFunctions.instance;
    final ventanaPaypal = abrirVentanaPaypal();
    var paypalAbierto = false;

    try {
      // Crear la orden en Firebase Functions
      final createCallable = functions.httpsCallable('createPaypalOrder');
      final createRes = await createCallable
          .call({})
          .timeout(const Duration(seconds: 20));

      final String orderId = createRes.data['orderId'] as String;
      final String approvalUrl = createRes.data['approvalUrl'] as String;

      final uri = Uri.parse(approvalUrl);
      final lanzado = await navegarPaypal(uri, ventanaPaypal);

      if (!lanzado) {
        throw StateError(
          'El navegador bloqueó la pestaña de PayPal. Permite ventanas emergentes e inténtalo de nuevo.',
        );
      }
      paypalAbierto = true;

      if (!context.mounted) {
        throw StateError('Operación cancelada.');
      }

      // Esperar a que el usuario apruebe en PayPal y vuelva a la app.
      final confirmo = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Completar pago en PayPal'),
          content: const Text(
            'Se abrió PayPal en una nueva pestaña.\n\n'
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
        ventanaPaypal?.cerrar();
        throw StateError('CANCELADO_POR_USUARIO');
      }

      // La Function captura el pago y lo registra verificado en Firestore.
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
    } catch (_) {
      if (!paypalAbierto) cerrarVentanaPaypal(ventanaPaypal);
      rethrow;
    }
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
            : ConfiguracionPagos.fromMap(
                Map<String, dynamic>.from(datos as Map),
              );
        _configLista = true;
        _actualizar();
      }, onError: (_) => _fallar());
      _subPagos = _origenPagos(uid).listen((lista) {
        pagos =
            lista
                .map<Pago>(
                  (item) =>
                      Pago.fromMap(Map<String, dynamic>.from(item as Map)),
                )
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

  /// La Cloud Function cobra con PayPal y registra el pago verificado.
  /// Devuelve el id de la orden real de PayPal si salió bien.
  Future<String> pagarConPaypal(BuildContext context) async {
    if (procesando) throw StateError(AppStrings.esperaUnMomento);
    if (!hayPeriodo) throw StateError(AppStrings.sinPeriodoPago);
    if (pagoDelPeriodo != null) throw StateError(AppStrings.pagoYaRegistrado);

    procesando = true;
    notifyListeners();
    try {
      // La Cloud Function captura y registra el pago verificado en Firestore.
      return await _cobrarPaypal(context);
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
