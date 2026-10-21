import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/app.dart';

void main() {
  testWidgets('muestra el placeholder de Home sin Firebase', (tester) async {
    await tester.pumpWidget(const SamanSportsApp());

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Volver al inicio'), findsOneWidget);
  });
}
