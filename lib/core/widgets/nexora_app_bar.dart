
import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/nexora_theme.dart';

/// Visual style variants for [NexoraAppBar].
enum NexoraAppBarStyle {
  /// Off-white scaffold surface background (`#F6F8FC`), slate onSurface icons and text.
  surface,

  /// Deep luxury navy background (`#050B28`), pure white icons and text.
  darkNavy,

  /// Card/sheet white background (`#FFFFFF`), slate onSurface icons and text.
  container,

  /// Completely transparent background for overlays and hero headers.
  transparent,
}

/// A standardized app bar primitive adhering to Nexora's Impeccable Design System.
///
/// Features accessible touch targets (48x48dp minimum), consistent typography hierarchy,
/// resilient fallback back navigation, and clean theme variants.
class NexoraAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NexoraAppBar({
    super.key,
    this.title,
    this.titleText,
    this.subtitle,
    this.subtitleText,
    this.leading,
    this.actions,
    this.bottom,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.style = NexoraAppBarStyle.surface,
    this.onBackPressed,
    this.fallbackRoute = AppRoutes.home,
    this.showBottomDivider = false,
    this.elevation = 0,
    this.toolbarHeight = 64.0,
    this.titleSpacing = NexoraSpacing.md,
  }) : assert(
          title == null || titleText == null,
          'Provide either title or titleText, not both.',
        );

  /// Custom title widget. Mutually exclusive with [titleText].
  final Widget? title;

  /// String title for standard text styling.
  final String? titleText;

  /// Custom subtitle widget. Mutually exclusive with [subtitleText].
  final Widget? subtitle;

  /// String subtitle text.
  final String? subtitleText;

  /// Leading widget. When null and [automaticallyImplyLeading] is true,
  /// renders a standardized back button.
  final Widget? leading;

  /// Action widgets aligned to the end of the app bar.
  final List<Widget>? actions;

  /// Optional widget displayed at the bottom of the app bar (e.g. [TabBar]).
  final PreferredSizeWidget? bottom;

  /// Whether to automatically show a back button if leading is null.
  final bool automaticallyImplyLeading;

  /// Whether the title should be centered. Defaults to false per Nexora design.
  final bool centerTitle;

  /// Visual theme style for colors and contrast.
  final NexoraAppBarStyle style;

  /// Custom callback invoked when back button is tapped.
  final VoidCallback? onBackPressed;

  /// Route to navigate to if back is pressed when the navigator stack cannot pop.
  final String fallbackRoute;

  /// Whether to show a subtle 1px hairline border at the bottom.
  final bool showBottomDivider;

  /// Elevation shadow depth. Defaults to 0 (flat).
  final double elevation;

  /// Height of the toolbar. Defaults to 64.0 to match Nexora standard rhythm.
  final double toolbarHeight;

  /// Horizontal spacing around the title. Defaults to [NexoraSpacing.md] (16dp).
  final double titleSpacing;

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  Color _resolveBackgroundColor(ThemeData theme) {
    switch (style) {
      case NexoraAppBarStyle.surface:
        return theme.scaffoldBackgroundColor;
      case NexoraAppBarStyle.darkNavy:
        return NexoraTheme.darkNavy;
      case NexoraAppBarStyle.container:
        return theme.colorScheme.surfaceContainerLowest;
      case NexoraAppBarStyle.transparent:
        return Colors.transparent;
    }
  }

  Color _resolveForegroundColor(ThemeData theme) {
    switch (style) {
      case NexoraAppBarStyle.surface:
      case NexoraAppBarStyle.container:
        return theme.colorScheme.onSurface;
      case NexoraAppBarStyle.darkNavy:
        return Colors.white;
      case NexoraAppBarStyle.transparent:
        return theme.colorScheme.onSurface;
    }
  }

  void _handleBack(BuildContext context) {
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, fallbackRoute);
    }
  }

  Widget? _buildLeading(BuildContext context, Color foreground) {
    if (leading != null) return leading;

    if (!automaticallyImplyLeading) return null;

    final modalRoute = ModalRoute.of(context);
    final canPop = Navigator.canPop(context) || (modalRoute?.canPop ?? false);

    // If on the root route and cannot pop, omit the back button
    final isHomeRoot = modalRoute?.settings.name == AppRoutes.home ||
        modalRoute?.settings.name == AppRoutes.splash ||
        (modalRoute?.isFirst ?? false);
    if (!canPop && isHomeRoot) return null;
    if (!canPop && fallbackRoute.isEmpty) return null;

    return Semantics(
      button: true,
      label: 'Back',
      child: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_rounded),
        color: foreground,
        style: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(48, 48)),
        ),
        onPressed: () => _handleBack(context),
      ),
    );
  }

  Widget? _buildTitle(BuildContext context, Color foreground) {
    if (title != null) return title;

    if (titleText == null && subtitleText == null && subtitle == null) {
      return null;
    }

    final theme = Theme.of(context);
    final isDark = style == NexoraAppBarStyle.darkNavy;

    final titleWidget = Text(
      titleText ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (theme.appBarTheme.titleTextStyle ??
              theme.textTheme.titleMedium ??
              const TextStyle())
          .copyWith(
        color: foreground,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
    );

    if (subtitleText == null && subtitle == null) {
      return titleWidget;
    }

    final resolvedSubtitle = subtitle ??
        Text(
          subtitleText!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? const Color(0xFFCBD5E1)
                : theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );

    return Column(
      crossAxisAlignment:
          centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        titleWidget,
        const SizedBox(height: 2),
        resolvedSubtitle,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = _resolveBackgroundColor(theme);
    final fg = _resolveForegroundColor(theme);

    final resolvedLeading = _buildLeading(context, fg);
    final resolvedTitle = _buildTitle(context, fg);

    final bar = AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: bg,
      foregroundColor: fg,
      surfaceTintColor: Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: elevation,
      toolbarHeight: toolbarHeight,
      titleSpacing: titleSpacing,
      centerTitle: centerTitle,
      leading: resolvedLeading,
      title: resolvedTitle,
      actions: [
        ...?actions,
        const SizedBox(width: NexoraSpacing.xs),
      ],
      bottom: bottom,
      shape: showBottomDivider
          ? Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 1.0,
              ),
            )
          : null,
    );

    return bar;
  }
}

