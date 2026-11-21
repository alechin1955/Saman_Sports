import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/eventos_entrenador_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/evento.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';
import 'package:saman_sports/repositories/eventos_entrenador_repository.dart';
import 'package:saman_sports/views/entrenador/eventos_entrenador_view.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/entrenador_controller.dart';

void main() {
  test('cancela una solicitud pendiente', () async {
    final repo = _Repo();
    final controller = EventosEntrenadorController(repository: repo);
    addTearDown(controller.dispose);
    final ok = await controller.cancelarSolicitud(_evento());
    expect(ok, isTrue);
    expect(controller.mensaje, AppStrings.entSolicitudCancelada);
    expect(repo.cancelado, 'e1');
  });

  test('muestra el error del repositorio', () async {
    final controller = EventosEntrenadorController(
      repository: _Repo(error: 'No se pudo'),
    );
    addTearDown(controller.dispose);
    final ok = await controller.cancelarSolicitud(_evento());
    expect(ok, isFalse);
    expect(controller.error, 'No se pudo');
  });

  test('editar llama al repositorio con los campos validados', () async {
    final repo = _Repo();
    final controller = EventosEntrenadorController(
      repository: repo,
      reloj: () => DateTime(2026, 11, 1),
    );
    addTearDown(controller.dispose);
    controller.iniciar();
    await Future<void>.delayed(Duration.zero);
    controller.observarCancha('c1');
    await Future<void>.delayed(Duration.zero);

    final ok = await controller.editarSolicitud(
      evento: _evento(),
      nombre: 'Torneo editado',
      disciplina: _deporte,
      cancha: _cancha,
      fecha: DateTime(2026, 11, 12),
      horaInicio: 600,
      horaFin: 720,
      capacidad: 12,
      descripcion: 'Nuevo horario',
    );

    expect(ok, isTrue);
    expect(repo.editado?['titulo'], 'Torneo editado');
    expect(repo.editado?['fecha'], '2026-11-12');
    expect(repo.editado?['capacidad'], 12);
  });

  testWidgets('una solicitud aprobada no muestra editar ni cancelar', (
    tester,
  ) async {
    final controller = EventosEntrenadorController(
      repository: _Repo(lista: [_evento(estado: EstadoEvento.aprobado)]),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: EventosEntrenadorView(
          auth: AuthController(salir: () async {}),
          controller: controller,
          entrenador: EntrenadorController(repository: _Nomina()),
        ),
      ),
    );
    controller.iniciar();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(AppStrings.editar), findsNothing);
    expect(find.text(AppStrings.entCancelarSolicitud), findsNothing);
  });
}

class _Repo implements EventosEntrenadorRepository {
  _Repo({this.error, this.lista = const []});

  final String? error;
  final List<Evento> lista;
  String? cancelado;
  Map<String, dynamic>? editado;

  @override
  Stream<List<Cancha>> canchas() => Stream.value(const [_cancha]);

  @override
  Stream<List<Evento>> eventos() => Stream.value(lista);

  @override
  Stream<List<ReservaHorario>> reservasCancha(String canchaId) =>
      Stream.value(const []);

  @override
  Future<String?> solicitar(Map<String, dynamic> datos) async => null;

  @override
  Future<String?> cancelar(String eventoId) async {
    cancelado = eventoId;
    return error;
  }

  @override
  Future<String?> editar(String eventoId, Map<String, dynamic> datos) async {
    editado = datos;
    return error;
  }
}

class _Nomina implements EntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => const [_deporte];

  @override
  Future<List<AlumnoInscrito>> inscritos(String deporteId) async => const [];
}

Evento _evento({EstadoEvento estado = EstadoEvento.pendiente}) {
  return Evento(
    id: 'e1',
    titulo: 'Torneo',
    tipo: TipoEvento.evento,
    canchaId: 'c1',
    canchaNombre: 'Cancha 1',
    fecha: '2026-11-10',
    horaInicio: 600,
    horaFin: 720,
    descripcion: 'Partido',
    estado: estado,
    creadoPorUid: 'ent1',
    deporteId: 'tenis',
    deporteNombre: 'Tenis',
    capacidad: 10,
  );
}

const _cancha = Cancha(
  id: 'c1',
  nombre: 'Cancha 1',
  ubicacion: 'Campus',
  descripcion: '',
  activa: true,
  version: 0,
);

const _deporte = Deporte(
  id: 'tenis',
  nombre: 'Tenis',
  descripcion: '',
  icono: 'tenis',
  horario: '',
  cupos: 10,
  inscritos: 1,
  entrenadorNombre: 'Ana',
);
