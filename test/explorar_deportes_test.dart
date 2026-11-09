import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/explorar_deportes_controller.dart';
import 'package:saman_sports/controllers/inscripciones_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/views/estudiante/explorar_deportes_view.dart';

/// Franja con el formato que guarda el administrador (minutos del día).
Map<String, int> franja(int dia, int hora) => {
  'dia': dia,
  'horaInicio': hora * 60,
  'horaFin': (hora + 2) * 60,
};

/// Seis deportes con el mismo formato que crea el panel del administrador.
final List<Map<String, dynamic>> deportesDelAdmin = [
  {
    'id': 'd1',
    'nombre': 'Fútbol',
    'descripcion': 'Cancha principal.',
    'icono': 'futbol',
    'horario': 'Lun y Mié 16:00',
    'cupos': 22,
    'inscritos': 18,
    'entrenadorNombre': 'Carlos Méndez',
    'horarios': [franja(1, 16), franja(3, 16)],
  },
  {
    'id': 'd2',
    'nombre': 'Baloncesto',
    'descripcion': 'Fundamentos.',
    'icono': 'baloncesto',
    'horario': 'Mar y Jue 17:00',
    'cupos': 15,
    'inscritos': 14,
    'entrenadorNombre': 'Laura Pérez',
    'horarios': [franja(2, 17), franja(4, 17)],
  },
  {
    'id': 'd3',
    'nombre': 'Tenis',
    'descripcion': 'Técnica.',
    'icono': 'tenis',
    'horario': 'Vie 15:00',
    'cupos': 10,
    'inscritos': 4,
    'entrenadorNombre': 'Andrés Rojas',
    'horarios': [franja(5, 15)],
  },
  {
    'id': 'd4',
    'nombre': 'Voleibol',
    'descripcion': 'Gimnasio.',
    'icono': 'voleibol',
    'horario': 'Lun y Vie 18:00',
    'cupos': 16,
    'inscritos': 9,
    'entrenadorNombre': 'Ana Torres',
    'horarios': [franja(1, 18), franja(5, 18)],
  },
  {
    'id': 'd5',
    'nombre': 'Natación',
    'descripcion': 'Piscina.',
    'icono': 'natacion',
    'horario': 'Mar y Jue 7:00',
    'cupos': 12,
    'inscritos': 12,
    'entrenadorNombre': 'Carlos Méndez',
    'horarios': [franja(2, 7), franja(4, 7)],
  },
  {
    'id': 'd6',
    'nombre': 'Running',
    'descripcion': 'Campus.',
    'icono': 'running',
    'horario': 'Sáb 7:00',
    'cupos': 30,
    'inscritos': 11,
    'entrenadorNombre': 'Laura Pérez',
    'horarios': [franja(6, 7)],
  },
];

ExplorarDeportesController controladorConDeportes() {
  return ExplorarDeportesController(
    origen: () => Stream.value(deportesDelAdmin),
  );
}

/// Inscripciones de prueba: el estudiante 'u1' aún no tiene ninguna.
InscripcionesController inscripcionesDePrueba({List<String>? inscritos}) {
  return InscripcionesController(
    uidActual: () => 'u1',
    origen: (_) => Stream.value(const []),
    inscribir: (id) async {
      inscritos?.add(id);
      return AuthResponse(isSuccess: true);
    },
    cancelar: (_) async => AuthResponse(isSuccess: true),
  );
}

