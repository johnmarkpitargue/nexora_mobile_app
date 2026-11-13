import 'package:flutter/material.dart';

import '../../../../app/theme/nexora_theme.dart';

class AccountSection extends StatelessWidget {
  const AccountSection({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.trailing,
  });

  final String title;
  final String? description;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ?trailing,
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: NexoraSpacing.xxs),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ],
        const SizedBox(height: NexoraSpacing.sm),
        child,
      ],
    );
  }
}

class AccountPanel extends StatelessWidget {
  const AccountPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(NexoraSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NexoraRadius.card),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

class AccountInfoBanner extends StatelessWidget {
  const AccountInfoBanner({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.tone = AccountInfoTone.info,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final AccountInfoTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _colors(theme.colorScheme);

    return Semantics(
      container: true,
      label: '$title. $message',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(NexoraRadius.card),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(NexoraSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.foreground, size: 21),
              const SizedBox(width: NexoraSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: NexoraSpacing.xxs),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.foreground.withValues(alpha: 0.82),
                        height: 1.45,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: NexoraSpacing.sm),
                      action!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _InfoColors _colors(ColorScheme scheme) {
    return switch (tone) {
      AccountInfoTone.success => const _InfoColors(
        background: Color(0xFFF0FDF4),
        border: Color(0xFFBBF7D0),
        foreground: Color(0xFF166534),
      ),
      AccountInfoTone.warning => const _InfoColors(
        background: Color(0xFFFFFBEB),
        border: Color(0xFFFDE68A),
        foreground: Color(0xFF92400E),
      ),
      AccountInfoTone.error => _InfoColors(
        background: scheme.errorContainer,
        border: scheme.error.withValues(alpha: 0.24),
        foreground: scheme.onErrorContainer,
      ),
      AccountInfoTone.info => const _InfoColors(
        background: Color(0xFFEFF6FF),
        border: Color(0xFFBFDBFE),
        foreground: Color(0xFF1E3A8A),
      ),
    };
  }
}

enum AccountInfoTone { info, success, warning, error }

class AccountEmptyState extends StatelessWidget {
  const AccountEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NexoraSpacing.lg,
        vertical: NexoraSpacing.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 38, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: NexoraSpacing.md),
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
              if (action != null) ...[
                const SizedBox(height: NexoraSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AccountBottomActionBar extends StatelessWidget {
  const AccountBottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(NexoraSpacing.md),
        child: child,
      ),
    );
  }
}

class _InfoColors {
  const _InfoColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
