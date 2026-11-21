import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/notificaciones_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/notificacion.dart';
import 'package:saman_sports/repositories/notificaciones_repository.dart';
import 'package:saman_sports/views/widgets/campana_notificaciones.dart';
import 'package:saman_sports/views/widgets/notificaciones_scope.dart';

void main() {
  testWidgets('sin scope no dibuja nada', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CampanaNotificaciones())),
    );
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('muestra el número y distingue confirmar de informativo', (tester) async {
    final repo = _Repo();
    final controller = NotificacionesController(repositorio: repo);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: NotificacionesScope(
          controller: controller,
          child: const Scaffold(body: CampanaNotificaciones()),
        ),
      ),
    );
    repo.fuente.add([
      _aviso('c', 'evento_confirmar', eventoId: 'ev1'),
      _aviso('i', 'evento_info'),
    ]);
    controller.iniciar();
    repo.sesion.add('est1');
    await tester.pump();
    await tester.pump();
    expect(controller.noLeidas, 2);
    expect(find.text('2'), findsWidgets);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.confirmarParticipacion), findsOneWidget);
    expect(find.text(AppStrings.noAsistire), findsOneWidget);
    expect(find.text(AppStrings.marcarLeida), findsOneWidget);
    await tester.tap(find.text(AppStrings.marcarLeida));
    await tester.pump();
    expect(repo.marcadas.single.id, 'i');
  });
}

Notificacion _aviso(String id, String tipo, {String eventoId = ''}) {
  return Notificacion(
    id: id,
    destinatarioUid: 'est1',
    tipo: tipo,
    titulo: id,
    mensaje: id,
    periodo: '',
    leida: false,
    fecha: DateTime(2026, 11, 1),
    eventoId: eventoId,
  );
}

class _Repo implements NotificacionesRepository {
  final sesion = StreamController<String?>.broadcast();
  final fuente = StreamController<List<Notificacion>>();
  final escucho = Completer<void>();
  final marcadas = <Notificacion>[];

  @override
  Stream<String?> uidSesion() => sesion.stream;
  @override
  Future<String?> rolDe(String uid) async => 'estudiante';
  @override
  Stream<List<Notificacion>> propias(String uid) {
    if (!escucho.isCompleted) escucho.complete();
    return fuente.stream;
  }
  @override
  Stream<List<Notificacion>> bandejaAdmin() => const Stream.empty();
  @override
  Future<String?> marcarLeida(Notificacion aviso) async {
    marcadas.add(aviso);
    return null;
  }

  @override
  Future<String?> responderParticipacion(Notificacion aviso, bool asistira) async =>
      null;
}
