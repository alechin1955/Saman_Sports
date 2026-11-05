import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/models/configuracion_pagos.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/models/pago.dart';

abstract interface class AdminPagoRepository {
  Stream<List<Pago>> pagos();
  Stream<ConfiguracionPagos?> configuracion();
  Stream<List<Estudiante>> estudiantes();
  Future<String?> registrarPagoPaypal({
    required String pagoId,
    required String paypalOrderId,
    required DateTime fechaPago,
    required bool verificado,
    required String verificadoPor,
  });
  Future<String?> guardarFechaCorte({
    required String periodo,
    required DateTime fechaInicio,
    required DateTime fechaCorte,
    required double monto,
  });
  Future<String?> actualizarSolvencia({
    required String uid,
    required bool solvente,
  });
  Future<String?> crearNotificacionPago({
    required String uid,
    required String periodo,
    required DateTime fechaCorte,
  });
}

class FirebaseAdminPagoAdapter implements AdminPagoRepository {
  @override
  Stream<List<Pago>> pagos() {
    return FirebaseServices.streamPagosAdmin().map(
      (lista) => lista.map(Pago.fromMap).toList(),
    );
  }

  @override
  Stream<ConfiguracionPagos?> configuracion() {
    return FirebaseServices.streamConfiguracionPagos().map(
      (mapa) => mapa == null ? null : ConfiguracionPagos.fromMap(mapa),
    );
  }

  @override
  Stream<List<Estudiante>> estudiantes() {
    return FirebaseServices.streamEstudiantesAdmin().map(
      (lista) => lista
          .map((mapa) => Estudiante.fromMap('${mapa['id'] ?? ''}', mapa))
          .toList(),
    );
  }

  @override
  Future<String?> registrarPagoPaypal({
    required String pagoId,
    required String paypalOrderId,
    required DateTime fechaPago,
    required bool verificado,
    required String verificadoPor,
  }) {
    return _texto(
      FirebaseServices.registrarPagoPaypal(
        pagoId: pagoId,
        paypalOrderId: paypalOrderId,
        fechaPago: fechaPago,
        verificado: verificado,
        verificadoPor: verificadoPor,
      ),
    );
  }

  @override
  Future<String?> guardarFechaCorte({
    required String periodo,
    required DateTime fechaInicio,
    required DateTime fechaCorte,
    required double monto,
  }) {
    return _texto(
      FirebaseServices.guardarFechaCorte(
        periodo: periodo,
        fechaInicio: fechaInicio,
        fechaCorte: fechaCorte,
        monto: monto,
      ),
    );
  }

  @override
  Future<String?> actualizarSolvencia({
    required String uid,
    required bool solvente,
  }) {
    return _texto(
      FirebaseServices.actualizarSolvencia(uid: uid, solvente: solvente),
    );
  }

  @override
  Future<String?> crearNotificacionPago({
    required String uid,
    required String periodo,
    required DateTime fechaCorte,
  }) {
    return _texto(
      FirebaseServices.crearNotificacionPago(
        uid: uid,
        periodo: periodo,
        fechaCorte: fechaCorte,
      ),
    );
  }
}

Future<String?> _texto(Future<AuthResponse> respuesta) async {
  final resultado = await respuesta;
  if (resultado.isSuccess) return null;
  return resultado.errorMessage ?? 'Ocurrió un error. Inténtalo de nuevo.';
}
