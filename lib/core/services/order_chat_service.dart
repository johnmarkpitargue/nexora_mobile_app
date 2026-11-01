import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_service.dart';
import 'in_app_notification_service.dart';
import '../../features/chat/presentation/chat_detail_page.dart';

class OrderChatService extends ChangeNotifier {
  static final OrderChatService instance = OrderChatService._internal();

  OrderChatService._internal() {
    _initGlobalDispatchListener();
  }

  RealtimeChannel? _dispatchChannel;
  RealtimeChannel? _ordersDbChannel;

  /// Ensures global dispatch listener is initialized once Supabase is ready
  void ensureInitialized() {
    _initGlobalDispatchListener();
  }

  void _initGlobalDispatchListener() {
    if (!isSupabaseReady) return;
    if (_dispatchChannel == null) {
      try {
        _dispatchChannel = Supabase.instance.client.channel('rider_dispatch_chat');
      _dispatchChannel!.onBroadcast(
        event: 'new_rider_message',
        callback: (payload) {
          try {
            final orderId = (payload['order_id'] ?? payload['orderId'] ?? '').toString();
            final clean = normalizeOrderId(orderId);
            if (clean.isEmpty) return;

            final sender = (payload['sender'] ?? '').toString().toLowerCase();
            if (sender == 'customer' || sender == 'user') return;

            final text = (payload['text'] ?? '').toString();
            final rawSenderName = (payload['sender_name'] ?? payload['senderName'] ?? 'Pedro Jose Garcia').toString();
            final senderName = rawSenderName.contains('Mark') ? 'Pedro Jose Garcia' : rawSenderName;
            final timeStr = _getCurrentTime();
            final nowIso = (payload['timestamp'] ?? DateTime.now().toIso8601String()).toString();

            final msg = {
              'id': (payload['id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}').toString(),
              'orderId': clean,
              'sender': 'other',
              'senderName': senderName,
              'text': text,
              'time': timeStr,
              'timestamp': nowIso,
              'isMe': false,
              'isEdited': payload['is_edited'] == true || payload['isEdited'] == true,
              'isUnsent': payload['is_unsent'] == true || payload['isUnsent'] == true,
              'editedAt': payload['edited_at'] ?? payload['editedAt'],
              'attachmentData': (payload['attachment_data'] ?? payload['attachmentData'])?.toString(),
              'attachmentName': (payload['attachment_name'] ?? payload['attachmentName'])?.toString(),
              'attachmentSize': (payload['attachment_size'] ?? payload['attachmentSize']) as int?,
              'attachmentType': (payload['attachment_type'] ?? payload['attachmentType'])?.toString(),
            };

            if (!_orderChats.containsKey(clean)) {
              _orderChats[clean] = [];
            }

            final list = _orderChats[clean]!;
            final exists = list.any((m) => m['id'] == msg['id']);
            if (!exists) {
              list.add(msg);

              if (activeScreenOrderId != clean) {
                _unreadCounts[clean] = (_unreadCounts[clean] ?? 0) + 1;
                onNewMessageReceived?.call(msg);
                _showTopNotification(msg);
              }

              _riderTyping[clean] = false;
              _typingTimers[clean]?.cancel();

              try {
                ChatService.instance.receiveIncomingMessage(
                  conversationId: 'courier_$clean',
                  text: text,
                  senderName: senderName,
                );
              } catch (_) {}

              notifyListeners();
            }
          } catch (e) {
            debugPrint('⚠️ OrderChatService global dispatch parse error: $e');
          }
        },
      ).onBroadcast(
        event: 'edit_message',
        callback: (payload) {
          _handleRemoteEdit(payload);
        },
      ).onBroadcast(
        event: 'unsend_message',
        callback: (payload) {
          _handleRemoteUnsend(payload);
        },
      ).onBroadcast(
        event: 'request_chat_history',
        callback: (payload) {
          _handleHistoryRequest(payload);
        },
      ).onBroadcast(
        event: 'sync_chat_history',
        callback: (payload) {
          _handleHistorySync(payload);
        },
      ).subscribe((status, [error]) {
        if (status != RealtimeSubscribeStatus.subscribed) {
          debugPrint('📡 OrderChatService global dispatch status: $status');
        }
      });
      } catch (_) {}
    }

    if (_ordersDbChannel == null) {
      try {
        _ordersDbChannel = Supabase.instance.client
            .channel('orders_buyer_db_sync')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'orders',
              callback: (payload) {
                try {
                  final row = payload.newRecord;
                  final orderCode = (row['order_id'] ?? row['id'] ?? '').toString();
                  if (orderCode.isNotEmpty) {
                    syncRemoteMessages(orderCode);
                  }
                } catch (_) {}
              },
            )
            .subscribe((status, [error]) {
              if (status != RealtimeSubscribeStatus.subscribed) {
                debugPrint('📡 Orders DB sync status: $status');
              }
            });
      } catch (_) {}
    }
  }

