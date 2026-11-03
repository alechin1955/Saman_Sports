import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/asistencia_controller.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/repositories/asistencia_repository.dart';

const alumno = AlumnoInscrito(
  inscripcionId: 'i1',
  uid: 'u1',
  nombre: 'Ana',
  carnet: '1',
  correo: '',
);

class _Repo implements AsistenciaRepository {
  Map<String, EstadoAsistencia> datos = {};
  bool fallaLectura = false;
  bool fallaGuardado = false;
  int escrituras = 0;
  @override
  Future<Map<String, EstadoAsistencia>> leer(String id, DateTime fecha) async {
    if (fallaLectura) throw StateError('sin conexión');
    return Map.of(datos);
  }

  @override
  Future<void> guardar(
    String id,
    DateTime fecha,
    Map<String, EstadoAsistencia> estados,
  ) async {
    if (fallaGuardado) throw StateError('sin conexión');
    escrituras++;
    datos = Map.of(estados);
  }
}

void main() {
  test(
    'no marca ausencias implícitas y exige completar antes de guardar',
    () async {
      final repo = _Repo();
      final c = AsistenciaController(repository: repo);
      addTearDown(c.dispose);
      await c.abrir('d1', DateTime.now(), [alumno]);
      expect(c.estados, isEmpty);
      expect(await c.guardar(), isFalse);
      c.marcar('i1', EstadoAsistencia.presente);
      expect(c.presentes, 1);
      expect(c.completa, isTrue);
      expect(await c.guardar(), isTrue);
      expect(c.cambios, isFalse);
      expect(repo.escrituras, 1);
    },
  );
  test(
    'no cambia sesión con cambios pendientes salvo descarte explícito',
    () async {
      final c = AsistenciaController(repository: _Repo());
      addTearDown(c.dispose);
      await c.abrir('d1', DateTime.now(), [alumno]);
      c.marcar('i1', EstadoAsistencia.ausente);
      expect(await c.abrir('d2', DateTime.now(), [alumno]), isFalse);
      expect(c.deporteId, 'd1');
      expect(
        await c.abrir('d2', DateTime.now(), [alumno], descartar: true),
        isTrue,
      );
      expect(c.deporteId, 'd2');
    },
  );
  test('fallo de guardado conserva cambios para reintentar', () async {
    final repo = _Repo()..fallaGuardado = true;
    final c = AsistenciaController(repository: repo);
    addTearDown(c.dispose);
    await c.abrir('d1', DateTime.now(), [alumno]);
    c.marcar('i1', EstadoAsistencia.presente);
    expect(await c.guardar(), isFalse);
    expect(c.cambios, isTrue);
    repo.fallaGuardado = false;
    expect(await c.guardar(), isTrue);
  });
  test('fallo de lectura bloquea marcado y guardar', () async {
    final repo = _Repo()..fallaLectura = true;
    final c = AsistenciaController(repository: repo);
    addTearDown(c.dispose);
    await c.abrir('d1', DateTime.now(), [alumno]);
    expect(c.error, isNotNull);
    c.marcar('i1', EstadoAsistencia.presente);
    expect(c.estados, isEmpty);
    expect(await c.guardar(), isFalse);
  });
  test('rechaza fecha futura y estados de inscripciones ajenas', () async {
    final c = AsistenciaController(repository: _Repo());
    addTearDown(c.dispose);
    expect(
      await c.abrir('d1', DateTime.now().add(const Duration(days: 2)), [
        alumno,
      ]),
      isFalse,
    );
    await c.abrir('d1', DateTime.now(), [alumno]);
    c.marcar('ajeno', EstadoAsistencia.presente);
    expect(c.estados, isEmpty);
  });
}
