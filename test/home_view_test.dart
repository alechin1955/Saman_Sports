import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/app.dart';
import 'package:saman_sports/core/constants/app_strings.dart';

void main() {
  testWidgets('la portada no se desborda y navega', (tester) async {
    const tamanos = [Size(1440, 900), Size(390, 844), Size(768, 1024)];

    for (final tamano in tamanos) {
      await tester.binding.setSurfaceSize(tamano);
      await tester.pumpWidget(const SamanSportsApp());
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const SamanSportsApp());
    expect(find.byIcon(Icons.menu), findsOneWidget);

    await tester.tap(find.text(AppStrings.registrarme));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.crearCuenta), findsWidgets);

    await tester.binding.setSurfaceSize(null);
  });
}
