import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/app.dart';
import 'package:saman_sports/core/constants/app_strings.dart';

void main() {
  const tamanos = [Size(390, 844), Size(768, 1024), Size(1440, 900)];

  Future<void> abrir(WidgetTester tester, Size tamano) async {
    await tester.binding.setSurfaceSize(tamano);
    await tester.pumpWidget(SamanSportsApp(key: ValueKey(tamano)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> tocar(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('recorre home, login, registro, recuperar y dashboard', (tester) async {
    for (final tamano in tamanos) {
      await abrir(tester, tamano);
      expect(find.text(AppStrings.homeTitulo), findsOneWidget);

      if (tamano.width < 1024) {
        await tocar(tester, find.byIcon(Icons.menu));
      }
      await tocar(tester, find.text(AppStrings.iniciarSesion).first);
      expect(find.text(AppStrings.volverAlInicio), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tocar(tester, find.text(AppStrings.registrate));
      expect(find.text(AppStrings.crearCuenta), findsWidgets);
      expect(find.text(AppStrings.volverAlInicio), findsOneWidget);

      await tocar(tester, find.text(AppStrings.iniciarSesion).last);
      expect(find.text(AppStrings.olvidasteContrasena), findsOneWidget);

      await tocar(tester, find.text(AppStrings.olvidasteContrasena));
      expect(find.text(AppStrings.recuperarContrasena), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tocar(tester, find.text(AppStrings.volverAIniciarSesion));
      expect(find.text(AppStrings.volverAlInicio), findsOneWidget);
    }

    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(const SamanSportsApp(key: ValueKey('dashboard')));
    await tester.pumpAndSettle();
    await tocar(tester, find.text(AppStrings.iniciarSesion).first);
    expect(find.text(AppStrings.olvidasteContrasena), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
