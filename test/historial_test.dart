import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/historial_controller.dart';
import 'package:saman_sports/controllers/inscripciones_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/views/estudiante/historial_estudiante_view.dart';

/// Inscripción con el id que usa la fachada: {uid}_{deporteId}.
Map<String, dynamic> inscripcion(String deporteId, String estado, int dia) {
  return {
    'id': 'u1_$deporteId',
    'estudianteUid': 'u1',
    'deporteId': deporteId,
    'deporteNombre': 'Deporte $deporteId',
    'estado': estado,
    'fecha': DateTime(2026, 10, dia),
  };
}

/// Sesiones como las guarda el entrenador en deportes/{id}/asistencias.
final Map<String, List<Map<String, dynamic>>> sesionesPorDeporte = {
  'd1': [
    {'id': '2026-10-06', 'estados': {'u1_d1': 'presente', 'otro': 'ausente'}},
    {'id': '2026-10-08', 'estados': {'u1_d1': 'ausente'}},
    {'id': '2026-10-13', 'estados': {'u1_d1': 'presente'}},
    {'id': '2026-10-15', 'estados': {'u1_d1': 'presente'}},
    {'id': '2026-10-20', 'estados': {'otro': 'presente'}},
  ],
  'd2': [
    {'id': '2026-10-07', 'estados': {'u1_d2': 'ausente'}},
  ],
};

void main() {
  group('ResumenAsistencia', () {
    test('cuenta solo las sesiones donde aparece la inscripción', () {
      final r = ResumenAsistencia.calcular('u1_d1', sesionesPorDeporte['d1']!);
      expect(r.presentes, 3);
      expect(r.total, 4);
      expect(r.porcentaje, 75);
    });

    test('sin clases registradas no hay porcentaje', () {
      final r = ResumenAsistencia.calcular('u1_d9', const []);
      expect(r.total, 0);
      expect(r.porcentaje, isNull);
    });
  });

  group('HistorialController', () {
    late StreamController<List<Map<String, dynamic>>> fuente;

    HistorialController crear({bool fallaD2 = false}) {
      fuente = StreamController<List<Map<String, dynamic>>>();
      final inscripciones = InscripcionesController(
        uidActual: () => 'u1',
        origen: (_) => fuente.stream,
      );
      return HistorialController(
        inscripciones: inscripciones,
        leerAsistencias: (deporteId) async {
          if (fallaD2 && deporteId == 'd2') throw StateError('sin permiso');
          return sesionesPorDeporte[deporteId] ?? const [];
        },
      );
    }

    test('incluye las inscripciones canceladas en el historial', () async {
      final c = crear()..iniciar();
      fuente.add([
        inscripcion('d1', 'confirmada', 1),
        inscripcion('d2', 'cancelada', 5),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(c.historial.map((i) => i.deporteId), ['d2', 'd1']);
      c.dispose();
      c.inscripciones.dispose();
    });

    test('calcula la asistencia de cada disciplina y la general', () async {
      final c = crear()..iniciar();
      fuente.add([
        inscripcion('d1', 'confirmada', 1),
        inscripcion('d2', 'cancelada', 5),
      ]);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(c.resumenDe('u1_d1')?.porcentaje, 75);
      expect(c.resumenDe('u1_d2')?.porcentaje, 0);
      expect(c.general.presentes, 3);
      expect(c.general.total, 5);
      expect(c.general.porcentaje, 60);
      c.dispose();
      c.inscripciones.dispose();
    });

    test('si no puede leer una asistencia no rompe las demás', () async {
      final c = crear(fallaD2: true)..iniciar();
      fuente.add([
        inscripcion('d1', 'confirmada', 1),
        inscripcion('d2', 'confirmada', 5),
      ]);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(c.resumenDe('u1_d1')?.porcentaje, 75);
      expect(c.resumenDe('u1_d2'), isNull);
      expect(c.consultando('u1_d2'), isFalse);
      c.dispose();
      c.inscripciones.dispose();
    });
  });

  group('HistorialEstudianteView', () {
    HistorialController conDatos(List<Map<String, dynamic>> lista) {
      return HistorialController(
        inscripciones: InscripcionesController(
          uidActual: () => 'u1',
          origen: (_) => Stream.value(lista),
        ),
        leerAsistencias: (deporteId) async =>
            sesionesPorDeporte[deporteId] ?? const [],
      );
    }

    Widget pantalla(HistorialController c) => MaterialApp(
      home: HistorialEstudianteView(auth: AuthController(), controller: c),
    );

    const tamanos = [Size(390, 844), Size(768, 1024), Size(1440, 900)];
    for (final tamano in tamanos) {
      testWidgets('muestra cada disciplina con su asistencia en '
          '${tamano.width.toInt()} px', (tester) async {
        await tester.binding.setSurfaceSize(tamano);
        await tester.pumpWidget(
          pantalla(
            conDatos([
              inscripcion('d1', 'confirmada', 1),
              inscripcion('d2', 'cancelada', 5),
              inscripcion('d3', 'pendiente', 3),
            ]),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Deporte d1'), findsOneWidget);
        expect(find.text('Deporte d2'), findsOneWidget);
        expect(find.text(AppStrings.estadoCancelada), findsOneWidget);
        expect(
          find.text(
            '${AppStrings.asistencia}: 3 ${AppStrings.de} 4 '
            '${AppStrings.clases} (75 %)',
          ),
          findsOneWidget,
        );
        expect(find.text(AppStrings.sinClasesRegistradas), findsOneWidget);
        expect(find.text('60 %'), findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });
    }

    testWidgets('sin inscripciones muestra el estado vacío', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(pantalla(conDatos(const [])));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.sinHistorial), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });
  });
}
