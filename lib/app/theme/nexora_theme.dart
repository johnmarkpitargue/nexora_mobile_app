import 'package:flutter/material.dart';

/// Design tokens and Material 3 theme configuration for Nexora
class NexoraTheme {
  // Brand Colors from Redesigned Screenshot (Electric Blue, Cyan & Dark Navy)
  static const Color primary = Color(0xFF0066FF);
  static const Color primaryContainer = Color(0xFFEAF1FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF124EBB);

  /// Unified price color for product cards, lists, cart, and orders.
  static const Color price = Color(0xFF0F172A);

  static Color priceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF38BDF8)
      : price;

  static const Color secondary = Color(0xFF00D2FF);
  static const Color secondaryContainer = Color(0xFFE7F9FC);
  static const Color onSecondaryContainer = Color(0xFF087C94);

  static const Color darkNavy = Color(0xFF050B28);

  static const Color tertiary = Color(0xFFE11D48);
  static const Color tertiaryContainer = Color(0xFFFFE4E6);
  static const Color onTertiaryContainer = Color(0xFFBE123C);

  static const Color surface = Color(0xFFF5F7FA);
  static const Color surfaceDim = Color(0xFFE2E7EF);
  static const Color surfaceBright = Color(0xFFF9FAFC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8F9FB);
  static const Color surfaceContainer = Color(0xFFEDF1F6);
  static const Color surfaceContainerHigh = Color(0xFFE2E7EF);
  static const Color surfaceContainerHighest = Color(0xFFD5DCE8);

  static const Color onSurface = Color(0xFF0F172A);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color outline = Color(0xFFC7D0DE);
  static const Color outlineVariant = Color(0xFFDCE2EA);
  static const Color error = Color(0xFFE11D48);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Dark theme stays neutral and ink-like so brand blue keeps its meaning.
  static const Color darkCanvas = Color(0xFF060914);
  static const Color darkSurfaceLowest = Color(0xFF0D1323);
  static const Color darkSurfaceLow = Color(0xFF11192B);
  static const Color darkSurfaceContainer = Color(0xFF172136);
  static const Color darkSurfaceHigh = Color(0xFF202C43);
  static const Color darkSurfaceHighest = Color(0xFF2A3852);

  static const Color darkOnSurface = Color(0xFFF8FAFC);
  static const Color darkOnSurfaceVariant = Color(0xFFAAB4C8);
  static const Color darkOutline = Color(0xFF46536B);
  static const Color darkOutlineVariant = Color(0xFF28344A);

  /// Global reactive theme mode notifier defaulted to Dark Mode for the aesthetic request.
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  /// Snappy, smooth animation parameters for seamless theme transitions without lag or frame drops.
  static const Duration themeAnimationDuration = Duration(milliseconds: 200);
  static const Curve themeAnimationCurve = Curves.easeOut;

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static void toggleTheme() {
    themeModeNotifier.value = themeModeNotifier.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  static const String fontFamily = 'Plus Jakarta Sans';
  static const List<String> fontFamilyFallback = [
    'Segoe UI',
    'Roboto',
    'Noto Sans',
    'Arial',
    'sans-serif',
    'Segoe UI Emoji',
    'Apple Color Emoji',
    'Noto Color Emoji',
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: Colors.white,
        errorContainer: errorContainer,
        onErrorContainer: Color(0xFF93000A),
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ).apply(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        iconTheme: IconThemeData(color: onSurface, size: 24),
        actionsIconTheme: IconThemeData(color: onSurface, size: 22),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.card),
          side: const BorderSide(color: outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          animationDuration: NexoraMotion.standard,
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: NexoraSpacing.lg),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NexoraRadius.control),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: NexoraMotion.standard,
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: NexoraSpacing.lg),
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: outline)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NexoraRadius.control),
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          animationDuration: NexoraMotion.fast,
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NexoraRadius.control),
            ),
          ),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NexoraSpacing.md,
          vertical: NexoraSpacing.md,
        ),
        hintStyle: const TextStyle(
          color: onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.control),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.control),
          borderSide: const BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.control),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.control),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.control),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLowest,
        selectedColor: primaryContainer,
        checkmarkColor: primary,
        disabledColor: surfaceContainer,
        side: const BorderSide(color: outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.control),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: NexoraSpacing.sm,
          vertical: NexoraSpacing.xs,
        ),
        labelStyle: const TextStyle(
          color: onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkNavy,
        actionTextColor: secondary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        insetPadding: const EdgeInsets.all(NexoraSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.card),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: outline,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(NexoraRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.dialog),
        ),
        titleTextStyle: const TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: onSurfaceVariant,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primaryContainer,
        circularTrackColor: primaryContainer,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primaryContainer,
        selectionHandleColor: primary,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      scaffoldBackgroundColor: darkCanvas,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF102A52),
        onPrimaryContainer: Color(0xFFA7C7FF),
        secondary: secondary,
        onSecondary: darkCanvas,
        secondaryContainer: Color(0xFF0B303A),
        onSecondaryContainer: Color(0xFF7BDFF1),
        tertiary: tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFF4C0519),
        onTertiaryContainer: Color(0xFFFECDD3),
        error: error,
        onError: Colors.white,
        errorContainer: Color(0xFF7F1D1D),
        onErrorContainer: Color(0xFFFCA5A5),
        surface: darkCanvas,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurfaceVariant,
        outline: darkOutline,
        outlineVariant: darkOutlineVariant,
        surfaceContainerLowest: darkSurfaceLowest,
        surfaceContainerLow: darkSurfaceLow,
        surfaceContainer: darkSurfaceContainer,
        surfaceContainerHigh: darkSurfaceHigh,
        surfaceContainerHighest: darkSurfaceHighest,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: darkOnSurface,
        ),
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: darkOnSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkOnSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkOnSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
        ),
      ).apply(fontFamily: fontFamily, fontFamilyFallback: fontFamilyFallback),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCanvas,
        foregroundColor: darkOnSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        iconTheme: IconThemeData(color: darkOnSurface, size: 24),
        actionsIconTheme: IconThemeData(color: darkOnSurface, size: 22),
        titleTextStyle: TextStyle(
          color: darkOnSurface,
          fontSize: 18,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.card),
          side: const BorderSide(color: darkOutlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          animationDuration: NexoraMotion.standard,
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: NexoraSpacing.lg),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NexoraRadius.control),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: NexoraMotion.standard,
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: NexoraSpacing.lg),
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: darkOutline)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NexoraRadius.control),
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          animationDuration: NexoraMotion.fast,
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NexoraRadius.control),
            ),
          ),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(48, 48))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NexoraSpacing.md,
          vertical: NexoraSpacing.md,
        ),
        hintStyle: const TextStyle(
          color: darkOnSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: darkOnSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.control),
          borderSide: const BorderSide(color: darkOutlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.control),
          borderSide: const BorderSide(color: darkOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.control),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.control),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.control),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceLowest,
        selectedColor: darkSurfaceHighest,
        checkmarkColor: primary,
        disabledColor: darkSurfaceContainer,
        side: const BorderSide(color: darkOutlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.control),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: NexoraSpacing.sm,
          vertical: NexoraSpacing.xs,
        ),
        labelStyle: const TextStyle(
          color: darkOnSurface,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Color(0xFFA7C7FF),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkOutlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkSurfaceHigh,
        actionTextColor: secondary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        insetPadding: const EdgeInsets.all(NexoraSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.card),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurfaceLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: darkOutline,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(NexoraRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NexoraRadius.dialog),
        ),
        titleTextStyle: const TextStyle(
          color: darkOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: darkOnSurfaceVariant,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: Color(0xFF102A52),
        circularTrackColor: Color(0xFF102A52),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: Color(0xFF102A52),
        selectionHandleColor: primary,
      ),
    );
  }
}

/// Shared spacing rhythm for all Nexora buyer surfaces.
abstract final class NexoraSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

/// Semantic shapes. Cards stay restrained; pills are reserved for compact controls.
abstract final class NexoraRadius {
  static const double small = 10;
  static const double control = 12;
  static const double card = 14;
  static const double large = 16;
  static const double dialog = 20;
  static const double sheet = 24;
  static const double full = 999;
}

/// Motion tokens for fast, purposeful state and continuity feedback.
abstract final class NexoraMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration layout = Duration(milliseconds: 300);
  static const Duration emphasized = Duration(milliseconds: 420);
  static const Duration exit = Duration(milliseconds: 140);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Cubic(0.16, 1, 0.3, 1);

  /// Resolves to an instant transition when the platform disables animations.
  static Duration resolve(
    BuildContext context, [
    Duration duration = standard,
  ]) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false
        ? Duration.zero
        : duration;
  }
}

/// Responsive width thresholds used by shared navigation and grid shells.
abstract final class NexoraBreakpoints {
  static const double compact = 600;
  static const double expanded = 840;
}
