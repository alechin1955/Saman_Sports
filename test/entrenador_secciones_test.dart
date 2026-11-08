import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/eventos_entrenador_controller.dart';
import 'package:saman_sports/controllers/inicio_entrenador_controller.dart';
import 'package:saman_sports/controllers/perfil_entrenador_controller.dart';
import 'package:saman_sports/controllers/resenas_entrenador_controller.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/models/perfil_entrenador.dart';
import 'package:saman_sports/models/resena.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';
import 'package:saman_sports/repositories/eventos_entrenador_repository.dart';
import 'package:saman_sports/repositories/historial_asistencia_repository.dart';
import 'package:saman_sports/repositories/perfil_entrenador_repository.dart';
import 'package:saman_sports/repositories/resenas_entrenador_repository.dart';
import 'package:saman_sports/views/entrenador/opciones_entrenador.dart';

const _tenis = Deporte(
  id: 'tenis',
  nombre: 'Tenis',
  descripcion: '',
  icono: 'tenis',
  horario: 'Lunes 14:00',
  cupos: 20,
  inscritos: 8,
  entrenadorNombre: 'Juan Pérez',
  canchaId: 'c1',
  canchaNombre: 'Cancha 1',
);

const _cancha = Cancha(
  id: 'c1',
  nombre: 'Cancha 1',
  ubicacion: 'Edificio deportivo',
  descripcion: '',
  activa: true,
  version: 1,
);

const _perfil = PerfilEntrenador(
  uid: 'entrenador-1',
  nombre: 'Juan',
  apellido: 'Pérez',
  correo: 'entrenador@unimet.edu.ve',
  telefono: '04140000000',
  disciplina: 'Tenis',
  especialidad: 'Tenis de campo',
  biografia: 'Entrenador universitario.',
  anosExperiencia: 6,
  certificaciones: ['ITF Nivel 1'],
  activo: true,
);

