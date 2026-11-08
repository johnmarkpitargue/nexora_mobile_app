import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/core/network/api_client.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexora_flutter_app/core/models/shop_models.dart';
import 'package:nexora_flutter_app/core/services/chat_service.dart';
import 'package:nexora_flutter_app/features/chat/presentation/chat_detail_page.dart';
import 'package:nexora_flutter_app/features/chat/presentation/chat_page.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/product_card.dart';
import 'package:nexora_flutter_app/features/product_details/presentation/product_details_page.dart';
import 'package:nexora_flutter_app/features/shop/presentation/shop_page.dart';

final _transparentPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends StreamView<List<int>> with Fake implements HttpClientResponse {
  _MockHttpClientResponse() : super(Stream<List<int>>.fromIterable([_transparentPng]));

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPng.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    BuyerAccountService.instance.resetState();
    BuyerAccountService.instance.seedLoggedInBuyer(
      firstName: 'Juan',
      lastName: 'Dela Cruz',
      email: 'chat.buyer@nexora.com',
      mobileNumber: '09171234567',
      password: 'Password@123',
    );
    await ApiClient.instance.saveToken('test-chat-token');
  });

  group('ChatService Shop Messaging & Slider State Tests', () {
    test('getOrCreateShopConversation creates a new conversation with store context', () {
      final chatService = ChatService.instance;
      final conv = chatService.getOrCreateShopConversation(
        shopId: 'brand_sony_official',
        shopName: 'Sony Official Store',
        shopBadge: 'NEXORA MALL',
        initialProductSnippet: 'Sony WH-1000XM5',
      );

      expect(conv.id, contains('brand_sony_official'));
      expect(conv.title, 'Sony Official Store');
      expect(conv.brandTag, 'BRAND');
      expect(conv.itemTag, 'Sony WH-1000XM5');
      expect(chatService.conversations.any((c) => c.title == 'Sony Official Store'), isTrue);
    });

    test('hideConversation moves conversation to hidden list and unhide restores it', () {
      final chatService = ChatService.instance;
      final conv = chatService.getOrCreateShopConversation(
        shopId: 'test_hide_shop',
        shopName: 'Test Hide Shop',
      );

      expect(chatService.conversations.any((c) => c.id == conv.id), isTrue);
      expect(chatService.hiddenConversations.any((c) => c.id == conv.id), isFalse);

      // Hide conversation
      chatService.hideConversation(conv.id);
      expect(chatService.conversations.any((c) => c.id == conv.id), isFalse);
      expect(chatService.hiddenConversations.any((c) => c.id == conv.id), isTrue);

      // Unhide conversation
      chatService.unhideConversation(conv.id);
      expect(chatService.conversations.any((c) => c.id == conv.id), isTrue);
      expect(chatService.hiddenConversations.any((c) => c.id == conv.id), isFalse);
    });

    test('deleteConversation marks conversation as deleted and removes from active and hidden', () {
      final chatService = ChatService.instance;
      final conv = chatService.getOrCreateShopConversation(
        shopId: 'test_delete_shop',
        shopName: 'Test Delete Shop',
      );

      chatService.deleteConversation(conv.id);
      expect(chatService.conversations.any((c) => c.id == conv.id), isFalse);
      expect(chatService.hiddenConversations.any((c) => c.id == conv.id), isFalse);
    });
  });

  group('ShopPage & ProductDetailsPage Direct Messaging Tests', () {
    testWidgets('Tapping Chat on ShopPage opens ChatDetailPage with that shop', (tester) async {
      const testShop = ShopModel(
        id: 'razer_flagship',
        name: 'Razer Flagship Store',
        badge: 'OFFICIAL STORE',
        followers: '85.2K',
        initials: 'RZ',
        categoryGroupTitle: 'GAMING PERIPHERALS',
        categories: [],
        vouchers: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopPage(initialShop: testShop),
        ),
      );
      await tester.pumpAndSettle();

      // Find Chat button in ShopPage header
      final chatButton = find.text('Chat');
      expect(chatButton, findsOneWidget);

      await tester.tap(chatButton);
      await tester.pumpAndSettle();

      // Should have pushed ChatDetailPage with Razer Flagship Store
      expect(find.byType(ChatDetailPage), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Razer Flagship Store')),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Chat icon on ProductDetailsPage opens ChatDetailPage with product shop', (tester) async {
      const testProduct = ProductModel(
        id: 'p_keyboard_test',
        title: 'Keychron Q1 Pro Mechanical Keyboard',
        imageUrl: 'https://example.com/keyboard.jpg',
        category: 'Electronics',
        price: '₱9,990',
        rating: 4.9,
        soldCount: '1.2k sold',
        shippingTag: 'Free Shipping',
        shopId: 'keychron_store',
        shopName: 'Keychron Official',
        shopBadge: 'NEXORA MALL',
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/pdp',
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              settings: const RouteSettings(name: '/pdp', arguments: testProduct),
              builder: (context) => const ProductDetailsPage(),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Find Chat Icon Button in bottom dock
      final chatIcon = find.byIcon(Icons.chat_bubble_outline_rounded);
      expect(chatIcon, findsOneWidget);

      await tester.tap(chatIcon);
      await tester.pumpAndSettle();

      // Should open ChatDetailPage with Keychron Official
      expect(find.byType(ChatDetailPage), findsOneWidget);
      expect(find.text('Keychron Official'), findsOneWidget);
    });
  });

  group('ChatPage Slider Actions Tests', () {
    testWidgets('ChatPage renders SlidableConversationCard with slider actions', (tester) async {
      final chatService = ChatService.instance;
      chatService.getOrCreateShopConversation(
        shopId: 'slider_test_store',
        shopName: 'Slider Test Store',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ChatPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Slider Test Store'), findsOneWidget);
      expect(find.byType(SlidableConversationCard), findsWidgets);

      // Slide card to the left to reveal Hide & Delete action buttons
      await tester.drag(find.text('Slider Test Store'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      // Actions should be visible
      expect(find.text('Hide'), findsWidgets);
      expect(find.text('Delete'), findsWidgets);
    });

    testWidgets('ProductCard renders without RenderFlex overflow under narrow constraints', (tester) async {
      const product = ProductModel(
        title: 'Ultra High Performance Mechanical Wireless Keyboard with RGB Backlight and Hot-Swappable Switches',
        imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=600&q=80',
        category: 'Electronics',
        isMall: true,
        discountTag: '-45%',
        price: '₱3,890.00',
        originalPrice: '₱5,200',
        rating: 4.9,
        soldCount: '1.2k',
        shippingTag: 'Next Day Delivery | Metro Manila',
        hasPayLater: true,
        hasVoucher: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 183.4,
                height: 320.0,
                child: ProductCard(product: product),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('₱3,890.00'), findsOneWidget);
    });
  });
}

