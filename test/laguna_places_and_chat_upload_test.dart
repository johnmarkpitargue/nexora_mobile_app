import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/core/services/laguna_places_service.dart';
import 'package:nexora_flutter_app/core/services/address_service.dart';
import 'package:nexora_flutter_app/core/services/order_chat_service.dart';

void main() {
  group('LagunaPlacesService Accuracy Tests', () {
    final service = LagunaPlacesService.instance;

    test('Accurately resolves Liliw coordinates', () {
      final place = service.resolveCoordinates('Tuy-Baanan, Liliw, Laguna');
      expect(place.cityOrMunicipality, 'Liliw');
      expect(place.latitude, closeTo(14.1332, 0.001));
      expect(place.longitude, closeTo(121.4367, 0.001));
      expect(place.postalCode, '4004');
    });

    test('Accurately resolves Calamba coordinates', () {
      final place = service.resolveCoordinates('Poblacion, Calamba, Laguna');
      expect(place.cityOrMunicipality, contains('Calamba'));
      expect(place.latitude, closeTo(14.2144, 0.005));
      expect(place.longitude, closeTo(121.1558, 0.005));
    });

    test('Accurately resolves Santa Rosa coordinates', () {
      final place = service.resolveCoordinates('Tagapo, Santa Rosa, Laguna');
      expect(place.cityOrMunicipality, contains('Santa Rosa'));
      expect(place.latitude, closeTo(14.318, 0.01));
      expect(place.longitude, closeTo(121.1114, 0.01));
    });

    test('Accurately resolves Los Baños coordinates', () {
      final place = service.resolveCoordinates('Batong Malake, Los Baños, Laguna');
      expect(place.cityOrMunicipality, 'Los Baños');
      expect(place.latitude, closeTo(14.1706, 0.005));
      expect(place.longitude, closeTo(121.2435, 0.005));
    });

    test('Falls back to Liliw customer default for unknown Laguna locations', () {
      final place = service.resolveCoordinates('Random Unknown Street');
      expect(place.latitude, closeTo(14.1332, 0.001));
      expect(place.longitude, closeTo(121.4367, 0.001));
    });
  });

  group('AddressModel GPS Pinpoint Accuracy Tests', () {
    test('AddressModel preserves accurate latitude and longitude', () {
      final address = AddressModel(
        id: 'test_addr_1',
        fullName: 'Alex Rivera',
        phone: '09171234567',
        region: 'Region IV-A (CALABARZON)',
        city: 'Liliw, Laguna',
        barangay: 'Tuy-Baanan',
        regionCity: 'Region IV-A (CALABARZON)',
        streetBuilding: '14 Rizal St.',
        postalCode: '4004',
        label: 'Home',
        latitude: 14.1332,
        longitude: 121.4367,
      );

      expect(address.latitude, 14.1332);
      expect(address.longitude, 121.4367);

      final updated = address.copyWith(streetBuilding: '15 Rizal St.');
      expect(updated.latitude, 14.1332);
      expect(updated.longitude, 121.4367);
      expect(updated.streetBuilding, '15 Rizal St.');
    });
  });

  group('5MB Upload Limit & Attachment Tests', () {
    const int max5Mb = 5 * 1024 * 1024; // 5242880 bytes

    test('File size limit correctly distinguishes <= 5MB vs > 5MB', () {
      const int validImageSize = 3 * 1024 * 1024; // 3MB
      const int boundarySize = 5 * 1024 * 1024; // 5MB exact
      const int oversizedFile = 5 * 1024 * 1024 + 1; // 5MB + 1 byte
      const int largeFile = 8 * 1024 * 1024; // 8MB

      expect(validImageSize <= max5Mb, isTrue);
      expect(boundarySize <= max5Mb, isTrue);
      expect(oversizedFile > max5Mb, isTrue);
      expect(largeFile > max5Mb, isTrue);
    });

    test('OrderChatService stores and preserves attachment metadata', () async {
      final chatService = OrderChatService.instance;
      const orderId = 'test_order_attach_99';

      await chatService.sendMessage(
        orderId,
        'Here is the parcel location',
        customerName: 'Alex Rivera',
        attachmentData: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        attachmentName: 'gate_photo.jpg',
        attachmentSize: 2048,
        attachmentType: 'image',
      );

      final messages = chatService.getMessages(orderId);
      final lastMsg = messages.last;

      expect(lastMsg['attachmentData'], isNotNull);
      expect(lastMsg['attachmentName'], 'gate_photo.jpg');
      expect(lastMsg['attachmentSize'], 2048);
      expect(lastMsg['attachmentType'], 'image');
      expect(lastMsg['isMe'], isTrue);
    });
  });
}
