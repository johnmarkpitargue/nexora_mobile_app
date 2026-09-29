import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/main.dart';

void main() {
  testWidgets('Nexora App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NexoraApp());
    expect(find.byType(NexoraApp), findsOneWidget);
  });
}
