import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/evento_publico.dart';
import 'package:saman_sports/views/home/widgets/proximos_eventos_section.dart';

void main() {
  testWidgets('sección vacía', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProximosEventosSection(eventos: []))),
    );
    expect(find.text(AppStrings.sinProximosEventos), findsOneWidget);
  });

  for (final ancho in [390.0, 1440.0]) {
    testWidgets('lista un evento en $ancho px', (tester) async {
      await tester.binding.setSurfaceSize(Size(ancho, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProximosEventosSection(
              eventos: [
                EventoPublico(
                  id: 'ev',
                  titulo: 'Torneo',
                  tipo: 'evento',
                  deporteId: 'futbol',
                  deporteNombre: 'Fútbol',
                  canchaNombre: 'Cancha A',
                  fecha: '2026-12-01',
                  horaInicio: 480,
                  horaFin: 540,
                  descripcion: '',
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Torneo'), findsOneWidget);
      expect(find.text('Fútbol'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    });
  }
}
