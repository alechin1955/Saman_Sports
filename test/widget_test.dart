import 'package:flutter_test/flutter_test.dart';
import 'package:saman_deportivo/main.dart';

void main() {
  testWidgets('Admin App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SamanDeportivoAdminApp());
  });
}