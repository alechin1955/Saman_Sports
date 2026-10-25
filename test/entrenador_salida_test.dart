import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/controllers/asistencia_controller.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/repositories/asistencia_repository.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';
import 'package:saman_sports/views/entrenador/dashboard_entrenador_view.dart';

const alumno = AlumnoInscrito(
  inscripcionId: 'i1',
  uid: 'u1',
  nombre: 'Ana Pérez',
  carnet: '20261001',
  correo: '',
);

class _Nomina implements EntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => [
    const Deporte(
      id: 'd1',
      nombre: 'Tenis',
      descripcion: '',
      icono: 'tenis',
      horario: 'Lun 14:00',
      cupos: 20,
      inscritos: 1,
      entrenadorNombre: 'Diego',
    ),
  ];
  @override
  Future<List<AlumnoInscrito>> inscritos(String id) async => [alumno];
}

class _Asistencia implements AsistenciaRepository {
  @override
  Future<Map<String, EstadoAsistencia>> leer(String id, DateTime fecha) async =>
      {};
  @override
  Future<void> guardar(
    String id,
    DateTime fecha,
    Map<String, EstadoAsistencia> estados,
  ) async {}
}

class _Auth extends AuthController {
  bool cerro = false;
  @override
  Future<void> cerrarSesion() async {
    cerro = true;
  }
}

void main() {
  testWidgets(
    'cancelar salida conserva borrador y confirmar permite cerrar sesión',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await tester.binding.setSurfaceSize(const Size(1440, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final auth = _Auth();
      final nomina = EntrenadorController(repository: _Nomina());
      final asistencia = AsistenciaController(repository: _Asistencia());
      addTearDown(auth.dispose);
      addTearDown(nomina.dispose);
      addTearDown(asistencia.dispose);
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/entrenador',
          routes: {
            '/': (_) => const Scaffold(body: Text('Inicio público')),
            '/entrenador': (_) => DashboardEntrenadorView(
              auth: auth,
              controller: nomina,
              asistencia: asistencia,
            ),
          },
        ),
      );
      await tester.pumpAndSettle();
      asistencia.marcar('i1', EstadoAsistencia.presente);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Tienes asistencia sin guardar'), findsOneWidget);
      await tester.tap(find.text('Continuar editando'));
      await tester.pumpAndSettle();
      expect(auth.cerro, isFalse);
      expect(asistencia.cambios, isTrue);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar y salir'));
      await tester.pumpAndSettle();
      expect(auth.cerro, isTrue);
      expect(asistencia.cambios, isFalse);
      expect(find.text('Inicio público'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
