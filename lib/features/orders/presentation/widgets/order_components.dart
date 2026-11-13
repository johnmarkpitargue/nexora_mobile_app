import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({
    super.key,
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _statusColors(theme, label);
    return Semantics(
      label: 'Order status: $label',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? NexoraSpacing.xs : NexoraSpacing.sm,
          vertical: compact ? NexoraSpacing.xxs : 6,
        ),
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(NexoraRadius.full),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.$2,
            fontSize: compact ? 10 : 11,
          ),
        ),
      ),
    );
  }

  static (Color, Color) _statusColors(ThemeData theme, String status) {
    final isDark = theme.brightness == Brightness.dark;
    final value = status.toLowerCase();
    if (value.contains('cancel') || value.contains('refund')) {
      return (theme.colorScheme.errorContainer, theme.colorScheme.error);
    }
    if (value.contains('complete') || value.contains('deliver')) {
      return isDark
          ? (const Color(0xFF064E3B), const Color(0xFF34D399))
          : (const Color(0xFFDCFCE7), const Color(0xFF166534));
    }
    if (value.contains('pay') || value.contains('pending')) {
      return isDark
          ? (const Color(0xFF78350F), const Color(0xFFFBBF24))
          : (const Color(0xFFFEF3C7), const Color(0xFF92400E));
    }
    if (value.contains('receive') || value.contains('transit')) {
      return isDark
          ? (const Color(0xFF164E63), const Color(0xFF22D3EE))
          : (NexoraTheme.secondaryContainer, const Color(0xFF0E7490));
    }
    return (
      theme.colorScheme.primaryContainer,
      isDark ? const Color(0xFF38BDF8) : theme.colorScheme.primary,
    );
  }
}

class OrderProgressLine extends StatelessWidget {
  const OrderProgressLine({
    super.key,
    required this.progress,
    required this.label,
  });

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = progress.clamp(0.0, 1.0);
    return Semantics(
      label: '$label, ${(value * 100).round()} percent complete',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(NexoraRadius.full),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: value,
              backgroundColor: theme.colorScheme.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: NexoraSpacing.xs),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class OrderEmptyState extends StatelessWidget {
  const OrderEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(NexoraSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 32),
              ),
              const SizedBox(height: NexoraSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: NexoraSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: NexoraSpacing.xl),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
