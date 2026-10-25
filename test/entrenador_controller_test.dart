import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';

Deporte deporte(String id) => Deporte(
  id: id,
  nombre: id,
  descripcion: '',
  icono: 'otro',
  horario: 'Lun 14:00',
  cupos: 20,
  inscritos: 1,
  entrenadorNombre: 'Diego',
);
const alumno = AlumnoInscrito(
  inscripcionId: 'i1',
  uid: 'u1',
  nombre: 'Ana Pérez',
  carnet: '20261001',
  correo: 'ana@correo.unimet.edu.ve',
);

class RepositorioPrueba implements EntrenadorRepository {
  List<Deporte> deportes = [deporte('a'), deporte('b')];
  final respuestas = <String, Completer<List<AlumnoInscrito>>>{};
  bool fallar = false;
  @override
  Future<List<Deporte>> disciplinas() async {
    if (fallar) throw StateError('sin conexión');
    return deportes;
  }

  @override
  Future<List<AlumnoInscrito>> inscritos(String id) async =>
      respuestas[id]?.future ?? [alumno];
}

void main() {
  test('carga primera disciplina y busca por carnet o nombre', () async {
    final c = EntrenadorController(repository: RepositorioPrueba());
    addTearDown(c.dispose);
    await c.cargar();
    expect(c.seleccionId, 'a');
    expect(c.cargando, isFalse);
    c.buscar('20261001');
    expect(c.filtrados, [alumno]);
    c.buscar('ANA');
    expect(c.filtrados, [alumno]);
    c.buscar('inexistente');
    expect(c.filtrados, isEmpty);
  });
  test(
    'ignora nómina anterior si cambia de disciplina durante consulta',
    () async {
      final repo = RepositorioPrueba();
      final c = EntrenadorController(repository: repo);
      addTearDown(c.dispose);
      await c.cargar();
      repo.respuestas['a'] = Completer();
      repo.respuestas['b'] = Completer();
      final primera = c.seleccionar('a');
      final segunda = c.seleccionar('b');
      repo.respuestas['b']!.complete([]);
      await segunda;
      repo.respuestas['a']!.complete([alumno]);
      await primera;
      expect(c.seleccionId, 'b');
      expect(c.alumnos, isEmpty);
      expect(c.cargandoNomina, isFalse);
    },
  );
  test('vacío y error no se sustituyen por datos ficticios', () async {
    final repo = RepositorioPrueba()..deportes = [];
    final c = EntrenadorController(repository: repo);
    addTearDown(c.dispose);
    await c.cargar();
    expect(c.disciplinas, isEmpty);
    expect(c.error, isNull);
    repo.fallar = true;
    await c.cargar();
    expect(c.error, isNotNull);
    expect(c.alumnos, isEmpty);
    expect(c.cargando, isFalse);
  });
  test('consulta finalizada después de dispose no notifica', () async {
    final repo = RepositorioPrueba();
    final c = EntrenadorController(repository: repo);
    await c.cargar();
    repo.respuestas['b'] = Completer();
    final pendiente = c.seleccionar('b');
    c.dispose();
    repo.respuestas['b']!.complete([alumno]);
    await pendiente;
  });
}
