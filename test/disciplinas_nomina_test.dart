import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';
import 'package:saman_sports/views/entrenador/widgets/disciplinas_nomina.dart';

class _Repo implements EntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => [
    const Deporte(
      id: 'tenis',
      nombre: 'Tenis',
      descripcion: '',
      icono: 'tenis',
      horario: 'Lun 14:00',
      cupos: 20,
      inscritos: 1,
      entrenadorNombre: 'Entrenador',
    ),
  ];
  @override
  Future<List<AlumnoInscrito>> inscritos(String id) async => [
    const AlumnoInscrito(
      inscripcionId: 'i1',
      uid: 'u1',
      nombre: 'Ana Pérez',
      carnet: '20261001',
      correo: 'ana@correo.unimet.edu.ve',
    ),
  ];
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final ancho in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('nómina y búsqueda sin desbordamientos a $ancho px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(ancho, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final c = EntrenadorController(repository: _Repo());
      addTearDown(c.dispose);
      await c.cargar();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DisciplinasNomina(controller: c),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tenis'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'inexistente');
      await tester.pumpAndSettle();
      expect(find.text('No encontramos coincidencias'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
