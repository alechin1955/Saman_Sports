import 'package:saman_sports/models/configuracion_pagos.dart';
import 'package:saman_sports/models/pago.dart';

enum AdminPuntualidad { aTiempo, tardio, pendiente }

class AdminSolvencia {
  static DateTime limiteExclusivo(DateTime fechaCorte) {
    final dia = DateTime(fechaCorte.year, fechaCorte.month, fechaCorte.day);
    return dia.add(const Duration(days: 1));
  }

  static bool corteVencido(DateTime ahora, DateTime fechaCorte) {
    return !ahora.isBefore(limiteExclusivo(fechaCorte));
  }

  static bool pagoValidoPeriodo({
    required Pago pago,
    required String uid,
    required ConfiguracionPagos config,
  }) {
    return _valido(
      uidPago: pago.estudianteUid,
      uid: uid,
      periodoPago: pago.periodo,
      periodo: config.periodo,
      estado: pago.estado.name,
      verificado: pago.verificado,
      fechaPago: pago.fechaPago,
      monto: pago.monto,
      montoEsperado: config.monto,
    );
  }

  static bool datosValidos({
    required String uidPago,
    required String uid,
    required String? periodoPago,
    required String periodo,
    required String estado,
    required bool verificado,
    required DateTime? fechaPago,
    required double monto,
    required double montoEsperado,
  }) {
    return _valido(
      uidPago: uidPago,
      uid: uid,
      periodoPago: periodoPago,
      periodo: periodo,
      estado: estado,
      verificado: verificado,
      fechaPago: fechaPago,
      monto: monto,
      montoEsperado: montoEsperado,
    );
  }

  static bool esSolvente({
    required String uid,
    required List<Pago> pagos,
    required ConfiguracionPagos config,
  }) {
    return pagos.any(
      (pago) => pagoValidoPeriodo(pago: pago, uid: uid, config: config),
    );
  }

  static AdminPuntualidad puntualidad({
    required Pago pago,
    required ConfiguracionPagos config,
  }) {
    if (!pagoValidoPeriodo(pago: pago, uid: pago.estudianteUid, config: config)) {
      return AdminPuntualidad.pendiente;
    }
    final fecha = pago.fechaPago!;
    if (fecha.isBefore(limiteExclusivo(config.fechaCorte))) {
      return AdminPuntualidad.aTiempo;
    }
    return AdminPuntualidad.tardio;
  }

  static bool _valido({
    required String uidPago,
    required String uid,
    required String? periodoPago,
    required String periodo,
    required String estado,
    required bool verificado,
    required DateTime? fechaPago,
    required double monto,
    required double montoEsperado,
  }) {
    if (uid.trim().isEmpty || uidPago.trim() != uid.trim()) return false;
    if (periodo.trim().isEmpty) return false;
    if (periodoPago == null || periodoPago.trim().isEmpty) return false;
    if (periodoPago.trim() != periodo.trim()) return false;
    if (estado != EstadoPago.realizado.name) return false;
    if (!verificado || fechaPago == null) return false;
    if (monto <= 0 || montoEsperado <= 0) return false;
    if (monto + 0.001 < montoEsperado) return false;
    return true;
  }
}

class AdminCorteEstudiante {
  const AdminCorteEstudiante({
    this.error,
    this.solvente = false,
    this.avisoCreado = false,
  });

  final String? error;
  final bool solvente;
  final bool avisoCreado;
}