void main() {
  test('el menú separa todas las funciones del entrenador', () {
    expect(OpcionesEntrenador.menu.map((opcion) => opcion.ruta), [
      AppRoutes.dashboardEntrenador,
      AppRoutes.entrenadorDisciplinas,
      AppRoutes.entrenadorAsistencia,
      AppRoutes.entrenadorEventos,
      AppRoutes.entrenadorResenas,
      AppRoutes.entrenadorPerfil,
    ]);
  });

  test('Inicio resume disciplinas, alumnos y asistencia reciente', () async {
    final controller = InicioEntrenadorController(
      entrenadorRepository: _EntrenadorRepo(),
      perfilRepository: _PerfilRepo(),
      historialRepository: _HistorialRepo(),
    );
    addTearDown(controller.dispose);

    await controller.cargar();

    expect(controller.perfil, _perfil);
    expect(controller.disciplinas, [_tenis]);
    expect(controller.totalEstudiantes, 8);
    expect(controller.proximaClase?.disciplina.nombre, 'Tenis');
    expect(controller.asistenciasRecientes, hasLength(1));
    expect(controller.asistenciasRecientes.single.presentes, 1);
  });

  test(
    'Inicio elige la próxima franja real y no la primera disciplina',
    () async {
      final controller = InicioEntrenadorController(
        entrenadorRepository: _AgendaRepo(),
        perfilRepository: _PerfilRepo(),
        historialRepository: _HistorialRepo(),
        reloj: () => DateTime(2026, 11, 3, 9),
      );
      addTearDown(controller.dispose);

      await controller.cargar();

      expect(controller.proximaClase?.disciplina.nombre, 'Voleibol');
      expect(controller.proximaClase?.inicio, DateTime(2026, 11, 3, 18));
    },
  );

  test(
    'Inicio distingue un fallo de historial de un historial vacío',
    () async {
      final controller = InicioEntrenadorController(
        entrenadorRepository: _EntrenadorRepo(),
        perfilRepository: _PerfilRepo(),
        historialRepository: _HistorialFalla(),
      );
      addTearDown(controller.dispose);

      await controller.cargar();

      expect(controller.error, isNull);
      expect(controller.advertenciaAsistencias, isNotNull);
      expect(controller.asistenciasRecientes, isEmpty);
    },
  );

  test(
    'una solicitud de evento conserva disciplina, horario y capacidad',
    () async {
      final repo = _EventosRepo();
      final controller = EventosEntrenadorController(
        repository: repo,
        reloj: () => DateTime(2026, 11, 7),
      );
      addTearDown(controller.dispose);
      controller.iniciar();
      await pumpEventQueue();
      controller.observarCancha('c1');
      await pumpEventQueue();

      final ok = await controller.solicitar(
        nombre: 'Torneo interno',
        disciplina: _tenis,
        fecha: DateTime(2026, 11, 10),
        horaInicio: 840,
        horaFin: 960,
        cancha: _cancha,
        capacidad: 24,
        descripcion: 'Encuentro de cierre de semestre.',
      );

      expect(ok, isTrue);
      expect(repo.solicitud?['deporteId'], 'tenis');
      expect(repo.solicitud?['canchaId'], 'c1');
      expect(repo.solicitud?['horaInicio'], 840);
      expect(repo.solicitud?['capacidad'], 24);
      expect(repo.solicitud, isNot(contains('estado')));
      expect(repo.solicitud, isNot(contains('creadoPorUid')));
    },
  );

  test(
    'Eventos solo ofrece canchas activas y detecta el choque antes de enviar',
    () async {
      final repo = _EventosRepo(
        canchasDisponibles: const [
          _cancha,
          Cancha(
            id: 'c2',
            nombre: 'Cancha cerrada',
            ubicacion: '',
            descripcion: '',
            activa: false,
            version: 1,
          ),
        ],
        reservas: const [
          ReservaHorario(
            id: 'r1',
            canchaId: 'c1',
            canchaNombre: 'Cancha 1',
            dia: 2,
            horaInicio: 840,
            horaFin: 960,
            tipo: TipoReserva.deporte,
            refId: 'd1',
            refNombre: 'Baloncesto',
            activa: true,
          ),
        ],
      );
      final controller = EventosEntrenadorController(
        repository: repo,
        reloj: () => DateTime(2026, 11, 7),
      );
      addTearDown(controller.dispose);

      controller.iniciar();
      await pumpEventQueue();
      controller.observarCancha('c1');
      await pumpEventQueue();

      expect(controller.canchas, [_cancha]);
      expect(
        controller.choqueHorario(
          cancha: _cancha,
          fecha: DateTime(2026, 11, 10),
          horaInicio: 840,
          horaFin: 960,
        ),
        contains('Baloncesto'),
      );
      final ok = await controller.solicitar(
        nombre: 'Torneo interno',
        disciplina: _tenis,
        cancha: _cancha,
        fecha: DateTime(2026, 11, 10),
        horaInicio: 840,
        horaFin: 960,
        capacidad: 24,
        descripcion: '',
      );
      expect(ok, isFalse);
      expect(repo.solicitud, isNull);
    },
  );

  test(
    'al superar el timeout informa procesamiento y conserva la lista en vivo',
    () async {
      final repo = _EventosLentoRepo();
      final controller = EventosEntrenadorController(
        repository: repo,
        reloj: () => DateTime(2026, 11, 7),
        timeoutSolicitud: const Duration(milliseconds: 5),
      );
      addTearDown(controller.dispose);
      addTearDown(repo.cerrar);
      controller.iniciar();
      await pumpEventQueue();
      controller.observarCancha('c1');
      await pumpEventQueue();

      final ok = await controller.solicitar(
        nombre: 'Torneo interno',
        disciplina: _tenis,
        cancha: _cancha,
        fecha: DateTime(2026, 11, 10),
        horaInicio: 1020,
        horaFin: 1080,
        capacidad: 24,
        descripcion: '',
      );

      expect(ok, isTrue);
      expect(controller.error, isNull);
      expect(controller.mensaje, contains('procesando'));
      repo.publicar(_evento);
      await pumpEventQueue();
      expect(controller.eventos, [_evento]);
    },
  );

  test(
    'Eventos escucha únicamente la lista entregada por su repositorio',
    () async {
      final repo = _EventosRepo();
      final controller = EventosEntrenadorController(repository: repo);
      addTearDown(controller.dispose);

      controller.iniciar();
      await pumpEventQueue();

      expect(controller.eventos, hasLength(1));
      expect(controller.eventos.single.estado, EstadoEvento.pendiente);
    },
  );

  test('Eventos distingue un error de una lista vacía', () async {
    final controller = EventosEntrenadorController(
      repository: _EventosErrorRepo(),
    );
    addTearDown(controller.dispose);

    controller.iniciar();
    await pumpEventQueue();

    expect(controller.error, isNotNull);
    expect(controller.eventos, isEmpty);
  });

  test('Perfil carga todos los datos propios del entrenador', () async {
    final controller = PerfilEntrenadorController(
      repository: _PerfilRepo(),
      entrenadorRepository: _EntrenadorRepo(),
    );
    addTearDown(controller.dispose);

    await controller.cargar();

    expect(controller.perfil?.nombreCompleto, 'Juan Pérez');
    expect(controller.perfil?.certificaciones, ['ITF Nivel 1']);
    expect(controller.perfil?.anosExperiencia, 6);
    expect(controller.totalEstudiantes, 8);
  });

  test(
    'Reseñas muestra solo las asociadas a disciplinas del entrenador',
    () async {
      final repo = _ResenasRepo();
      final controller = ResenasEntrenadorController(repository: repo);
      addTearDown(controller.dispose);

      await controller.iniciar();
      await pumpEventQueue();

      expect(controller.resenas, hasLength(1));
      expect(controller.resenas.single.deporteId, 'tenis');
      expect(repo.deporteIds, ['tenis']);
    },
  );

  test('Reseñas distingue un error de una lista vacía', () async {
    final controller = ResenasEntrenadorController(
      repository: _ResenasErrorRepo(),
    );
    addTearDown(controller.dispose);

    await controller.iniciar();
    await pumpEventQueue();

    expect(controller.error, isNotNull);
    expect(controller.resenas, isEmpty);
  });
}

