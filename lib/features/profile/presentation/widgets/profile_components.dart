import 'package:flutter/material.dart';

import '../../../../app/theme/nexora_theme.dart';

class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.avatarImage,
    this.onAvatarTap,
    this.isGuest = false,
  });

  final String name;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final ImageProvider<Object>? avatarImage;
  final VoidCallback? onAvatarTap;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? Color.alphaBlend(
            NexoraTheme.primary.withValues(alpha: 0.10),
            NexoraTheme.darkNavy,
          )
        : theme.colorScheme.surfaceContainerLowest;
    final foreground = isDark ? Colors.white : theme.colorScheme.onSurface;
    final secondary = isDark
        ? const Color(0xFFCBD5E1)
        : theme.colorScheme.onSurfaceVariant;

    Widget avatar() => Semantics(
      button: onAvatarTap != null,
      label: onAvatarTap != null ? 'Change profile photo' : 'Profile photo',
      child: InkWell(
        onTap: onAvatarTap,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: 28,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : (isGuest
                  ? theme.colorScheme.primaryContainer
                  : const Color(0xFFE2E8F0)),
          foregroundImage: avatarImage,
          onForegroundImageError: avatarImage == null ? null : (_, _) {},
          child: Icon(
            isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
            size: 28,
            color: isDark
                ? Colors.white
                : (isGuest
                    ? theme.colorScheme.primary
                    : const Color(0xFF64748B)),
          ),
        ),
      ),
    );

    Widget copy() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
        ),
        const SizedBox(height: NexoraSpacing.xxs),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: secondary,
                fontSize: 13,
                height: 1.35,
              ),
        ),
      ],
    );

    Widget action() => isGuest
        ? FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NexoraRadius.control),
              ),
            ),
            child: Text(actionLabel),
          )
        : OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              foregroundColor: isDark ? Colors.white : theme.colorScheme.onSurface,
              side: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.35)
                    : theme.colorScheme.outlineVariant,
                width: 1,
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NexoraRadius.control),
              ),
            ),
            child: Text(actionLabel),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        return Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NexoraRadius.large),
            side: BorderSide(
              color: isDark
                  ? NexoraTheme.primary.withValues(alpha: 0.32)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(NexoraSpacing.lg),
            child: stack
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(alignment: Alignment.centerLeft, child: avatar()),
                      const SizedBox(height: NexoraSpacing.md),
                      copy(),
                      const SizedBox(height: NexoraSpacing.md),
                      Align(alignment: Alignment.centerLeft, child: action()),
                    ],
                  )
                : Row(
                    children: [
                      avatar(),
                      const SizedBox(width: NexoraSpacing.md),
                      Expanded(child: copy()),
                      const SizedBox(width: NexoraSpacing.sm),
                      action(),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class ProfileMetricData {
  const ProfileMetricData({
    required this.value,
    required this.label,
    required this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback onTap;
}

class ProfileMetricsPanel extends StatelessWidget {
  const ProfileMetricsPanel({super.key, required this.items});

  final List<ProfileMetricData> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final columns = compact ? 2 : items.length;
        final rows = (items.length / columns).ceil();
        final itemWidth = constraints.maxWidth / columns;

        return Material(
          color: theme.colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NexoraRadius.card),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Wrap(
            children: [
              for (var index = 0; index < items.length; index++)
                SizedBox(
                  width: itemWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: index % columns == columns - 1
                            ? BorderSide.none
                            : BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                        bottom: index ~/ columns == rows - 1
                            ? BorderSide.none
                            : BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                      ),
                    ),
                    child: InkWell(
                      onTap: items[index].onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NexoraSpacing.xs,
                          vertical: NexoraSpacing.md,
                        ),
                        child: Column(
                          children: [
                            Text(
                              items[index].value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(height: NexoraSpacing.xxs),
                            Text(
                              items[index].label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileShortcutData {
  const ProfileShortcutData({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class ProfileShortcutGrid extends StatelessWidget {
  const ProfileShortcutGrid({super.key, required this.items});

  final List<ProfileShortcutData> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final compact = constraints.maxWidth < 340 || largeText;

        return Material(
          color: theme.colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NexoraRadius.card),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: compact
              ? Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _PurchaseShortcut(item: items[index], horizontal: true),
                      if (index != items.length - 1)
                        Divider(
                          height: 1,
                          indent: 60,
                          color: theme.colorScheme.outlineVariant,
                        ),
                    ],
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NexoraSpacing.xs,
                    vertical: NexoraSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        Expanded(child: _PurchaseShortcut(item: items[index])),
                        if (index != items.length - 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 13),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _PurchaseShortcut extends StatelessWidget {
  const _PurchaseShortcut({required this.item, this.horizontal = false});

  final ProfileShortcutData item;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(item.icon, color: theme.colorScheme.onSurface, size: 21),
    );
    final label = SizedBox(
      height: horizontal ? null : 20,
      child: Align(
        alignment: horizontal ? Alignment.centerLeft : Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            item.label,
            maxLines: 1,
            textAlign: horizontal ? TextAlign.start : TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: item.label,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal ? NexoraSpacing.md : 2,
            vertical: horizontal ? NexoraSpacing.sm : NexoraSpacing.xs,
          ),
          child: horizontal
              ? Row(
                  children: [
                    icon,
                    const SizedBox(width: NexoraSpacing.sm),
                    Expanded(child: label),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                )
              : Column(
                  children: [
                    icon,
                    const SizedBox(height: NexoraSpacing.xs),
                    label,
                  ],
                ),
        ),
      ),
    );
  }
}

class ProfileSettingGroup extends StatelessWidget {
  const ProfileSettingGroup({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: NexoraSpacing.sm),
        Material(
          color: theme.colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NexoraRadius.card),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: theme.colorScheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileSettingTile extends StatelessWidget {
  const ProfileSettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.trailingWidget,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailing;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '$title. $subtitle${trailing == null ? '' : '. $trailing'}',
      child: ListTile(
        onTap: onTap,
        minLeadingWidth: 32,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: NexoraSpacing.md,
          vertical: NexoraSpacing.xs,
        ),
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(
                subtitle,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              )
            : null,
        trailing: trailingWidget ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 92),
                    child: Text(
                      trailing!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: NexoraSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
      ),
    );
  }
}
