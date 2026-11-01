import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import 'in_app_notification_service.dart';
import 'rider_service.dart';
import '../../features/chat/presentation/rider_chat_screen.dart';

class RiderChatService extends ChangeNotifier {
  static final RiderChatService instance = RiderChatService._();

  RiderChatService._() {
    initGlobalDispatchListener();
  }

  RealtimeChannel? _dispatchChannel;
  RealtimeChannel? _ordersDbChannel;

  /// Ensures global dispatch listener is initialized once Supabase is ready
  void ensureInitialized() {
    initGlobalDispatchListener();
  }

  void initGlobalDispatchListener() {
    if (!isSupabaseReady) return;
    if (_dispatchChannel == null) {
      try {
        _dispatchChannel = Supabase.instance.client.channel('rider_dispatch_chat');
        _dispatchChannel!.onBroadcast(
          event: 'new_customer_message',
          callback: (payload) {
            try {
              final orderId = (payload['order_id'] ?? payload['orderId'] ?? '').toString();
              final clean = normalizeOrderId(orderId);
              if (clean.isEmpty) return;

              final sender = (payload['sender'] ?? '').toString().toLowerCase();
              if (sender == 'rider') return;

              final msg = RiderChatMessage.fromMap(
                Map<String, dynamic>.from(payload),
                currentSender: 'rider',
              );

              if (!_orderChats.containsKey(clean)) {
                _orderChats[clean] = [];
              }

              final list = _orderChats[clean]!;
              final exists = list.any((m) => m.id == msg.id);
              if (!exists) {
                list.add(msg);
                if (activeScreenOrderId != clean) {
                  _unreadCounts[clean] = (_unreadCounts[clean] ?? 0) + 1;
                  onNewMessageReceived?.call(msg);
                  _showTopNotification(msg);
                }
                notifyListeners();
              }
            } catch (e) {
              debugPrint('⚠️ Error parsing customer message from dispatch: $e');
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
        ).subscribe();
      } catch (_) {}
    }

    if (_ordersDbChannel == null) {
      try {
        _ordersDbChannel = Supabase.instance.client
            .channel('orders_rider_db_sync')
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
            .subscribe();
      } catch (_) {}
    }
  }

  final Map<String, List<RiderChatMessage>> _orderChats = {};
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, bool> _customerTyping = {};
  final Map<String, Timer?> _typingTimers = {};
  final Map<String, Completer<bool>> _channelReadyCompleters = {};
  final Map<String, int> _unreadCounts = {};

  /// Callback for showing in-app banner/notification when a message arrives
  void Function(RiderChatMessage msg)? onNewMessageReceived;

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
      final now = DateTime.now();
      _orderChats[clean] = [
        RiderChatMessage(
          id: 'init_${clean}_sys',
          orderId: clean,
          sender: 'system',
          senderName: 'Nexora Dispatch',
          text: 'Dispatch channel opened for order #$clean. Real-time encryption active.',
          time: now.subtract(const Duration(minutes: 5)),
          isMe: false,
        ),
      ];
    }
  }

  List<RiderChatMessage> getMessages(String orderId, {String customerName = 'Alex Rivera'}) {
    final clean = normalizeOrderId(orderId);
    if (!_orderChats.containsKey(clean) || _orderChats[clean]!.isEmpty) {
      _initSeedMessagesForOrder(clean);
    }
    return _orderChats[clean] ?? [];
  }

  bool isCustomerTyping(String orderId) {
    final clean = normalizeOrderId(orderId);
    return _customerTyping[clean] ?? false;
  }

  int getUnreadCount(String orderId) {
    final clean = normalizeOrderId(orderId);
    return _unreadCounts[clean] ?? 0;
  }

  int getTotalUnreadCount() {
    int total = 0;
    for (final count in _unreadCounts.values) {
      total += count;
    }
    return total;
  }

  void markAsRead(String orderId) {
    final clean = normalizeOrderId(orderId);
    if ((_unreadCounts[clean] ?? 0) > 0) {
      _unreadCounts[clean] = 0;
      notifyListeners();
    }
  }

