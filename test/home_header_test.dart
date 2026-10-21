import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/app.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_colors.dart';

void main() {
  testWidgets('el Home muestra secciones y botones naranjas', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    await tester.pumpWidget(const SamanSportsApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(AppStrings.queEsTitulo), findsOneWidget);
    expect(find.text(AppStrings.deportesDisponibles), findsOneWidget);
    expect(find.text(AppStrings.datosEjemplo), findsWidgets);

    for (final texto in [AppStrings.iniciarSesion, AppStrings.registrarse]) {
      final boton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, texto),
      );
      expect(
        boton.style?.backgroundColor?.resolve({}),
        AppColors.primary,
      );
      expect(
        boton.style?.foregroundColor?.resolve({}),
        AppColors.surface,
      );
    }

    for (final tamano in [const Size(360, 800), const Size(768, 1024), const Size(1440, 900)]) {
      await tester.binding.setSurfaceSize(tamano);
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });
}
