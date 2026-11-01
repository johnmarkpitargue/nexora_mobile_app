import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/services/profanity_filter_service.dart';
import 'package:nexora_rider_app/core/models/chat_message.dart';

void main() {
  group('Rider ProfanityFilterService Tests', () {
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
      expect(filter.hasProfanity('Hello maam, on the way na po ako with your order.'), isFalse);
      expect(filter.hasProfanity('I have arrived at your building lobby, thank you!'), isFalse);
      expect(filter.hasProfanity('Please prepare exact COD cash amount po.'), isFalse);
    });
  });

  group('RiderChatMessage 10-Minute Edit Window & Unsend Tests', () {
    test('Allows editing when message is sent by me and under 10 minutes old', () {
      final recentMsg = RiderChatMessage(
        id: 'msg_r_1',
        orderId: 'nx-8942-ord',
        sender: 'rider',
        senderName: 'Pedro Jose Garcia',
        text: 'On the way now!',
        time: DateTime.now().subtract(const Duration(minutes: 3)),
        isMe: true,
      );

      expect(recentMsg.canEdit, isTrue);
      expect(recentMsg.canUnsend, isTrue);
      expect(recentMsg.remainingEditMinutes, greaterThanOrEqualTo(6));
    });

    test('Disallows editing when message is older than 10 minutes', () {
      final expiredMsg = RiderChatMessage(
        id: 'msg_r_2',
        orderId: 'nx-8942-ord',
        sender: 'rider',
        senderName: 'Pedro Jose Garcia',
        text: 'Old dispatch update',
        time: DateTime.now().subtract(const Duration(minutes: 15)),
        isMe: true,
      );

      expect(expiredMsg.canEdit, isFalse);
      expect(expiredMsg.canUnsend, isTrue); // Can still unsend
      expect(expiredMsg.remainingEditMinutes, equals(0));
    });

    test('Disallows editing or unsending when already unsent or from other user', () {
      final unsentMsg = RiderChatMessage(
        id: 'msg_r_3',
        orderId: 'nx-8942-ord',
        sender: 'rider',
        senderName: 'Pedro Jose Garcia',
        text: 'You unsent a message',
        time: DateTime.now(),
        isMe: true,
        isUnsent: true,
      );
      expect(unsentMsg.canEdit, isFalse);
      expect(unsentMsg.canUnsend, isFalse);

      final customerMsg = RiderChatMessage(
        id: 'msg_c_4',
        orderId: 'nx-8942-ord',
        sender: 'customer',
        senderName: 'Alex Rivera',
        text: 'Hello rider',
        time: DateTime.now(),
        isMe: false,
      );
      expect(customerMsg.canEdit, isFalse);
      expect(customerMsg.canUnsend, isFalse);
    });
  });
}
