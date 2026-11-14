import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/features/auth/presentation/landing_page.dart';

void main() {
  Widget buildApp(Widget home, {bool disableAnimations = true, TextScaler textScaler = TextScaler.noScaling}) {
    return MaterialApp(
      theme: NexoraTheme.lightTheme,
      routes: {
        AppRoutes.login: (_) => const Scaffold(body: Text('Login destination')),
        AppRoutes.register: (_) => const Scaffold(body: Text('Register destination')),
        AppRoutes.home: (_) => const Scaffold(body: Text('Home destination')),
      },
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: textScaler,
              disableAnimations: disableAnimations,
            ),
            child: home,
          );
        },
      ),
    );
  }

  testWidgets('landing stays usable at compact width and 200 percent text', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 900));

    await tester.pumpWidget(
      buildApp(
        const LandingPage(),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Good finds, without the noise.'), findsOneWidget);
    expect(find.text('Studio Pro headphones'), findsOneWidget);
    expect(find.text('Explore the shop'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('landing carousel communicates position and supports swiping', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await tester.pumpWidget(
      buildApp(const LandingPage(), disableAnimations: true),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Featured product 1 of 3'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('landing-product-stories')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Featured product 2 of 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('landing actions open their real destinations', (tester) async {
    await tester.pumpWidget(
      buildApp(const LandingPage(), disableAnimations: true),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('landing-sign-in-action')));
    await tester.pumpAndSettle();
    expect(find.text('Login destination'), findsOneWidget);

    Navigator.of(tester.element(find.text('Login destination'))).pop();
    await tester.pumpAndSettle();

    final registerAction = find.byKey(const ValueKey('landing-register-action'));
    await tester.ensureVisible(registerAction);
    await tester.pumpAndSettle();
    await tester.tap(registerAction);
    await tester.pumpAndSettle();
    expect(find.text('Register destination'), findsOneWidget);

    Navigator.of(tester.element(find.text('Register destination'))).pop();
    await tester.pumpAndSettle();

    final exploreAction = find.byKey(const ValueKey('landing-explore-action'));
    await tester.ensureVisible(exploreAction);
    await tester.pumpAndSettle();
    await tester.tap(exploreAction);
    await tester.pumpAndSettle();
    expect(find.text('Home destination'), findsOneWidget);
  });
}
