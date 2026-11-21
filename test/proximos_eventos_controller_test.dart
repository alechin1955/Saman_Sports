import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/proximos_eventos_controller.dart';
import 'package:saman_sports/models/evento_publico.dart';
import 'package:saman_sports/repositories/proximos_eventos_repository.dart';

void main() {
  test('filtra fechas anteriores a hoy', () async {
    final repo = _Repo(
      eventos: [
        _evento('viejo', '2026-11-01'),
        _evento('hoy', '2026-11-21'),
      ],
    );
    final controller = ProximosEventosController(
      reloj: () => DateTime(2026, 11, 21),
      repositorio: repo,
    )..iniciar();
    await Future<void>.delayed(Duration.zero);
    expect(controller.eventos.map((e) => e.id), ['hoy']);
    controller.dispose();
  });

  test('puede confirmar solo deportes inscritos activos', () async {
    final repo = _Repo(
      eventos: [
        _evento('mio', '2026-11-22', deporteId: 'futbol'),
        _evento('otro', '2026-11-22', deporteId: 'tenis'),
      ],
      inscripcionesLista: [
        {'deporteId': 'futbol', 'estado': 'pendiente'},
        {'deporteId': 'tenis', 'estado': 'cancelada'},
      ],
    );
    final controller = ProximosEventosController(
      modo: ModoEventos.estudiante,
      uid: 'est1',
      reloj: () => DateTime(2026, 11, 21),
      repositorio: repo,
    )..iniciar();
    await Future<void>.delayed(Duration.zero);
    expect(controller.puedeConfirmar(controller.eventos.firstWhere((e) => e.id == 'mio')), isTrue);
    expect(controller.puedeConfirmar(controller.eventos.firstWhere((e) => e.id == 'otro')), isFalse);
    controller.dispose();
  });

  test('entrenador filtra sus deportes y cuenta confirmados', () async {
    final repo = _Repo(
      eventos: [
        _evento('mio', '2026-11-22', deporteId: 'futbol'),
        _evento('ajeno', '2026-11-22', deporteId: 'tenis'),
      ],
      participantesLista: [
        {'estado': 'confirmado'},
        {'estado': 'rechazado'},
      ],
    );
    final controller = ProximosEventosController(
      modo: ModoEventos.entrenador,
      reloj: () => DateTime(2026, 11, 21),
      repositorio: repo,
    )..iniciar();
    controller.filtrarPorDeportes({'futbol'});
    await Future<void>.delayed(Duration.zero);
    expect(controller.eventos.map((e) => e.id), ['mio']);
    expect(controller.confirmados['mio'], 1);
    controller.dispose();
  });

  test('responder actualiza el estado', () async {
    final repo = _Repo(eventos: [_evento('ev', '2026-11-22', deporteId: 'futbol')]);
    final controller = ProximosEventosController(
      modo: ModoEventos.estudiante,
      uid: 'est1',
      reloj: () => DateTime(2026, 11, 21),
      repositorio: repo,
    )..iniciar();
    await Future<void>.delayed(Duration.zero);
    await controller.responder(controller.eventos.single, true);
    expect(controller.participacion['ev'], EstadoParticipacion.confirmado);
    controller.dispose();
  });
}

EventoPublico _evento(String id, String fecha, {String deporteId = ''}) {
  return EventoPublico(
    id: id,
    titulo: id,
    tipo: 'evento',
    deporteId: deporteId,
    deporteNombre: deporteId,
    canchaNombre: 'A',
    fecha: fecha,
    horaInicio: 480,
    horaFin: 540,
    descripcion: '',
  );
}

class _Repo implements ProximosEventosRepository {
  _Repo({
    required this.eventos,
    this.inscripcionesLista = const [],
    this.participantesLista = const [],
  });

  final List<EventoPublico> eventos;
  final List<Map<String, dynamic>> inscripcionesLista;
  final List<Map<String, dynamic>> participantesLista;
  final respuestas = <(String, bool)>[];

  @override
  Stream<List<EventoPublico>> publicos({required String desdeFecha, int limite = 20}) {
    return Stream.value(eventos);
  }

  @override
  Stream<List<Map<String, dynamic>>> inscripciones(String uid) {
    return Stream.value(inscripcionesLista);
  }

  @override
  Stream<String> participacion({required String eventoId, required String uid}) {
    return const Stream.empty();
  }

  @override
  Stream<List<Map<String, dynamic>>> participantes({required String eventoId}) {
    return Stream.value(participantesLista);
  }

  @override
  Future<String?> responder({
    required String eventoId,
    required bool asistira,
    String? notificacionId,
  }) async {
    respuestas.add((eventoId, asistira));
    return null;
  }
}
