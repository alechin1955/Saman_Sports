import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/comunidad_controller.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart';
import 'package:saman_sports/controllers/explorar_deportes_controller.dart';
import 'package:saman_sports/controllers/resultado_login.dart';
import 'package:saman_sports/core/routes/app_routes.dart';
import 'package:saman_sports/views/auth/guardia_rol.dart';

void main() {
  testWidgets('las siete rutas del entrenador exigen el rol entrenador', (
    tester,
  ) async {
    final auth = AuthController();
    final estudiante = EstudianteController();
    final explorar = ExplorarDeportesController();
    final comunidad = ComunidadController();
    addTearDown(auth.dispose);
    addTearDown(estudiante.dispose);
    addTearDown(explorar.dispose);
    addTearDown(comunidad.dispose);
    final rutas = AppRoutes.routes(auth, estudiante, explorar, comunidad);
    final nombres = [
      AppRoutes.dashboardEntrenador,
      AppRoutes.entrenadorDisciplinas,
      AppRoutes.entrenadorAsistencia,
      AppRoutes.entrenadorEventos,
      AppRoutes.entrenadorResenas,
      AppRoutes.entrenadorSoporte,
      AppRoutes.entrenadorPerfil,
    ];
    late List<Widget> pantallas;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            pantallas = nombres.map((ruta) => rutas[ruta]!(context)).toList();
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(pantallas, hasLength(7));
    for (final pantalla in pantallas) {
      expect(pantalla, isA<GuardiaRol>());
      expect((pantalla as GuardiaRol).esperado, DestinoLogin.entrenador);
    }
  });
}
