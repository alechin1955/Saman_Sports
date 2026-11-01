import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/asistencia_controller.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/controllers/entrenador_panel_bridge.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/repositories/asistencia_repository.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';

const _alumno = AlumnoInscrito(
  inscripcionId: 'i1',
  uid: 'u1',
  nombre: 'Ana Pérez',
  carnet: '20261001',
  correo: 'ana@correo.unimet.edu.ve',
);

class _Nomina implements EntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => const [
    Deporte(
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
  Future<List<AlumnoInscrito>> inscritos(String deporteId) async => [_alumno];
}

class _Asistencia implements AsistenciaRepository {
  int lecturas = 0;

  @override
  Future<Map<String, EstadoAsistencia>> leer(
    String deporteId,
    DateTime fecha,
  ) async {
    lecturas++;
    return {};
  }

  @override
  Future<void> guardar(
    String deporteId,
    DateTime fecha,
    Map<String, EstadoAsistencia> estados,
  ) async {}
}

void main() {
  test(
    'sincroniza la nómina elegida con la implementación de asistencia',
    () async {
      final asistenciaRepository = _Asistencia();
      final entrenador = EntrenadorController(repository: _Nomina());
      final asistencia = AsistenciaController(repository: asistenciaRepository);
      final panel = EntrenadorPanelBridge(
        entrenador: entrenador,
        asistencia: asistencia,
      );
      addTearDown(() {
        panel.dispose();
        entrenador.dispose();
        asistencia.dispose();
      });

      await panel.cargar();
      await pumpEventQueue();

      expect(asistencia.deporteId, 'd1');
      expect(asistencia.alumnos, [_alumno]);
      expect(asistenciaRepository.lecturas, 1);
    },
  );

  test('conserva el borrador y expone el bloqueo de salida', () async {
    final entrenador = EntrenadorController(repository: _Nomina());
    final asistencia = AsistenciaController(repository: _Asistencia());
    final panel = EntrenadorPanelBridge(
      entrenador: entrenador,
      asistencia: asistencia,
    );
    addTearDown(() {
      panel.dispose();
      entrenador.dispose();
      asistencia.dispose();
    });

    await panel.cargar();
    await pumpEventQueue();
    asistencia.marcar('i1', EstadoAsistencia.presente);

    expect(panel.bloqueaSalida, isTrue);
    await entrenador.cargar();
    expect(asistencia.estados['i1'], EstadoAsistencia.presente);

    panel.descartarBorrador();
    expect(panel.bloqueaSalida, isFalse);
  });
}
