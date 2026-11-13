import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/widgets/nexora_widgets.dart';

void main() {
  group('NexoraCard Primitive', () {
    testWidgets('renders child and default theme styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: NexoraTheme.lightTheme,
          home: const Scaffold(
            body: NexoraCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Material), findsWidgets);
    });

    testWidgets('supports section constructor with title, subtitle and icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: NexoraTheme.lightTheme,
          home: const Scaffold(
            body: NexoraCard.section(
              title: Text('Delivery Info'),
              subtitle: Text('Standard courier'),
              icon: Icon(Icons.local_shipping_outlined),
              trailing: Icon(Icons.chevron_right_rounded),
              child: Text('Arriving tomorrow'),
            ),
          ),
        ),
      );

      expect(find.text('Delivery Info'), findsOneWidget);
      expect(find.text('Standard courier'), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.text('Arriving tomorrow'), findsOneWidget);
    });

    testWidgets('handles onTap callbacks with InkWell feedback', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: NexoraTheme.lightTheme,
          home: Scaffold(
            body: NexoraCard(
              onTap: () => tapped = true,
              semanticLabel: 'Tappable product card',
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('supports darkNavy and primaryTint variants', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: NexoraTheme.lightTheme,
          home: const Scaffold(
            body: Column(
              children: [
                NexoraCard(
                  variant: NexoraCardVariant.darkNavy,
                  child: Text('Dark Navy Banner'),
                ),
                NexoraCard(
                  variant: NexoraCardVariant.primaryTint,
                  child: Text('Voucher Guarantee'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Dark Navy Banner'), findsOneWidget);
      expect(find.text('Voucher Guarantee'), findsOneWidget);
    });
  });

  group('NexoraAppBar Primitive', () {
    testWidgets('renders titleText and auto back button with 48x48 touch target', (
      tester,
    ) async {
      var backTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: NexoraTheme.lightTheme,
          home: Scaffold(
            appBar: NexoraAppBar(
              titleText: 'Order History',
              onBackPressed: () => backTapped = true,
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Order History'), findsOneWidget);
      final backButton = find.byTooltip('Back');
      expect(backButton, findsOneWidget);

      final size = tester.getSize(backButton);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      await tester.tap(backButton);
      await tester.pump();
      expect(backTapped, isTrue);
    });

    testWidgets('supports darkNavy style with white foreground', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: NexoraTheme.lightTheme,
          home: const Scaffold(
            appBar: NexoraAppBar(
              titleText: 'Nexora Official Store',
              subtitleText: 'Verified Mall Partner',
              style: NexoraAppBarStyle.darkNavy,
            ),
            body: SizedBox(),
          ),
        ),
      );

      expect(find.text('Nexora Official Store'), findsOneWidget);
      expect(find.text('Verified Mall Partner'), findsOneWidget);
    });

    testWidgets('renders actions and optional bottom divider', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: NexoraTheme.lightTheme,
          home: Scaffold(
            appBar: NexoraAppBar(
              titleText: 'Wishlist',
              showBottomDivider: true,
              actions: [
                IconButton(
                  tooltip: 'Cart',
                  icon: const Icon(Icons.shopping_bag_outlined),
                  onPressed: () {},
                ),
              ],
            ),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.byTooltip('Cart'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });
  });
}