  final Map<String, List<Map<String, dynamic>>> _orderChats = {};
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, bool> _riderTyping = {};
  final Map<String, Timer?> _typingTimers = {};
  final Map<String, Completer<bool>> _channelReadyCompleters = {};
  final Map<String, int> _unreadCounts = {};

  /// Callback for showing in-app banner/notification when a message arrives
  void Function(Map<String, dynamic> msg)? onNewMessageReceived;

  /// Currently open chat screen orderId (to prevent unread count incrementing)
  String? activeScreenOrderId;

  bool get isSupabaseReady {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  String normalizeOrderId(String orderId) {
    return orderId.replaceAll('#', '').trim().toLowerCase();
  }

  void _initSeedMessagesForOrder(String clean) {
    if (_orderChats[clean] == null || _orderChats[clean]!.isEmpty) {
      _orderChats[clean] = [
        {
          'id': 'init_${clean}_sys',
          'orderId': clean,
          'sender': 'system',
          'senderName': 'Nexora Dispatch',
          'text': 'Dispatch channel opened for order #$clean. Real-time encryption active.',
          'time': _getCurrentTime(),
          'isMe': false,
        },
      ];
    }
  }

  List<Map<String, dynamic>> getMessages(String orderId) {
    final clean = normalizeOrderId(orderId);
    if (!_orderChats.containsKey(clean) || _orderChats[clean]!.isEmpty) {
      _initSeedMessagesForOrder(clean);
    } else {
      final hasSys = _orderChats[clean]!.any((m) => m['sender'] == 'system');
      if (!hasSys) {
        _orderChats[clean]!.insert(0, {
          'id': 'init_${clean}_sys',
          'orderId': clean,
          'sender': 'system',
          'senderName': 'Nexora Dispatch',
          'text': 'Dispatch channel opened for order #$clean. Real-time encryption active.',
          'time': _getCurrentTime(),
          'isMe': false,
        });
      }
    }
    return _orderChats[clean]!;
  }

  bool isRiderTyping(String orderId) {
    final clean = normalizeOrderId(orderId);
    return _riderTyping[clean] ?? false;
  }

  int getUnreadCount(String orderId) {
    final clean = normalizeOrderId(orderId);
    return _unreadCounts[clean] ?? 0;
  }

  void markAsRead(String orderId) {
    final clean = normalizeOrderId(orderId);
    if ((_unreadCounts[clean] ?? 0) > 0) {
      _unreadCounts[clean] = 0;
      notifyListeners();
    }
  }

  /// Subscribes to real-time chat updates for the specified order
  void subscribeToOrder(String orderId) {
    final clean = normalizeOrderId(orderId);
    if (clean.isEmpty) return;

    // Always fetch latest chat messages from Supabase remote storage
    syncRemoteMessages(clean);

    if (_channels.containsKey(clean)) return;

    if (!isSupabaseReady) return;

    final completer = Completer<bool>();
    _channelReadyCompleters[clean] = completer;

    try {
      final channelName = 'rider_chat_$clean';
      final channel = Supabase.instance.client.channel(
        channelName,
        opts: const RealtimeChannelConfig(self: false),
      );

      channel.onBroadcast(
        event: 'chat_message',
        callback: (payload) {
          try {
            final sender = (payload['sender'] ?? '').toString().toLowerCase();
            // Ignore messages sent by ourselves
            if (sender == 'customer' || sender == 'user') return;

            final rawSenderName = (payload['sender_name'] ?? payload['senderName'] ?? 'Pedro Jose Garcia').toString();
            final senderName = rawSenderName.contains('Mark') ? 'Pedro Jose Garcia' : rawSenderName;
            final text = (payload['text'] ?? '').toString();
            final nowIso = (payload['timestamp'] ?? DateTime.now().toIso8601String()).toString();
            final timeStr = payload['timestamp'] != null
                ? _formatIsoToTime(payload['timestamp'].toString())
                : _getCurrentTime();

            final msg = {
              'id': (payload['id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}').toString(),
              'orderId': clean,
              'sender': 'other', // from other party (the rider)
              'senderName': senderName,
              'text': text,
              'time': timeStr,
              'timestamp': nowIso,
              'isMe': false,
              'isEdited': payload['is_edited'] == true || payload['isEdited'] == true,
              'isUnsent': payload['is_unsent'] == true || payload['isUnsent'] == true,
              'editedAt': payload['edited_at'] ?? payload['editedAt'],
              'attachmentData': (payload['attachment_data'] ?? payload['attachmentData'])?.toString(),
              'attachmentName': (payload['attachment_name'] ?? payload['attachmentName'])?.toString(),
              'attachmentSize': (payload['attachment_size'] ?? payload['attachmentSize']) as int?,
              'attachmentType': (payload['attachment_type'] ?? payload['attachmentType'])?.toString(),
            };

            if (!_orderChats.containsKey(clean)) {
              _orderChats[clean] = [];
            }

            final list = _orderChats[clean]!;
            final exists = list.any((m) => m['id'] == msg['id']);
            if (!exists) {
              list.add(msg);

              // Increment unread count if user is not actively viewing this chat
              if (activeScreenOrderId != clean) {
                _unreadCounts[clean] = (_unreadCounts[clean] ?? 0) + 1;
                onNewMessageReceived?.call(msg);
                _showTopNotification(msg);
              }

              // Rider finished sending, stop typing indicator
              _riderTyping[clean] = false;
              _typingTimers[clean]?.cancel();

              // Sync to general ChatService for Messages tab
              try {
                ChatService.instance.receiveIncomingMessage(
                  conversationId: 'courier_$clean',
                  text: text,
                  senderName: senderName,
                );
              } catch (_) {}

              notifyListeners();
            }
          } catch (e) {
            debugPrint('⚠️ OrderChatService message parse error: $e');
          }
        },
      ).onBroadcast(
        event: 'edit_message',
        callback: (payload) {
          _handleRemoteEdit(payload);
        },
      ).onBroadcast(
        event: 'unsend_message',
        callback: (payload) {
          _handleRemoteUnsend(payload);
        },
      ).onBroadcast(
        event: 'typing',
        callback: (payload) {
          try {
            final sender = (payload['sender'] ?? '').toString().toLowerCase();
            if (sender == 'customer' || sender == 'user') return;

            final isTyping = payload['is_typing'] == true || payload['isTyping'] == true;
            _riderTyping[clean] = isTyping;
            notifyListeners();

            _typingTimers[clean]?.cancel();
            if (isTyping) {
              _typingTimers[clean] = Timer(const Duration(seconds: 3), () {
                _riderTyping[clean] = false;
                notifyListeners();
              });
            }
          } catch (e) {
            debugPrint('⚠️ OrderChatService typing error: $e');
          }
        },
      ).onBroadcast(
        event: 'request_chat_history',
        callback: (payload) {
          _handleHistoryRequest(payload);
        },
      ).onBroadcast(
        event: 'sync_chat_history',
        callback: (payload) {
          _handleHistorySync(payload);
        },
      ).subscribe((status, [error]) {
        debugPrint('📡 OrderChatService channel $channelName status: $status');
        if (status == RealtimeSubscribeStatus.subscribed) {
          if (!completer.isCompleted) completer.complete(true);
          requestHistory(clean);
        } else if (status == RealtimeSubscribeStatus.channelError || status == RealtimeSubscribeStatus.timedOut) {
          if (!completer.isCompleted) completer.complete(false);
          _channels.remove(clean);
          _channelReadyCompleters.remove(clean);
        }
      });

      _channels[clean] = channel;
    } catch (e) {
      debugPrint('⚠️ OrderChatService subscribe error: $e');
      if (!completer.isCompleted) completer.complete(false);
    }
  }

  /// Sends a real-time message from the buyer to the rider
  Future<void> sendMessage(
    String orderId,
    String text, {
    String customerName = 'Alex Rivera',
    String? attachmentData,
    String? attachmentName,
    int? attachmentSize,
    String? attachmentType,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && (attachmentData == null || attachmentData.isEmpty)) return;

    final clean = normalizeOrderId(orderId);
    final id = 'msg_c_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';
    final timeStr = _getCurrentTime();
    final nowIso = DateTime.now().toIso8601String();

    final msg = {
      'id': id,
      'orderId': clean,
      'sender': 'user', // current buyer
      'senderName': customerName,
      'text': trimmed,
      'time': timeStr,
      'timestamp': nowIso,
      'isMe': true,
      'isEdited': false,
      'isUnsent': false,
      'editedAt': null,
      'attachmentData': attachmentData,
      'attachmentName': attachmentName,
      'attachmentSize': attachmentSize,
      'attachmentType': attachmentType,
    };

    if (!_orderChats.containsKey(clean)) {
      _orderChats[clean] = [];
    }
    _orderChats[clean]!.add(msg);
    notifyListeners();

    // Ensure subscribed to channel
    subscribeToOrder(orderId);

    // Wait briefly for channel readiness if subscribing for the first time
    final ready = _channelReadyCompleters[clean];
    if (ready != null && !ready.isCompleted) {
      try {
        await ready.future.timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    final channel = _channels[clean];
    if (channel != null) {
      try {
        await channel.sendBroadcastMessage(
          event: 'chat_message',
          payload: {
            'id': id,
            'order_id': clean,
            'orderId': clean,
            'sender': 'customer',
            'sender_name': customerName,
            'senderName': customerName,
            'text': trimmed,
            'timestamp': DateTime.now().toIso8601String(),
            'attachment_data': attachmentData,
            'attachment_name': attachmentName,
            'attachment_size': attachmentSize,
            'attachment_type': attachmentType,
          },
        );
      } catch (e) {
        debugPrint('⚠️ OrderChatService broadcast send error: $e');
      }
    }

    // Also broadcast to global dispatch channel for real-time cross-order sync
    try {
      final global = _dispatchChannel ?? Supabase.instance.client.channel('rider_dispatch_chat');
      await global.sendBroadcastMessage(
        event: 'new_customer_message',
        payload: {
          'id': id,
          'order_id': clean,
          'orderId': clean,
          'sender': 'customer',
          'sender_name': customerName,
          'senderName': customerName,
          'text': trimmed,
          'timestamp': DateTime.now().toIso8601String(),
          'attachment_data': attachmentData,
          'attachment_name': attachmentName,
          'attachment_size': attachmentSize,
          'attachment_type': attachmentType,
        },
      );
    } catch (_) {}

    // Persist to Supabase database so messages sync across APKs even if offline/backgrounded
    _persistMessageToSupabase(clean, {
      'id': id,
      'order_id': clean,
      'orderId': clean,
      'sender': 'customer',
      'sender_name': customerName,
      'senderName': customerName,
      'text': trimmed,
      'timestamp': nowIso,
      'attachment_data': attachmentData,
      'attachment_name': attachmentName,
      'attachment_size': attachmentSize,
      'attachment_type': attachmentType,
    });

    // Stop typing indicator after sending
    sendTyping(orderId, false);

    // Sync to general ChatService for Messages tab
    try {
      ChatService.instance.sendUserMessage('courier_$clean', trimmed);
    } catch (_) {}
  }

  /// Broadcasts typing indicator to rider
  Future<void> sendTyping(String orderId, bool isTyping) async {
    final clean = normalizeOrderId(orderId);
    final channel = _channels[clean];
    if (channel != null) {
      try {
        await channel.sendBroadcastMessage(
          event: 'typing',
          payload: {
            'order_id': clean,
            'orderId': clean,
            'sender': 'customer',
            'is_typing': isTyping,
            'isTyping': isTyping,
          },
        );
      } catch (_) {}
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  String _formatIsoToTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $ampm';
    } catch (_) {
      return _getCurrentTime();
    }
  }

  /// Checks if message was sent by buyer and is under 10 minutes old
  bool canEditMessage(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] == true || msg['sender'] == 'user';
    final isUnsent = msg['isUnsent'] == true;
    if (!isMe || isUnsent) return false;

    final timestampStr = msg['timestamp'] ?? msg['time'];
    DateTime msgTime;
    if (timestampStr != null) {
      msgTime = DateTime.tryParse(timestampStr.toString()) ?? DateTime.now();
    } else {
      msgTime = DateTime.now();
    }
    return DateTime.now().difference(msgTime).inMinutes < 10;
  }

  /// Calculates remaining minutes left to edit under the 10-minute window
  int getRemainingEditMinutes(Map<String, dynamic> msg) {
    final timestampStr = msg['timestamp'] ?? msg['time'];
    DateTime msgTime;
    if (timestampStr != null) {
      msgTime = DateTime.tryParse(timestampStr.toString()) ?? DateTime.now();
    } else {
      msgTime = DateTime.now();
    }
    final diff = DateTime.now().difference(msgTime).inMinutes;
    return (10 - diff).clamp(0, 10);
  }

  /// Edits an existing message sent by the buyer
  Future<bool> editMessage(String orderId, String messageId, String newText) async {
    final clean = normalizeOrderId(orderId);
    final list = _orderChats[clean];
    if (list == null) return false;

    final idx = list.indexWhere((m) => m['id'] == messageId);
    if (idx == -1) return false;

    if (!canEditMessage(list[idx])) return false;

    final nowIso = DateTime.now().toIso8601String();
    list[idx]['text'] = newText;
    list[idx]['isEdited'] = true;
    list[idx]['editedAt'] = nowIso;
    notifyListeners();

    final payload = {
      'id': messageId,
      'order_id': clean,
      'orderId': clean,
      'sender': 'customer',
      'text': newText,
      'is_edited': true,
      'isEdited': true,
      'edited_at': nowIso,
    };

    final channel = _channels[clean];
    if (channel != null) {
      try {
        await channel.sendBroadcastMessage(
          event: 'edit_message',
          payload: payload,
        );
      } catch (_) {}
    }

    try {
      final global = _dispatchChannel ?? Supabase.instance.client.channel('rider_dispatch_chat');
      await global.sendBroadcastMessage(
        event: 'edit_message',
        payload: payload,
      );
    } catch (_) {}

    _persistRemoteEditToSupabase(clean, messageId, newText, nowIso);

    return true;
  }

  /// Unsends an existing message sent by the buyer
  Future<bool> unsendMessage(String orderId, String messageId) async {
    final clean = normalizeOrderId(orderId);
    final list = _orderChats[clean];
    if (list == null) return false;

    final idx = list.indexWhere((m) => m['id'] == messageId);
    if (idx == -1) return false;

    list[idx]['text'] = 'You unsent a message';
    list[idx]['isUnsent'] = true;
    notifyListeners();

    final payload = {
      'id': messageId,
      'order_id': clean,
      'orderId': clean,
      'sender': 'customer',
      'is_unsent': true,
      'isUnsent': true,
    };

    final channel = _channels[clean];
    if (channel != null) {
      try {
        await channel.sendBroadcastMessage(
          event: 'unsend_message',
          payload: payload,
        );
      } catch (_) {}
    }

    try {
      final global = _dispatchChannel ?? Supabase.instance.client.channel('rider_dispatch_chat');
      await global.sendBroadcastMessage(
        event: 'unsend_message',
        payload: payload,
      );
    } catch (_) {}

    _persistRemoteUnsendToSupabase(clean, messageId);

    return true;
  }

  /// Persists a chat message to Supabase database (orders table chat storage + optional chat_messages table)
  Future<void> _persistMessageToSupabase(String orderId, Map<String, dynamic> msgMap) async {
    final clean = normalizeOrderId(orderId);
    if (clean.isEmpty || !isSupabaseReady) return;

    try {
      final row = await Supabase.instance.client
          .from('orders')
          .select('id, item_details')
          .or('order_id.eq.$clean,order_id.eq.${clean.toUpperCase()},order_id.eq.#${clean.toUpperCase()}')
          .limit(1)
          .maybeSingle();

      String baseTitle = 'Delivery Order';
      List<Map<String, dynamic>> chatList = [];

      if (row != null) {
        final currentDetails = (row['item_details'] ?? '').toString();
        if (currentDetails.startsWith('{') && currentDetails.endsWith('}')) {
          try {
            final parsed = jsonDecode(currentDetails) as Map<String, dynamic>;
            baseTitle = (parsed['title'] ?? 'Delivery Order').toString();
            if (parsed['chat'] is List) {
              chatList = (parsed['chat'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            }
          } catch (_) {}
        } else if (currentDetails.isNotEmpty) {
          baseTitle = currentDetails;
        }

        chatList.removeWhere((m) => m['id'] == msgMap['id']);
        
        // Sanitize messages: never allow multi-megabyte base64 blobs inside orders.item_details (prevents egress blowup)
        final sanitizedMsg = Map<String, dynamic>.from(msgMap);
        if (sanitizedMsg['attachment_data'] != null &&
            sanitizedMsg['attachment_data'].toString().length > 500) {
          sanitizedMsg['attachment_data'] = '[image_attachment]';
        }
        chatList.add(sanitizedMsg);

        for (int i = 0; i < chatList.length; i++) {
          final m = chatList[i];
          if (m['attachment_data'] != null && m['attachment_data'].toString().length > 500) {
            chatList[i] = Map<String, dynamic>.from(m)..['attachment_data'] = '[image_attachment]';
          }
        }

        if (chatList.length > 50) {
          chatList = chatList.sublist(chatList.length - 50);
        }

        final updatedJson = jsonEncode({
          'title': baseTitle,
          'chat': chatList,
        });

        final targetId = row['id'];
        if (targetId != null) {
          await Supabase.instance.client
              .from('orders')
              .update({'item_details': updatedJson})
              .eq('id', targetId);
        } else {
          await Supabase.instance.client
              .from('orders')
              .update({'item_details': updatedJson})
              .or('order_id.eq.$clean,order_id.eq.${clean.toUpperCase()}');
        }
      }

      // Also attempt insert into chat_messages table if configured
      try {
        await Supabase.instance.client.from('chat_messages').upsert({
          'id': msgMap['id'],
          'order_id': clean,
          'sender': msgMap['sender'],
          'sender_name': msgMap['sender_name'] ?? msgMap['senderName'],
          'text': msgMap['text'],
          'timestamp': msgMap['timestamp'],
          'is_edited': msgMap['is_edited'] ?? msgMap['isEdited'] ?? false,
          'is_unsent': msgMap['is_unsent'] ?? msgMap['isUnsent'] ?? false,
          'attachment_data': msgMap['attachment_data'],
          'attachment_name': msgMap['attachment_name'],
          'attachment_size': msgMap['attachment_size'],
          'attachment_type': msgMap['attachment_type'],
        });
      } catch (_) {}
    } catch (e) {
      debugPrint('ℹ️ OrderChatService _persistMessageToSupabase notice: $e');
    }
  }

  /// Synchronizes messages from Supabase remote storage
  Future<void> syncRemoteMessages(String orderId) async {
    final clean = normalizeOrderId(orderId);
    if (clean.isEmpty || !isSupabaseReady) return;

    try {
      final row = await Supabase.instance.client
          .from('orders')
          .select('item_details')
          .or('order_id.eq.$clean,order_id.eq.${clean.toUpperCase()},order_id.eq.#${clean.toUpperCase()}')
          .limit(1)
          .maybeSingle();

      if (row != null && row['item_details'] != null) {
        final detailsStr = row['item_details'].toString();
        if (detailsStr.startsWith('{') && detailsStr.endsWith('}')) {
          try {
            final parsed = jsonDecode(detailsStr) as Map<String, dynamic>;
            if (parsed['chat'] is List) {
              final remoteList = (parsed['chat'] as List)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();

              if (!_orderChats.containsKey(clean)) {
                _initSeedMessagesForOrder(clean);
              }
              final list = _orderChats[clean]!;
              bool changed = false;

              for (final rMsg in remoteList) {
                final id = (rMsg['id'] ?? '').toString();
                if (id.isEmpty) continue;
                final sender = (rMsg['sender'] ?? '').toString().toLowerCase();
                final isCustomerSender = sender == 'customer' || sender == 'user';
                final isMe = isCustomerSender;

                final rawSenderName = (rMsg['sender_name'] ?? rMsg['senderName'] ?? (isMe ? 'Alex Rivera' : 'Pedro Jose Garcia')).toString();
                final senderName = rawSenderName.contains('Mark') ? 'Pedro Jose Garcia' : rawSenderName;
                final nowIso = (rMsg['timestamp'] ?? DateTime.now().toIso8601String()).toString();
                final timeStr = rMsg['timestamp'] != null
                    ? _formatIsoToTime(rMsg['timestamp'].toString())
                    : _getCurrentTime();

                final formattedMsg = {
                  'id': id,
                  'orderId': clean,
                  'sender': isMe ? 'user' : 'other',
                  'senderName': senderName,
                  'text': (rMsg['text'] ?? '').toString(),
                  'time': timeStr,
                  'timestamp': nowIso,
                  'isMe': isMe,
                  'isEdited': rMsg['is_edited'] == true || rMsg['isEdited'] == true,
                  'isUnsent': rMsg['is_unsent'] == true || rMsg['isUnsent'] == true,
                  'editedAt': rMsg['edited_at'] ?? rMsg['editedAt'],
                  'attachmentData': (rMsg['attachment_data'] ?? rMsg['attachmentData'])?.toString(),
                  'attachmentName': (rMsg['attachment_name'] ?? rMsg['attachmentName'])?.toString(),
                  'attachmentSize': (rMsg['attachment_size'] ?? rMsg['attachmentSize']) as int?,
                  'attachmentType': (rMsg['attachment_type'] ?? rMsg['attachmentType'])?.toString(),
                };

                final idx = list.indexWhere((m) => m['id'] == id);
                if (idx < 0) {
                  list.add(formattedMsg);
                  changed = true;
                  if (activeScreenOrderId != clean && !isMe) {
                    _unreadCounts[clean] = (_unreadCounts[clean] ?? 0) + 1;
                    onNewMessageReceived?.call(formattedMsg);
                  }
                } else {
                  if (list[idx]['text'] != formattedMsg['text'] ||
                      list[idx]['isEdited'] != formattedMsg['isEdited'] ||
                      list[idx]['isUnsent'] != formattedMsg['isUnsent']) {
                    list[idx] = formattedMsg;
                    changed = true;
                  }
                }
              }

              if (changed) {
                notifyListeners();
              }
            }
          } catch (_) {}
        }
      }

      // Also check chat_messages table if configured
      try {
        final rows = await Supabase.instance.client
            .from('chat_messages')
            .select()
            .eq('order_id', clean)
            .order('timestamp', ascending: true);

        if (rows.isNotEmpty) {
          if (!_orderChats.containsKey(clean)) {
            _initSeedMessagesForOrder(clean);
          }
          final list = _orderChats[clean]!;
          bool changed = false;

          for (final r in rows) {
            final id = (r['id'] ?? '').toString();
            final sender = (r['sender'] ?? '').toString().toLowerCase();
            final isMe = sender == 'customer' || sender == 'user';
            final idx = list.indexWhere((m) => m['id'] == id);
            if (idx < 0) {
              list.add({
                'id': id,
                'orderId': clean,
                'sender': isMe ? 'user' : 'other',
                'senderName': (r['sender_name'] ?? (isMe ? 'Alex Rivera' : 'Pedro Jose Garcia')).toString(),
                'text': (r['text'] ?? '').toString(),
                'time': _formatIsoToTime(r['timestamp'].toString()),
                'timestamp': r['timestamp'].toString(),
                'isMe': isMe,
                'isEdited': r['is_edited'] == true,
                'isUnsent': r['is_unsent'] == true,
                'editedAt': r['edited_at'],
                'attachmentData': r['attachment_data'],
                'attachmentName': r['attachment_name'],
                'attachmentSize': r['attachment_size'],
                'attachmentType': r['attachment_type'],
              });
              changed = true;
            }
          }
          if (changed) notifyListeners();
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('ℹ️ OrderChatService syncRemoteMessages notice: $e');
    }
  }

  /// Persists remote edit to Supabase
  Future<void> _persistRemoteEditToSupabase(String orderId, String messageId, String newText, String editedAt) async {
    final clean = normalizeOrderId(orderId);
    if (clean.isEmpty || !isSupabaseReady) return;

    try {
      final row = await Supabase.instance.client
          .from('orders')
          .select('id, item_details')
          .or('order_id.eq.$clean,order_id.eq.${clean.toUpperCase()},order_id.eq.#${clean.toUpperCase()}')
          .limit(1)
          .maybeSingle();

      if (row != null) {
        final detailsStr = (row['item_details'] ?? '').toString();
        if (detailsStr.startsWith('{') && detailsStr.endsWith('}')) {
          final parsed = jsonDecode(detailsStr) as Map<String, dynamic>;
          final chatList = (parsed['chat'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          final idx = chatList.indexWhere((m) => m['id'] == messageId);
          if (idx != -1) {
            chatList[idx]['text'] = newText;
            chatList[idx]['is_edited'] = true;
            chatList[idx]['isEdited'] = true;
            chatList[idx]['edited_at'] = editedAt;

            final updatedJson = jsonEncode({
              'title': parsed['title'] ?? 'Delivery Order',
              'chat': chatList,
            });

            await Supabase.instance.client
                .from('orders')
                .update({'item_details': updatedJson})
                .eq('id', row['id']);
          }
        }
      }
    } catch (_) {}
  }

  /// Persists remote unsend to Supabase
  Future<void> _persistRemoteUnsendToSupabase(String orderId, String messageId) async {
    final clean = normalizeOrderId(orderId);
    if (clean.isEmpty || !isSupabaseReady) return;

    try {
      final row = await Supabase.instance.client
          .from('orders')
          .select('id, item_details')
          .or('order_id.eq.$clean,order_id.eq.${clean.toUpperCase()},order_id.eq.#${clean.toUpperCase()}')
          .limit(1)
          .maybeSingle();

      if (row != null) {
        final detailsStr = (row['item_details'] ?? '').toString();
        if (detailsStr.startsWith('{') && detailsStr.endsWith('}')) {
          final parsed = jsonDecode(detailsStr) as Map<String, dynamic>;
          final chatList = (parsed['chat'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          final idx = chatList.indexWhere((m) => m['id'] == messageId);
          if (idx != -1) {
            chatList[idx]['text'] = 'This message was unsent';
            chatList[idx]['is_unsent'] = true;
            chatList[idx]['isUnsent'] = true;

            final updatedJson = jsonEncode({
              'title': parsed['title'] ?? 'Delivery Order',
              'chat': chatList,
            });

            await Supabase.instance.client
                .from('orders')
                .update({'item_details': updatedJson})
                .eq('id', row['id']);
          }
        }
      }
    } catch (_) {}
  }

  void _handleRemoteEdit(Map<String, dynamic> payload) {
    try {
      final orderId = (payload['order_id'] ?? payload['orderId'] ?? '').toString();
      final clean = normalizeOrderId(orderId);
      final msgId = (payload['id'] ?? '').toString();
      final newText = (payload['text'] ?? '').toString();
      final editedAt = payload['edited_at'] ?? payload['editedAt'];

      final list = _orderChats[clean];
      if (list != null) {
        final idx = list.indexWhere((m) => m['id'] == msgId);
        if (idx != -1) {
          list[idx]['text'] = newText;
          list[idx]['isEdited'] = true;
          list[idx]['editedAt'] = editedAt;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error handling remote edit: $e');
    }
  }

  void _handleRemoteUnsend(Map<String, dynamic> payload) {
    try {
      final orderId = (payload['order_id'] ?? payload['orderId'] ?? '').toString();
      final clean = normalizeOrderId(orderId);
      final msgId = (payload['id'] ?? '').toString();

      final list = _orderChats[clean];
      if (list != null) {
        final idx = list.indexWhere((m) => m['id'] == msgId);
        if (idx != -1) {
          final isMe = list[idx]['isMe'] == true;
          list[idx]['text'] = isMe ? 'You unsent a message' : 'This message was unsent';
          list[idx]['isUnsent'] = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error handling remote unsend: $e');
    }
  }

  /// Requests existing chat history for order from connected peers
  Future<void> requestHistory(String orderId) async {
    final clean = normalizeOrderId(orderId);
    if (clean.isEmpty) return;

    final payload = {
      'order_id': clean,
      'orderId': clean,
      'sender': 'customer',
      'request_id': 'req_${DateTime.now().millisecondsSinceEpoch}',
    };

    final channel = _channels[clean];
    if (channel != null) {
      try {
        await channel.sendBroadcastMessage(
          event: 'request_chat_history',
          payload: payload,
        );
      } catch (_) {}
    }

    try {
      final global = _dispatchChannel ?? Supabase.instance.client.channel('rider_dispatch_chat');
      await global.sendBroadcastMessage(
        event: 'request_chat_history',
        payload: payload,
      );
    } catch (_) {}
  }

  void _handleHistoryRequest(Map<String, dynamic> payload) {
    try {
      final orderId = (payload['order_id'] ?? payload['orderId'] ?? '').toString();
      final clean = normalizeOrderId(orderId);
      final sender = (payload['sender'] ?? '').toString().toLowerCase();
      if (sender == 'customer' || sender == 'user') return;

      final currentMsgs = _orderChats[clean];
      if (currentMsgs == null || currentMsgs.isEmpty) return;

      final serialized = currentMsgs
          .where((m) => m['sender'] != 'system')
          .map((m) => {
                'id': m['id'],
                'order_id': clean,
                'orderId': clean,
                'sender': m['isMe'] == true ? 'customer' : 'rider',
                'sender_name': m['senderName'],
                'senderName': m['senderName'],
                'text': m['text'],
                'timestamp': m['timestamp'] ?? DateTime.now().toIso8601String(),
                'is_edited': m['isEdited'] == true,
                'is_unsent': m['isUnsent'] == true,
                'edited_at': m['editedAt'],
              })
          .toList();

      if (serialized.isEmpty) return;

      final responsePayload = {
        'order_id': clean,
        'orderId': clean,
        'sender': 'customer',
        'messages': serialized,
      };

      final channel = _channels[clean];
      if (channel != null) {
        channel.sendBroadcastMessage(
          event: 'sync_chat_history',
          payload: responsePayload,
        );
      }

      final global = _dispatchChannel ?? Supabase.instance.client.channel('rider_dispatch_chat');
      global.sendBroadcastMessage(
        event: 'sync_chat_history',
        payload: responsePayload,
      );
    } catch (e) {
      debugPrint('⚠️ Error answering history request: $e');
    }
  }

  void _handleHistorySync(Map<String, dynamic> payload) {
    try {
      final orderId = (payload['order_id'] ?? payload['orderId'] ?? '').toString();
      final clean = normalizeOrderId(orderId);
      final rawList = payload['messages'];
      if (rawList is! List || rawList.isEmpty) return;

      if (!_orderChats.containsKey(clean)) {
        _initSeedMessagesForOrder(clean);
      }

      final currentList = _orderChats[clean]!;
      bool addedAny = false;

      for (final item in rawList) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = (map['id'] ?? '').toString();
        if (id.isEmpty) continue;

        final exists = currentList.any((m) => m['id'] == id);
        if (!exists) {
          final sender = (map['sender'] ?? '').toString().toLowerCase();
          final isMe = sender == 'customer' || sender == 'user';
          final rawSenderName = (map['sender_name'] ?? map['senderName'] ?? (isMe ? 'Alex Rivera' : 'Pedro Jose Garcia')).toString();
          final senderName = rawSenderName.contains('Mark') && !isMe ? 'Pedro Jose Garcia' : rawSenderName;
          final timeStr = map['timestamp'] != null
              ? _formatIsoToTime(map['timestamp'].toString())
              : _getCurrentTime();

          currentList.add({
            'id': id,
            'orderId': clean,
            'sender': isMe ? 'user' : 'other',
            'senderName': senderName,
            'text': (map['text'] ?? '').toString(),
            'time': timeStr,
            'timestamp': (map['timestamp'] ?? DateTime.now().toIso8601String()).toString(),
            'isMe': isMe,
            'isEdited': map['is_edited'] == true || map['isEdited'] == true,
            'isUnsent': map['is_unsent'] == true || map['isUnsent'] == true,
            'editedAt': map['edited_at'] ?? map['editedAt'],
          });
          addedAny = true;
        }
      }

      if (addedAny) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Error processing history sync: $e');
    }
  }

  void _showTopNotification(Map<String, dynamic> msg) {
    try {
      final rawSenderName = (msg['senderName'] ?? 'Pedro Jose Garcia').toString();
      final senderName = rawSenderName.contains('Mark') ? 'Pedro Jose Garcia' : rawSenderName;
      final text = (msg['text'] ?? '').toString();
      final orderId = (msg['orderId'] ?? '').toString();

      InAppNotificationService.instance.showNotification(
        senderName: senderName,
        message: text,
        orderId: orderId,
        icon: Icons.two_wheeler_rounded,
        accentColor: const Color(0xFF00B4D8),
        onReply: () {
          final nav = InAppNotificationService.navigatorKey.currentState;
          if (nav != null) {
            nav.push(
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(
                  orderId: orderId,
                  title: '$senderName (Courier)',
                  subtitle: 'Courier • Active on route',
                  orderRef: '#$orderId',
                  avatarBgColor: const Color(0xFF00B4D8),
                  avatarIcon: Icons.two_wheeler_rounded,
                  initialMessages: getMessages(orderId),
                ),
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('⚠️ Error showing buyer top notification: $e');
    }
  }

  /// Unsubscribes from order channel
  Future<void> unsubscribeFromOrder(String orderId) async {
    final clean = normalizeOrderId(orderId);
    final channel = _channels.remove(clean);
    _channelReadyCompleters.remove(clean);
    if (channel != null && isSupabaseReady) {
      try {
        await Supabase.instance.client.removeChannel(channel);
      } catch (_) {}
    }
    _typingTimers[clean]?.cancel();
  }
}
