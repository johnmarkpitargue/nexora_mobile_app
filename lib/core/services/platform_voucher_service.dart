import 'package:flutter/material.dart';

/// Platform-wide voucher model ready for web/backend integration.
class PlatformVoucherModel {
  final String id;
  final String code; // e.g. "NEXORA100", "FREESHIP"
  final String title; // e.g. "Platform Free Shipping Voucher"
  final String description; // e.g. "Min. spend ₱0 • Valid on all stores"
  final double discountAmount; // e.g. 50.0 or 100.0
  final bool isPercentage; // true if discountAmount represents percentage (e.g. 0.10 for 10%)
  final double minSpend; // minimum merchandise spend required
  final String expiry; // e.g. "Valid until 31 Dec 2026"
  final bool isFreeShipping; // true if it covers shipping fees

  const PlatformVoucherModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountAmount,
    this.isPercentage = false,
    this.minSpend = 0.0,
    required this.expiry,
    this.isFreeShipping = false,
  });

  /// Factory constructor to deserialize JSON responses from web backend functions.
  factory PlatformVoucherModel.fromJson(Map<String, dynamic> json) {
    return PlatformVoucherModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Platform Voucher',
      description: json['description']?.toString() ?? '',
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      isPercentage: json['isPercentage'] == true,
      minSpend: (json['minSpend'] as num?)?.toDouble() ?? 0.0,
      expiry: json['expiry']?.toString() ?? 'Limited Time',
      isFreeShipping: json['isFreeShipping'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'discountAmount': discountAmount,
      'isPercentage': isPercentage,
      'minSpend': minSpend,
      'expiry': expiry,
      'isFreeShipping': isFreeShipping,
    };
  }
}

/// Service managing platform vouchers, ready for web API hookup.
class PlatformVoucherService extends ChangeNotifier {
  static final PlatformVoucherService instance =
      PlatformVoucherService._internal();

  PlatformVoucherService._internal();

  // Vouchers list is empty by default so it's ready for web/API integration without mock clutter
  final List<PlatformVoucherModel> _availableVouchers = [];
  PlatformVoucherModel? _appliedVoucher;

  List<PlatformVoucherModel> get availableVouchers =>
      List.unmodifiable(_availableVouchers);
  List<PlatformVoucherModel> get vouchers => availableVouchers;
  PlatformVoucherModel? get appliedVoucher => _appliedVoucher;

  /// Hook for web/backend function: set vouchers received from web API
  void setVouchers(List<PlatformVoucherModel> vouchers) {
    _availableVouchers.clear();
    _availableVouchers.addAll(vouchers);
    notifyListeners();
  }

  /// Hook for web/backend verification of voucher codes
  Future<PlatformVoucherModel?> verifyAndApplyCode(
    String code, {
    double currentSubtotal = 0.0,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return null;

    // Check currently loaded vouchers first
    final existing = _availableVouchers.where(
      (v) => v.code.toUpperCase() == cleanCode,
    );
    if (existing.isNotEmpty) {
      final voucher = existing.first;
      if (currentSubtotal >= voucher.minSpend) {
        _appliedVoucher = voucher;
        notifyListeners();
        return voucher;
      }
    }

    // Dynamic fallback verification for standard platform voucher codes
    if (cleanCode == 'FREESHIP' || cleanCode == 'FREESHIPPING') {
      final voucher = const PlatformVoucherModel(
        id: 'plat_free_ship',
        code: 'FREESHIP',
        title: 'Platform Free Shipping',
        description: 'Free shipping on any order',
        discountAmount: 45.0,
        isFreeShipping: true,
        expiry: 'Valid today',
      );
      _appliedVoucher = voucher;
      notifyListeners();
      return voucher;
    } else if (cleanCode == 'NEXORA50' || cleanCode == 'WELCOME50') {
      final voucher = const PlatformVoucherModel(
        id: 'plat_welcome_50',
        code: 'NEXORA50',
        title: '₱50 Platform Discount',
        description: '₱50 OFF on orders above ₱300',
        discountAmount: 50.0,
        minSpend: 300.0,
        expiry: 'Limited time',
      );
      _appliedVoucher = voucher;
      notifyListeners();
      return voucher;
    } else if (cleanCode == 'NEXORA100') {
      final voucher = const PlatformVoucherModel(
        id: 'plat_100',
        code: 'NEXORA100',
        title: '₱100 Platform Discount',
        description: '₱100 OFF on orders above ₱500',
        discountAmount: 100.0,
        minSpend: 500.0,
        expiry: 'Limited time',
      );
      _appliedVoucher = voucher;
      notifyListeners();
      return voucher;
    }

    return null;
  }

  void selectVoucher(PlatformVoucherModel? voucher) {
    _appliedVoucher = voucher;
    notifyListeners();
  }

  void clearVoucher() {
    _appliedVoucher = null;
    notifyListeners();
  }
}

