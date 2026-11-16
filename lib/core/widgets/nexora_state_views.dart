import 'package:flutter/material.dart';
import '../../app/theme/nexora_theme.dart';

/// Shared empty state panel with clear messaging and optional primary action.
class NexoraEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NexoraEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: NexoraTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 32, color: NexoraTheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: NexoraTheme.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(NexoraRadius.control),
                      ),
                    ),
                    child: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared error panel with actionable Retry button.
class NexoraErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const NexoraErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(NexoraRadius.card),
              border: Border.all(color: NexoraTheme.error.withValues(alpha: 0.25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 36, color: NexoraTheme.error),
                const SizedBox(height: 12),
                Text(
                  'Unable to load content',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try Again'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared subtle loading skeleton list for consistent loading state.
class NexoraLoadingSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const NexoraLoadingSkeleton({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 96,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => Container(
        height: itemHeight,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(NexoraRadius.card),
          border: Border.all(color: scheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Consistent status badge pill using Nexora semantic colors.
class NexoraStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const NexoraStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(NexoraRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Consistent section header row with optional action link.
class NexoraSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NexoraSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: NexoraTheme.accent,
              minimumSize: const Size(48, 40),
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
