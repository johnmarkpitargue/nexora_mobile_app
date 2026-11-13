import 'package:flutter/material.dart';

import '../../app/theme/nexora_theme.dart';

/// Style variants for [NexoraCard].
enum NexoraCardVariant {
  /// Standard off-white/pure-white card with subtle border outline.
  surface,

  /// Soft primary blue container tint for highlights, notices, or guarantees.
  primaryTint,

  /// Deep navy container for prominent banners or account cards.
  darkNavy,

  /// Transparent background with outline border.
  outlined,
}

/// A standardized card primitive adhering to Nexora's Impeccable Design System.
///
/// Provides consistent padding, border radius, background tokens, touch
/// targets, and optional section headers without nested card clutter.
class NexoraCard extends StatelessWidget {
  const NexoraCard({
    super.key,
    required this.child,
    this.variant = NexoraCardVariant.surface,
    this.padding = const EdgeInsets.all(NexoraSpacing.md),
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.clipBehavior = Clip.antiAlias,
    this.elevation = 0,
    this.shadowColor,
  })  : title = null,
        subtitle = null,
        icon = null,
        trailing = null;

  /// Creates a structured section card with a standardized header.
  const NexoraCard.section({
    super.key,
    required this.child,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.variant = NexoraCardVariant.surface,
    this.padding = const EdgeInsets.all(NexoraSpacing.md),
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.clipBehavior = Clip.antiAlias,
    this.elevation = 0,
    this.shadowColor,
  });

  /// The main content of the card.
  final Widget child;

  /// Optional section title widget or text.
  final Widget? title;

  /// Optional section subtitle widget or text.
  final Widget? subtitle;

  /// Optional leading icon for section header.
  final Widget? icon;

  /// Optional trailing widget for section header.
  final Widget? trailing;

  /// Visual theme variant of the card.
  final NexoraCardVariant variant;

  /// Inner padding around the content. Defaults to [NexoraSpacing.md] (16dp).
  final EdgeInsetsGeometry? padding;

  /// Outer margin around the card.
  final EdgeInsetsGeometry? margin;

  /// Border radius of the card corners. Defaults to [NexoraRadius.card] (14dp).
  final BorderRadius? borderRadius;

  /// Custom border color. When null, resolves from the current [variant] and theme.
  final Color? borderColor;

  /// Custom border width. Defaults to 1.0.
  final double borderWidth;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the card is long pressed.
  final VoidCallback? onLongPress;

  /// Accessibility label describing the card.
  final String? semanticLabel;

  /// Clipping strategy for card children. Defaults to [Clip.antiAlias].
  final Clip clipBehavior;

  /// Elevation shadow depth. Defaults to 0 (flat per Nexora DESIGN.md).
  final double elevation;

  /// Shadow color if elevation > 0.
  final Color? shadowColor;

  Color _resolveBackgroundColor(ThemeData theme) {
    switch (variant) {
      case NexoraCardVariant.surface:
        return theme.colorScheme.surfaceContainerLowest;
      case NexoraCardVariant.primaryTint:
        return theme.colorScheme.primaryContainer;
      case NexoraCardVariant.darkNavy:
        return NexoraTheme.darkNavy;
      case NexoraCardVariant.outlined:
        return Colors.transparent;
    }
  }

  Color _resolveBorderColor(ThemeData theme) {
    if (borderColor != null) return borderColor!;
    switch (variant) {
      case NexoraCardVariant.surface:
        return theme.colorScheme.outlineVariant;
      case NexoraCardVariant.primaryTint:
        return theme.colorScheme.primary.withValues(alpha: 0.18);
      case NexoraCardVariant.darkNavy:
        return Colors.white.withValues(alpha: 0.12);
      case NexoraCardVariant.outlined:
        return theme.colorScheme.outlineVariant;
    }
  }

  Widget _buildSectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = variant == NexoraCardVariant.darkNavy;

    return Padding(
      padding: const EdgeInsets.only(bottom: NexoraSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(
                color: isDark ? Colors.white : theme.colorScheme.primary,
                size: 20,
              ),
              child: icon!,
            ),
            const SizedBox(width: NexoraSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle(
                  style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  child: title!,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: NexoraSpacing.xxs),
                  DefaultTextStyle(
                    style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                    child: subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: NexoraSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedRadius =
        borderRadius ?? BorderRadius.circular(NexoraRadius.card);
    final resolvedBg = _resolveBackgroundColor(theme);
    final resolvedBorder = _resolveBorderColor(theme);

    Widget content = child;
    if (title != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionHeader(context),
          child,
        ],
      );
    }

    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    Widget cardWidget = Material(
      color: resolvedBg,
      elevation: elevation,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: resolvedRadius,
        side: borderWidth > 0
            ? BorderSide(color: resolvedBorder, width: borderWidth)
            : BorderSide.none,
      ),
      clipBehavior: clipBehavior,
      child: onTap != null || onLongPress != null
          ? InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: resolvedRadius,
              child: content,
            )
          : content,
    );

    if (margin != null) {
      cardWidget = Padding(
        padding: margin!,
        child: cardWidget,
      );
    }

    if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      cardWidget = Semantics(
        container: true,
        label: semanticLabel,
        button: onTap != null,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

