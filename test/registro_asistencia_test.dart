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
      final tabla = ancho >= RegistroAsistencia.anchoTabla + 40;
      expect(find.text('Estudiante'), tabla ? findsOneWidget : findsNothing);
      expect(
        find.text('Ana Pérez (Carnet: 20261001)', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('asistencia-i1-presente')));
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

  testWidgets(
    'Sin registrar quita la marca y bloquea guardar hasta completar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = _Repo();
      final c = AsistenciaController(repository: repo);
      addTearDown(c.dispose);
      await c.abrir('d1', DateTime.now(), [
        for (final (id, nombre) in [('i1', 'Ana Pérez'), ('i2', 'Luis Díaz')])
          AlumnoInscrito(
            inscripcionId: id,
            uid: 'u$id',
            nombre: nombre,
            carnet: '2026$id',
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
      Future<void> tocar(String clave) async {
        await tester.tap(find.byKey(ValueKey('asistencia-$clave')));
        await tester.pumpAndSettle();
      }

      bool puedeGuardar() => tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Guardar asistencia'),
              matching: find.byWidgetPredicate((w) => w is FilledButton),
            ),
          )
          .enabled;

      await tocar('i1-presente');
      expect(
        find.text('Falta 1 estudiante por marcar para poder guardar.'),
        findsOneWidget,
      );
      expect(puedeGuardar(), isFalse);

      await tocar('i2-ausente');
      expect(
        find.text('1 presentes · 1 ausentes · 0 sin registrar'),
        findsOneWidget,
      );
      expect(puedeGuardar(), isTrue);

      await tocar('i2-sin');
      expect(c.estados.containsKey('i2'), isFalse);
      expect(
        find.text('1 presentes · 0 ausentes · 1 sin registrar'),
        findsOneWidget,
      );
      expect(puedeGuardar(), isFalse);

      await tocar('i2-ausente');
      await tester.tap(find.text('Guardar asistencia'));
      await tester.pumpAndSettle();
      expect(repo.datos, {
        'i1': EstadoAsistencia.presente,
        'i2': EstadoAsistencia.ausente,
      });
      expect(tester.takeException(), isNull);
    },
  );
}
