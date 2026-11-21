import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/views/admin/widgets/tabla_desplazable.dart';

void main() {
  testWidgets('muestra la barra y desplaza la última columna', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TablaDesplazable(
            child: SizedBox(
              width: 1600,
              child: Text('ultima-columna'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final barra = tester.widget<Scrollbar>(find.byType(Scrollbar));
    expect(barra.thumbVisibility, isTrue);
    expect(barra.trackVisibility, isTrue);

    final estado = tester.state<ScrollableState>(find.byType(Scrollable));
    estado.position.jumpTo(400);
    await tester.pump();

    expect(estado.position.pixels, 400);
    expect(find.text('ultima-columna'), findsOneWidget);
  });
}
