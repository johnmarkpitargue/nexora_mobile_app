import 'package:flutter/material.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/nexora_theme.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/notification_feed_service.dart';
import '../../../core/services/order_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _filter = 'All';

  void _markAllRead() {
    NotificationFeedService.instance.markAllAsRead();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            key: const ValueKey('notifications-mark-read'),
            tooltip: 'Mark all as read',
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all_rounded),
          ),
          IconButton(
            key: const ValueKey('notifications-settings-action'),
            tooltip: 'Notification settings',
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.notificationPreferences),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: NexoraSpacing.xs),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          NotificationFeedService.instance,
          OrderService.instance,
          ChatService.instance,
        ]),
        builder: (context, _) {
          final allEntries =
              NotificationFeedService.instance.getCombinedEntries();
          final visible = _filter == 'All'
              ? allEntries
              : allEntries.where((entry) => entry.type == _filter).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: NexoraSpacing.md,
                    vertical: NexoraSpacing.xs,
                  ),
                  children: [
                    for (final filter in const [
                      'All',
                      'Orders',
                      'Messages',
                      'Promos',
                    ])
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: NexoraSpacing.xs,
                        ),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              Expanded(
                child: visible.isEmpty
                    ? _NotificationEmptyState(filter: _filter)
                    : ListView.separated(
                        key: const ValueKey('notifications-list'),
                        padding: const EdgeInsets.fromLTRB(
                          NexoraSpacing.md,
                          NexoraSpacing.sm,
                          NexoraSpacing.md,
                          NexoraSpacing.xxl,
                        ),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => Divider(
                          indent: 60,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        itemBuilder: (context, index) {
                          final entry = visible[index];
                          return Dismissible(
                            key: ValueKey('notif_${entry.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                            ),
                            onDismissed: (_) {
                              NotificationFeedService.instance
                                  .removeNotification(entry.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Removed "${entry.title}"'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: _NotificationTile(
                              entry: entry,
                              onTap: () {
                                NotificationFeedService.instance
                                    .markAsRead(entry.id);
                                if (entry.routeArgs != null) {
                                  Navigator.pushNamed(
                                    context,
                                    entry.route,
                                    arguments: entry.routeArgs,
                                  );
                                } else {
                                  Navigator.pushNamed(context, entry.route);
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.entry, required this.onTap});

  final NotificationEntryModel entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: NexoraSpacing.xxs,
      ),
      leading: DecoratedBox(
        decoration: BoxDecoration(
          color: !entry.isRead
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: 44,
          child: Icon(
            entry.icon,
            size: 22,
            color: !entry.isRead
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: !entry.isRead ? FontWeight.w800 : FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (!entry.isRead)
            Container(
              margin: const EdgeInsets.only(left: 6),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: NexoraSpacing.xxs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.type,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.time,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState({required this.filter});

  final String filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String title;
    String description;
    IconData icon;

    switch (filter) {
      case 'Orders':
        title = 'No Order Alerts Yet';
        description =
            'When your orders are placed, packed, or dispatched for delivery, real-time courier updates will appear here.';
        icon = Icons.local_shipping_outlined;
        break;
      case 'Messages':
        title = 'No Message Alerts';
        description =
            'Direct chats from sellers and couriers will appear here.';
        icon = Icons.chat_bubble_outline_rounded;
        break;
      case 'Promos':
        title = 'No Promo Alerts';
        description =
            'Special voucher releases and flash sale alerts will appear here.';
        icon = Icons.local_offer_outlined;
        break;
      default:
        title = 'You’re all caught up';
        description =
            'Order tracking updates, seller chats, and promo alerts will appear here.';
        icon = Icons.notifications_none_rounded;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(NexoraSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 34,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: NexoraSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: NexoraSpacing.xs),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