  /// Subscribes to real-time chat updates for the specified order
  void subscribeToOrder(String orderId, {String customerName = 'Alex Rivera'}) {
    final clean = normalizeOrderId(orderId);
    if (clean.isEmpty) return;

    // Ensure initial dispatch notice seeded
    if (!_orderChats.containsKey(clean) || _orderChats[clean]!.isEmpty) {
      _initSeedMessagesForOrder(clean);
    }

    // Always fetch latest chat messages from Supabase remote storage
    syncRemoteMessages(clean);

    if (_channels.containsKey(clean)) return;

    if (!isSupabaseReady) {
      debugPrint('ℹ️ Supabase not yet initialized. Local chat active for $clean.');
      return;
    }

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
            if (sender == 'rider') return;

            final msg = RiderChatMessage.fromMap(
              Map<String, dynamic>.from(payload),
              currentSender: 'rider',
            );

            if (!_orderChats.containsKey(clean)) {
              _orderChats[clean] = [];
            }

            final list = _orderChats[clean]!;
            final exists = list.any((m) => m.id == msg.id);
            if (!exists) {
              list.add(msg);

              // Increment unread count if user is not actively viewing this chat
              if (activeScreenOrderId != clean) {
                _unreadCounts[clean] = (_unreadCounts[clean] ?? 0) + 1;
                onNewMessageReceived?.call(msg);
                _showTopNotification(msg);
              }

              // Customer finished sending, stop typing indicator
              _customerTyping[clean] = false;
              _typingTimers[clean]?.cancel();

              notifyListeners();
            }
          } catch (e) {
            debugPrint('⚠️ RiderChatService message parse error: $e');
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
            if (sender == 'rider') return;

            final isTyping = payload['is_typing'] == true || payload['isTyping'] == true;
            _customerTyping[clean] = isTyping;
            notifyListeners();

            _typingTimers[clean]?.cancel();
            if (isTyping) {
              _typingTimers[clean] = Timer(const Duration(seconds: 3), () {
                _customerTyping[clean] = false;
                notifyListeners();
              });
            }
          } catch (e) {
            debugPrint('⚠️ RiderChatService typing error: $e');
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
        debugPrint('📡 RiderChatService channel $channelName status: $status');
        if (status == RealtimeSubscribeStatus.subscribed) {
          if (!completer.isCompleted) completer.complete(true);
          requestHistory(clean);
        } else if (status == RealtimeSubscribeStatus.channelError || status == RealtimeSubscribeStatus.timedOut) {
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      _channels[clean] = channel;
    } catch (e) {
      debugPrint('⚠️ RiderChatService subscribe error: $e');
      if (!completer.isCompleted) completer.complete(false);
    }
  }

