import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/eventos_entrenador_controller.dart';
import 'package:saman_sports/controllers/inicio_entrenador_controller.dart';
import 'package:saman_sports/controllers/perfil_entrenador_controller.dart';
import 'package:saman_sports/controllers/resenas_entrenador_controller.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/asistencia.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/models/perfil_entrenador.dart';
import 'package:saman_sports/models/resena.dart';
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
  canchaNombre: 'Cancha 1',
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
    expect(
      OpcionesEntrenador.menu.map((opcion) => opcion.ruta),
      [
        AppRoutes.dashboardEntrenador,
        AppRoutes.entrenadorDisciplinas,
        AppRoutes.entrenadorAsistencia,
        AppRoutes.entrenadorEventos,
        AppRoutes.entrenadorResenas,
        AppRoutes.entrenadorSoporte,
        AppRoutes.entrenadorPerfil,
      ],
    );
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
    expect(controller.proximaClase?.nombre, 'Tenis');
    expect(controller.asistenciasRecientes, hasLength(1));
    expect(controller.asistenciasRecientes.single.presentes, 1);
  });

  test('una solicitud de evento conserva disciplina, horario y capacidad', () async {
    final repo = _EventosRepo();
    final controller = EventosEntrenadorController(
      repository: repo,
      reloj: () => DateTime(2026, 11, 7),
    );
    addTearDown(controller.dispose);

    final ok = await controller.solicitar(
      nombre: 'Torneo interno',
      disciplina: _tenis,
      fecha: DateTime(2026, 11, 10),
      horaInicio: 14,
      horaFin: 16,
      ubicacion: 'Cancha 1',
      capacidad: 24,
      descripcion: 'Encuentro de cierre de semestre.',
    );

    expect(ok, isTrue);
    expect(repo.solicitud?['deporteId'], 'tenis');
    expect(repo.solicitud?['horaInicio'], 14);
    expect(repo.solicitud?['capacidad'], 24);
  });

  test('Eventos escucha únicamente la lista entregada por su repositorio', () async {
    final repo = _EventosRepo();
    final controller = EventosEntrenadorController(repository: repo);
    addTearDown(controller.dispose);

    controller.iniciar();
    await pumpEventQueue();

    expect(controller.eventos, hasLength(1));
    expect(controller.eventos.single.estado, EstadoEvento.pendiente);
  });

  test('Perfil carga todos los datos propios del entrenador', () async {
    final controller = PerfilEntrenadorController(repository: _PerfilRepo());
    addTearDown(controller.dispose);

    await controller.cargar();

    expect(controller.perfil?.nombreCompleto, 'Juan Pérez');
    expect(controller.perfil?.certificaciones, ['ITF Nivel 1']);
    expect(controller.perfil?.anosExperiencia, 6);
  });

  test('Reseñas muestra solo las asociadas a disciplinas del entrenador', () async {
    final controller = ResenasEntrenadorController(repository: _ResenasRepo());
    addTearDown(controller.dispose);

    await controller.iniciar();
    await pumpEventQueue();

    expect(controller.resenas, hasLength(1));
    expect(controller.resenas.single.deporteId, 'tenis');
  });
}

class _EntrenadorRepo implements EntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => const [_tenis];

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

class _EventosRepo implements EventosEntrenadorRepository {
  Map<String, dynamic>? solicitud;

  @override
  Stream<List<Evento>> eventos() => Stream.value([
    Evento(
      id: 'e1',
      titulo: 'Torneo interno',
      tipo: TipoEvento.evento,
      deporteId: 'tenis',
      deporteNombre: 'Tenis',
      canchaId: '',
      canchaNombre: 'Cancha 1',
      fecha: '2026-11-10',
      horaInicio: 14,
      horaFin: 16,
      descripcion: '',
      estado: EstadoEvento.pendiente,
      creadoPorUid: 'entrenador-1',
      capacidad: 24,
    ),
  ]);

  @override
  Future<String?> solicitar(Map<String, dynamic> datos) async {
    solicitud = datos;
    return null;
  }
}

class _ResenasRepo implements ResenasEntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => const [_tenis];

  @override
  Stream<List<Resena>> resenas() => Stream.value([
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
