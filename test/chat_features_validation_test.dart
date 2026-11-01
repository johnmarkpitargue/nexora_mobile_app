import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/core/services/profanity_filter_service.dart';
import 'package:nexora_flutter_app/core/services/order_chat_service.dart';

void main() {
  group('ProfanityFilterService Tests', () {
    final filter = ProfanityFilterService.instance;

    test('Detects English profanities', () {
      expect(filter.hasProfanity('Hello, this is a fuck test'), isTrue);
      expect(filter.hasProfanity('You are a bitch'), isTrue);
      expect(filter.hasProfanity('bullshit item received'), isTrue);
    });

    test('Detects Tagalog / Filipino profanities and curses', () {
      expect(filter.hasProfanity('Ano ba yan gago ka'), isTrue);
      expect(filter.hasProfanity('tangina mo naman'), isTrue);
      expect(filter.hasProfanity('ang kupal mo kuya'), isTrue);
      expect(filter.hasProfanity('bobo naman ng rider'), isTrue);
      expect(filter.hasProfanity('putang ina'), isTrue);
    });

    test('Detects leetspeak and obfuscated variations', () {
      expect(filter.hasProfanity('f*ck this service'), isTrue);
      expect(filter.hasProfanity('sh!t delivery'), isTrue);
      expect(filter.hasProfanity('t@ngina'), isTrue);
      expect(filter.hasProfanity('g@go'), isTrue);
      expect(filter.hasProfanity('u10l'), isTrue);
    });

    test('Allows clean and respectful communications', () {
      expect(filter.hasProfanity('Hello kuya, on the way na po kayo?'), isFalse);
      expect(filter.hasProfanity('Please leave at the guard house, thank you!'), isFalse);
      expect(filter.hasProfanity('Exact cash is ready po.'), isFalse);
      expect(filter.hasProfanity('Good day, I am waiting at the lobby.'), isFalse);
    });
  });

  group('OrderChatService 10-Minute Edit Window & Unsend Tests', () {
    final chatService = OrderChatService.instance;

    test('Allows editing when message is under 10 minutes old', () {
      final recentMsg = {
        'id': 'msg_test_1',
        'isMe': true,
        'isUnsent': false,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 4)).toIso8601String(),
        'text': 'Initial message',
      };

      expect(chatService.canEditMessage(recentMsg), isTrue);
      expect(chatService.getRemainingEditMinutes(recentMsg), greaterThanOrEqualTo(5));
    });

    test('Disallows editing when message is older than 10 minutes', () {
      final expiredMsg = {
        'id': 'msg_test_2',
        'isMe': true,
        'isUnsent': false,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String(),
        'text': 'Old message',
      };

      expect(chatService.canEditMessage(expiredMsg), isFalse);
      expect(chatService.getRemainingEditMinutes(expiredMsg), equals(0));
    });

    test('Disallows editing when message is from other user or unsent', () {
      final otherMsg = {
        'id': 'msg_test_3',
        'isMe': false,
        'sender': 'other',
        'isUnsent': false,
        'timestamp': DateTime.now().toIso8601String(),
        'text': 'Other message',
      };
      expect(chatService.canEditMessage(otherMsg), isFalse);

      final unsentMsg = {
        'id': 'msg_test_4',
        'isMe': true,
        'isUnsent': true,
        'timestamp': DateTime.now().toIso8601String(),
        'text': 'You unsent a message',
      };
      expect(chatService.canEditMessage(unsentMsg), isFalse);
    });
  });
}
