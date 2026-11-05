import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/admin/admin_controladores.dart';
import 'package:saman_sports/controllers/admin/admin_deporte_controller.dart';
import 'package:saman_sports/controllers/admin/admin_entrenador_controller.dart';
import 'package:saman_sports/controllers/admin/admin_estudiante_controller.dart';
import 'package:saman_sports/controllers/admin/admin_evento_controller.dart';
import 'package:saman_sports/controllers/admin/admin_inscripcion_controller.dart';
import 'package:saman_sports/controllers/admin/admin_pago_controller.dart';
import 'package:saman_sports/controllers/admin/admin_resena_controller.dart';
import 'package:saman_sports/controllers/admin/admin_resumen_controller.dart';
import 'package:saman_sports/controllers/admin/admin_soporte_controller.dart';
import 'package:saman_sports/controllers/admin/admin_transaccion_controller.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/configuracion_pagos.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/entrenador_admin.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/models/inscripcion.dart';
import 'package:saman_sports/models/pago.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/models/resena.dart';
import 'package:saman_sports/models/ticket_soporte.dart';
import 'package:saman_sports/models/transaccion.dart';
import 'package:saman_sports/repositories/admin/admin_deporte_repository.dart';
import 'package:saman_sports/repositories/admin/admin_entrenador_repository.dart';
import 'package:saman_sports/repositories/admin/admin_estudiante_repository.dart';
import 'package:saman_sports/repositories/admin/admin_evento_repository.dart';
import 'package:saman_sports/repositories/admin/admin_inscripcion_repository.dart';
import 'package:saman_sports/repositories/admin/admin_pago_repository.dart';
import 'package:saman_sports/repositories/admin/admin_resena_repository.dart';
import 'package:saman_sports/repositories/admin/admin_resumen_repository.dart';
import 'package:saman_sports/repositories/admin/admin_soporte_repository.dart';
import 'package:saman_sports/repositories/admin/admin_transaccion_repository.dart';
import 'package:saman_sports/views/admin/admin_dashboard_view.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final size in [
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('panel admin adaptable a ${size.width}', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final auth = AuthController();
      addTearDown(auth.dispose);
      final panel = _panel();
      addTearDown(panel.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminDashboardView(auth: auth, controladores: panel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.adminResumen), findsWidgets);
      expect(tester.takeException(), isNull);
      if (size.width < 1024) {
        expect(find.byType(Drawer), findsNothing);
        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text(AppStrings.deportes).first);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.adminDeportesDescripcion), findsOneWidget);
      expect(find.text(AppStrings.adminNuevoDeporte), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

AdminControladores _panel() {
  return AdminControladores(
    resumen: AdminResumenController(repository: _Resumen()),
    deportes: AdminDeporteController(repository: _Deportes()),
    entrenadores: AdminEntrenadorController(repository: _Entrenadores()),
    estudiantes: AdminEstudianteController(repository: _Estudiantes()),
    resenas: AdminResenaController(repository: _Resenas()),
    pagos: AdminPagoController(repository: _Pagos()),
    inscripciones: AdminInscripcionController(repository: _Inscripciones()),
    eventos: AdminEventoController(repository: _Eventos()),
    soporte: AdminSoporteController(repository: _Soporte()),
    transacciones: AdminTransaccionController(repository: _Historial()),
  );
}

class _Resumen implements AdminResumenRepository {
  @override
  Future<Map<String, num>> contar() async => {'estudiantes': 3, 'ingresos': 25};
}

class _Deportes implements AdminDeporteRepository {
  @override
  Stream<List<Cancha>> canchas() => Stream.value(const []);
  @override
  Stream<List<Deporte>> deportes() => Stream.value(const []);
  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) =>
      Stream.value(const []);
  @override
  Future<String?> actualizarCancha({
    required String id,
    required String nombre,
    required String ubicacion,
    required String descripcion,
    required bool activa,
  }) async => null;
  @override
  Future<String?> actualizarDeporte({
    required String id,
    required Map<String, dynamic> datos,
    String? canchaId,
    List<Map<String, dynamic>>? franjas,
  }) async => null;
  @override
  Future<String?> asignarEntrenador({
    required String deporteId,
    required String entrenadorUid,
    required String entrenadorNombre,
  }) async => null;
  @override
  Future<String?> cambiarEstadoDeporte({
    required String id,
    required bool activo,
  }) async => null;
  @override
  Future<String?> crearCancha({
    required String nombre,
    required String ubicacion,
    required String descripcion,
  }) async => null;
  @override
  Future<String?> crearDeporte({
    required Map<String, dynamic> datos,
    required String canchaId,
    required List<Map<String, dynamic>> franjas,
  }) async => null;
}

