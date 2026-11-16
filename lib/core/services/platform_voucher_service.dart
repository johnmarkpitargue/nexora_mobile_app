import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

/// Platform & store voucher model backed by Laravel `/api/mobile/v1/buyer/vouchers`.
class PlatformVoucherModel {
  final String id;
  final String code;
  final String scope; // 'platform', 'shipping', 'store'
  final String? sellerId;
  final String title;
  final String description;
  final double discountAmount;
  final bool isPercentage;
  final double minSpend;
  final String expiry;
  final bool isFreeShipping;
  final bool isClaimed;

  const PlatformVoucherModel({
    required this.id,
    required this.code,
    this.scope = 'platform',
    this.sellerId,
    required this.title,
    required this.description,
    required this.discountAmount,
    this.isPercentage = false,
    this.minSpend = 0.0,
    required this.expiry,
    this.isFreeShipping = false,
    this.isClaimed = false,
  });

  factory PlatformVoucherModel.fromJson(Map<String, dynamic> json) {
    final scope = (json['voucher_scope'] ?? json['scope'] ?? 'platform').toString();
    final type = (json['type'] ?? '').toString().toLowerCase();
    final rawVal = double.tryParse((json['value'] ?? json['discountAmount'] ?? 0).toString()) ?? 0.0;
    final isPct = json['isPercentage'] == true || type == 'percent' || type == 'percentage';
    final minSpendVal = double.tryParse((json['min_spend'] ?? json['minSpend'] ?? 0).toString()) ?? 0.0;
    final code = json['code']?.toString() ?? '';

    return PlatformVoucherModel(
      id: json['id']?.toString() ?? '',
      code: code,
      scope: scope,
      sellerId: json['seller_id']?.toString(),
      title: json['title']?.toString() ??
          (scope == 'shipping'
              ? 'Shipping Discount ($code)'
              : scope == 'store'
                  ? 'Store Voucher ($code)'
                  : 'Platform Voucher ($code)'),
      description: json['description']?.toString() ??
          (minSpendVal > 0
              ? 'Min. spend ₱${minSpendVal.toStringAsFixed(0)}'
              : 'No minimum spend'),
      discountAmount: isPct ? (rawVal > 1 ? rawVal / 100.0 : rawVal) : rawVal,
      isPercentage: isPct,
      minSpend: minSpendVal,
      expiry: json['expires_at']?.toString() ?? json['expiry']?.toString() ?? 'Limited Time',
      isFreeShipping: json['isFreeShipping'] == true || scope == 'shipping',
      isClaimed: json['is_claimed'] == true || json['claimed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'voucher_scope': scope,
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'discountAmount': discountAmount,
      'isPercentage': isPercentage,
      'minSpend': minSpend,
      'expiry': expiry,
      'isFreeShipping': isFreeShipping,
      'is_claimed': isClaimed,
    };
  }
}

/// Service managing real buyer vouchers fetched from Laravel.
class PlatformVoucherService extends ChangeNotifier {
  static final PlatformVoucherService instance =
      PlatformVoucherService._internal();

  PlatformVoucherService._internal();

  final List<PlatformVoucherModel> _availableVouchers = [];
  PlatformVoucherModel? _appliedVoucher;

  List<PlatformVoucherModel> get availableVouchers =>
      List.unmodifiable(_availableVouchers);
  List<PlatformVoucherModel> get vouchers => availableVouchers;
  PlatformVoucherModel? get appliedVoucher => _appliedVoucher;

  Future<List<PlatformVoucherModel>> fetchVouchersRemote() async {
    if (!ApiClient.instance.hasToken) {
      _availableVouchers.clear();
      notifyListeners();
      return const [];
    }
    final res = await ApiClient.instance.get(ApiConstants.buyerVouchers);
    final raw = res['data'];
    final List list = raw is List
        ? raw
        : (raw is Map && raw['vouchers'] is List
            ? raw['vouchers']
            : (raw is Map && raw['data'] is List ? raw['data'] : []));

    _availableVouchers
      ..clear()
      ..addAll(list.whereType<Map<String, dynamic>>().map(PlatformVoucherModel.fromJson));
    notifyListeners();
    return availableVouchers;
  }

  void setVouchers(List<PlatformVoucherModel> vouchers) {
    _availableVouchers.clear();
    _availableVouchers.addAll(vouchers);
    notifyListeners();
  }

  /// Match and claim an active voucher from the database by code.
  Future<PlatformVoucherModel?> verifyAndApplyCode(
    String code, {
    double currentSubtotal = 0.0,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return null;

    if (_availableVouchers.isEmpty && ApiClient.instance.hasToken) {
      try {
        await fetchVouchersRemote();
      } catch (_) {}
    }

    final existing = _availableVouchers.where(
      (v) => v.code.toUpperCase() == cleanCode,
    );
    if (existing.isEmpty) {
      return null;
    }

    final voucher = existing.first;
    if (currentSubtotal < voucher.minSpend) {
      return null;
    }

    if (ApiClient.instance.hasToken && int.tryParse(voucher.id) != null && !voucher.isClaimed) {
      await ApiClient.instance.post(ApiConstants.buyerVoucherClaim(voucher.id));
    }

    _appliedVoucher = voucher;
    notifyListeners();
    return voucher;
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
