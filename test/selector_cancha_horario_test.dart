import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/core/constants/app_strings.dart';
import 'package:saman_sports/models/cancha.dart';
import 'package:saman_sports/models/reserva_horario.dart';
import 'package:saman_sports/views/admin/widgets/selector_cancha_horario.dart';

void main() {
  testWidgets('muestra choque y permite el borde que se toca', (tester) async {
    List<FranjaHorario> franjas = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SelectorCanchaHorario(
                canchas: const [
                  Cancha(
                    id: 'c1',
                    nombre: 'Cancha 1',
                    ubicacion: 'Campus',
                    descripcion: '',
                    activa: true,
                    version: 0,
                  ),
                ],
                canchaId: 'c1',
                franjas: franjas,
                reservasCancha: const [
                  ReservaHorario(
                    id: 'r1',
                    canchaId: 'c1',
                    canchaNombre: 'Cancha 1',
                    dia: 3,
                    horaInicio: 960,
                    horaFin: 1080,
                    tipo: TipoReserva.deporte,
                    refId: 'futbol',
                    refNombre: 'Fútbol',
                    activa: true,
                  ),
                ],
                onCanchaChanged: (_) {},
                onFranjasChanged: (valor) => setState(() => franjas = valor),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mié'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('hora-inicio')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('17:00').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hora-fin')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('19:00').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('ocupada'), findsOneWidget);

    await tester.tap(find.byKey(const Key('hora-inicio')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('18:00').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.adminAgregarHorario));
    await tester.pump();
    expect(find.textContaining('ocupada'), findsNothing);
  });
}
