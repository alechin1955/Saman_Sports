import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/entrenador/entrenador_notificacion_controller.dart';
import 'package:saman_sports/models/notificacion.dart';
import 'package:saman_sports/repositories/entrenador/entrenador_notificacion_repository.dart';
import 'package:saman_sports/views/entrenador/notificaciones_entrenador_view.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('la campana cuenta las no leídas y marca una como leída', () async {
    final repo = _Avisos();
    final controller = EntrenadorNotificacionController(repository: repo);
    controller.iniciar();
    await Future<void>.delayed(Duration.zero);

    expect(controller.noLeidas, 1);
    expect(controller.notificaciones.first.titulo, 'Más reciente');

    expect(await controller.marcarLeida(controller.notificaciones.first), isNull);
    expect(repo.leidas, ['nueva']);
    controller.dispose();
  });

  testWidgets('la campana abre la lista', (tester) async {
    final controller = EntrenadorNotificacionController(repository: _Avisos());
    addTearDown(controller.dispose);
    controller.iniciar();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: CampanaEntrenador(controller: controller))),
    );
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.byTooltip(EntrenadorNotificacionController.titulo));
    await tester.pumpAndSettle();
    expect(find.text('Más reciente'), findsOneWidget);
  });
}

class _Avisos implements EntrenadorNotificacionRepository {
  final leidas = <String>[];

  @override
  Stream<List<Notificacion>> notificaciones() => Stream.value([
    Notificacion(
      id: 'nueva',
      destinatarioUid: 'e1',
      tipo: 'evento',
      titulo: 'Más reciente',
      mensaje: 'Hay un evento',
      periodo: '',
      leida: false,
      fecha: DateTime(2026, 11, 8),
    ),
    Notificacion(
      id: 'vieja',
      destinatarioUid: 'e1',
      tipo: 'evento',
      titulo: 'Antigua',
      mensaje: 'Aviso',
      periodo: '',
      leida: true,
      fecha: DateTime(2026, 11, 1),
    ),
  ]);

  @override
  Future<String?> marcarLeida(String id) async {
    leidas.add(id);
    return null;
  }
}
