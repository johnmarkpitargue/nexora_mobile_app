/// API Constants for Nexora Marketplace Mobile Apps
/// Points to the HTTPS Laravel backend behind Cloudflare Tunnel.
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'NEXORA_API_BASE_URL',
    defaultValue: 'https://nexoramarket.store',
  );

  // Auth endpoints
  static const String buyerLogin = '/api/mobile/v1/auth/buyer/login';
  static const String buyerRegister = '/api/mobile/v1/auth/buyer/register';
  static const String verifyEmailOtp = '/api/mobile/v1/auth/buyer/email/verify';
  static const String resendEmailOtp = '/api/mobile/v1/auth/buyer/email/resend';
  static const String me = '/api/mobile/v1/auth/me';
  static const String logout = '/api/mobile/v1/auth/logout';

  // Buyer Endpoints
  static const String buyerAccount = '/api/mobile/v1/buyer/account';
  static const String updateProfile = '/api/mobile/v1/buyer/account/profile';
  static const String updatePassword = '/api/mobile/v1/buyer/account/password';
  static const String requestEmailOtp = '/api/mobile/v1/buyer/account/email/request-otp';
  static const String verifyEmailChangeOtp = '/api/mobile/v1/buyer/account/email/verify-otp';
  static const String requestPhoneOtp = '/api/mobile/v1/buyer/account/phone/request-otp';
  static const String verifyPhoneChangeOtp = '/api/mobile/v1/buyer/account/phone/verify-otp';

  // Address
  static const String buyerAddresses = '/api/mobile/v1/buyer/addresses';
  static String buyerAddressDetail(dynamic id) => '/api/mobile/v1/buyer/addresses/$id';
  static String buyerAddressDefault(dynamic id) => '/api/mobile/v1/buyer/addresses/$id/default';

  // PSGC Locations
  static const String provinces = '/api/locations/provinces';
  static String cities(dynamic provinceCode) => '/api/locations/provinces/$provinceCode/cities';
  static String barangays(dynamic cityCode) => '/api/locations/cities/$cityCode/barangays';

  // Catalog & Product
  static const String catalog = '/api/mobile/v1/buyer/catalog';
  static const String buyerCatalog = catalog;
  static const String categories = '/api/mobile/v1/buyer/categories';
  static String productDetail(dynamic id) => '/api/mobile/v1/buyer/products/$id';
  static String buyerProduct(dynamic id) => productDetail(id);
  static String storeDetail(dynamic id) => '/api/mobile/v1/buyer/stores/$id';
  static String buyerStore(dynamic id) => storeDetail(id);

  // Wishlist & Follow
  static const String wishlist = '/api/mobile/v1/buyer/wishlist';
  static const String buyerWishlist = wishlist;
  static String toggleWishlist(dynamic productId) => '/api/mobile/v1/buyer/wishlist/$productId/toggle';
  static String buyerWishlistToggle(dynamic productId) => toggleWishlist(productId);
  static const String followedStores = '/api/mobile/v1/buyer/stores/followed';
  static String toggleStoreFollow(dynamic sellerId) => '/api/mobile/v1/buyer/stores/$sellerId/follow-toggle';
  static String buyerStoreFollowToggle(dynamic sellerId) => toggleStoreFollow(sellerId);

  // Vouchers
  static const String vouchers = '/api/mobile/v1/buyer/vouchers';
  static const String buyerVouchers = vouchers;
  static String claimVoucher(dynamic voucherId) => '/api/mobile/v1/buyer/vouchers/$voucherId/claim';
  static String buyerVoucherClaim(dynamic voucherId) => claimVoucher(voucherId);

  // Cart
  static const String cart = '/api/mobile/v1/buyer/cart';
  static const String buyerCart = cart;
  static const String cartItems = '/api/mobile/v1/buyer/cart/items';
  static const String buyerCartItems = cartItems;
  static String cartItem(dynamic id) => '/api/mobile/v1/buyer/cart/items/$id';
  static String buyerCartItem(dynamic id) => cartItem(id);
  static const String cartSelectAll = '/api/mobile/v1/buyer/cart/select-all';
  static const String buyerCartSelectAll = cartSelectAll;
  static String cartSelectStore(dynamic sellerId) => '/api/mobile/v1/buyer/cart/select-store/$sellerId';

  // Checkout
  static const String checkoutSummary = '/api/mobile/v1/buyer/checkout/summary';
  static const String checkout = '/api/mobile/v1/buyer/checkout';
  static const String buyerCheckout = checkout;

  // Orders
  static const String orders = '/api/mobile/v1/buyer/orders';
  static const String buyerOrders = orders;
  static String orderDetail(dynamic id) => '/api/mobile/v1/buyer/orders/$id';
  static String buyerOrder(dynamic id) => orderDetail(id);
  static String cancelOrder(dynamic id) => '/api/mobile/v1/buyer/orders/$id/cancel';
  static String buyerOrderCancel(dynamic id) => cancelOrder(id);
  static String confirmReceipt(dynamic id) => '/api/mobile/v1/buyer/orders/$id/confirm-receipt';
  static String buyerOrderConfirmReceipt(dynamic id) => confirmReceipt(id);
  static String returnOrder(dynamic id) => '/api/mobile/v1/buyer/orders/$id/return';
  static String buyerOrderReturn(dynamic id) => returnOrder(id);
  static String reviewOrder(dynamic id) => '/api/mobile/v1/buyer/orders/$id/review';
  static String buyerOrderReview(dynamic id) => reviewOrder(id);

  // Chat
  static const String chat = '/api/mobile/v1/buyer/chat';
  static const String buyerChat = chat;
  static String chatConversation(dynamic id) => '/api/mobile/v1/buyer/chat/$id';
  static String buyerChatConversation(dynamic id) => chatConversation(id);
  static const String startChat = '/api/mobile/v1/buyer/chat/start';
  static const String buyerChatStart = startChat;
  static String sendMessage(dynamic id) => '/api/mobile/v1/buyer/chat/$id/message';
  static String buyerChatMessage(dynamic id) => sendMessage(id);
}
