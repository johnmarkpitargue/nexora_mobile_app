import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/services/address_service.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/notification_preferences_service.dart';
import 'package:nexora_flutter_app/core/services/payment_method_service.dart';
import 'package:nexora_flutter_app/features/profile/presentation/my_addresses_page.dart';
import 'package:nexora_flutter_app/features/profile/presentation/notification_preferences_page.dart';
import 'package:nexora_flutter_app/features/profile/presentation/payment_methods_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await BuyerAccountService.instance.resetState();
  });

  testWidgets(
    'empty address book stays usable at compact width and 200% text',
    (tester) async {
      await _useCompactSurface(tester);
      _seedBuyer('addresses-empty');

      await tester.pumpWidget(
        _app(const MyAddressesPage(), textScaler: const TextScaler.linear(2)),
      );
      await tester.pump();

      expect(find.text('My addresses'), findsOneWidget);
      expect(find.text('No saved addresses'), findsOneWidget);
      expect(find.byKey(const ValueKey('add-address-action')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('address selection updates the default with clear feedback', (
    tester,
  ) async {
    _seedBuyer('addresses-default');
    final service = AddressService.instance;
    service.addAddress(_address('home', 'Jordan Home', isDefault: true));
    service.addAddress(_address('work', 'Jordan Work'));

    await tester.pumpWidget(_app(const MyAddressesPage()));
    await tester.pump();

    expect(find.text('Jordan Home'), findsOneWidget);
    expect(find.text('Jordan Work'), findsOneWidget);

    await tester.tap(find.text('Jordan Work'));
    await tester.pump();

    expect(service.defaultAddress?.id, 'work');
    expect(
      find.text('Jordan Work is now your default address.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('payment methods adapt and react to default changes', (
    tester,
  ) async {
    await _useCompactSurface(tester);
    _seedBuyer('payments');
    final service = PaymentMethodService.instance;

    await tester.pumpWidget(
      _app(const PaymentMethodsPage(), textScaler: const TextScaler.linear(2)),
    );
    await tester.pump();

    expect(find.text('Primary Payment Method'), findsOneWidget);
    expect(find.text('Cash on Delivery'), findsWidgets);
    expect(find.byKey(const ValueKey('primary-payment-card')), findsOneWidget);
    expect(tester.takeException(), isNull);

    service.linkGCash(
      phoneNumber: '09178909128',
      accountHolder: 'Phase Twelve',
      makeDefault: true,
    );
    await tester.pump();

    expect(find.text('GCash'), findsWidgets);
    expect(find.text('Update GCash account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'notification controls are clear and test tools are progressive',
    (tester) async {
      await _useCompactSurface(tester);
      final service = NotificationPreferencesService.instance;
      service.updateSettings(promoAlerts: false);

      await tester.pumpWidget(
        _app(
          const NotificationPreferencesPage(),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pump();

      expect(find.text('What you receive'), findsOneWidget);
      expect(find.text('Test in-app alert'), findsNothing);
      expect(tester.takeException(), isNull);

      await _scrollUntilVisible(tester, find.text('Open test tools'));
      await tester.tap(find.text('Open test tools'));
      await tester.pump();
      await _scrollUntilVisible(tester, find.text('Test in-app alert'));

      expect(find.text('Test in-app alert'), findsOneWidget);
      expect(find.text('Test phone notification'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

AddressModel _address(String id, String name, {bool isDefault = false}) {
  return AddressModel(
    id: id,
    fullName: name,
    phone: '09171234567',
    regionCity: 'Makati City, Metro Manila',
    city: 'Makati City',
    barangay: 'Poblacion',
    postalCode: '1210',
    streetBuilding: id == 'home' ? '12 Home Street' : '88 Work Avenue',
    label: id == 'home' ? 'Home' : 'Work',
    isDefault: isDefault,
    latitude: 14.5547,
    longitude: 121.0244,
  );
}

void _seedBuyer(String suffix) {
  BuyerAccountService.instance.seedLoggedInBuyer(
    firstName: 'Phase',
    lastName: 'Twelve',
    email: 'phase12-$suffix@nexora.test',
    mobileNumber: '09171234567',
    password: 'Password123!',
  );
}

Future<void> _useCompactSurface(WidgetTester tester) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(320, 900));
}

Future<void> _scrollUntilVisible(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 280);
  await tester.pump();
}

Widget _app(Widget home, {TextScaler textScaler = TextScaler.noScaling}) {
  return MaterialApp(
    theme: NexoraTheme.lightTheme,
    home: home,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: textScaler, disableAnimations: true),
      child: child!,
    ),
  );
}
