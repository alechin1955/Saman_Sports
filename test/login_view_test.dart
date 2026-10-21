import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/app.dart';
import 'package:saman_sports/core/constants/app_strings.dart';

void main() {
  testWidgets('un correo externo muestra error y no entra', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const SamanSportsApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.iniciarSesion));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.iniciarSesion));
    await tester.pump();

    expect(find.text(AppStrings.correoInstitucionalInvalido), findsOneWidget);
    expect(find.text(AppStrings.panelEstudiante), findsNothing);
  });

  testWidgets('un correo institucional válido no entra sin Firebase', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(const SamanSportsApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.tap(find.text(AppStrings.iniciarSesion));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@unimet.edu.ve');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.iniciarSesion));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.panelEstudiante), findsNothing);
    expect(find.text(AppStrings.iniciarSesion), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('volver al inicio regresa a la portada', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(const SamanSportsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.iniciarSesion));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.volverAlInicio));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.homeTitulo), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
