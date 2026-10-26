import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/asistencia_controller.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/repositories/asistencia_repository.dart';
import 'package:saman_sports/repositories/historial_asistencia_repository.dart';
import 'package:saman_sports/views/entrenador/widgets/boton_exportar_asistencia.dart';

class _Repo implements AsistenciaRepository {
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

class _Historial implements HistorialAsistenciaRepository {
  bool falla = false;
  @override
  Future<List<SesionAsistencia>> sesiones(String id) async {
    if (falla) throw StateError('sin permisos');
    return [
      SesionAsistencia(
        fecha: DateTime(2026, 10, 20),
        estados: {'i1': EstadoAsistencia.presente},
      ),
    ];
  }
}

void main() {
  testWidgets('exporta nómina guardada y bloquea exportación con borrador', (
    tester,
  ) async {
    final c = AsistenciaController(repository: _Repo());
    addTearDown(c.dispose);
    await c.abrir('d1', DateTime(2026, 10, 25), [
      const AlumnoInscrito(
        inscripcionId: 'i1',
        uid: 'u1',
        nombre: 'Ana',
        carnet: '123',
        correo: '',
      ),
    ]);
    String? archivo;
    String? contenido;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BotonExportarAsistencia(
            controller: c,
            disciplina: 'Tenis',
            repository: _Historial(),
            entregar: (nombre, csv) async {
              archivo = nombre;
              contenido = csv;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(archivo, 'asistencia_d1_2026-10-25.csv');
    expect(contenido, contains('100.0%'));
    c.marcar('i1', EstadoAsistencia.ausente);
    await tester.pumpAndSettle();
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
  });
  testWidgets('fallo de historial no entrega un CSV ni anuncia éxito', (
    tester,
  ) async {
    final c = AsistenciaController(repository: _Repo());
    addTearDown(c.dispose);
    await c.abrir('d1', DateTime(2026, 10, 25), [
      const AlumnoInscrito(
        inscripcionId: 'i1',
        uid: 'u1',
        nombre: 'Ana',
        carnet: '123',
        correo: '',
      ),
    ]);
    bool entregado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BotonExportarAsistencia(
            controller: c,
            disciplina: 'Tenis',
            repository: _Historial()..falla = true,
            entregar: (_, _) async {
              entregado = true;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(entregado, isFalse);
    expect(
      find.text('No se pudo exportar el listado. Intenta nuevamente.'),
      findsOneWidget,
    );
  });
}