void main() {
  group('ExplorarDeportesController', () {
    Future<ExplorarDeportesController> iniciado() async {
      final c = controladorConDeportes()..iniciar();
      await Future<void>.delayed(Duration.zero);
      return c;
    }

    test('muestra solo los deportes que publicó el administrador', () async {
      final c = await iniciado();
      expect(c.cargando, isFalse);
      expect(c.sinPublicar, isFalse);
      expect(c.deportesFiltrados.length, 6);
      c.dispose();
    });

    test('si no hay deportes publicados no inventa ninguno', () async {
      final c = ExplorarDeportesController(origen: () => Stream.value(const []))
        ..iniciar();
      await Future<void>.delayed(Duration.zero);

      expect(c.deportes, isEmpty);
      expect(c.sinPublicar, isTrue);
      c.dispose();
    });

    test('si falla la conexión muestra error y no datos de ejemplo', () async {
      final c = ExplorarDeportesController(
        origen: () => Stream.error(Exception('sin red')),
      )..iniciar();
      await Future<void>.delayed(Duration.zero);

      expect(c.error, AppStrings.errorConexion);
      expect(c.deportes, isEmpty);
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

    test(
      'filtra por día con los horarios del admin y se quita al repetir',
      () async {
        final c = await iniciado();
        c.elegirDia('Sáb');
        expect(c.deportesFiltrados.single.nombre, 'Running');
        c.elegirDia('Lun');
        expect(c.deportesFiltrados.map((d) => d.nombre), [
          'Fútbol',
          'Voleibol',
        ]);
        c.elegirDia('Lun');
        expect(c.dia, isNull);
        c.dispose();
      },
    );

    test('un deporte sin franjas se filtra por el texto del horario', () {
      final viejo = Deporte.fromMap(const {
        'id': 'x',
        'nombre': 'Ajedrez',
        'horario': 'Mié 14:00',
        'cupos': 8,
        'inscritos': 0,
      });
      expect(ExplorarDeportesController.tieneClaseEl(viejo, 'Mié'), isTrue);
      expect(ExplorarDeportesController.tieneClaseEl(viejo, 'Lun'), isFalse);
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
    Widget pantalla(
      ExplorarDeportesController controller, {
      InscripcionesController? inscripciones,
    }) {
      return MaterialApp(
        home: ExplorarDeportesView(
          auth: AuthController(),
          controller: controller,
          inscripciones: inscripciones ?? inscripcionesDePrueba(),
        ),
      );
    }

    const tamanos = [Size(390, 844), Size(768, 1024), Size(1440, 900)];

    for (final tamano in tamanos) {
      testWidgets('muestra el catálogo sin desbordarse en '
          '${tamano.width.toInt()} px', (tester) async {
        await tester.binding.setSurfaceSize(tamano);
        await tester.pumpWidget(pantalla(controladorConDeportes()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.datosEjemplo), findsNothing);
        expect(
          find.text('6 ${AppStrings.disciplinasEncontradas}'),
          findsOneWidget,
        );
        await tester.binding.setSurfaceSize(null);
      });
    }

    testWidgets('sin deportes del admin muestra el aviso correspondiente', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(
        pantalla(
          ExplorarDeportesController(origen: () => Stream.value(const [])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.sinDisciplinasPublicadas), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('al buscar solo quedan los deportes que coinciden', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(pantalla(controladorConDeportes()));
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
      await tester.pumpWidget(pantalla(controladorConDeportes()));
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

    testWidgets('ver detalles muestra la información y permite cerrar', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(pantalla(controladorConDeportes()));
      await tester.pumpAndSettle();

      final detalles = find.text(AppStrings.verDetalles).first;
      await tester.ensureVisible(detalles);
      await tester.pumpAndSettle();
      await tester.tap(detalles);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.inscripcionPendienteNota), findsOneWidget);
      expect(find.text(AppStrings.inscribirme), findsOneWidget);
      await tester.tap(find.text(AppStrings.cerrar));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.inscripcionPendienteNota), findsNothing);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('inscribirme llama a la fachada y avisa que quedó pendiente', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      final inscritos = <String>[];
      await tester.pumpWidget(
        pantalla(
          controladorConDeportes(),
          inscripciones: inscripcionesDePrueba(inscritos: inscritos),
        ),
      );
      await tester.pumpAndSettle();

      final detalles = find.text(AppStrings.verDetalles).first;
      await tester.ensureVisible(detalles);
      await tester.tap(detalles);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.inscribirme));
      await tester.pumpAndSettle();

      expect(inscritos, ['d1']);
      expect(find.text(AppStrings.inscripcionRegistrada), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('un deporte sin cupos no deja inscribirse', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(pantalla(controladorConDeportes()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'natacion');
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.verDetalles));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.sinCuposDisponibles), findsOneWidget);
      final boton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, AppStrings.inscribirme),
      );
      expect(boton.onPressed, isNull);
      await tester.binding.setSurfaceSize(null);
    });
  });
}
