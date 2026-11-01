import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/core/widgets/google_logo_icon.dart';

void main() {
  group('Official GoogleLogoIcon Widget Tests', () {
    testWidgets('Renders GoogleLogoIcon at default 20x20 size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GoogleLogoIcon(),
            ),
          ),
        ),
      );

      final finder = find.byType(GoogleLogoIcon);
      expect(finder, findsOneWidget);

      final size = tester.getSize(finder);
      expect(size.width, equals(20.0));
      expect(size.height, equals(20.0));
    });

    testWidgets('Renders GoogleLogoIcon at custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GoogleLogoIcon(size: 48),
            ),
          ),
        ),
      );

      final finder = find.byType(GoogleLogoIcon);
      expect(finder, findsOneWidget);

      final size = tester.getSize(finder);
      expect(size.width, equals(48.0));
      expect(size.height, equals(48.0));
    });
  });
}
