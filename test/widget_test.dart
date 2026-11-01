import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/main.dart';

void main() {
  testWidgets('Nexora Rider App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NexoraRiderApp());
    expect(find.text('NEXORA RIDER'), findsOneWidget);
  });
}
