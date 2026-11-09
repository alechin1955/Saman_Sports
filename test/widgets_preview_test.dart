import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/core/theme/app_theme.dart';
import 'package:saman_sports/views/widgets/widgets_preview_view.dart';

void main() {
  testWidgets('en escritorio se ve el header y el panel dividido', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const WidgetsPreviewView()),
    );

    expect(find.text(AppStrings.deportes), findsOneWidget);
    expect(find.text(AppStrings.loginTagline), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
  });

  testWidgets('en móvil cambia a menú y oculta el panel izquierdo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const WidgetsPreviewView()),
    );

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.text(AppStrings.deportes), findsNothing);
    expect(find.text(AppStrings.loginTagline), findsNothing);
    expect(find.text(AppStrings.iniciarSesion), findsWidgets);
  });
}
