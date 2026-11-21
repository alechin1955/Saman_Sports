import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/proximos_eventos_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/evento_publico.dart';
import 'package:saman_sports/repositories/proximos_eventos_repository.dart';
import 'package:saman_sports/views/widgets/proximos_eventos_card.dart';

void main() {
  for (final ancho in [390.0, 1440.0]) {
    testWidgets('card en $ancho px', (tester) async {
      await tester.binding.setSurfaceSize(Size(ancho, 900));
      final repo = _Repo([
        _evento('mio', 'futbol'),
        _evento('otro', 'tenis'),
      ]);
      final controller = ProximosEventosController(
        modo: ModoEventos.estudiante,
        uid: 'est1',
        reloj: () => DateTime(2026, 11, 21),
        repositorio: repo,
      )..iniciar();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ProximosEventosCard(controller: controller))),
      );
      await tester.pump();
      expect(find.text(AppStrings.tuDeporte), findsOneWidget);
      expect(find.text(AppStrings.confirmarParticipacion), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    });
  }

  testWidgets('estado vacío', (tester) async {
    final controller = ProximosEventosController(
      repositorio: _Repo(const []),
      reloj: () => DateTime(2026, 11, 21),
    )..iniciar();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ProximosEventosCard(controller: controller))),
    );
    await tester.pump();
    expect(find.text(AppStrings.sinProximosEventos), findsOneWidget);
  });
}

EventoPublico _evento(String id, String deporte) {
  return EventoPublico(
    id: id,
    titulo: id,
    tipo: 'evento',
    deporteId: deporte,
    deporteNombre: deporte,
    canchaNombre: 'A',
    fecha: '2026-11-22',
    horaInicio: 480,
    horaFin: 540,
    descripcion: '',
  );
}

class _Repo implements ProximosEventosRepository {
  _Repo(this.eventos);
  final List<EventoPublico> eventos;

  @override
  Stream<List<EventoPublico>> publicos({required String desdeFecha, int limite = 20}) =>
      Stream.value(eventos);

  @override
  Stream<List<Map<String, dynamic>>> inscripciones(String uid) => Stream.value(const [
    {'deporteId': 'futbol', 'estado': 'confirmada'},
  ]);

  @override
  Stream<String> participacion({required String eventoId, required String uid}) =>
      const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> participantes({required String eventoId}) =>
      const Stream.empty();

  @override
  Future<String?> responder({
    required String eventoId,
    required bool asistira,
    String? notificacionId,
  }) async => null;
}
