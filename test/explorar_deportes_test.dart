import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/explorar_deportes_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/views/estudiante/explorar_deportes_view.dart';

/// Controlador con la colección vacía: usa los 6 deportes de ejemplo.
ExplorarDeportesController controladorDeEjemplo() {
  return ExplorarDeportesController(origen: () => Stream.value(const []));
}

void main() {
  group('ExplorarDeportesController', () {
    Future<ExplorarDeportesController> iniciado() async {
      final c = controladorDeEjemplo()..iniciar();
      await Future<void>.delayed(Duration.zero);
      return c;
    }

    test('si la colección está vacía usa los datos de ejemplo', () async {
      final c = await iniciado();
      expect(c.cargando, isFalse);
      expect(c.usandoEjemplo, isTrue);
      expect(c.deportesFiltrados.length, 6);
      c.dispose();
    });

    test('lee los deportes reales cuando la colección tiene datos', () async {
      final c = ExplorarDeportesController(
        origen: () => Stream.value(const [
          {'id': 'd1', 'nombre': 'Ajedrez', 'cupos': 10, 'inscritos': 2},
        ]),
      )..iniciar();
      await Future<void>.delayed(Duration.zero);

      expect(c.usandoEjemplo, isFalse);
      expect(c.deportes.single.nombre, 'Ajedrez');
      c.dispose();
    });

    test('busca sin importar tildes ni mayúsculas', () async {
      final c = await iniciado();
      c.buscar('FUTBOL');
      expect(c.deportesFiltrados.single.nombre, 'Fútbol');
      c.dispose();
    });

    test('busca por nombre del entrenador', () async {
      final c = await iniciado();
      c.buscar('carlos');
      expect(c.deportesFiltrados.map((d) => d.nombre), ['Fútbol', 'Natación']);
      c.dispose();
    });

    test('solo con cupos quita los deportes completos', () async {
      final c = await iniciado();
      c.cambiarSoloConCupos(true);
      expect(c.deportesFiltrados.any((d) => d.nombre == 'Natación'), isFalse);
      expect(c.deportesFiltrados.length, 5);
      c.dispose();
    });

    test('filtra por día y al repetir el día se quita el filtro', () async {
      final c = await iniciado();
      c.elegirDia('Sáb');
      expect(c.deportesFiltrados.single.nombre, 'Running');
      c.elegirDia('Sáb');
      expect(c.dia, isNull);
      c.dispose();
    });

    test('limpiar filtros vuelve a mostrar todo', () async {
      final c = await iniciado();
      c
        ..buscar('tenis')
        ..cambiarSoloConCupos(true)
        ..elegirDia('Vie');
      c.limpiarFiltros();
      expect(c.hayFiltros, isFalse);
      expect(c.deportesFiltrados.length, 6);
      c.dispose();
    });
  });

  group('ExplorarDeportesView', () {
    Widget pantalla(ExplorarDeportesController controller) {
      return MaterialApp(
        home: ExplorarDeportesView(
          auth: AuthController(),
          controller: controller,
        ),
      );
    }

    const tamanos = [Size(390, 844), Size(768, 1024), Size(1440, 900)];

    for (final tamano in tamanos) {
      testWidgets('muestra el catálogo sin desbordarse en '
          '${tamano.width.toInt()} px', (tester) async {
        await tester.binding.setSurfaceSize(tamano);
        await tester.pumpWidget(pantalla(controladorDeEjemplo()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.datosEjemplo), findsOneWidget);
        expect(
          find.text('6 ${AppStrings.disciplinasEncontradas}'),
          findsOneWidget,
        );
        await tester.binding.setSurfaceSize(null);
      });
    }

    testWidgets('al buscar solo quedan los deportes que coinciden', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(pantalla(controladorDeEjemplo()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'tenis');
      await tester.pumpAndSettle();

      expect(
        find.text('1 ${AppStrings.disciplinasEncontradas}'),
        findsOneWidget,
      );
      expect(find.text('Tenis'), findsOneWidget);
      expect(find.text('Fútbol'), findsNothing);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('sin resultados muestra el estado vacío y limpia filtros', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(pantalla(controladorDeEjemplo()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ajedrez');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.sinResultados), findsOneWidget);

      await tester.tap(find.text(AppStrings.limpiarFiltros));
      await tester.pumpAndSettle();
      expect(
        find.text('6 ${AppStrings.disciplinasEncontradas}'),
        findsOneWidget,
      );
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('ver detalles abre la información del deporte', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(pantalla(controladorDeEjemplo()));
      await tester.pumpAndSettle();

      final detalles = find.text(AppStrings.verDetalles).first;
      await tester.ensureVisible(detalles);
      await tester.pumpAndSettle();
      await tester.tap(detalles);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.inscripcionProximamente), findsOneWidget);
      await tester.tap(find.text(AppStrings.cerrar));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.inscripcionProximamente), findsNothing);
      await tester.binding.setSurfaceSize(null);
    });
  });
}
