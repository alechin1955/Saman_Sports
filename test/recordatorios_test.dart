import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/recordatorios_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/views/estudiante/recordatorios_estudiante_view.dart';

/// Aviso con el formato que escribe el administrador en notificaciones.
Map<String, dynamic> aviso(
  String id,
  String tipo, {
  bool leida = false,
  int dia = 1,
}) {
  return {
    'id': id,
    'destinatarioUid': 'u1',
    'tipo': tipo,
    'titulo': 'Aviso $id',
    'mensaje': 'Mensaje del aviso $id',
    'periodo': '2026-11',
    'leida': leida,
    'fecha': DateTime(2026, 11, dia),
  };
}

void main() {
  group('RecordatoriosController', () {
    late StreamController<List<Map<String, dynamic>>> fuente;
    late List<String> marcados;

    RecordatoriosController crear({AuthResponse? respuesta}) {
      fuente = StreamController<List<Map<String, dynamic>>>();
      marcados = [];
      return RecordatoriosController(
        uidActual: () => 'u1',
        origen: (_) => fuente.stream,
        marcar: (id) async {
          marcados.add(id);
          return respuesta ?? AuthResponse(isSuccess: true);
        },
      );
    }

    test('ordena del más nuevo al más viejo y cuenta los no leídos',
        () async {
      final c = crear()..iniciar();
      fuente.add([
        aviso('a', 'pago_pendiente', dia: 1),
        aviso('b', 'evento', leida: true, dia: 5),
        aviso('c', 'evento', dia: 3),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(c.cargando, isFalse);
      expect(c.avisos.map((a) => a.id), ['b', 'c', 'a']);
      expect(c.noLeidos, 2);
      c.dispose();
    });

    test('marcar uno ya leído no llama a la fachada', () async {
      final c = crear()..iniciar();
      fuente.add([aviso('b', 'evento', leida: true)]);
      await Future<void>.delayed(Duration.zero);

      expect(await c.marcarLeido(c.avisos.single), isNull);
      expect(marcados, isEmpty);
      c.dispose();
    });

    test('marcar todos solo envía los no leídos', () async {
      final c = crear()..iniciar();
      fuente.add([
        aviso('a', 'pago_pendiente', dia: 1),
        aviso('b', 'evento', leida: true, dia: 5),
        aviso('c', 'evento', dia: 3),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(await c.marcarTodos(), isNull);
      expect(marcados, ['c', 'a']);
      expect(c.procesando, isFalse);
      c.dispose();
    });

    test('devuelve el error de la fachada', () async {
      final c = crear(
        respuesta: AuthResponse(
          isSuccess: false,
          errorMessage: 'No puedes marcar esta notificación.',
        ),
      )..iniciar();
      fuente.add([aviso('a', 'pago_pendiente')]);
      await Future<void>.delayed(Duration.zero);

      expect(
        await c.marcarLeido(c.avisos.single),
        'No puedes marcar esta notificación.',
      );
      c.dispose();
    });

    test('sin sesión muestra el error de sesión', () {
      final c = RecordatoriosController(
        uidActual: () => null,
        origen: (_) => const Stream.empty(),
        marcar: (_) async => AuthResponse(isSuccess: true),
      )..iniciar();
      expect(c.error, AppStrings.sesionNoIniciada);
      c.dispose();
    });
  });

  group('RecordatoriosEstudianteView', () {
    RecordatoriosController conDatos(
      List<Map<String, dynamic>> lista, {
      List<String>? marcados,
    }) {
      return RecordatoriosController(
        uidActual: () => 'u1',
        origen: (_) => Stream.value(lista),
        marcar: (id) async {
          marcados?.add(id);
          return AuthResponse(isSuccess: true);
        },
      );
    }

    Widget pantalla(RecordatoriosController c) => MaterialApp(
      home: RecordatoriosEstudianteView(auth: AuthController(), controller: c),
    );

    final avisos = [
      aviso('a', 'pago_pendiente', dia: 1),
      aviso('b', 'evento', leida: true, dia: 5),
    ];

    const tamanos = [Size(390, 844), Size(768, 1024), Size(1440, 900)];
    for (final tamano in tamanos) {
      testWidgets('lista los avisos y marca los nuevos en '
          '${tamano.width.toInt()} px', (tester) async {
        await tester.binding.setSurfaceSize(tamano);
        await tester.pumpWidget(pantalla(conDatos(avisos)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Aviso a'), findsOneWidget);
        expect(find.text('Aviso b'), findsOneWidget);
        expect(find.text('1 ${AppStrings.sinLeer}'), findsOneWidget);
        expect(find.text(AppStrings.nuevo), findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });
    }

    testWidgets('marcar como leída llama a la fachada con ese aviso', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      final marcados = <String>[];
      await tester.pumpWidget(
        pantalla(conDatos(avisos, marcados: marcados)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.marcarLeida));
      await tester.pumpAndSettle();
      expect(marcados, ['a']);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('sin avisos muestra el estado vacío', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(pantalla(conDatos(const [])));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.sinRecordatorios), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });
  });
}
