import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/constants/api_constants.dart';
import 'package:nexora_flutter_app/core/network/api_client.dart';
import 'package:nexora_flutter_app/core/services/address_service.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/external_notification_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/core/services/platform_voucher_service.dart';
import 'package:nexora_flutter_app/core/services/profile_service.dart';
import 'package:nexora_flutter_app/core/utils/guest_auth_guard.dart';
import 'package:nexora_flutter_app/core/utils/image_url_helper.dart';
import 'package:nexora_flutter_app/core/widgets/nexora_widgets.dart';
import 'package:nexora_flutter_app/features/profile/presentation/new_address_page.dart';

import 'widgets/shipping_option_modal.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _currentAttemptIdempotencyKey;
  bool _isPlacingOrder = false;
  bool _isLoadingSummary = false;
  String? _summaryError;

  // Authoritative server checkout summary
  CheckoutSummaryPreview? _serverSummary;
  List<PlatformVoucherModel> _availableVouchers = [];

  // Selected DB vouchers by scope
  PlatformVoucherModel? _selectedStoreVoucher;
  PlatformVoucherModel? _selectedPlatformVoucher;
  PlatformVoucherModel? _selectedShippingVoucher;

  // Optional note per store (UI preview for checkout session)
  final Map<String, String> _sellerMessages = {};

  final CartService _cartService = CartService.instance;
  final OrderService _orderService = OrderService.instance;
  final PlatformVoucherService _voucherService =
      PlatformVoucherService.instance;

  List<CartItemModel> _checkoutItems = [];

  bool get _isDirectBuy => _cartService.directBuyItem != null;

  @override
  void initState() {
    super.initState();
    _initCheckoutItems();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!BuyerAccountService.instance.isLoggedIn) {
        final authenticated = await GuestAuthGuard.requireLogin(
          context,
          title: 'Sign In Required for Checkout',
          message: 'Please sign in or create an account to finalize your order, compute shipping fees, and track your delivery.',
        );
        if (!mounted) return;
        if (!authenticated) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          return;
        }
      }
      await _loadCheckoutPreview();
    });
  }

  void _initCheckoutItems() {
    if (_cartService.directBuyItem != null) {
      _checkoutItems = [_cartService.directBuyItem!.copyWith()];
    } else {
      final checked = _cartService.items.where((i) => i.isChecked).toList();
      if (checked.isNotEmpty) {
        _checkoutItems = checked.map((e) => e.copyWith()).toList();
      } else if (_cartService.items.isNotEmpty) {
        _checkoutItems = [_cartService.items.first.copyWith(isChecked: true)];
      }
    }
  }

  List<int> get _serverCartItemIds {
    if (_isDirectBuy) return const [];
    return _checkoutItems
        .map((e) => int.tryParse(e.id) ?? 0)
        .where((id) => id > 0)
        .toList();
  }

  Future<void> _loadCheckoutPreview() async {
    if (!ApiClient.instance.hasToken) return;
    if (_checkoutItems.isEmpty) return;

    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });

    try {
      final pId = int.tryParse(_selectedPlatformVoucher?.id ?? '');
      final sId = int.tryParse(_selectedShippingVoucher?.id ?? '');
      final stId = int.tryParse(_selectedStoreVoucher?.id ?? '');

      final addressId = int.tryParse(
        AddressService.instance.defaultAddress?.id ?? '',
      );

      if (!_isDirectBuy && _serverCartItemIds.isNotEmpty) {
        final preview = await _orderService.fetchCheckoutSummaryRemote(
          cartItemIds: _serverCartItemIds,
          addressId: addressId,
          platformVoucherId: pId,
          shippingVoucherId: sId,
          storeVoucherId: stId,
        );
        if (!mounted) return;
        setState(() {
          _serverSummary = preview;
          _availableVouchers = preview.availableVouchers;
          _isLoadingSummary = false;
        });
      } else {
        // Direct Buy item isn't in DB cart until order placement; fetch real DB vouchers
        final vouchers = await _voucherService.fetchVouchersRemote();
        if (!mounted) return;
        setState(() {
          _availableVouchers = vouchers;
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSummary = false;
        _summaryError = e is ApiException
            ? e.message
            : 'Unable to refresh checkout summary.';
      });
    }
  }

  double get _merchandiseOriginalSubtotal {
    return _checkoutItems.fold<double>(
      0.0,
      (sum, item) => sum + ((item.originalPrice ?? item.price) * item.quantity),
    );
  }

  double get _effectiveSubtotal {
    if (_serverSummary != null && _serverSummary!.totalSubtotal > 0) {
      return _serverSummary!.totalSubtotal;
    }
    return _checkoutItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  double get _itemDiscount {
    final diff = _merchandiseOriginalSubtotal - _effectiveSubtotal;
    return diff > 0 ? diff : 0.0;
  }

  double get _shippingSubtotal => _serverSummary?.totalShipping ?? 0.0;

  double _previewVoucherDiscount(PlatformVoucherModel? v, double baseAmount) {
    if (v == null || baseAmount <= 0) return 0.0;
    if (baseAmount < v.minSpend) return 0.0;
    final raw = v.isPercentage
        ? baseAmount * v.discountAmount
        : v.discountAmount;
    return raw > baseAmount ? baseAmount : raw;
  }

  double get _platformDiscount {
    if (_serverSummary != null) return _serverSummary!.platformDiscount;
    return _previewVoucherDiscount(
      _selectedPlatformVoucher,
      _effectiveSubtotal,
    );
  }

  double get _storeDiscount {
    if (_serverSummary != null) return _serverSummary!.storeDiscount;
    return _previewVoucherDiscount(_selectedStoreVoucher, _effectiveSubtotal);
  }

  double get _shippingDiscount {
    if (_serverSummary != null) return _serverSummary!.shippingDiscount;
    return _previewVoucherDiscount(_selectedShippingVoucher, _shippingSubtotal);
  }

  double get _totalVoucherDiscount =>
      _platformDiscount + _storeDiscount + _shippingDiscount;

  double get _finalTotal {
    if (_serverSummary != null) return _serverSummary!.estimatedTotal;
    final total =
        _effectiveSubtotal + _shippingSubtotal - _totalVoucherDiscount;
    return total < 0 ? 0.0 : total;
  }

  double get _totalSaved => _itemDiscount + _totalVoucherDiscount;

  int get _totalItemCount =>
      _checkoutItems.fold<int>(0, (sum, e) => sum + e.quantity);

  String _formatPeso(double amount) {
    return amount % 1 == 0
        ? '₱${amount.toStringAsFixed(0)}'
        : '₱${amount.toStringAsFixed(2)}';
  }

  String _formatVoucherBenefit(PlatformVoucherModel v) {
    if (v.isFreeShipping && v.discountAmount <= 0) {
      return 'Free Shipping';
    }
    if (v.isPercentage) {
      return '${(v.discountAmount * 100).toStringAsFixed(0)}% OFF';
    }
    return '₱${v.discountAmount.toStringAsFixed(0)} OFF';
  }

  Future<void> _openShippingOptionModal() async {
    await showModalBottomSheet<ShippingOptionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShippingOptionModal(
        initialSelection: ShippingOptionResult(
          methodType: 'door_to_door',
          optionName: 'Standard Door-to-Door',
          estimatedDate: _serverSummary != null
              ? 'Weight-based rate'
              : 'Calculated by parcel weight at confirmation',
          shippingFee: _shippingSubtotal,
        ),
      ),
    );
  }

  Future<void> _claimAndSelectVoucher(
    PlatformVoucherModel voucher, {
    required String targetScope,
  }) async {
    if (ApiClient.instance.hasToken &&
        !voucher.isClaimed &&
        int.tryParse(voucher.id) != null) {
      try {
        await ApiClient.instance.post(
          ApiConstants.buyerVoucherClaim(voucher.id),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Unable to claim voucher.',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      if (targetScope == 'shipping' || voucher.scope == 'shipping') {
        _selectedShippingVoucher = voucher;
      } else if (targetScope == 'store' ||
          voucher.scope == 'store' ||
          voucher.scope == 'seller') {
        _selectedStoreVoucher = voucher;
      } else {
        _selectedPlatformVoucher = voucher;
      }
    });

    await _loadCheckoutPreview();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied voucher ${voucher.code}: ${_formatVoucherBenefit(voucher)}',
        ),
        backgroundColor: NexoraTheme.primary,
      ),
    );
  }

  Future<void> _openStoreVoucherModal(String storeName, int? sellerId) async {
    final storeVouchers = _availableVouchers.where((v) {
      final s = v.scope.toLowerCase();
      final isStoreScope = s == 'store' || s == 'seller';
      if (!isStoreScope) return false;
      if (sellerId != null && v.sellerId != null) {
        return v.sellerId == sellerId.toString();
      }
      return true;
    }).toList();

    await _showVoucherPickerSheet(
      title: 'Shop Vouchers',
      subtitle: storeName,
      vouchers: storeVouchers,
      selectedVoucher: _selectedStoreVoucher,
      targetScope: 'store',
      emptyMessage: 'No active store vouchers available from $storeName.',
      onRemove: () async {
        setState(() => _selectedStoreVoucher = null);
        await _loadCheckoutPreview();
      },
    );
  }

  Future<void> _openPlatformVoucherModal() async {
    final platformAndShipping = _availableVouchers.where((v) {
      final s = v.scope.toLowerCase();
      return s == 'platform' || s == 'shipping';
    }).toList();

    await _showVoucherPickerSheet(
      title: 'Platform & Shipping Vouchers',
      subtitle: 'Apply official Nexora vouchers to your order',
      vouchers: platformAndShipping,
      selectedVoucher: _selectedPlatformVoucher ?? _selectedShippingVoucher,
      targetScope: 'platform',
      emptyMessage: 'No platform or shipping vouchers available right now.',
      onRemove: () async {
        setState(() {
          _selectedPlatformVoucher = null;
          _selectedShippingVoucher = null;
        });
        await _loadCheckoutPreview();
      },
    );
  }

  Future<void> _showVoucherPickerSheet({
    required String title,
    required String subtitle,
    required List<PlatformVoucherModel> vouchers,
    required PlatformVoucherModel? selectedVoucher,
    required String targetScope,
    required String emptyMessage,
    required Future<void> Function() onRemove,
  }) async {
    final codeController = TextEditingController();
    String? codeError;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(ctx);
          final cs = theme.colorScheme;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedVoucher != null)
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await onRemove();
                          },
                          child: const Text(
                            'Remove',
                            style: TextStyle(
                              color: NexoraTheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Enter voucher code',
                            isDense: true,
                            errorText: codeError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final code = codeController.text
                                      .trim()
                                      .toUpperCase();
                                  if (code.isEmpty) return;

                                  setModalState(() {
                                    isSubmitting = true;
                                    codeError = null;
                                  });

                                  final match = _availableVouchers.where(
                                    (v) => v.code.toUpperCase() == code,
                                  );
                                  if (match.isEmpty) {
                                    setModalState(() {
                                      isSubmitting = false;
                                      codeError = 'Voucher code not found or not eligible for this order.';
                                    });
                                    return;
                                  }

                                  final picked = match.first;
                                  Navigator.pop(ctx);
                                  await _claimAndSelectVoucher(
                                    picked,
                                    targetScope: picked.scope,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (vouchers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    ...vouchers.map((v) {
                      final isSelected =
                          _selectedPlatformVoucher?.id == v.id ||
                          _selectedShippingVoucher?.id == v.id ||
                          _selectedStoreVoucher?.id == v.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primary.withValues(alpha: 0.08)
                              : theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? cs.primary : cs.outlineVariant,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          onTap: () async {
                            Navigator.pop(ctx);
                            await _claimAndSelectVoucher(
                              v,
                              targetScope: v.scope,
                            );
                          },
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              v.scope == 'shipping'
                                  ? Icons.local_shipping_outlined
                                  : Icons.confirmation_num_outlined,
                              color: cs.primary,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_formatVoucherBenefit(v)} (${v.code})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              NexoraStatusBadge(
                                label: v.scope.toUpperCase(),
                                color: v.scope == 'shipping'
                                    ? NexoraTheme.accent
                                    : cs.primary,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Min. spend ₱${v.minSpend.toStringAsFixed(0)} • Exp: ${v.expiry}',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: cs.primary,
                                )
                              : Text(
                                  'Use',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSellerMessageModal(String storeName) async {
    final current = _sellerMessages[storeName] ?? '';
    final controller = TextEditingController(text: current);
    const quickNotes = [
      'Fragile - handle with care',
      'Please call upon arrival',
      'Double bubble wrap packaging',
      'Leave at reception/security',
      'Deliver during office hours',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final cs = Theme.of(ctx).colorScheme;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Message for Seller',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (current.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() => _sellerMessages.remove(storeName));
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: NexoraTheme.error),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: 'Leave packaging or delivery instructions...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: quickNotes.map((note) {
                      return ActionChip(
                        label: Text(note, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          setModalState(() {
                            controller.text = controller.text.isEmpty
                                ? note
                                : '${controller.text}, $note';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          final trimmed = controller.text.trim();
                          if (trimmed.isEmpty) {
                            _sellerMessages.remove(storeName);
                          } else {
                            _sellerMessages[storeName] = trimmed;
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Save Message'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handlePlaceOrder() async {
    if (_checkoutItems.isEmpty) return;

    if (!BuyerAccountService.instance.isLoggedIn) {
      final authenticated = await GuestAuthGuard.requireLogin(
        context,
        title: 'Sign In to Place Order',
        message: 'Please sign in or create an account to finalize your order.',
      );
      if (!authenticated || !mounted) return;
    }

    final defaultAddr = AddressService.instance.defaultAddress;
    final int? addrId = defaultAddr != null
        ? int.tryParse(defaultAddr.id)
        : null;
    if (defaultAddr == null || addrId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add or select a delivery address before placing your order.',
          ),
          backgroundColor: NexoraTheme.error,
        ),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NewAddressPage()),
      );
      return;
    }

    if (_serverSummary != null && !_serverSummary!.allServiceable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _serverSummary!.serviceabilityError ??
                'Your delivery address is outside our courier servicing areas.',
          ),
          backgroundColor: NexoraTheme.error,
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    _currentAttemptIdempotencyKey ??=
        'chk_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 10000}';

    String orderId = '';

    try {
      List<int>? cartItemIds;
      if (_isDirectBuy) {
        final dItem = _cartService.directBuyItem!;
        final pId = int.tryParse(dItem.productId ?? '') ?? 0;
        if (pId <= 0) {
          throw const ApiException(
            message: 'Invalid product selected for checkout.',
            statusCode: 400,
          );
        }
        final createdCartItemId = await _cartService.addItemRemote(
          productId: pId,
          quantity: dItem.quantity,
          variant: dItem.variantData is Map<String, dynamic>
              ? dItem.variantData as Map<String, dynamic>
              : null,
        );
        if (createdCartItemId == null || createdCartItemId <= 0) {
          throw const ApiException(
            message: 'Unable to prepare item for checkout.',
            statusCode: 500,
          );
        }
        cartItemIds = [createdCartItemId];
      } else if (_serverCartItemIds.isNotEmpty) {
        cartItemIds = _serverCartItemIds;
      }

      final orders = await _orderService.placeOrderRemote(
        addressId: addrId,
        paymentMethod: 'cod',
        idempotencyKey: _currentAttemptIdempotencyKey,
        cartItemIds: cartItemIds,
        platformVoucherId: int.tryParse(_selectedPlatformVoucher?.id ?? ''),
        shippingVoucherId: int.tryParse(_selectedShippingVoucher?.id ?? ''),
        storeVoucherId: int.tryParse(_selectedStoreVoucher?.id ?? ''),
      );

      if (orders.isEmpty) {
        throw const ApiException(
          message: 'Checkout did not create any orders.',
          statusCode: 500,
        );
      }

      final firstOrd = orders[0];
      orderId = (firstOrd['order_number'] ?? '#${firstOrd['id']}').toString();

      _currentAttemptIdempotencyKey = null;
      _cartService.clearDirectBuy();
      await _cartService.loadCartRemote();
      await _orderService.fetchOrdersRemote();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      final userMsg = e is ApiException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: NexoraTheme.error),
              SizedBox(width: 8),
              Text(
                'Checkout Failed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(userMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _handlePlaceOrder();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    try {
      ExternalNotificationService.show(
        title: 'Nexora Order Placed (Cash on Delivery)',
        body:
            'Order $orderId has been placed. Track live delivery status in My Orders.',
      );
    } catch (_) {}

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: NexoraTheme.success.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: NexoraTheme.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(dialogContext).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Order $orderId has been placed via Cash on Delivery. Track real-time updates in My Orders.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.orders,
                      arguments: {'initialTab': 'to_ship', 'initialIndex': 1},
                    );
                  },
                  child: const Text(
                    'View Order Status',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            }
          },
        ),
        title: Text(
          'Checkout',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_isLoadingSummary)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _checkoutItems.isEmpty
          ? NexoraEmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'No items selected for checkout',
              message:
                  'Select items in your cart or pick a product to proceed.',
              actionLabel: 'Browse Products',
              onAction: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.home),
            )
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _loadCheckoutPreview,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            if (_summaryError != null)
                              Container(
                                margin: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  10,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: NexoraTheme.warning.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: NexoraTheme.warning.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: NexoraTheme.warning,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _summaryError!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _loadCheckoutPreview,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            _buildAddressCard(context),
                            const SizedBox(height: 10),
                            ..._buildGroupedStoreCards(context),
                            const SizedBox(height: 10),
                            _buildShippingOptionCard(context),
                            const SizedBox(height: 10),
                            _buildVoucherCard(context),
                            const SizedBox(height: 10),
                            _buildPaymentMethodsCard(context),
                            const SizedBox(height: 10),
                            _buildPaymentDetailsCard(context),
                            const SizedBox(height: 110),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: _buildBottomCheckoutDock(context),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAddressCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (AddressService.instance.addresses.isEmpty) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewAddressPage()),
              );
            } else {
              await Navigator.pushNamed(context, AppRoutes.myAddresses);
            }
            if (mounted) {
              await _loadCheckoutPreview();
            }
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.location_on,
                        color: cs.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          ProfileService.instance,
                          AddressService.instance,
                        ]),
                        builder: (context, _) {
                          final defaultAddr =
                              AddressService.instance.defaultAddress;
                          final profile = ProfileService.instance;
                          final addressStr =
                              defaultAddr?.fullAddress ?? profile.address;
                          final name =
                              defaultAddr?.fullName ??
                              (profile.name.isNotEmpty
                                  ? profile.name
                                  : 'Recipient');
                          final phone = defaultAddr?.phone ?? profile.phone;

                          if (addressStr.trim().isEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: cs.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Add Delivery Address',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Tap to set your delivery address for this order',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$name ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    if (phone.isNotEmpty)
                                      TextSpan(
                                        text: phone,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                addressStr,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: cs.onSurfaceVariant,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 3,
                child: Row(
                  children: List.generate(15, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        color: index % 2 == 0
                            ? NexoraTheme.primary
                            : NexoraTheme.accent,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedStoreCards(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Map<String, List<CartItemModel>> grouped = {};
    for (final item in _checkoutItems) {
      final key = item.storeName.isNotEmpty ? item.storeName : 'Store';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped.entries.map((entry) {
      final storeName = entry.key;
      final items = entry.value;
      final sellerId = items.first.sellerId;
      final badge = items.first.storeBadge;
      final sellerMsg = _sellerMessages[storeName] ?? '';

      return Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (badge.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildItemRow(context, item),
              ),
            ),
            const Divider(height: 16),
            _buildActionRow(
              context,
              label: 'Shop Voucher',
              value: _selectedStoreVoucher != null
                  ? '${_formatVoucherBenefit(_selectedStoreVoucher!)} (${_selectedStoreVoucher!.code}) >'
                  : 'Select or enter code >',
              valueColor: _selectedStoreVoucher != null
                  ? cs.primary
                  : cs.onSurfaceVariant,
              onTap: () => _openStoreVoucherModal(storeName, sellerId),
            ),
            const Divider(height: 16),
            _buildActionRow(
              context,
              label: 'Message for Seller',
              value: sellerMsg.isNotEmpty
                  ? '$sellerMsg >'
                  : 'Please leave a message >',
              valueColor: sellerMsg.isNotEmpty
                  ? cs.onSurface
                  : cs.onSurfaceVariant,
              onTap: () => _openSellerMessageModal(storeName),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildItemRow(BuildContext context, CartItemModel item) {
    final cs = Theme.of(context).colorScheme;
    final resolvedUrl = ImageUrlHelper.resolve(item.imageUrl);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: resolvedUrl.isEmpty
              ? Container(
                  width: 72,
                  height: 72,
                  color: cs.surfaceContainerHigh,
                  child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant),
                )
              : Image.network(
                  resolvedUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 72,
                    height: 72,
                    color: cs.surfaceContainerHigh,
                    child: Icon(
                      Icons.image_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: cs.onSurface,
                  height: 1.25,
                ),
              ),
              if (item.variant.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.variant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _formatPeso(item.price),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      color: NexoraTheme.priceColor(context),
                    ),
                  ),
                  if (item.originalPrice != null &&
                      item.originalPrice! > item.price)
                    Text(
                      _formatPeso(item.originalPrice!),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: cs.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'x${item.quantity}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildShippingOptionCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasServerFee = _serverSummary != null;
    final feeText = hasServerFee
        ? _formatPeso(_shippingSubtotal)
        : 'Weight-based';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping Option',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: cs.onSurface,
                ),
              ),
              InkWell(
                onTap: _openShippingOptionModal,
                child: Text(
                  'Details >',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _openShippingOptionModal,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    color: cs.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Standard Door-to-Door',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          hasServerFee
                              ? 'Calculated from parcel weight per store'
                              : 'Weight-based shipping calculated at confirmation',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    feeText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total $_totalItemCount Item(s)',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              Text(
                _formatPeso(_finalTotal),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final List<String> appliedLabels = [
      if (_selectedPlatformVoucher != null)
        '${_selectedPlatformVoucher!.code} (${_formatVoucherBenefit(_selectedPlatformVoucher!)})',
      if (_selectedShippingVoucher != null)
        '${_selectedShippingVoucher!.code} (${_formatVoucherBenefit(_selectedShippingVoucher!)})',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: _openPlatformVoucherModal,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                Icons.confirmation_num_outlined,
                size: 18,
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Platform Vouchers',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    appliedLabels.isNotEmpty
                        ? appliedLabels.join(' • ')
                        : (_availableVouchers.isNotEmpty
                              ? 'Select voucher (${_availableVouchers.length})'
                              : 'Select voucher'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: appliedLabels.isNotEmpty
                          ? cs.primary
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.payments_outlined,
                    color: cs.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash on Delivery',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pay in cash to your assigned Nexora rider upon doorstep delivery.',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final voucherErrors = _serverSummary?.voucherErrors ?? const <String>[];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            context,
            'Merchandise Subtotal',
            _formatPeso(_merchandiseOriginalSubtotal),
          ),
          const SizedBox(height: 6),
          _buildDetailRow(
            context,
            'Shipping Fee',
            _serverSummary != null
                ? _formatPeso(_shippingSubtotal)
                : 'Weight-based',
          ),
          if (_itemDiscount > 0) ...[
            const SizedBox(height: 6),
            _buildDetailRow(
              context,
              'Item Discount',
              '-${_formatPeso(_itemDiscount)}',
              valueColor: NexoraTheme.success,
            ),
          ],
          if (_platformDiscount > 0) ...[
            const SizedBox(height: 6),
            _buildDetailRow(
              context,
              'Platform Voucher',
              '-${_formatPeso(_platformDiscount)}',
              valueColor: NexoraTheme.success,
            ),
          ],
          if (_storeDiscount > 0) ...[
            const SizedBox(height: 6),
            _buildDetailRow(
              context,
              'Store Voucher',
              '-${_formatPeso(_storeDiscount)}',
              valueColor: NexoraTheme.success,
            ),
          ],
          if (_shippingDiscount > 0) ...[
            const SizedBox(height: 6),
            _buildDetailRow(
              context,
              'Shipping Discount',
              '-${_formatPeso(_shippingDiscount)}',
              valueColor: NexoraTheme.success,
            ),
          ],
          if (voucherErrors.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: NexoraTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                voucherErrors.join('\n'),
                style: const TextStyle(
                  fontSize: 11,
                  color: NexoraTheme.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payment',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: cs.onSurface,
                ),
              ),
              Text(
                _formatPeso(_finalTotal),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: NexoraTheme.priceColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(
    BuildContext context, {
    required String label,
    required String value,
    required Color valueColor,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12.5, color: cs.onSurface)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCheckoutDock(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Total: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _formatPeso(_finalTotal),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: NexoraTheme.priceColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_totalSaved > 0)
                    Text(
                      'Saved ${_formatPeso(_totalSaved)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: NexoraTheme.success,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isPlacingOrder
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Place Order',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
