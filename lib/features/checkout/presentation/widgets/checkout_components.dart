import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/widgets/nexora_widgets.dart';

class CheckoutSection extends StatelessWidget {
  const CheckoutSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    this.subtitle,
    this.padding = const EdgeInsets.all(NexoraSpacing.md),
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return NexoraCard.section(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      icon: icon != null ? Icon(icon) : null,
      trailing: trailing,
      padding: padding,
      child: child,
    );
  }
}

class CheckoutActionRow extends StatelessWidget {
  const CheckoutActionRow({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String? value;
  final IconData? icon;
  final Color? valueColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: value == null ? label : '$label, $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NexoraRadius.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: NexoraSpacing.sm),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: NexoraSpacing.sm),
                ],
                Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
                if (value != null) ...[
                  const SizedBox(width: NexoraSpacing.sm),
                  Flexible(
                    child: Text(
                      value!,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: valueColor ?? theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: NexoraSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CheckoutPriceRow extends StatelessWidget {
  const CheckoutPriceRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = emphasized
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodySmall?.copyWith(fontSize: 13);
    final valueStyle = emphasized
        ? theme.textTheme.titleMedium?.copyWith(
            color: valueColor ?? theme.colorScheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          )
        : theme.textTheme.bodyMedium?.copyWith(
            color: valueColor ?? theme.colorScheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NexoraSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: NexoraSpacing.md),
          Text(value, textAlign: TextAlign.end, style: valueStyle),
        ],
      ),
    );
  }
}
