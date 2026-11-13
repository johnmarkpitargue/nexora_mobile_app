import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';

void main() {
  test('theme exposes restrained shared component defaults', () {
    final theme = NexoraTheme.lightTheme;
    final filledStyle = theme.filledButtonTheme.style!;
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    final cardRadius = cardShape.borderRadius as BorderRadius;

    expect(theme.colorScheme.primary, NexoraTheme.primary);
    expect(theme.scaffoldBackgroundColor, NexoraTheme.surface);
    expect(
      filledStyle.minimumSize!.resolve(<WidgetState>{}),
      const Size(0, 48),
    );
    expect(cardRadius.topLeft.x, NexoraRadius.card);
    expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(theme.appBarTheme.toolbarHeight, 64);
  });

  test(
    'light and dark themes share roles without flattening their surfaces',
    () {
      final light = NexoraTheme.lightTheme.colorScheme;
      final dark = NexoraTheme.darkTheme.colorScheme;

      expect(light.primary, dark.primary);
      expect(light.surfaceContainerLowest, isNot(light.surface));
      expect(dark.surfaceContainerLowest, isNot(dark.surface));
      expect(light.onSurface, isNot(light.onSurfaceVariant));
      expect(dark.onSurface, isNot(dark.onSurfaceVariant));
      expect(
        NexoraTheme.lightTheme.scaffoldBackgroundColor,
        NexoraTheme.surface,
      );
      expect(
        NexoraTheme.darkTheme.scaffoldBackgroundColor,
        NexoraTheme.darkCanvas,
      );
    },
  );

  testWidgets('motion uses standard timing when animations are enabled', (
    tester,
  ) async {
    late Duration resolvedDuration;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            resolvedDuration = NexoraMotion.resolve(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolvedDuration, NexoraMotion.standard);
  });

  testWidgets('motion becomes instant when platform animations are disabled', (
    tester,
  ) async {
    late Duration resolvedDuration;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  resolvedDuration = NexoraMotion.resolve(
                    context,
                    NexoraMotion.layout,
                  );
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );

    expect(resolvedDuration, Duration.zero);
  });
}
