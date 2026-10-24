import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/views/estudiante/dashboard_estudiante_view.dart';

const _datos = <String, dynamic>{
  'nombre': 'María',
  'apellido': 'González',
  'cedula': 'V-28123456',
  'carnet': '20231110123',
  'telefono': '0414-1234567',
  'correo': 'maria@correo.unimet.edu.ve',
  'rol': 'estudiante',
};

void main() {
  Widget pantalla(EstudianteController controller) {
    return MaterialApp(
      home: DashboardEstudianteView(
        auth: AuthController(),
        controller: controller,
      ),
    );
  }

  EstudianteController controladorFalso(Map<String, dynamic>? datos) {
    return EstudianteController(
      uidActual: () => 'abc',
      leer: (uid) async => datos,
    );
  }

  const tamanos = [Size(390, 844), Size(768, 1024), Size(1440, 900)];

  for (final tamano in tamanos) {
    testWidgets('muestra el saludo y los accesos sin desbordarse en '
        '${tamano.width.toInt()} px', (tester) async {
      await tester.binding.setSurfaceSize(tamano);
      final controller = controladorFalso(_datos);
      await tester.pumpWidget(pantalla(controller));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('${AppStrings.hola} María'), findsOneWidget);
      expect(find.text(AppStrings.cuentaActiva), findsOneWidget);
      expect(find.text(AppStrings.noSolvente), findsOneWidget);
      expect(find.text(AppStrings.accesosRapidos), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });
  }

  testWidgets('si no hay datos muestra el error y Reintentar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(pantalla(controladorFalso(null)));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.perfilNoEncontrado), findsOneWidget);
    expect(find.text(AppStrings.reintentar), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