class _Entrenadores implements AdminEntrenadorRepository {
  @override
  Future<String?> actualizar(EntrenadorAdmin datos) async => null;
  @override
  Future<String?> cambiarEstado({
    required String uid,
    required bool activo,
  }) async => null;
  @override
  Future<String?> crearCuenta({
    required String correo,
    required String clave,
    required EntrenadorAdmin datos,
  }) async => null;
  @override
  Stream<Map<String, Map<String, dynamic>>> entrenadoresPublicos() =>
      Stream.value(const {});
  @override
  Stream<Map<String, Map<String, dynamic>>> perfilesPrivados() =>
      Stream.value(const {});
}

class _Estudiantes implements AdminEstudianteRepository {
  @override
  Future<String?> cambiarEstado({
    required String uid,
    required bool activo,
  }) async => null;
  @override
  Stream<List<Estudiante>> estudiantes() => Stream.value(const []);
}

class _Resenas implements AdminResenaRepository {
  @override
  Future<String?> cambiarVisibilidad({
    required String id,
    required bool visible,
  }) async => null;
  @override
  Stream<List<({Resena resena, bool visible})>> resenas() =>
      Stream.value(const []);
}

class _Pagos implements AdminPagoRepository {
  @override
  Future<String?> actualizarSolvencia({
    required String uid,
    required bool solvente,
  }) async => null;
  @override
  Stream<ConfiguracionPagos?> configuracion() => Stream.value(null);
  @override
  Future<String?> crearNotificacionPago({
    required String uid,
    required String periodo,
    required DateTime fechaCorte,
  }) async => null;
  @override
  Stream<List<Estudiante>> estudiantes() => Stream.value(const []);
  @override
  Future<String?> guardarFechaCorte({
    required String periodo,
    required DateTime fechaInicio,
    required DateTime fechaCorte,
    required double monto,
  }) async => null;
  @override
  Stream<List<Pago>> pagos() => Stream.value(const []);
  @override
  Future<String?> registrarPagoPaypal({
    required String pagoId,
    required String paypalOrderId,
    required DateTime fechaPago,
    required bool verificado,
    required String verificadoPor,
  }) async => null;
}

class _Inscripciones implements AdminInscripcionRepository {
  @override
  Future<String?> cambiarEstado({
    required String id,
    required String estado,
  }) async => null;
  @override
  Stream<List<Inscripcion>> inscripciones() => Stream.value(const []);
}

class _Eventos implements AdminEventoRepository {
  @override
  Future<String?> actualizarEvento({
    required String id,
    required Map<String, dynamic> datos,
    String? canchaId,
    String? fecha,
    int? horaInicio,
    int? horaFin,
  }) async => null;
  @override
  Future<String?> cambiarEstadoEvento({
    required String id,
    required String estado,
  }) async => null;
  @override
  Stream<List<Cancha>> canchas() => Stream.value(const []);
  @override
  Future<String?> crearEvento({
    required Map<String, dynamic> datos,
    required String canchaId,
    required String fecha,
    required int horaInicio,
    required int horaFin,
  }) async => null;
  @override
  Stream<List<Evento>> eventos() => Stream.value(const []);
  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) =>
      Stream.value(const []);
}

class _Soporte implements AdminSoporteRepository {
  @override
  Future<String?> responder({
    required String id,
    required String respuesta,
  }) async => null;
  @override
  Stream<List<TicketSoporte>> tickets() => Stream.value(const []);
}

class _Historial implements AdminTransaccionRepository {
  @override
  Stream<List<Transaccion>> transacciones() => Stream.value(const []);
}
