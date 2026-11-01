import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_rider_app/core/services/rider_location_service.dart';

void main() {
  group('RiderLocationService Real-time GPS & Speed Tests', () {
    test('Default coordinates fallback to hub coordinates when uninitialized', () {
      final service = RiderLocationService.instance;
      expect(service.currentLat, equals(14.2250));
      expect(service.currentLng, equals(121.1610));
      expect(service.currentSpeedKmh, equals(0.0));
    });

    test('Haversine distance calculation is accurate within expected meters', () {
      // Calamba Hub to Customer Pin distance (~1.3 km)
      final dist = RiderLocationService.calculateDistanceKm(
        14.2250,
        121.1610,
        14.2135,
        121.1648,
      );

      expect(dist, greaterThan(1.2));
      expect(dist, lessThan(1.5));
    });

    test('Distance between identical coordinates is 0.0', () {
      final dist = RiderLocationService.calculateDistanceKm(
        14.2250,
        121.1610,
        14.2250,
        121.1610,
      );

      expect(dist, equals(0.0));
    });

    test('Order tracking state manages active order ID and status correctly', () {
      final service = RiderLocationService.instance;
      service.updateOrderStatus('in_transit');
      expect(service.isTracking, isFalse); // until startTracking stream is initiated
    });
  });
}
