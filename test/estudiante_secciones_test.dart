import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/controllers/auth_controller.dart';
import 'package:saman_sports/controllers/estudiante_controller.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/inscripcion.dart';
import 'package:saman_sports/models/pago.dart';
import 'package:saman_sports/views/estudiante/estatus_pagos_view.dart';
import 'package:saman_sports/views/estudiante/mis_disciplinas_view.dart';

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
  group('Modelos Inscripcion y Pago', () {
    test('Inscripcion lee el estado y el pago', () {
      final i = Inscripcion.fromMap({
        'id': 'i1',
        'estudianteUid': 'abc',
        'deporteId': 'ej-tenis',
        'deporteNombre': 'Tenis',
        'estado': 'confirmada',
        'pagoId': 'p1',
        'fecha': DateTime(2026, 10, 24),
      });

      expect(i.estado, EstadoInscripcion.confirmada);
      expect(i.activa, isTrue);
      expect(i.pagoId, 'p1');
      expect(i.toMap().containsKey('id'), isFalse);
      expect(i.toMap()['estado'], 'confirmada');
    });

    test('un estado desconocido se lee como pendiente', () {
      final i = Inscripcion.fromMap({'id': 'i2', 'estado': 'otro'});
      expect(i.estado, EstadoInscripcion.pendiente);
      expect(i.pagoId, isNull);
    });

    test('una inscripción cancelada ya no está activa', () {
      final i = Inscripcion.fromMap({'id': 'i3', 'estado': 'cancelada'});
      expect(i.activa, isFalse);
    });

    test('Pago acepta el monto como número o como texto', () {
      expect(Pago.fromMap({'monto': 15}).monto, 15.0);
      expect(Pago.fromMap({'monto': '12.5'}).monto, 12.5);
      expect(
        Pago.fromMap({'estado': 'realizado'}).estado,
        EstadoPago.realizado,
      );
    });
  });

  group('Pantallas Mis disciplinas y Estatus y pagos', () {
    const tamanos = [Size(390, 844), Size(768, 1024), Size(1440, 900)];

    for (final tamano in tamanos) {
      final ancho = tamano.width.toInt();

      testWidgets('Mis disciplinas muestra su estado vacío en $ancho px', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(tamano);
        await tester.pumpWidget(
          MaterialApp(home: MisDisciplinasView(auth: AuthController())),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.sinDisciplinas), findsOneWidget);
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets(
        'Estatus y pagos muestra la cuenta y los pasos en $ancho px',
        (tester) async {
          await tester.binding.setSurfaceSize(tamano);
          final controller = EstudianteController(
            uidActual: () => 'abc',
            leer: (uid) async => _datos,
          );
          await tester.pumpWidget(
            MaterialApp(
              home: EstatusPagosView(
                auth: AuthController(),
                controller: controller,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text(AppStrings.noSolvente), findsOneWidget);
          expect(find.text(AppStrings.pasoPagar), findsOneWidget);
          expect(find.text(AppStrings.sinPagos), findsOneWidget);
          await tester.binding.setSurfaceSize(null);
        },
      );
    }
  });
}
