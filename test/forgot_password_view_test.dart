import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/app.dart';
import 'package:saman_sports/core/constants/app_strings.dart';

void main() {
  testWidgets('muestra la confirmación genérica y vuelve al formulario', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(const SamanSportsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.iniciarSesion));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.olvidasteContrasena));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'ana@correo.unimet.edu.ve',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, AppStrings.enviarEnlace));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.revisarCorreo), findsOneWidget);
    await tester.tap(find.text(AppStrings.usarOtroCorreo));
    await tester.pump();
    expect(find.text(AppStrings.recuperarContrasena), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('en móvil no se desborda', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const SamanSportsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.iniciarSesion));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.olvidasteContrasena));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.volverAlInicio), findsNothing);
    expect(find.text(AppStrings.volverAIniciarSesion), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
}
