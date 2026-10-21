import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/app.dart';
import 'package:saman_sports/core/constants/app_strings.dart';

void main() {
  Future<void> abrirRegistro(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(const SamanSportsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.registrarse));
    await tester.pumpAndSettle();
  }

  Future<void> enviar(WidgetTester tester) async {
    final boton = find.widgetWithText(ElevatedButton, AppStrings.crearCuenta);
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pump();
  }

  testWidgets('rechaza correos que no son de estudiante', (tester) async {
    await abrirRegistro(tester);
    final correo = find.byType(TextFormField).at(5);

    for (final valor in ['ana@unimet.edu.ve', 'ana@gmail.com']) {
      await tester.enterText(correo, valor);
      await enviar(tester);
      expect(find.text(AppStrings.soloCorreoEstudiante), findsOneWidget);
      expect(find.text('Panel del estudiante'), findsNothing);
    }
  });

  testWidgets('con datos válidos abre el panel del estudiante', (tester) async {
    await abrirRegistro(tester);
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Ana');
    await tester.enterText(campos.at(1), 'Pérez');
    await tester.enterText(campos.at(2), 'V-12345678');
    await tester.enterText(campos.at(3), '2023111012');
    await tester.enterText(campos.at(4), '0414-1234567');
    await tester.enterText(campos.at(5), 'ana@correo.unimet.edu.ve');
    await tester.enterText(campos.at(6), '123456');
    await tester.enterText(campos.at(7), '123456');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await enviar(tester);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.panelEstudiante), findsNothing);
    expect(find.text(AppStrings.crearCuenta), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('el registro en móvil no se desborda', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const SamanSportsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.registrarme));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
}
