import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import 'chat_service.dart';

class NotificationEntryModel {
  final String id;
  final String type; // 'Orders', 'Messages', 'System'
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

/// Real database-backed notification feed service consuming `/api/mobile/v1/notifications`.
/// Returns an empty list cleanly when the backend has zero notifications.
class NotificationFeedService extends ChangeNotifier {
  static final NotificationFeedService instance =
      NotificationFeedService._internal();

  NotificationFeedService._internal();

  final List<NotificationEntryModel> _feed = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _remoteUnreadCount = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationEntryModel> get notifications => List.unmodifiable(_feed);

  int get unreadCount {
    if (!ApiClient.instance.hasToken) return 0;
    final localUnread = _feed.where((n) => !n.isRead).length;
    return _remoteUnreadCount > 0 ? _remoteUnreadCount : localUnread;
  }

  Future<void> fetchNotificationsRemote() async {
    if (!ApiClient.instance.hasToken) {
      _feed.clear();
      _remoteUnreadCount = 0;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.instance.get(ApiConstants.notifications);
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        final rawList = data['notifications'] as List? ?? [];
        _remoteUnreadCount =
            int.tryParse((data['unread_count'] ?? 0).toString()) ?? 0;

        _feed
          ..clear()
          ..addAll(rawList.whereType<Map<String, dynamic>>().map((item) {
            final rawType = (item['type'] ?? '').toString().toLowerCase();
            final isOrder =
                rawType.contains('order') || item['order_id'] != null;
            final categoryType = isOrder ? 'Orders' : 'System';

            return NotificationEntryModel(
              id: item['id'].toString(),
              type: categoryType,
              icon: isOrder
                  ? Icons.local_shipping_outlined
                  : Icons.notifications_outlined,
              title: item['title']?.toString() ?? 'Nexora Update',
              message: item['message']?.toString() ?? '',
              time: item['created_human']?.toString() ?? 'Recently',
              route: isOrder ? AppRoutes.orders : AppRoutes.notifications,
              routeArgs: item['order_id'] != null
                  ? {'orderId': item['order_id'].toString()}
                  : null,
              isRead: item['is_read'] == true,
              createdAt:
                  DateTime.tryParse(item['created_at']?.toString() ?? '') ??
                      DateTime.now(),
            );
          }));
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Unable to load notifications right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final idx = _feed.indexWhere((n) => n.id == id);
    if (idx != -1 && !_feed[idx].isRead) {
      _feed[idx].isRead = true;
      if (_remoteUnreadCount > 0) _remoteUnreadCount--;
      notifyListeners();
    }

    if (ApiClient.instance.hasToken && !id.startsWith('local_')) {
      try {
        final res = await ApiClient.instance
            .post(ApiConstants.readNotification(id));
        final data = res['data'];
        if (data is Map<String, dynamic> && data['unread_count'] != null) {
          _remoteUnreadCount =
              int.tryParse(data['unread_count'].toString()) ?? 0;
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    for (final n in _feed) {
      n.isRead = true;
    }
    _remoteUnreadCount = 0;
    ChatService.instance.markAllAsRead();
    notifyListeners();

    if (ApiClient.instance.hasToken) {
      try {
        await ApiClient.instance.post(ApiConstants.readAllNotifications);
      } catch (_) {}
    }
  }

  void addNotification({
    required String title,
    required String message,
    String type = 'Orders',
    IconData icon = Icons.notifications_rounded,
    String route = AppRoutes.orders,
    dynamic routeArgs,
    String? time,
  }) {
    _feed.insert(
      0,
      NotificationEntryModel(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        icon: icon,
        title: title,
        message: message,
        time: time ?? 'Just now',
        route: route,
        routeArgs: routeArgs,
        isRead: false,
      ),
    );
    _remoteUnreadCount++;
    notifyListeners();
  }

  void removeNotification(String id) {
    _feed.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clear() {
    _feed.clear();
    _remoteUnreadCount = 0;
    _errorMessage = null;
    notifyListeners();
  }

  List<NotificationEntryModel> getCombinedEntries() {
    return List<NotificationEntryModel>.unmodifiable(_feed);
  }
}
