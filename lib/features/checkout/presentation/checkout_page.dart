import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/core/services/address_service.dart';
import 'package:nexora_flutter_app/core/services/profile_service.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/payment_method_service.dart';
import 'package:nexora_flutter_app/core/services/external_notification_service.dart';
import 'package:nexora_flutter_app/core/services/shop_service.dart';
import 'package:nexora_flutter_app/core/models/shop_models.dart';
import 'package:nexora_flutter_app/core/utils/guest_auth_guard.dart';
import 'package:nexora_flutter_app/core/network/api_client.dart';
import 'package:nexora_flutter_app/features/profile/presentation/new_address_page.dart';
import 'widgets/shipping_option_modal.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _selectedPaymentIndex = 0;
  String? _currentAttemptIdempotencyKey;

  List<Map<String, dynamic>> get _paymentOptions {
    // The web backend only supports Cash on Delivery (COD). Non-web options are hidden per Rule B3 & Rule 4.
    return [
      {
        'id': 'cod',
        'name': 'Cash on Delivery',
        'shortName': 'Cash on Delivery',
        'desc': 'Pay in cash upon doorstep delivery',
        'icon': Icons.payments_outlined,
        'color': const Color(0xFF00B4D8),
        'tag': 'Supported',
        'isLinked': true,
      },
    ];
  }

  bool _merchandiseProtection = true;
  bool _isPlacingOrder = false;

  // Voucher & Message for Seller State
  ShopVoucherModel? _appliedVoucher;
  double _voucherDiscount = 0.0;
  String _sellerMessage = '';

  // Dynamic Shipping Option State
  String _selectedShippingType = 'door_to_door';
  String _selectedShippingName = 'Standard Local';
  String _estimatedArrivalDate = '8 - 9 Oct';
  double _selectedShippingFee = 0.0;
  String? _selectedPickupLocation;

  final CartService _cartService = CartService.instance;
  final OrderService _orderService = OrderService.instance;

  // Persisted snapshot of items being checked out
  List<CartItemModel> _checkoutItems = [];

  @override
  void initState() {
    super.initState();
    _syncDefaultPaymentSelection();
    PaymentMethodService.instance.addListener(_onPaymentServiceChanged);
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

    // Require login if in guest mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!BuyerAccountService.instance.isLoggedIn && mounted) {
        GuestAuthGuard.requireLogin(
          context,
          title: 'Sign In Required for Checkout',
          message: 'Please sign in or create an account to finalize your order, apply shipping details, and track your package.',
        ).then((authenticated) {
          if (!authenticated && mounted) {
            Navigator.pop(context);
          } else if (mounted) {
            _syncDefaultPaymentSelection();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    PaymentMethodService.instance.removeListener(_onPaymentServiceChanged);
    super.dispose();
  }

  void _onPaymentServiceChanged() {
    if (mounted) {
      setState(() {
        _syncDefaultPaymentSelection();
      });
    }
  }

  void _syncDefaultPaymentSelection() {
    final defaultMethod = PaymentMethodService.instance.defaultMethod;
    final opts = _paymentOptions;
    if (defaultMethod.type == PaymentType.gcash && defaultMethod.isLinked) {
      final idx = opts.indexWhere((o) => o['id'] == 'gcash');
      if (idx != -1) _selectedPaymentIndex = idx;
    } else if (defaultMethod.type == PaymentType.card && defaultMethod.isLinked) {
      final idx = opts.indexWhere((o) => o['id'] == defaultMethod.id);
      if (idx != -1) _selectedPaymentIndex = idx;
    } else {
      _selectedPaymentIndex = 0; // Cash on Delivery
    }
  }

  double get _merchandiseSubtotal {
    if (_checkoutItems.isNotEmpty) {
      final total = _checkoutItems.fold<double>(
        0.0,
        (sum, item) => sum + ((item.originalPrice ?? item.price) * item.quantity),
      );
      if (total > 0) return total;
    }
    final checked = _cartService.items.where((i) => i.isChecked);
    if (checked.isEmpty) return 490.0;
    return _cartService.originalSubtotal > 0 ? _cartService.originalSubtotal : 490.0;
  }

  double get _effectiveSubtotal {
    if (_checkoutItems.isNotEmpty) {
      final total = _checkoutItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );
      if (total > 0) return total;
    }
    return _cartService.subtotal;
  }

  double get _itemDiscount {
    final diff = _merchandiseSubtotal - _effectiveSubtotal;
    return diff > 0 ? diff : 0.0;
  }

  double get _shippingSubtotal => _selectedShippingFee > 0 ? 75.0 : 34.0;
  double get _shippingDiscount => _selectedShippingFee > 0 ? 30.0 : 34.0;

  double get _finalTotal {
    final baseProductTotal = _merchandiseSubtotal - _itemDiscount - _voucherDiscount;
    final actualShippingPaid = _selectedShippingFee;
    final protection = _merchandiseProtection ? 12.0 : 0.0;
    final total = (baseProductTotal > 0 ? baseProductTotal : 0.0) + actualShippingPaid + protection;
    return total < 0 ? 0.0 : total;
  }

  double get _totalSaved => _itemDiscount + _shippingDiscount + _voucherDiscount;

  Future<void> _openShippingOptionModal() async {
    final result = await showModalBottomSheet<ShippingOptionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShippingOptionModal(
        initialSelection: ShippingOptionResult(
          methodType: _selectedShippingType,
          optionName: _selectedShippingName,
          estimatedDate: _estimatedArrivalDate,
          shippingFee: _selectedShippingFee,
          pickupLocation: _selectedPickupLocation,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedShippingType = result.methodType;
        _selectedShippingName = result.optionName;
        _estimatedArrivalDate = result.estimatedDate;
        _selectedShippingFee = result.shippingFee;
        _selectedPickupLocation = result.pickupLocation;
      });
    }
  }

  ShopModel _resolveShop(String storeName) {
    final lower = storeName.toLowerCase().trim();
    for (final s in ShopService.instance.allShops) {
      if (s.name.toLowerCase().contains(lower) || lower.contains(s.name.toLowerCase())) {
        return s;
      }
    }
    return ShopService.nexoraOfficialStore;
  }

  Future<void> _openShopVoucherModal(String storeName) async {
    final shop = _resolveShop(storeName);
    final storeVouchers = shop.vouchers;
    final promoCodeController = TextEditingController();
    String? promoError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 16,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                        color: Colors.grey.shade300,
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
                            const Text(
                              'Shop Vouchers',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              shop.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_appliedVoucher != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _appliedVoucher = null;
                              _voucherDiscount = 0.0;
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Voucher removed')),
                            );
                          },
                          child: const Text(
                            'Remove',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Promo Code Input Box
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: promoError != null ? Colors.red : const Color(0xFFE2E8F0),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: promoCodeController,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter Voucher / Promo Code',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            final code = promoCodeController.text.trim().toUpperCase();
                            if (code.isEmpty) return;

                            ShopVoucherModel? matchedVoucher;
                            if (code == 'NEXORA100' || code == 'STUDIO100' || code == 'NL100') {
                              matchedVoucher = const ShopVoucherModel(
                                id: 'promo_100',
                                discountTitle: '₱100 OFF',
                                tag: 'Promo Code',
                                minSpend: 'Min. spend ₱0',
                                expiry: 'Exp: 31.12.2026',
                                buttonColor: Color(0xFF0066FF),
                                discountAmount: 100,
                              );
                            } else if (code == 'NEXORA10' || code == 'VIP10') {
                              matchedVoucher = const ShopVoucherModel(
                                id: 'promo_10pct',
                                discountTitle: '10% OFF',
                                tag: 'Promo VIP',
                                minSpend: 'Min. spend ₱0',
                                expiry: 'Exp: 31.12.2026',
                                buttonColor: Color(0xFF0066FF),
                                discountAmount: 0.10,
                                isPercentage: true,
                              );
                            } else if (code == 'NEXORA50' || code == 'WELCOME50') {
                              matchedVoucher = const ShopVoucherModel(
                                id: 'promo_50',
                                discountTitle: '₱50 OFF',
                                tag: 'Welcome',
                                minSpend: 'Min. spend ₱0',
                                expiry: 'Exp: 31.12.2026',
                                buttonColor: Color(0xFF0066FF),
                                discountAmount: 50,
                              );
                            } else {
                              setModalState(() {
                                promoError = 'Invalid code. Try NEXORA100 or select a voucher below.';
                              });
                              return;
                            }

                            _applyVoucherModel(matchedVoucher);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  if (promoError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      promoError!,
                      style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 18),

                  const Text(
                    'Available Store Vouchers',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (storeVouchers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No specific store vouchers available for this shop right now.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    ...storeVouchers.map((v) {
                      final isSelected = _appliedVoucher?.id == v.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF0066FF) : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          onTap: () {
                            _applyVoucherModel(v);
                            Navigator.pop(ctx);
                          },
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.confirmation_num_outlined, color: Color(0xFF0066FF), size: 22),
                          ),
                          title: Row(
                            children: [
                              Text(
                                v.discountTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  v.tag,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${v.minSpend} • ${v.expiry}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0066FF), size: 22)
                              : ElevatedButton(
                                  onPressed: () {
                                    _applyVoucherModel(v);
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0066FF),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Apply', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                ),
                        ),
                      );
                    }),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _applyVoucherModel(ShopVoucherModel voucher) {
    double discount = 0.0;
    if (voucher.isPercentage) {
      discount = _effectiveSubtotal * voucher.discountAmount;
    } else {
      discount = voucher.discountAmount;
    }
    if (discount > _effectiveSubtotal) {
      discount = _effectiveSubtotal;
    }
    setState(() {
      _appliedVoucher = voucher;
      _voucherDiscount = discount;
    });
    ShopService.instance.claimVoucher(voucher.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Applied voucher: ${voucher.discountTitle}! Saved ₱${discount.toStringAsFixed(0)}'),
        backgroundColor: const Color(0xFF0066FF),
      ),
    );
  }

  Future<void> _openSellerMessageModal(String storeName) async {
    final controller = TextEditingController(text: _sellerMessage);
    final quickNotes = [
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
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 16,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                        color: Colors.grey.shade300,
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
                            const Text(
                              'Message for Seller',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Special note for $storeName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_sellerMessage.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _sellerMessage = '';
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Clear', style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: controller,
                    maxLines: 3,
                    maxLength: 200,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'e.g. Please ensure bubble wrapping, fragile goods inside.',
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    'Quick Notes',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: quickNotes.map((note) {
                      return ActionChip(
                        label: Text(
                          note,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                        onPressed: () {
                          setModalState(() {
                            if (controller.text.isEmpty) {
                              controller.text = note;
                            } else {
                              controller.text = '${controller.text}, $note';
                            }
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
                          _sellerMessage = controller.text.trim();
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPaymentMethodModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final options = _paymentOptions;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select your preferred payment method for this order.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(options.length, (idx) {
                final opt = options[idx];
                final isSelected = _selectedPaymentIndex == idx;
                final Color optColor = opt['color'] as Color;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? optColor.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? optColor : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    onTap: () async {
                      final isLinked = opt['isLinked'] == true;
                      if (!isLinked) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please link your GCash account first to use GCash at checkout.'),
                            backgroundColor: Color(0xFF005CE6),
                          ),
                        );
                        await Navigator.pushNamed(context, AppRoutes.paymentMethods);
                        if (mounted) {
                          setState(() {
                            final gcashLinked = PaymentMethodService.instance.gcashMethod?.isLinked == true;
                            if (gcashLinked) {
                              _selectedPaymentIndex = idx;
                            }
                          });
                        }
                        return;
                      }
                      setState(() {
                        _selectedPaymentIndex = idx;
                      });
                      Navigator.pop(ctx);
                    },
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: optColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(opt['icon'] as IconData, color: optColor, size: 20),
                    ),
                    title: Row(
                      children: [
                        Text(
                          opt['shortName'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: isSelected ? optColor : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: (opt['isLinked'] == true)
                                ? optColor.withValues(alpha: 0.12)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            opt['tag'] as String,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: (opt['isLinked'] == true) ? optColor : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      opt['desc'] as String,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    trailing: (opt['isLinked'] != true)
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF005CE6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Link Account',
                              style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          )
                        : (isSelected
                            ? Icon(Icons.check_circle, color: optColor, size: 22)
                            : const Icon(Icons.radio_button_off, color: Color(0xFFCBD5E1), size: 20)),
                  ),
                );
              }),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0066FF)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All payments processed via Nexora Guaranteed 256-bit encryption. Bangko Sentral ng Pilipinas compliant.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handlePlaceOrder() async {
    if (!BuyerAccountService.instance.isLoggedIn) {
      final authenticated = await GuestAuthGuard.requireLogin(
        context,
        title: 'Sign In to Place Order',
        message: 'Please sign in or create an account to finalize your order.',
      );
      if (!authenticated || !mounted) return;
    }

    final defaultAddr = AddressService.instance.defaultAddress;
    final int? addrId = defaultAddr != null ? int.tryParse(defaultAddr.id) : null;
    if (defaultAddr == null || addrId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add or select a delivery address before placing your order.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NewAddressPage()),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    _currentAttemptIdempotencyKey ??=
        'chk_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 10000}';

    String orderId = '';
    String selectedPayment = 'Cash on Delivery';

    try {
      final options = _paymentOptions;
      final safeIndex = (_selectedPaymentIndex >= 0 && _selectedPaymentIndex < options.length)
          ? _selectedPaymentIndex
          : 0;
      selectedPayment = (options[safeIndex]['name'] ?? 'Cash on Delivery').toString();

      List<int>? cartItemIds;
      // If Buy Now direct item, add to remote cart first and checkout ONLY that item (B2)
      if (_cartService.directBuyItem != null) {
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
          variant: dItem.variantData is Map<String, dynamic> ? dItem.variantData : null,
        );
        if (createdCartItemId == null || createdCartItemId <= 0) {
          throw const ApiException(
            message: 'Unable to prepare item for checkout.',
            statusCode: 500,
          );
        }
        cartItemIds = [createdCartItemId];
      }

      // Hit Laravel POST /api/mobile/v1/buyer/checkout
      final orders = await _orderService.placeOrderRemote(
        addressId: addrId,
        paymentMethod: 'cod',
        idempotencyKey: _currentAttemptIdempotencyKey,
        cartItemIds: cartItemIds,
      );

      if (orders.isEmpty) {
        throw const ApiException(
          message: 'Checkout did not create any orders.',
          statusCode: 500,
        );
      }

      final firstOrd = orders[0];
      orderId = (firstOrd['order_number'] ?? '#${firstOrd['id']}').toString();

      // Reset idempotency key on success and synchronize state from server
      _currentAttemptIdempotencyKey = null;
      _cartService.clearDirectBuy();
      await _cartService.loadCartRemote();
      await _orderService.fetchOrdersRemote();

    } catch (e, st) {
      debugPrint('⚠️ Checkout error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _isPlacingOrder = false;
      });

      String userMsg = e.toString();
      if (e is ApiException) {
        userMsg = e.message;
      } else if (userMsg.startsWith('Exception: ')) {
        userMsg = userMsg.substring(11);
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text('Checkout Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isPlacingOrder = false;
    });

    try {
      ExternalNotificationService.show(
        title: '📦 Nexora Order Placed ($selectedPayment)',
        body: 'Order $orderId has been placed. You will receive real-time courier updates here!',
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
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F7FA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF00B4D8),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Order $orderId has been placed ($_selectedShippingName • Est. $_estimatedArrivalDate). Track your delivery real-time in My Orders.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D2FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text(
                    'View Order Status',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            }
          },
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF64748B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nexora Checkout Help & Buyer Protection')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // 1. Delivery Address Card
                _buildAddressCard(),

                const SizedBox(height: 10),

                // 2. Store & Item Card Group
                _buildStoreAndItemCard(),

                const SizedBox(height: 10),

                // 3. Shipping Option Card (Clickable to change delivery option!)
                _buildShippingOptionCard(),

                const SizedBox(height: 10),

                // 4. Platform Vouchers Card
                _buildVoucherCard(),

                const SizedBox(height: 10),

                // 5. Payment Methods Card
                _buildPaymentMethodsCard(),

                const SizedBox(height: 10),

                // 6. Payment Details Summary Breakdown
                _buildPaymentDetailsCard(),

                // Clearance spacing for bottom dock
                const SizedBox(height: 110),
              ],
            ),
          ),

          // Bottom Fixed Action Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomCheckoutDock(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (AddressService.instance.addresses.isEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewAddressPage()),
              );
            } else {
              Navigator.pushNamed(context, AppRoutes.myAddresses);
            }
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.location_on, color: Color(0xFF00B4D8), size: 18),
                    ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([ProfileService.instance, AddressService.instance]),
                    builder: (context, _) {
                      final defaultAddr = AddressService.instance.defaultAddress;
                      final profile = ProfileService.instance;
                      final addressStr = defaultAddr?.fullAddress ?? profile.address;
                      final name = defaultAddr?.fullName ?? (profile.name.isNotEmpty ? profile.name : 'Recipient');
                      final phone = defaultAddr?.phone ?? profile.phone;

                      if (addressStr.trim().isEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Row(
                              children: [
                                Icon(Icons.add_circle_outline, color: Color(0xFF00B4D8), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Add Delivery Address',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: Color(0xFF00B4D8),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Tap to set your delivery address for this order',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (phone.isNotEmpty)
                                  TextSpan(
                                    text: phone,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            addressStr,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF475569),
                              height: 1.3,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
          ),

          // Dashed Cyan/Blue Segment Ribbon at bottom of Address Card
          SizedBox(
            height: 4,
            child: Row(
              children: List.generate(15, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: index % 2 == 0 ? const Color(0xFF00D2FF) : const Color(0xFF0066FF),
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

  Widget _buildStoreAndItemCard() {
    final itemsToDisplay = _checkoutItems.isNotEmpty
        ? _checkoutItems
        : _cartService.items.where((i) => i.isChecked).toList();

    final storeBadge = itemsToDisplay.isNotEmpty && itemsToDisplay.first.storeBadge.isNotEmpty
        ? itemsToDisplay.first.storeBadge
        : 'MALL';
    final storeName = itemsToDisplay.isNotEmpty && itemsToDisplay.first.storeName.isNotEmpty
        ? itemsToDisplay.first.storeName
        : 'Nexora Official Store';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  storeBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),

          const SizedBox(height: 12),

          // Items List
          if (itemsToDisplay.isEmpty)
            _buildItemRow(
              imageUrl:
                  'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=300&q=80',
              title: 'Nexora StreamMic D20 Professional Condenser Microphone',
              variant: 'Tight Cardioid Solo',
              price: '₱299',
              originalPrice: '₱490',
              qty: 1,
            )
          else
            ...itemsToDisplay.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildItemRow(
                  imageUrl: item.imageUrl,
                  title: item.title,
                  variant: item.variant,
                  price: '₱${item.price.toStringAsFixed(0)}',
                  originalPrice: item.originalPrice != null
                      ? '₱${item.originalPrice!.toStringAsFixed(0)}'
                      : null,
                  qty: item.quantity,
                ),
              );
            }),

          const SizedBox(height: 10),

          // Merchandise Protection Checkbox Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _merchandiseProtection = !_merchandiseProtection;
                    });
                  },
                  child: Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: _merchandiseProtection ? const Color(0xFF00D2FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: _merchandiseProtection
                          ? null
                          : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                    ),
                    child: _merchandiseProtection
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Merchandise Protection',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '₱12 x 1',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.3),
                          children: [
                            TextSpan(
                              text:
                                  'Protect your items from total loss due to accidental damage and liquid damage where the original item is beyond repair. ',
                            ),
                            TextSpan(
                              text: 'Learn more >',
                              style: TextStyle(
                                color: Color(0xFF0066FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action Rows: Shop Voucher, Message for Seller, E-receipt
          _buildActionRow(
            label: 'Shop Voucher',
            value: _appliedVoucher != null
                ? '-₱${_voucherDiscount.toStringAsFixed(0)} (${_appliedVoucher!.discountTitle}) >'
                : 'Select or enter code >',
            valueColor: _appliedVoucher != null ? const Color(0xFF0066FF) : const Color(0xFF94A3B8),
            onTap: () => _openShopVoucherModal(storeName),
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildActionRow(
            label: 'Message for Seller',
            value: _sellerMessage.isNotEmpty ? '$_sellerMessage >' : 'Please leave a message >',
            valueColor: _sellerMessage.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            onTap: () => _openSellerMessageModal(storeName),
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildActionRow(
            label: 'E-receipt ⓘ',
            value: 'Request Now >',
            valueColor: const Color(0xFF94A3B8),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('E-receipt will be sent to your registered email upon order completion.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required String imageUrl,
    required String title,
    required String variant,
    required String price,
    String? originalPrice,
    required int qty,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 72,
              height: 72,
              color: const Color(0xFFE2E8F0),
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFF0F172A),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  variant,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (originalPrice != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      originalPrice,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Text(
          'x$qty',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildShippingOptionCard() {
    final isFree = _selectedShippingFee == 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shipping Option',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              GestureDetector(
                onTap: _openShippingOptionModal,
                child: const Text(
                  'View All >',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF0066FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Selected Shipping Option Box (Clickable!)
          GestureDetector(
            onTap: _openShippingOptionModal,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00D2FF), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00D2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 11, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _estimatedArrivalDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _selectedShippingName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (isFree) ...[
                        const Text(
                          '₱34',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F7FA),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF00B4D8), width: 0.8),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Free ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00B4D8),
                                ),
                              ),
                              Icon(Icons.local_shipping, size: 11, color: Color(0xFF00B4D8)),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          '₱${_selectedShippingFee.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.access_time_filled, size: 14, color: Color(0xFF00B4D8)),
              SizedBox(width: 4),
              Text(
                'Get up to ₱40 if order arrives late',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const Divider(height: 16, color: Color(0xFFF1F5F9)),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total 1 Item(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                '₱${_finalTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, size: 18, color: Color(0xFF00D2FF)),
          const SizedBox(width: 8),
          const Text(
            'Platform Vouchers',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF00B4D8), width: 0.8),
            ),
            child: const Row(
              children: [
                Text(
                  'Free Shipping Discount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B4D8),
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 12, color: Color(0xFF00B4D8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    final options = _paymentOptions;
    final selectedOption = options[_selectedPaymentIndex.clamp(0, options.length - 1)];
    final Color optColor = selectedOption['color'] as Color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: _openPaymentMethodModal,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: optColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: optColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: optColor,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.chevron_right, size: 14, color: optColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Selected Payment Method Display Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: optColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: optColor.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: optColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    selectedOption['icon'] as IconData,
                    color: optColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            selectedOption['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedOption['desc'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle_rounded,
                  color: optColor,
                  size: 20,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Informative helper banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 15, color: optColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'All payments protected by Nexora Buyer Guarantee and 256-bit encrypted checkout.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Details',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          _buildDetailRow('Merchandise Subtotal', '₱${_merchandiseSubtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _buildDetailRow('Shipping Subtotal', '₱${_shippingSubtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _buildDetailRow('Item Discount', '-₱${_itemDiscount.toStringAsFixed(0)}',
              valueColor: const Color(0xFF0F172A)),
          const SizedBox(height: 6),
          _buildDetailRow('Shipping Discount Subtotal', '-₱${_shippingDiscount.toStringAsFixed(0)}',
              valueColor: const Color(0xFF0F172A)),
          if (_voucherDiscount > 0) ...[
            const SizedBox(height: 6),
            _buildDetailRow(
              'Shop Voucher Discount',
              '-₱${_voucherDiscount.toStringAsFixed(0)}',
              valueColor: const Color(0xFF0F172A),
            ),
          ],

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payment',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '₱${_finalTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required String label,
    required String value,
    required Color valueColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
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

  Widget _buildBottomCheckoutDock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'Total: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '₱${_finalTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Saved ₱${_totalSaved.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B4D8),
                  ),
                ),
              ],
            ),

            // Vibrant Place Order Blue Button
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _isPlacingOrder
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Place Order',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
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
