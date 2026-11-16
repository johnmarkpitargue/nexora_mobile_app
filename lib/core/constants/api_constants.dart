/// API Constants for Nexora Marketplace Rider App
/// Single source of truth pointing to the HTTPS Laravel backend.
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'NEXORA_API_BASE_URL',
    defaultValue: 'https://nexoramarket.store',
  );

  // Auth
  static const String riderLogin = '/api/mobile/v1/auth/rider/login';
  static String riderActivate(String token) =>
      '/api/mobile/v1/auth/rider/activate/$token';
  static const String me = '/api/mobile/v1/auth/me';
  static const String logout = '/api/mobile/v1/auth/logout';

  // Rider Operations
  static const String profile = '/api/mobile/v1/rider/profile';
  static const String riderProfile = profile;
  static const String availability = '/api/mobile/v1/rider/availability';
  static const String toggleAvailability = availability;
  static const String hubs = '/api/mobile/v1/rider/hubs';
  static const String selectHub = '/api/mobile/v1/rider/hub/select';
  static const String offers = '/api/mobile/v1/rider/offers';
  static const String riderOffers = offers;
  static const String availableDeliveries =
      '/api/mobile/v1/rider/deliveries/available';
  static String acceptOffer(dynamic offerId) =>
      '/api/mobile/v1/rider/offers/$offerId/accept';
  static String declineOffer(dynamic offerId) =>
      '/api/mobile/v1/rider/offers/$offerId/decline';
  static const String pickup = '/api/mobile/v1/rider/pickup';
  static const String confirmPickup = pickup;
  static const String activeDeliveries =
      '/api/mobile/v1/rider/deliveries/active';
  static const String deliveryHistory =
      '/api/mobile/v1/rider/deliveries/history';
  static String showDelivery(dynamic orderId) =>
      '/api/mobile/v1/rider/deliveries/$orderId';
  static String startDelivery(dynamic orderId) =>
      '/api/mobile/v1/rider/deliveries/$orderId/start';
  static String completeDelivery(dynamic orderId) =>
      '/api/mobile/v1/rider/deliveries/$orderId/complete';
  static String deliver(dynamic orderId) =>
      '/api/mobile/v1/rider/deliveries/$orderId/deliver';
  static String failDelivery(dynamic orderId) =>
      '/api/mobile/v1/rider/deliveries/$orderId/fail';
  static const String earnings = '/api/mobile/v1/rider/earnings';
  static const String riderEarnings = earnings;
  static const String riderPayouts = '/api/mobile/v1/rider/payouts';
  static const String riderCodCollections = '/api/mobile/v1/rider/cod-collections';
  static const String remittance = '/api/mobile/v1/rider/remittance';
  static const String submitRemittance = remittance;

  // Transfer Courier Operations
  static const String transferCourierDashboard =
      '/api/mobile/v1/transfer-courier/dashboard';
  static const String transferCourierProfile =
      '/api/mobile/v1/transfer-courier/profile';
  static const String transferCourierEarnings =
      '/api/mobile/v1/transfer-courier/earnings';
  static const String transferCourierPayouts =
      '/api/mobile/v1/transfer-courier/payouts';
  static const String transferCourierInventory =
      '/api/mobile/v1/transfer-courier/inventory';
  static const String transferCourierManifests =
      '/api/mobile/v1/transfer-courier/manifests';
  static String transferCourierManifestDetail(dynamic id) =>
      '/api/mobile/v1/transfer-courier/manifests/$id';
  static String transferCourierManifestInventory(dynamic id) =>
      '/api/mobile/v1/transfer-courier/manifests/$id/inventory';
  static String transferCourierManifestScan(dynamic id) =>
      '/api/mobile/v1/transfer-courier/manifests/$id/scan';
  static String transferCourierManifestDepart(dynamic id) =>
      '/api/mobile/v1/transfer-courier/manifests/$id/depart';
  static String transferCourierManifestArrive(dynamic id) =>
      '/api/mobile/v1/transfer-courier/manifests/$id/arrive';
  static String transferCourierManifestReportIssue(dynamic id) =>
      '/api/mobile/v1/transfer-courier/manifests/$id/report-issue';

  // Rider Parcel Lookup & Shared Notifications
  static const String riderLookup = '/api/mobile/v1/rider/lookup';
  static const String notifications = '/api/mobile/v1/notifications';
  static const String readAllNotifications =
      '/api/mobile/v1/notifications/read-all';
  static String readNotification(dynamic id) =>
      '/api/mobile/v1/notifications/$id/read';

  // Safety & Reports Center
  static const String safetyReports = '/api/mobile/v1/safety-reports';
  static String safetyReportDetail(dynamic id) =>
      '/api/mobile/v1/safety-reports/$id';
  static const String restrictions = '/api/mobile/v1/restrictions';
  static String appealRestriction(dynamic id) =>
      '/api/mobile/v1/restrictions/$id/appeal';
}
