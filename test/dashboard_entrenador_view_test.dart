import 'package:saman_sports/controllers/entrenador_controller.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/models/alumno_inscrito.dart';
import 'package:saman_sports/repositories/entrenador_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/views/entrenador/dashboard_entrenador_view.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final size in [
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('panel entrenador adaptable a ${size.width}', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final auth = AuthController();
      addTearDown(auth.dispose);
      final controller = EntrenadorController(repository: _Vacio());
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardEntrenadorView(auth: auth, controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dashboard del entrenador'), findsOneWidget);
      expect(find.text('Bienvenido a tu espacio deportivo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (size.width < 1024) {
        expect(find.byType(Drawer), findsNothing);
        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();
        expect(find.text('Panel del entrenador'), findsOneWidget);
      } else {
        expect(find.text('Panel del entrenador'), findsOneWidget);
      }
    });
  }
}

class _Vacio implements EntrenadorRepository {
  @override
  Future<List<Deporte>> disciplinas() async => [];
  @override
  Future<List<AlumnoInscrito>> inscritos(String id) async => [];
}
