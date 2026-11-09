import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/FirebaseServices.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/soporte_estudiante_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/utils/ticket_soporte_estudiante.dart';
import 'package:saman_sports/views/estudiante/soporte_estudiante_view.dart';

/// Ticket con el formato que guarda la colección tickets.
Map<String, dynamic> ticket(
  String id, {
  String estado = 'abierto',
  String respuesta = '',
  int dia = 1,
}) {
  return {
    'id': id,
    'asunto': 'Asunto $id',
    'categoria': 'pagos',
    'descripcion': 'No me aparece mi pago del período.',
    'autorUid': 'u1',
    'autorNombre': 'María González',
    'autorRol': 'estudiante',
    'estado': estado,
    'respuesta': respuesta,
    'fecha': DateTime(2026, 11, dia),
  };
}

void main() {
  group('construirTicketEstudiante', () {
    const perfil = {
      'nombre': 'María',
      'apellido': 'González',
      'rol': 'estudiante',
    };

    test('arma el ticket como lo piden las reglas de tickets', () {
      final datos = construirTicketEstudiante(
        estudianteUid: 'u1',
        perfil: perfil,
        categoria: 'pagos',
        asunto: '  Pago no aparece  ',
        descripcion: 'Pagué con PayPal y sigue pendiente.',
        fechaServidor: 'AHORA',
      );
      expect(datos['autorUid'], 'u1');
      expect(datos['autorRol'], 'estudiante');
      expect(datos['autorNombre'], 'María González');
      expect(datos['asunto'], 'Pago no aparece');
      expect(datos['estado'], 'abierto');
      expect(datos['respuesta'], '');
      expect(datos['resueltoEn'], isNull);
    });

    test('rechaza una categoría que no existe y un perfil que no es '
        'estudiante', () {
      expect(
        () => construirTicketEstudiante(
          estudianteUid: 'u1',
          perfil: perfil,
          categoria: 'otra',
          asunto: 'Pago no aparece',
          descripcion: 'Pagué con PayPal y sigue pendiente.',
          fechaServidor: 'AHORA',
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => construirTicketEstudiante(
          estudianteUid: 'u1',
          perfil: const {'rol': 'entrenador'},
          categoria: 'pagos',
          asunto: 'Pago no aparece',
          descripcion: 'Pagué con PayPal y sigue pendiente.',
          fechaServidor: 'AHORA',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('SoporteEstudianteController', () {
    late StreamController<List<Map<String, dynamic>>> fuente;
    late List<String> enviados;

    SoporteEstudianteController crear() {
      fuente = StreamController<List<Map<String, dynamic>>>();
      enviados = [];
      return SoporteEstudianteController(
        uidActual: () => 'u1',
        origen: (_) => fuente.stream,
        crear: (categoria, asunto, descripcion) async {
          enviados.add('$categoria|$asunto');
          return AuthResponse(isSuccess: true);
        },
      );
    }

    test('ordena los tickets del más nuevo al más viejo', () async {
      final c = crear()..iniciar();
      fuente.add([ticket('a', dia: 1), ticket('b', dia: 4)]);
      await Future<void>.delayed(Duration.zero);

      expect(c.tickets.map((t) => t.id), ['b', 'a']);
      expect(c.tickets.first.categoriaVisible, 'Pagos y solvencia');
      c.dispose();
    });

    test('valida antes de enviar y no llama a la fachada', () async {
      final c = crear()..iniciar();
      final error = await c.enviar(
        categoria: 'pagos',
        asunto: 'Hola',
        descripcion: 'Pagué con PayPal y sigue pendiente.',
      );
      expect(error, AppStrings.soporteAsuntoCorto);
      expect(enviados, isEmpty);
      c.dispose();
    });

    test('envía el ticket con el texto limpio', () async {
      final c = crear()..iniciar();
      final error = await c.enviar(
        categoria: 'pagos',
        asunto: '  Pago no aparece ',
        descripcion: 'Pagué con PayPal y sigue pendiente.',
      );
      expect(error, isNull);
      expect(enviados, ['pagos|Pago no aparece']);
      expect(c.enviando, isFalse);
      c.dispose();
    });
  });

  group('SoporteEstudianteView', () {
    SoporteEstudianteController conDatos(
      List<Map<String, dynamic>> lista, {
      List<String>? enviados,
    }) {
      return SoporteEstudianteController(
        uidActual: () => 'u1',
        origen: (_) => Stream.value(lista),
        crear: (categoria, asunto, descripcion) async {
          enviados?.add('$categoria|$asunto');
          return AuthResponse(isSuccess: true);
        },
      );
    }

    Widget pantalla(SoporteEstudianteController c) => MaterialApp(
      home: SoporteEstudianteView(auth: AuthController(), controller: c),
    );

    final tickets = [
      ticket('a', dia: 1),
      ticket(
        'b',
        estado: 'resuelto',
        respuesta: 'Ya registramos tu pago.',
        dia: 4,
      ),
    ];

    const tamanos = [Size(390, 844), Size(768, 1024), Size(1440, 900)];
    for (final tamano in tamanos) {
      testWidgets('muestra el formulario y los tickets en '
          '${tamano.width.toInt()} px', (tester) async {
        await tester.binding.setSurfaceSize(tamano);
        await tester.pumpWidget(pantalla(conDatos(tickets)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.soporteNuevoTicket), findsOneWidget);
        expect(find.text('Asunto a'), findsOneWidget);
        expect(find.text('Asunto b'), findsOneWidget);
        expect(find.text(AppStrings.soporteResuelto), findsOneWidget);
        expect(find.text('Ya registramos tu pago.'), findsOneWidget);
        expect(find.text(AppStrings.soporteSinRespuesta), findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });
    }

    testWidgets('enviar el formulario llama a la fachada y lo limpia', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      final enviados = <String>[];
      await tester.pumpWidget(
        pantalla(conDatos(const [], enviados: enviados)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pagos y solvencia').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('soporte_asunto')),
        'Pago no aparece',
      );
      await tester.enterText(
        find.byKey(const ValueKey('soporte_descripcion')),
        'Pagué con PayPal y sigue pendiente.',
      );
      await tester.tap(find.text(AppStrings.soporteEnviar));
      await tester.pumpAndSettle();

      expect(enviados, ['pagos|Pago no aparece']);
      expect(find.text(AppStrings.soporteEnviado), findsOneWidget);
      expect(find.text('Pago no aparece'), findsNothing);
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('sin tickets muestra el estado vacío', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(pantalla(conDatos(const [])));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.soporteSinTickets), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    });
  });
}