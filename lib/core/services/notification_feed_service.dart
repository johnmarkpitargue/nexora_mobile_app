import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import 'chat_service.dart';
import 'order_service.dart';

class NotificationEntryModel {
  final String id;
  final String type; // 'Orders', 'Messages', 'Promos', 'System'
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final String route;
  final dynamic routeArgs;
  bool isRead;
  final DateTime createdAt;

  NotificationEntryModel({
    required this.id,
    required this.type,
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.route,
    this.routeArgs,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  NotificationEntryModel copyWith({
    String? id,
    String? type,
    IconData? icon,
    String? title,
    String? message,
    String? time,
    String? route,
    dynamic routeArgs,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationEntryModel(
      id: id ?? this.id,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      route: route ?? this.route,
      routeArgs: routeArgs ?? this.routeArgs,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Centralized notification feed service powering the Notifications inbox,
/// unread bell badges, and notification preference test triggers.
class NotificationFeedService extends ChangeNotifier {
  static final NotificationFeedService instance =
      NotificationFeedService._internal();

  NotificationFeedService._internal() {
    _initDefaultFeed();
  }

  final List<NotificationEntryModel> _feed = [];

  List<NotificationEntryModel> get notifications =>
      List.unmodifiable(_feed);

  int get unreadCount => _feed.where((n) => !n.isRead).length;

  void _initDefaultFeed() {
    _feed.addAll([
      NotificationEntryModel(
        id: 'notif_welcome_promo',
        type: 'Promos',
        icon: Icons.local_offer_rounded,
        title: 'Welcome to Nexora! ₱100 Off Voucher',
        message:
            'Use voucher code NEXORA100 on checkout to enjoy ₱100 off your order. Valid on all stores.',
        time: 'Just now',
        route: AppRoutes.home,
        isRead: false,
      ),
      NotificationEntryModel(
        id: 'notif_courier_tracking',
        type: 'Orders',
        icon: Icons.two_wheeler_rounded,
        title: 'Real-Time Courier & GPS Dispatch Active',
        message:
            'Door-to-door courier tracking is active for your deliveries. You will receive live alerts when riders are en route.',
        time: 'Today',
        route: AppRoutes.orders,
        isRead: false,
      ),
      NotificationEntryModel(
        id: 'notif_security_buyer',
        type: 'System',
        icon: Icons.verified_user_rounded,
        title: 'Nexora Buyer Protection Guarantee',
        message:
            'All orders placed on Nexora are safeguarded with 100% verified merchant authentications and free 7-day returns.',
        time: 'Yesterday',
        route: AppRoutes.home,
        isRead: true,
      ),
    ]);
  }

  /// Adds a new notification to the top of the feed and notifies listeners.
  void addNotification({
    required String title,
    required String message,
    String type = 'Orders',
    IconData icon = Icons.notifications_rounded,
    String route = AppRoutes.orders,
    dynamic routeArgs,
    String? time,
  }) {
    final entry = NotificationEntryModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      icon: icon,
      title: title,
      message: message,
      time: time ?? 'Just now',
      route: route,
      routeArgs: routeArgs,
      isRead: false,
    );

    _feed.insert(0, entry);
    notifyListeners();
  }

  /// Marks a specific notification as read.
  void markAsRead(String id) {
    final idx = _feed.indexWhere((n) => n.id == id);
    if (idx != -1 && !_feed[idx].isRead) {
      _feed[idx].isRead = true;
      notifyListeners();
    }
  }

  /// Marks all notifications as read.
  void markAllAsRead() {
    bool changed = false;
    for (final n in _feed) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    ChatService.instance.markAllAsRead();
    if (changed) {
      notifyListeners();
    }
  }

  /// Clears a single notification.
  void removeNotification(String id) {
    _feed.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  /// Aggregates both stored feed items, live orders, and live messages into a unified list.
  List<NotificationEntryModel> getCombinedEntries() {
    final List<NotificationEntryModel> combined = List.from(_feed);

    // Dynamic active orders
    for (final order in OrderService.instance.activeOrders) {
      if (!combined.any((n) => n.id == 'order_${order.orderId}')) {
        combined.insert(
          0,
          NotificationEntryModel(
            id: 'order_${order.orderId}',
            type: 'Orders',
            icon: Icons.local_shipping_outlined,
            title: 'Order ${order.statusText}',
            message:
                'Order ${order.orderId} is currently ${order.statusText.toLowerCase()} (${order.etaText}). Tap for live tracking.',
            time: order.dateText,
            route: AppRoutes.orders,
            routeArgs: {'orderId': order.orderId},
            isRead: false,
          ),
        );
      }
    }

    // Dynamic unread chats
    for (final conv in ChatService.instance.conversations) {
      if (conv.unread > 0 &&
          !combined.any((n) => n.id == 'chat_${conv.id}')) {
        combined.insert(
          0,
          NotificationEntryModel(
            id: 'chat_${conv.id}',
            type: 'Messages',
            icon: Icons.chat_bubble_outline_rounded,
            title: conv.title,
            message: conv.subtitle,
            time: conv.time,
            route: AppRoutes.chat,
            routeArgs: {'conversationId': conv.id},
            isRead: false,
          ),
        );
      }
    }

    return combined;
  }
}