class _EntrenadorRepo implements EntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => const [_tenis];

  @override
  Future<List<AlumnoInscrito>> inscritos(String deporteId) async => const [];
}

class _AgendaRepo implements EntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => const [
    Deporte(
      id: 'natacion',
      nombre: 'Natación',
      descripcion: '',
      icono: 'natacion',
      horario: 'Miércoles 08:00',
      cupos: 20,
      inscritos: 5,
      entrenadorNombre: 'Juan Pérez',
      horarios: [FranjaHorario(dia: 3, horaInicio: 480, horaFin: 600)],
    ),
    Deporte(
      id: 'voleibol',
      nombre: 'Voleibol',
      descripcion: '',
      icono: 'voleibol',
      horario: 'Martes 18:00',
      cupos: 20,
      inscritos: 5,
      entrenadorNombre: 'Juan Pérez',
      horarios: [FranjaHorario(dia: 2, horaInicio: 1080, horaFin: 1200)],
    ),
  ];

  @override
  Future<List<AlumnoInscrito>> inscritos(String deporteId) async => const [];
}

class _PerfilRepo implements PerfilEntrenadorRepository {
  @override
  Future<PerfilEntrenador> cargar() async => _perfil;
}

class _HistorialRepo implements HistorialAsistenciaRepository {
  @override
  Future<List<SesionAsistencia>> sesiones(String deporteId) async => [
    SesionAsistencia(
      fecha: DateTime(2026, 11, 6),
      estados: const {
        'i1': EstadoAsistencia.presente,
        'i2': EstadoAsistencia.ausente,
      },
    ),
  ];
}

class _HistorialFalla implements HistorialAsistenciaRepository {
  @override
  Future<List<SesionAsistencia>> sesiones(String deporteId) async {
    throw StateError('sin permisos');
  }
}

class _EventosRepo implements EventosEntrenadorRepository {
  _EventosRepo({
    this.canchasDisponibles = const [_cancha],
    this.reservas = const [],
  });

  final List<Cancha> canchasDisponibles;
  final List<ReservaHorario> reservas;
  Map<String, dynamic>? solicitud;

  @override
  Stream<List<Cancha>> canchas() => Stream.value(canchasDisponibles);

  @override
  Stream<List<Evento>> eventos() => Stream.value([_evento]);

  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) => Stream.value(
    reservas.where((reserva) => reserva.canchaId == canchaId).toList(),
  );

  @override
  Future<String?> solicitar(Map<String, dynamic> datos) async {
    solicitud = datos;
    return null;
  }
}

class _EventosErrorRepo implements EventosEntrenadorRepository {
  @override
  Stream<List<Cancha>> canchas() => Stream.value(const [_cancha]);

  @override
  Stream<List<Evento>> eventos() => Stream.error(StateError('sin permisos'));

  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) =>
      const Stream.empty();

  @override
  Future<String?> solicitar(Map<String, dynamic> datos) async => null;
}

class _EventosLentoRepo implements EventosEntrenadorRepository {
  final _eventos = StreamController<List<Evento>>();
  final _pendiente = Completer<String?>();

  @override
  Stream<List<Cancha>> canchas() => Stream.value(const [_cancha]);

  @override
  Stream<List<Evento>> eventos() => _eventos.stream;

  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) =>
      Stream.value(const []);

  @override
  Future<String?> solicitar(Map<String, dynamic> datos) => _pendiente.future;

  void publicar(Evento evento) => _eventos.add([evento]);

  Future<void> cerrar() => _eventos.close();
}

const _evento = Evento(
  id: 'e1',
  titulo: 'Torneo interno',
  tipo: TipoEvento.evento,
  deporteId: 'tenis',
  deporteNombre: 'Tenis',
  canchaId: 'c1',
  canchaNombre: 'Cancha 1',
  fecha: '2026-11-10',
  horaInicio: 840,
  horaFin: 960,
  descripcion: '',
  estado: EstadoEvento.pendiente,
  creadoPorUid: 'entrenador-1',
  capacidad: 24,
);

class _ResenasRepo implements ResenasEntrenadorRepository {
  List<String>? deporteIds;

  @override
  Future<List<Deporte>> disciplinas() async => const [_tenis];

  @override
  Stream<List<Resena>> resenas(List<String> deporteIds) {
    this.deporteIds = deporteIds;
    return Stream.value([
      Resena(
        id: 'r1',
        autorUid: 'a1',
        autorNombre: 'Ana P.',
        disciplina: 'Tenis',
        deporteId: 'tenis',
        estrellas: 5,
        comentario: 'Excelente entrenamiento.',
        fecha: DateTime(2026, 11, 1),
      ),
      Resena(
        id: 'r2',
        autorUid: 'a2',
        autorNombre: 'Luis G.',
        disciplina: 'Natación',
        deporteId: 'natacion',
        estrellas: 4,
        comentario: 'Buen entrenamiento.',
        fecha: DateTime(2026, 11, 2),
      ),
    ]);
  }
}

class _ResenasErrorRepo implements ResenasEntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => const [_tenis];

  @override
  Stream<List<Resena>> resenas(List<String> deporteIds) =>
      Stream.error(StateError('sin permisos'));
}
