import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/views/widgets/opcion_panel.dart';
import 'package:saman_sports/views/widgets/panel_layout.dart';

void main() {
  const opciones = [
    OpcionPanel(
      icono: Icons.dashboard_outlined,
      texto: 'Dashboard',
      ruta: '/uno',
    ),
    OpcionPanel(icono: Icons.person_outline, texto: 'Mi perfil', ruta: '/dos'),
  ];

  Widget panel() {
    return MaterialApp(
      home: PanelLayout(
        auth: AuthController(),
        opciones: opciones,
        rutaActiva: '/uno',
        subtituloPanel: 'Panel de prueba',
        titulo: 'Título de prueba',
        descripcion: 'Descripción de prueba',
        child: const Text('Contenido de prueba'),
      ),
    );
  }

  testWidgets('en escritorio muestra el menú lateral fijo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(panel());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text(AppStrings.cerrarSesion), findsOneWidget);
    expect(find.text('Contenido de prueba'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('en móvil el menú se abre desde el Drawer', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(panel());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('Contenido de prueba'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text(AppStrings.cerrarSesion), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
