import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/inscripciones_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/deporte.dart';
import 'package:saman_sports/views/estudiante/mis_disciplinas_view.dart';

Map<String, dynamic> inscripcion(
  String id,
  String deporteId,
  String estado, {
  int dia = 1,
}) {
  return {
    'id': id,
    'estudianteUid': 'u1',
    'deporteId': deporteId,
    'deporteNombre': 'Deporte $deporteId',
    'estado': estado,
    'fecha': DateTime(2026, 11, dia),
  };
}

const futbol = Deporte(
  id: 'd1',
  nombre: 'Fútbol',
  descripcion: '',
  icono: 'futbol',
  horario: '',
  cupos: 10,
  inscritos: 3,
  entrenadorNombre: '',
);

void main() {
  group('InscripcionesController', () {
    late StreamController<List<Map<String, dynamic>>> fuente;
    late List<String> llamadas;

    InscripcionesController crear({
      AuthResponse? respuesta,
      String? Function()? uid,
    }) {
      fuente = StreamController<List<Map<String, dynamic>>>();
      llamadas = [];
      return InscripcionesController(
        uidActual: uid ?? () => 'u1',
        origen: (_) => fuente.stream,
        inscribir: (id) async {
          llamadas.add('inscribir $id');
          return respuesta ?? AuthResponse(isSuccess: true);
        },
        cancelar: (id) async {
          llamadas.add('cancelar $id');
          return respuesta ?? AuthResponse(isSuccess: true);
        },
      );
    }

    test('ordena de la más nueva a la más vieja y separa las activas',
        () async {
      final c = crear()..iniciar();
      fuente.add([
        inscripcion('a', 'd1', 'pendiente', dia: 2),
        inscripcion('b', 'd2', 'cancelada', dia: 5),
        inscripcion('c', 'd3', 'confirmada', dia: 3),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(c.cargando, isFalse);
      expect(c.inscripciones.map((i) => i.id), ['b', 'c', 'a']);
      expect(c.activas.map((i) => i.id), ['c', 'a']);
      expect(c.activaEn('d1')?.id, 'a');
      expect(c.activaEn('d2'), isNull);
      c.dispose();
    });

    test('sin sesión muestra el error de sesión', () {
      final c = crear(uid: () => null)..iniciar();
      expect(c.error, AppStrings.sesionNoIniciada);
      c.dispose();
    });

    test('se inscribe en un deporte con cupo', () async {
      final c = crear()..iniciar();
      fuente.add([]);
      await Future<void>.delayed(Duration.zero);

      expect(c.puedeInscribirse(futbol), isTrue);
      expect(await c.inscribirse(futbol), isNull);
      expect(llamadas, ['inscribir d1']);
      c.dispose();
    });

    test('no deja inscribirse dos veces en el mismo deporte', () async {
      final c = crear()..iniciar();
      fuente.add([inscripcion('a', 'd1', 'pendiente')]);
      await Future<void>.delayed(Duration.zero);

      expect(c.puedeInscribirse(futbol), isFalse);
      expect(await c.inscribirse(futbol), AppStrings.inscripcionYaExiste);
      expect(llamadas, isEmpty);
      c.dispose();
    });

    test('no deja inscribirse si no quedan cupos', () async {
      final c = crear()..iniciar();
      fuente.add([]);
      await Future<void>.delayed(Duration.zero);

      const lleno = Deporte(
        id: 'd9',
        nombre: 'Natación',
        descripcion: '',
        icono: 'natacion',
        horario: '',
        cupos: 5,
        inscritos: 5,
        entrenadorNombre: '',
      );
      expect(await c.inscribirse(lleno), AppStrings.inscripcionSinCupos);
      expect(llamadas, isEmpty);
      c.dispose();
    });

    test('devuelve el mensaje de error de la fachada', () async {
      final c = crear(
        respuesta: AuthResponse(
          isSuccess: false,
          errorMessage: AppStrings.inscripcionCuentaInactiva,
        ),
      )..iniciar();
      fuente.add([]);
      await Future<void>.delayed(Duration.zero);

      expect(await c.inscribirse(futbol), AppStrings.inscripcionCuentaInactiva);
      expect(c.procesando, isFalse);
      c.dispose();
    });
  });

  group('MisDisciplinasView', () {
    Widget pantalla(InscripcionesController c) => MaterialApp(
      home: MisDisciplinasView(auth: AuthController(), controller: c),
    );

    InscripcionesController conDatos(List<String> canceladas) {
      return InscripcionesController(
        uidActual: () => 'u1',
        origen: (_) => Stream.value([
          inscripcion('a', 'd1', 'pendiente', dia: 3),
          inscripcion('b', 'd2', 'confirmada', dia: 2),
          inscripcion('c', 'd3', 'cancelada'),
        ]),
        cancelar: (id) async {
          canceladas.add(id);
          return AuthResponse(isSuccess: true);
        },
      );
    }

    const tamanos = [Size(390, 844), Size(768, 1024), Size(1440, 900)];
    for (final tamano in tamanos) {
      testWidgets('lista las inscripciones activas en '
          '${tamano.width.toInt()} px', (tester) async {
        await tester.binding.setSurfaceSize(tamano);
        await tester.pumpWidget(pantalla(conDatos([])));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Deporte d1'), findsOneWidget);
        expect(find.text('Deporte d2'), findsOneWidget);
        expect(find.text('Deporte d3'), findsNothing);
        expect(find.text(AppStrings.estadoPendiente), findsOneWidget);
        expect(find.text(AppStrings.estadoConfirmada), findsOneWidget);
        expect(find.text(AppStrings.irAPagos), findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });
    }

    testWidgets('cancelar pide confirmación y libera el cupo', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      final canceladas = <String>[];
      await tester.pumpWidget(pantalla(conDatos(canceladas)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.cancelarInscripcion).first);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.cancelarInscripcionPregunta), findsOneWidget);

      await tester.tap(find.text(AppStrings.siCancelar));
      await tester.pumpAndSettle();
      expect(canceladas, ['a']);
      expect(find.text(AppStrings.inscripcionCancelada), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('si elige volver no cancela nada', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      final canceladas = <String>[];
      await tester.pumpWidget(pantalla(conDatos(canceladas)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.cancelarInscripcion).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.volver));
      await tester.pumpAndSettle();
      expect(canceladas, isEmpty);
      await tester.binding.setSurfaceSize(null);
    });
  });
}