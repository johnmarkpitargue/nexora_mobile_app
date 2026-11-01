import 'package:flutter/material.dart';
import 'buyer_account_service.dart';

enum PaymentType {
  gcash,
  cod,
  card,
  maya,
}

class PaymentMethodModel {
  final String id;
  final PaymentType type;
  final String name;
  final String accountNumber; // e.g. "0917 890 9128", "•••• 4012"
  final String accountHolder; // e.g. "Alexa N. Santos"
  final bool isDefault;
  final bool isLinked;
  final Color brandColor;

  PaymentMethodModel({
    required this.id,
    required this.type,
    required this.name,
    required this.accountNumber,
    this.accountHolder = '',
    this.isDefault = false,
    this.isLinked = true,
    required this.brandColor,
  });

  String get formattedDisplay {
    if (type == PaymentType.gcash) {
      final clean = accountNumber.replaceAll(' ', '');
      if (clean.length == 11 && clean.startsWith('09')) {
        return '+63 ${clean.substring(1, 4)} ••• ${clean.substring(7)}';
      }
      return accountNumber;
    }
    return accountNumber;
  }

  PaymentMethodModel copyWith({
    String? id,
    PaymentType? type,
    String? name,
    String? accountNumber,
    String? accountHolder,
    bool? isDefault,
    bool? isLinked,
    Color? brandColor,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
      isDefault: isDefault ?? this.isDefault,
      isLinked: isLinked ?? this.isLinked,
      brandColor: brandColor ?? this.brandColor,
    );
  }
}

class PaymentMethodService extends ChangeNotifier {
  static final PaymentMethodService instance = PaymentMethodService._();
  PaymentMethodService._() {
    BuyerAccountService.instance.addListener(_onBuyerChanged);
  }

  void _onBuyerChanged() {
    notifyListeners();
  }

  final Map<String, List<PaymentMethodModel>> _userMethods = {};

  String get _currentUserKey {
    final b = BuyerAccountService.instance.currentBuyer;
    return (b != null && b.email.isNotEmpty) ? b.email.toLowerCase().trim() : 'guest';
  }

  List<PaymentMethodModel> get _currentMethods {
    return _userMethods.putIfAbsent(_currentUserKey, () => _createDefaultMethodsForUser());
  }

  List<PaymentMethodModel> _createDefaultMethodsForUser() {
    return [
      PaymentMethodModel(
        id: 'cod_primary',
        type: PaymentType.cod,
        name: 'Cash on Delivery',
        accountNumber: 'Pay in cash upon doorstep delivery',
        isDefault: true,
        isLinked: true,
        brandColor: const Color(0xFF00B4D8),
      ),
      PaymentMethodModel(
        id: 'visa_primary',
        type: PaymentType.card,
        name: 'Visa Debit/Credit',
        accountNumber: '•••• •••• •••• 4012',
        accountHolder: 'ALEXA N. SANTOS',
        isDefault: false,
        isLinked: true,
        brandColor: const Color(0xFF1E293B),
      ),
      PaymentMethodModel(
        id: 'gcash_primary',
        type: PaymentType.gcash,
        name: 'GCash',
        accountNumber: '0917 890 9128',
        accountHolder: 'ALEXA N. SANTOS',
        isDefault: false,
        isLinked: true,
        brandColor: const Color(0xFF005CE6), // Official GCash Royal Blue
      ),
    ];
  }

  List<PaymentMethodModel> get methods => List.unmodifiable(_currentMethods);

  PaymentMethodModel get defaultMethod {
    final list = _currentMethods;
    return list.firstWhere(
      (m) => m.isDefault && m.isLinked,
      orElse: () => list.firstWhere((m) => m.isLinked, orElse: () => list.first),
    );
  }

  PaymentMethodModel? get gcashMethod {
    final list = _currentMethods;
    final idx = list.indexWhere((m) => m.type == PaymentType.gcash && m.isLinked);
    return idx != -1 ? list[idx] : null;
  }

  void linkGCash({
    required String phoneNumber,
    required String accountHolder,
    bool makeDefault = true,
  }) {
    String clean = phoneNumber.replaceAll(RegExp(r'\s+|-'), '').trim();
    if (clean.startsWith('+63')) {
      clean = '0${clean.substring(3)}';
    } else if (clean.startsWith('63')) {
      clean = '0${clean.substring(2)}';
    } else if (!clean.startsWith('0') && clean.length == 10) {
      clean = '0$clean';
    }

    final list = _currentMethods;
    if (makeDefault) {
      for (int i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }

    final newGcash = PaymentMethodModel(
      id: 'gcash_primary',
      type: PaymentType.gcash,
      name: 'GCash',
      accountNumber: clean,
      accountHolder: accountHolder.toUpperCase().trim(),
      isDefault: makeDefault,
      isLinked: true,
      brandColor: const Color(0xFF005CE6),
    );

    final idx = list.indexWhere((m) => m.type == PaymentType.gcash);
    if (idx != -1) {
      list[idx] = newGcash;
    } else {
      list.insert(0, newGcash);
    }

    notifyListeners();
  }

  void unlinkGCash() {
    final list = _currentMethods;
    final idx = list.indexWhere((m) => m.type == PaymentType.gcash);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        isLinked: false,
        isDefault: false,
      );
      final codIdx = list.indexWhere((m) => m.type == PaymentType.cod);
      if (codIdx != -1) {
        list[codIdx] = list[codIdx].copyWith(isDefault: true);
      }
      notifyListeners();
    }
  }

  void setDefault(String id) {
    final list = _currentMethods;
    for (int i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(isDefault: list[i].id == id);
    }
    notifyListeners();
  }

  void addCard({
    required String cardNumber,
    required String expiry,
    required String cardHolder,
    bool makeDefault = false,
  }) {
    final list = _currentMethods;
    if (makeDefault) {
      for (int i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }
    final digits = cardNumber.replaceAll(RegExp(r'\s+'), '').trim();
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;

    list.add(PaymentMethodModel(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
      type: PaymentType.card,
      name: 'Visa Debit/Credit',
      accountNumber: '•••• •••• •••• $last4',
      accountHolder: cardHolder.toUpperCase().trim(),
      isDefault: makeDefault,
      isLinked: true,
      brandColor: const Color(0xFF1E293B),
    ));
    notifyListeners();
  }

  void removeMethod(String id) {
    final list = _currentMethods;
    list.removeWhere((m) => m.id == id);
    if (!list.any((m) => m.isDefault && m.isLinked) && list.isNotEmpty) {
      list[0] = list[0].copyWith(isDefault: true);
    }
    notifyListeners();
  }
}
