import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/admin/admin_estudiante_controller.dart';
import 'package:saman_sports/controllers/admin/admin_inscripcion_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/estudiante.dart';
import 'package:saman_sports/models/inscripcion.dart';
import 'package:saman_sports/repositories/admin/admin_estudiante_repository.dart';
import 'package:saman_sports/repositories/admin/admin_inscripcion_repository.dart';
import 'package:saman_sports/views/admin/inscripciones_admin_view.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('botones, estado y pago en escritorio', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final panel = AdminInscripcionController(repository: _Inscripciones());
    final alumnos = AdminEstudianteController(repository: _Alumnos());
    addTearDown(panel.dispose);
    addTearDown(alumnos.dispose);
    panel.iniciar();
    alumnos.iniciar();

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InscripcionesAdminView(
            inscripciones: panel,
            estudiantes: alumnos,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final confirmar = tester.getRect(find.text(AppStrings.adminConfirmar));
    final cancelar = tester.getRect(find.text(AppStrings.cancelar).first);
    expect(confirmar.center.dy, closeTo(cancelar.center.dy, 1));
    expect(cancelar.center.dx, greaterThan(confirmar.center.dx));
    final siguiente = tester.getRect(find.text(AppStrings.cancelar).at(1));
    expect(cancelar.bottom, lessThanOrEqualTo(siguiente.top));

    expect(find.text(AppStrings.estadoPendiente), findsOneWidget);
    expect(find.text(AppStrings.estadoConfirmada), findsOneWidget);
    expect(find.text('pago123'), findsNothing);
    expect(find.text(AppStrings.adminPagoRegistrado), findsOneWidget);
    expect(find.text(AppStrings.adminEstudianteSinNombre), findsOneWidget);
    expect(find.text('uid-sin-nombre'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cards de inscripciones sin overflow a 390', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final panel = AdminInscripcionController(repository: _Inscripciones());
    final alumnos = AdminEstudianteController(repository: _Alumnos());
    addTearDown(panel.dispose);
    addTearDown(alumnos.dispose);
    panel.iniciar();
    alumnos.iniciar();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InscripcionesAdminView(
              inscripciones: panel,
              estudiantes: alumnos,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.adminConfirmar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Inscripciones implements AdminInscripcionRepository {
  @override
  Stream<List<Inscripcion>> inscripciones() => Stream.value([
    Inscripcion(
      id: 'i1',
      estudianteUid: 'ana',
      deporteId: 'futbol',
      deporteNombre: 'Fútbol',
      estado: EstadoInscripcion.pendiente,
      fecha: DateTime(2026, 3, 1),
      pagoId: 'pago123',
    ),
    Inscripcion(
      id: 'i2',
      estudianteUid: 'uid-sin-nombre',
      deporteId: 'futbol',
      deporteNombre: 'Fútbol',
      estado: EstadoInscripcion.confirmada,
      fecha: DateTime(2026, 3, 2),
    ),
  ]);

  @override
  Future<String?> cambiarEstado({
    required String id,
    required String estado,
  }) async => null;
}

class _Alumnos implements AdminEstudianteRepository {
  @override
  Stream<List<Estudiante>> estudiantes() => Stream.value([
    const Estudiante(
      uid: 'ana',
      cedula: 'V-1',
      nombre: 'Ana',
      apellido: 'Pérez',
      correo: 'ana@correo.unimet.edu.ve',
      carnet: '20201111',
      telefono: '04120000000',
      activo: true,
      solvente: true,
    ),
  ]);

  @override
  Future<String?> cambiarEstado({
    required String uid,
    required bool activo,
  }) async => null;

  @override
  Future<String?> actualizarSolvencia({
    required String uid,
    required bool solvente,
  }) async => null;

  @override
  Future<List<String>> revisarIdentificadores() async => const [];
}
