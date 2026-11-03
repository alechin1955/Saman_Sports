import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/asistencia_controller.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/repositories/asistencia_repository.dart';
import 'package:saman_sports/views/entrenador/widgets/registro_asistencia.dart';

class _Repo implements AsistenciaRepository {
  Map<String, EstadoAsistencia> datos = {};
  @override
  Future<Map<String, EstadoAsistencia>> leer(String id, DateTime fecha) async =>
      Map.of(datos);
  @override
  Future<void> guardar(
    String id,
    DateTime fecha,
    Map<String, EstadoAsistencia> estados,
  ) async {
    datos = Map.of(estados);
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final ancho in [320.0, 768.0, 1440.0]) {
    testWidgets('marca y guarda asistencia a $ancho px', (tester) async {
      await tester.binding.setSurfaceSize(Size(ancho, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = _Repo();
      final c = AsistenciaController(repository: repo);
      addTearDown(c.dispose);
      await c.abrir('d1', DateTime.now(), [
        const AlumnoInscrito(
          inscripcionId: 'i1',
          uid: 'u1',
          nombre: 'Ana Pérez',
          carnet: '20261001',
          correo: '',
        ),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RegistroAsistencia(controller: c),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Presente'));
      await tester.pumpAndSettle();
      expect(c.cambios, isTrue);
      await tester.ensureVisible(find.text('Guardar asistencia'));
      await tester.tap(find.text('Guardar asistencia'));
      await tester.pumpAndSettle();
      expect(repo.datos['i1'], EstadoAsistencia.presente);
      expect(find.text('Asistencia guardada correctamente.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
