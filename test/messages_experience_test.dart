import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/services/chat_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/features/chat/presentation/chat_detail_page.dart';
import 'package:nexora_flutter_app/features/chat/presentation/chat_page.dart';

void main() {
  setUp(() {
    OrderService.instance.clearAllOrders();
  });

  testWidgets('messages inbox stays usable at compact width and large text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 900));
    ChatService.instance.getOrCreateShopConversation(
      shopId: 'phase10_compact_store',
      shopName: 'Phase Ten Compact Store',
      shopBadge: 'OFFICIAL STORE',
      initialProductSnippet: 'Wireless studio headphones',
    );

    await tester.pumpWidget(
      _app(
        const ChatPage(),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(find.text('Messages'), findsOneWidget);
    expect(find.byKey(const ValueKey('messages-search-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('messages-filter-0')), findsOneWidget);
    expect(find.byType(SlidableConversationCard), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey('messages-search-field')),
      'Phase Ten',
    );
    await tester.pump();
    expect(find.text('Phase Ten Compact Store'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('message filters progressively narrow the inbox', (tester) async {
    await tester.pumpWidget(_app(const ChatPage()));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('messages-filter-3')));
    await tester.pump();

    expect(find.text('Nexora AI Support'), findsOneWidget);
    expect(find.text('Nexora Official Store'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('conversation detail and composer adapt at 200 percent text', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 760));

    await tester.pumpWidget(
      _app(
        const ChatDetailPage(
          title: 'Nexora Official Store',
          subtitle: 'Official Store',
          avatarIcon: Icons.storefront_rounded,
          avatarBgColor: NexoraTheme.primary,
          initialMessages: [
            {
              'sender': 'other',
              'text': 'Hello! How can we help with your order today?',
              'time': '2:00 PM',
            },
            {
              'sender': 'user',
              'text': 'I need an update on my headphones.',
              'time': '2:02 PM',
            },
          ],
        ),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(find.text('Nexora Official Store'), findsWidgets);
    expect(find.byKey(const ValueKey('message-send-action')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField).last, 'A concise reply');
    await tester.tap(find.byKey(const ValueKey('message-send-action')));
    await tester.pump();
    expect(find.text('A concise reply'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing feedback honors reduced motion and long names', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 400));

    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: ChatTypingIndicator(
            senderName: 'Nexora Premium Customer Support',
          ),
        ),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(find.textContaining('is typing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  Widget home, {
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    theme: NexoraTheme.lightTheme,
    home: home,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: textScaler, disableAnimations: disableAnimations),
      child: child!,
    ),
  );
}
