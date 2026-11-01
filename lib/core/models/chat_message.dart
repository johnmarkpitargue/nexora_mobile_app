class RiderChatMessage {
  final String id;
  final String orderId;
  final String sender; // 'rider', 'customer', 'system'
  final String senderName;
  final String text;
  final DateTime time;
  final bool isMe;
  final bool isEdited;
  final bool isUnsent;
  final DateTime? editedAt;
  final String? attachmentData; // Base64 data string
  final String? attachmentName;
  final int? attachmentSize; // Size in bytes
  final String? attachmentType; // 'image', 'file'

  const RiderChatMessage({
    required this.id,
    required this.orderId,
    required this.sender,
    this.senderName = '',
    required this.text,
    required this.time,
    required this.isMe,
    this.isEdited = false,
    this.isUnsent = false,
    this.editedAt,
    this.attachmentData,
    this.attachmentName,
    this.attachmentSize,
    this.attachmentType,
  });

  /// Check if this message has an attachment
  bool get hasAttachment => attachmentData != null && attachmentData!.isNotEmpty;

  /// Check if attachment is an image
  bool get isImageAttachment {
    if (!hasAttachment) return false;
    final type = attachmentType?.toLowerCase() ?? '';
    final name = attachmentName?.toLowerCase() ?? '';
    return type == 'image' ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        attachmentData!.startsWith('data:image');
  }

  /// Human readable attachment size badge
  String get formattedAttachmentSize {
    if (attachmentSize == null || attachmentSize == 0) return '';
    final kb = attachmentSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  /// Check if this message was sent by the user and is still under 10 minutes old
  bool get canEdit {
    if (!isMe || isUnsent) return false;
    return DateTime.now().difference(time).inMinutes < 10;
  }

  /// Check if this message can be unsent by the user
  bool get canUnsend {
    return isMe && !isUnsent;
  }

  /// Remaining minutes under the 10-minute edit limit
  int get remainingEditMinutes {
    if (!isMe || isUnsent) return 0;
    final diff = DateTime.now().difference(time).inMinutes;
    return (10 - diff).clamp(0, 10);
  }

  String get formattedTime {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  RiderChatMessage copyWith({
    String? id,
    String? orderId,
    String? sender,
    String? senderName,
    String? text,
    DateTime? time,
    bool? isMe,
    bool? isEdited,
    bool? isUnsent,
    DateTime? editedAt,
    String? attachmentData,
    String? attachmentName,
    int? attachmentSize,
    String? attachmentType,
  }) {
    return RiderChatMessage(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      sender: sender ?? this.sender,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      time: time ?? this.time,
      isMe: isMe ?? this.isMe,
      isEdited: isEdited ?? this.isEdited,
      isUnsent: isUnsent ?? this.isUnsent,
      editedAt: editedAt ?? this.editedAt,
      attachmentData: attachmentData ?? this.attachmentData,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentSize: attachmentSize ?? this.attachmentSize,
      attachmentType: attachmentType ?? this.attachmentType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'orderId': orderId,
      'sender': sender,
      'sender_name': senderName,
      'senderName': senderName,
      'text': text,
      'timestamp': time.toIso8601String(),
      'is_edited': isEdited,
      'is_unsent': isUnsent,
      'edited_at': editedAt?.toIso8601String(),
      'attachment_data': attachmentData,
      'attachment_name': attachmentName,
      'attachment_size': attachmentSize,
      'attachment_type': attachmentType,
    };
  }

  factory RiderChatMessage.fromMap(
    Map<String, dynamic> map, {
    String currentSender = 'rider',
  }) {
    final senderStr = (map['sender'] ?? 'customer').toString().toLowerCase();
    final timeStr = map['timestamp']?.toString() ?? map['time']?.toString();
    DateTime parsedTime;
    if (timeStr != null) {
      parsedTime = DateTime.tryParse(timeStr) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    DateTime? parsedEditedAt;
    if (map['edited_at'] != null) {
      parsedEditedAt = DateTime.tryParse(map['edited_at'].toString());
    }

    final rawOrderId = (map['order_id'] ?? map['orderId'] ?? '').toString();
    final rawSenderName = (map['sender_name'] ?? map['senderName'] ?? (senderStr == 'rider' ? 'Rider' : 'Customer')).toString();

    final isUnsentVal = map['is_unsent'] == true || map['isUnsent'] == true;
    final isEditedVal = map['is_edited'] == true || map['isEdited'] == true;

    return RiderChatMessage(
      id: (map['id'] ?? 'msg_${DateTime.now().millisecondsSinceEpoch}').toString(),
      orderId: rawOrderId,
      sender: senderStr,
      senderName: rawSenderName,
      text: (map['text'] ?? '').toString(),
      time: parsedTime,
      isMe: senderStr == currentSender,
      isEdited: isEditedVal,
      isUnsent: isUnsentVal,
      editedAt: parsedEditedAt,
      attachmentData: (map['attachment_data'] ?? map['attachmentData'])?.toString(),
      attachmentName: (map['attachment_name'] ?? map['attachmentName'])?.toString(),
      attachmentSize: (map['attachment_size'] ?? map['attachmentSize']) as int?,
      attachmentType: (map['attachment_type'] ?? map['attachmentType'])?.toString(),
    );
  }
}
