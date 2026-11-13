import 'package:flutter/material.dart';

import '../../../../app/theme/nexora_theme.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.icon,
    required this.backgroundColor,
    this.imageUrl,
    this.isOnline = false,
    this.isVerified = false,
    this.size = 44,
  });

  final IconData icon;
  final Color backgroundColor;
  final String? imageUrl;
  final bool isOnline;
  final bool isVerified;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl?.trim();
    return Semantics(
      image: true,
      label: [
        if (isVerified) 'Verified',
        if (isOnline) 'Online',
        'conversation avatar',
      ].join(', '),
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CircleAvatar(
                backgroundColor: backgroundColor,
                foregroundImage: image != null && image.isNotEmpty
                    ? NetworkImage(image)
                    : null,
                child: Icon(icon, color: Colors.white, size: size * 0.48),
              ),
            ),
            if (isOnline || isVerified)
              PositionedDirectional(
                end: -1,
                bottom: -1,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFF16A34A)
                        : NexoraTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerLowest,
                      width: 2,
                    ),
                  ),
                  child: isVerified
                      ? Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: size * 0.18,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MessageStatusBadge extends StatelessWidget {
  const MessageStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
  });

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NexoraSpacing.sm,
          vertical: NexoraSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: resolvedColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(NexoraRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: resolvedColor),
              const SizedBox(width: NexoraSpacing.xxs),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: resolvedColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $message',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NexoraSpacing.xl,
          vertical: NexoraSpacing.xxl,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 42,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: NexoraSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: NexoraSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: NexoraSpacing.lg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