  /// Sends a real-time message from the rider or courier to the buyer
  Future<void> sendMessage(
    String orderId,
    String text, {
    String? riderName,
    String customerName = 'Alex Rivera',
    String? attachmentData,
    String? attachmentName,
    int? attachmentSize,
    String? attachmentType,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && (attachmentData == null || attachmentData.isEmpty)) return;

    final effectiveSenderName = (riderName != null && riderName.trim().isNotEmpty)
        ? riderName.trim()
        : RiderService.instance.profile.name;

    final clean = normalizeOrderId(orderId);
    final msg = RiderChatMessage(
      id: 'msg_r_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}',
      orderId: clean,
      sender: 'rider',
      senderName: effectiveSenderName,
      text: trimmed,
      time: DateTime.now(),
      isMe: true,
      attachmentData: attachmentData,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
      attachmentType: attachmentType,
    );

    if (!_orderChats.containsKey(clean)) {
      _orderChats[clean] = [];
    }
    _orderChats[clean]!.add(msg);
    notifyListeners();

    // Ensure subscribed to channel
    subscribeToOrder(orderId, customerName: customerName);

    // Wait briefly for channel readiness if subscribing for the first time
    final ready = _channelReadyCompleters[clean];
    if (ready != null && !ready.isCompleted) {
      try {
        await ready.future.timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    // Broadcast through Supabase channel if connected
    final channel = _channels[clean];
    if (channel != null) {
      try {
        await channel.sendBroadcastMessage(
          event: 'chat_message',
          payload: msg.toMap(),
        );
      } catch (e) {
        debugPrint('⚠️ RiderChatService broadcast send error: $e');
      }
    }

    // Also broadcast to global dispatch channel for real-time cross-order sync
    try {
      final global = _dispatchChannel ?? Supabase.instance.client.channel('rider_dispatch_chat');
      await global.sendBroadcastMessage(
        event: 'new_rider_message',
        payload: msg.toMap(),
      );
    } catch (_) {}

    // Persist to Supabase database so messages sync across APKs even if offline/backgrounded
    _persistMessageToSupabase(clean, msg.toMap());

    // Stop typing indicator after sending
    sendTyping(orderId, false);
  }

  /// Broadcasts typing indicator to customer
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
            'sender': 'rider',
            'is_typing': isTyping,
            'isTyping': isTyping,
          },
        );
      } catch (_) {}
    }
  }

  /// Edits an existing message sent by the rider if within 10 minutes
  Future<bool> editMessage(String orderId, String messageId, String newText) async {
    final clean = normalizeOrderId(orderId);
    final list = _orderChats[clean];
    if (list == null) return false;

    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx == -1) return false;

    final msg = list[idx];
    if (!msg.canEdit) return false;

    final now = DateTime.now();
    list[idx] = msg.copyWith(
      text: newText,
      isEdited: true,
      editedAt: now,
    );
    notifyListeners();

    final payload = {
      'id': messageId,
      'order_id': clean,
      'orderId': clean,
      'sender': 'rider',
      'text': newText,
      'is_edited': true,
      'isEdited': true,
      'edited_at': now.toIso8601String(),
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

    _persistRemoteEditToSupabase(clean, messageId, newText, now.toIso8601String());

    return true;
  }

  /// Unsends an existing message sent by the rider
  Future<bool> unsendMessage(String orderId, String messageId) async {
    final clean = normalizeOrderId(orderId);
    final list = _orderChats[clean];
    if (list == null) return false;

    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx == -1) return false;

    final msg = list[idx];
    if (!msg.canUnsend) return false;

    list[idx] = msg.copyWith(
      text: 'You unsent a message',
      isUnsent: true,
    );
    notifyListeners();

    final payload = {
      'id': messageId,
      'order_id': clean,
      'orderId': clean,
      'sender': 'rider',
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
      debugPrint('ℹ️ RiderChatService _persistMessageToSupabase notice: $e');
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
                  .map((e) => RiderChatMessage.fromMap(
                        Map<String, dynamic>.from(e as Map),
                        currentSender: 'rider',
                      ))
                  .toList();

              if (!_orderChats.containsKey(clean)) {
                _initSeedMessagesForOrder(clean);
              }
              final list = _orderChats[clean]!;
              bool changed = false;

              for (final rMsg in remoteList) {
                final idx = list.indexWhere((m) => m.id == rMsg.id);
                if (idx < 0) {
                  list.add(rMsg);
                  changed = true;
                  if (activeScreenOrderId != clean && rMsg.sender != 'rider') {
                    _unreadCounts[clean] = (_unreadCounts[clean] ?? 0) + 1;
                    onNewMessageReceived?.call(rMsg);
                  }
                } else {
                  if (list[idx].text != rMsg.text ||
                      list[idx].isEdited != rMsg.isEdited ||
                      list[idx].isUnsent != rMsg.isUnsent) {
                    list[idx] = rMsg;
                    changed = true;
                  }
                }
              }

              list.sort((a, b) {
                if (a.sender == 'system') return -1;
                if (b.sender == 'system') return 1;
                return a.time.compareTo(b.time);
              });

              if (changed) {
                notifyListeners();
              }
            }
          } catch (_) {}
        }
      }

      // Also try chat_messages table if present
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
            final rMsg = RiderChatMessage.fromMap(
              Map<String, dynamic>.from(r),
              currentSender: 'rider',
            );
            final idx = list.indexWhere((m) => m.id == rMsg.id);
            if (idx < 0) {
              list.add(rMsg);
              changed = true;
            }
          }
          if (changed) notifyListeners();
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('ℹ️ RiderChatService syncRemoteMessages notice: $e');
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
      final editedAt = payload['edited_at'] != null ? DateTime.tryParse(payload['edited_at'].toString()) : DateTime.now();

      final list = _orderChats[clean];
      if (list != null) {
        final idx = list.indexWhere((m) => m.id == msgId);
        if (idx != -1) {
          list[idx] = list[idx].copyWith(
            text: newText,
            isEdited: true,
            editedAt: editedAt,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('⚠️ RiderChatService remote edit parse error: $e');
    }
  }

  void _handleRemoteUnsend(Map<String, dynamic> payload) {
    try {
      final orderId = (payload['order_id'] ?? payload['orderId'] ?? '').toString();
      final clean = normalizeOrderId(orderId);
      final msgId = (payload['id'] ?? '').toString();

      final list = _orderChats[clean];
      if (list != null) {
        final idx = list.indexWhere((m) => m.id == msgId);
        if (idx != -1) {
          final isMe = list[idx].isMe;
          list[idx] = list[idx].copyWith(
            text: isMe ? 'You unsent a message' : 'This message was unsent',
            isUnsent: true,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('⚠️ RiderChatService remote unsend parse error: $e');
    }
  }

  /// Requests existing chat history for order from connected peers
  Future<void> requestHistory(String orderId) async {
    final clean = normalizeOrderId(orderId);
    if (clean.isEmpty) return;

    final payload = {
      'order_id': clean,
      'orderId': clean,
      'sender': 'rider',
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
      if (sender == 'rider') return;

      final currentMsgs = _orderChats[clean];
      if (currentMsgs == null || currentMsgs.isEmpty) return;

      final serialized = currentMsgs
          .where((m) => m.sender != 'system')
          .map((m) => m.toMap())
          .toList();

      if (serialized.isEmpty) return;

      final responsePayload = {
        'order_id': clean,
        'orderId': clean,
        'sender': 'rider',
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

        final exists = currentList.any((m) => m.id == id);
        if (!exists) {
          final newMsg = RiderChatMessage.fromMap(
            map,
            currentSender: 'rider',
          );
          currentList.add(newMsg);
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

  void _showTopNotification(RiderChatMessage msg) {
    try {
      InAppNotificationService.instance.showNotification(
        senderName: msg.senderName.isNotEmpty ? msg.senderName : 'Customer',
        message: msg.text,
        orderId: msg.orderId,
        icon: Icons.person_pin_circle_rounded,
        accentColor: const Color(0xFF0284C7),
        onReply: () {
          final nav = InAppNotificationService.navigatorKey.currentState;
          if (nav != null) {
            nav.push(
              MaterialPageRoute(
                builder: (_) => RiderChatScreen(
                  orderId: msg.orderId,
                  customerName: msg.senderName.isNotEmpty ? msg.senderName : 'Customer',
                ),
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('⚠️ Error showing rider top notification: $e');
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
