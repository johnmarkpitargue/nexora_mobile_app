import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/services/laguna_places_service.dart';
import 'package:nexora_rider_app/core/models/delivery_order.dart';
import 'package:nexora_rider_app/core/models/chat_message.dart';

void main() {
  group('Rider App Laguna Places & Geocoding Tests', () {
    final service = LagunaPlacesService.instance;

    test('Accurately resolves Liliw delivery coordinates', () {
      final place = service.resolveCoordinates('Tuy-Baanan, Liliw, Laguna');
      expect(place.cityOrMunicipality, 'Liliw');
      expect(place.latitude, closeTo(14.1332, 0.001));
      expect(place.longitude, closeTo(121.4367, 0.001));
      expect(place.postalCode, '4004');
    });

    test('Accurately resolves Calamba and Santa Rosa', () {
      final calamba = service.resolveCoordinates('Poblacion, Calamba, Laguna');
      expect(calamba.cityOrMunicipality, contains('Calamba'));
      expect(calamba.latitude, closeTo(14.2144, 0.01));

      final staRosa = service.resolveCoordinates('Balibago, Santa Rosa, Laguna');
      expect(staRosa.cityOrMunicipality, contains('Santa Rosa'));
      expect(staRosa.latitude, closeTo(14.2965, 0.01));
    });

    test('DeliveryOrder defaults to accurate Liliw coordinates', () {
      final order = DeliveryOrder(
        id: 'NX-TEST-01',
        customerName: 'Alex Rivera',
        customerPhone: '09171234567',
        customerAddress: 'Tuy-Baanan, Liliw, Laguna',
        orderTotal: 500.0,
        deliveryFee: 65.0,
        paymentType: 'Cash on Delivery',
        distanceKm: 2.5,
        estimatedMinutes: 15,
        createdAt: DateTime.now(),
        status: DeliveryStatus.available,
        merchantAddress: 'Nexora Hub, Laguna',
        merchantName: 'Nexora Store',
        merchantPhone: '09181234567',
        items: [],
      );

      expect(order.customerLat, closeTo(14.1332, 0.001));
      expect(order.customerLng, closeTo(121.4367, 0.001));
    });
  });

  group('Rider Chat 5MB Limit & Attachment Model Tests', () {
    const int max5Mb = 5 * 1024 * 1024; // 5MB

    test('5MB limit enforcement', () {
      expect(2 * 1024 * 1024 <= max5Mb, isTrue);
      expect(5 * 1024 * 1024 <= max5Mb, isTrue);
      expect((5 * 1024 * 1024) + 1 > max5Mb, isTrue);
      expect(10 * 1024 * 1024 > max5Mb, isTrue);
    });

    test('RiderChatMessage attachment properties', () {
      final msg = RiderChatMessage(
        id: 'msg_test_01',
        orderId: 'NX-TEST-01',
        sender: 'rider',
        senderName: 'Pedro Jose Garcia',
        text: 'Parcel has arrived at your gate',
        time: DateTime.now(),
        isMe: true,
        attachmentData: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        attachmentName: 'doorstep.png',
        attachmentSize: 1048576, // 1MB
        attachmentType: 'image',
      );

      expect(msg.hasAttachment, isTrue);
      expect(msg.isImageAttachment, isTrue);
      expect(msg.formattedAttachmentSize, '1.00 MB');
      expect(msg.attachmentName, 'doorstep.png');

      final map = msg.toMap();
      expect(map['attachment_data'], isNotNull);
      expect(map['attachment_name'], 'doorstep.png');
      expect(map['attachment_size'], 1048576);

      final restored = RiderChatMessage.fromMap(map, currentSender: 'rider');
      expect(restored.hasAttachment, isTrue);
      expect(restored.isImageAttachment, isTrue);
      expect(restored.formattedAttachmentSize, '1.00 MB');
    });
  });
}
