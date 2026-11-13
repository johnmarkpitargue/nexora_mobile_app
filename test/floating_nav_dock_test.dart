import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/floating_nav_dock.dart';

void main() {
  testWidgets('dock preserves all destinations and reports taps', (
    tester,
  ) async {
    var tappedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        home: Scaffold(
          bottomNavigationBar: FloatingNavDock(
            currentIndex: 0,
            cartCount: 3,
            chatUnreadCount: 7,
            onTap: (index) => tappedIndex = index,
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byKey(const ValueKey('cart-nav-badge')), findsOneWidget);
    expect(find.byKey(const ValueKey('messages-nav-badge')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-item-2')));
    await tester.pump();

    expect(tappedIndex, 2);
  });

  testWidgets('dock hides empty badges and caps large counts', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NexoraTheme.lightTheme,
        home: Scaffold(
          bottomNavigationBar: FloatingNavDock(
            currentIndex: 4,
            cartCount: 0,
            chatUnreadCount: 120,
            onTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('cart-nav-badge')), findsNothing);
    expect(find.byKey(const ValueKey('messages-nav-badge')), findsOneWidget);
    expect(find.text('99+'), findsOneWidget);
  });
}
