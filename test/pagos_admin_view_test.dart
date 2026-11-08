import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/admin/admin_pago_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/configuracion_pagos.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/models/pago.dart';
import 'package:saman_sports/repositories/admin/admin_pago_repository.dart';
import 'package:saman_sports/repositories/admin/admin_solvencia.dart';
import 'package:saman_sports/views/admin/pagos_admin_view.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final ancho in [390.0, 1440.0]) {
    testWidgets('corte deshabilitado y verificación simulada en $ancho', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(ancho, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final panel = AdminPagoController(repository: _Pagos());
      addTearDown(panel.dispose);
      panel.iniciar();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PagosAdminView(pagos: panel)),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.adminVerificacionPaypalSimulada),
        findsOneWidget,
      );
      expect(find.textContaining('simulada'), findsOneWidget);
      final corte = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, AppStrings.adminAplicarCorte),
      );
      expect(corte.onPressed, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}

class _Pagos implements AdminPagoRepository {
  @override
  Stream<ConfiguracionPagos?> configuracion() => Stream.value(
    ConfiguracionPagos(
      periodo: '2026-1',
      fechaInicio: DateTime(2026, 1, 1),
      fechaCorte: DateTime.now().add(const Duration(days: 20)),
      monto: 15,
    ),
  );

  @override
  Stream<List<Estudiante>> estudiantes() => Stream.value(const [
    Estudiante(
      uid: 'ana',
      cedula: 'V-1',
      nombre: 'Ana',
      apellido: 'Pérez',
      correo: 'ana@correo.unimet.edu.ve',
      carnet: '1',
      telefono: '0412',
      activo: true,
      solvente: false,
    ),
  ]);

  @override
  Stream<List<Pago>> pagos() => Stream.value([
    Pago(
      id: 'p1',
      inscripcionId: 'i1',
      estudianteUid: 'ana',
      monto: 15,
      idTransaccion: 'PAYPAL-SIM',
      estado: EstadoPago.realizado,
      fecha: DateTime(2026, 2, 1),
    ),
  ]);

  @override
  Future<String?> actualizarSolvencia({
    required String uid,
    required bool solvente,
  }) async => null;

  @override
  Future<String?> crearNotificacionPago({
    required String uid,
    required String periodo,
    required DateTime fechaCorte,
  }) async => null;

  @override
  Future<String?> guardarFechaCorte({
    required String periodo,
    required DateTime fechaInicio,
    required DateTime fechaCorte,
    required double monto,
  }) async => null;

  @override
  Future<String?> registrarPagoPaypal({
    required String pagoId,
    required String paypalOrderId,
    required DateTime fechaPago,
    required bool verificado,
    required String verificadoPor,
    String? periodo,
  }) async => null;

  @override
  Future<AdminCorteEstudiante> aplicarCorteEstudiante({
    required String uid,
    required String periodo,
    required DateTime fechaCorte,
    required double monto,
  }) async => const AdminCorteEstudiante();

  @override
  Future<String?> cambiarEstadoPago({
    required String pagoId,
    required String estado,
  }) async => null;
}
