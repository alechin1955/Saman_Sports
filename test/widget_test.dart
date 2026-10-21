import 'package:flutter_test/flutter_test.dart';
import 'package:saman_sports/app.dart';
import 'package:saman_sports/core/constants/app_strings.dart';

void main() {
  testWidgets('abre la portada sin Firebase', (tester) async {
    await tester.pumpWidget(const SamanSportsApp());

    expect(find.text(AppStrings.homeTitulo), findsOneWidget);
    expect(find.text(AppStrings.explorarDeportes), findsOneWidget);
  });
}
