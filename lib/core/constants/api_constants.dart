/// API Constants for Nexora Marketplace Rider App
/// Single source of truth pointing to the HTTPS Laravel backend.
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'NEXORA_API_BASE_URL',
    defaultValue: 'https://nexoramarket.store',
  );

  // Auth
  static const String riderLogin = '/api/mobile/v1/auth/rider/login';
  static String riderActivate(String token) => '/api/mobile/v1/auth/rider/activate/$token';
  static const String me = '/api/mobile/v1/auth/me';
  static const String logout = '/api/mobile/v1/auth/logout';

  // Rider Operations
  static const String profile = '/api/mobile/v1/rider/profile';
  static const String riderProfile = profile;
  static const String availability = '/api/mobile/v1/rider/availability';
  static const String toggleAvailability = availability;
  static const String offers = '/api/mobile/v1/rider/offers';
  static const String riderOffers = offers;
  static String acceptOffer(dynamic offerId) => '/api/mobile/v1/rider/offers/$offerId/accept';
  static String declineOffer(dynamic offerId) => '/api/mobile/v1/rider/offers/$offerId/decline';
  static const String pickup = '/api/mobile/v1/rider/pickup';
  static const String confirmPickup = pickup;
  static const String activeDeliveries = '/api/mobile/v1/rider/deliveries/active';
  static const String deliveryHistory = '/api/mobile/v1/rider/deliveries/history';
  static String completeDelivery(dynamic orderId) => '/api/mobile/v1/rider/deliveries/$orderId/complete';
  static String failDelivery(dynamic orderId) => '/api/mobile/v1/rider/deliveries/$orderId/fail';
  static const String earnings = '/api/mobile/v1/rider/earnings';
  static const String riderEarnings = earnings;
  static const String remittance = '/api/mobile/v1/rider/remittance';
  static const String submitRemittance = remittance;
}

