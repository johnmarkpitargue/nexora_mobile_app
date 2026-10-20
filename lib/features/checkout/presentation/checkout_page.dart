import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/core/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/shipping_option_modal.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _selectedPaymentIndex = 0;
  final List<Map<String, dynamic>> _paymentOptions = [
    {
      'name': 'Cash on Delivery',
      'desc': 'Pay in cash upon doorstep delivery',
      'icon': Icons.payments_outlined,
      'color': Color(0xFF00B4D8),
      'tag': 'Supported',
    },
  ];

  bool _merchandiseProtection = true;
  final bool _useCoins = false;
  bool _isPlacingOrder = false;

  // Dynamic Shipping Option State
  String _selectedShippingType = 'door_to_door';
  String _selectedShippingName = 'Standard Local';
  String _estimatedArrivalDate = '8 - 9 Oct';
  double _selectedShippingFee = 0.0;
  String? _selectedPickupLocation;

  final CartService _cartService = CartService.instance;
  final OrderService _orderService = OrderService.instance;

  double get _merchandiseSubtotal {
    final checked = _cartService.items.where((i) => i.isChecked);
    if (checked.isEmpty) return 490.0;
    return _cartService.originalSubtotal > 0 ? _cartService.originalSubtotal : 490.0;
  }

  double get _itemDiscount {
    final checked = _cartService.items.where((i) => i.isChecked);
    if (checked.isEmpty) return 191.0;
    final diff = _merchandiseSubtotal - _cartService.subtotal;
    return diff > 0 ? diff : 191.0;
  }

  double get _shippingSubtotal => _selectedShippingFee > 0 ? 75.0 : 34.0;
  double get _shippingDiscount => _selectedShippingFee > 0 ? 30.0 : 34.0;

  double get _finalTotal {
    final baseProductTotal = _merchandiseSubtotal - _itemDiscount;
    final actualShippingPaid = _selectedShippingFee;
    final protection = _merchandiseProtection ? 12.0 : 0.0;
    final total = baseProductTotal + actualShippingPaid + protection;
    return total < 0 ? 0.0 : total;
  }

  double get _totalSaved => _itemDiscount + _shippingDiscount;

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


  void _openPaymentMethodModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'We currently offer Cash on Delivery (COD) exclusively for all orders.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00B4D8),
                  width: 1.5,
                ),
              ),
              child: ListTile(
                onTap: () {
                  setState(() {
                    _selectedPaymentIndex = 0;
                  });
                  Navigator.pop(ctx);
                },
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4D8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payments_outlined, color: Color(0xFF00B4D8), size: 20),
                ),
                title: Row(
                  children: [
                    const Text(
                      'Cash on Delivery',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F7FA),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B4D8),
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Pay in cash upon doorstep delivery',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                trailing: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF00B4D8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Other payment methods are not available at this time. Cash on Delivery is guaranteed and supported for all orders.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePlaceOrder() {
    setState(() {
      _isPlacingOrder = true;
    });

    final selectedItems = _cartService.removeAndGetSelectedItems();
    final selectedPayment = _paymentOptions[_selectedPaymentIndex]['name'] as String;
    final currentTotal = _finalTotal;
    final profile = ProfileService.instance;

    _orderService.placeOrder(
      items: selectedItems.isEmpty
          ? [
              CartItemModel(
                id: 'checkout_default',
                storeName: 'Mikana Official Store',
                storeBadge: 'MALL',
                title: 'Mikana Eternal Waves Hinokari Gold Plated Bracelet & Ring Edition',
                variant: 'Hateshinai',
                imageUrl:
                    'https://images.unsplash.com/photo-1603561591411-07134e71a2a9?auto=format&fit=crop&w=300&q=80',
                price: 299.00,
                originalPrice: 490.00,
                quantity: 1,
              )
            ]
          : selectedItems,
      totalPrice: currentTotal,
      paymentMethod: selectedPayment,
      recipientName: profile.name,
      recipientPhone: profile.phone,
      shippingAddress: profile.address,
      shippingOption: _selectedShippingName,
      shippingFee: _selectedShippingFee,
      subtotal: _merchandiseSubtotal,
      discount: _totalSaved,
      estimatedArrival: _estimatedArrivalDate,
    );

    final placedOrder = _orderService.latestActiveOrder;
    final orderId = placedOrder?.orderId ?? '#NX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Broadcast order to Supabase so the Rider App gets notified live!
    try {
      final itemsSummary = selectedItems.isEmpty
          ? 'Mikana Eternal Waves Bracelet & Ring Edition'
          : selectedItems.map((e) => '${e.quantity}x ${e.title}').join(', ');

      Supabase.instance.client.from('orders').insert({
        'order_id': orderId.replaceAll('#', ''),
        'customer_id': profile.name.isNotEmpty ? profile.name : 'Customer',
        'item_details': itemsSummary,
        'delivery_address': profile.address.isNotEmpty
            ? profile.address
            : 'Brgy. Real, Calamba City, Laguna',
        'delivery_lat': 14.2135,
        'delivery_lng': 121.1731,
        'status': 'pending',
      }).then((_) {
        debugPrint('✅ Order $orderId inserted into Supabase!');
      }).catchError((err) {
        debugPrint('⚠️ Supabase order broadcast notice: $err');
      });
    } catch (e) {
      debugPrint('⚠️ Supabase order broadcast error: $e');
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _isPlacingOrder = false;
      });

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
                  'Order $orderId has been dispatched ($_selectedShippingName • Est. $_estimatedArrivalDate). Track your delivery real-time in My Orders.',
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
                        arguments: {'initialIndex': 3},
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
    });
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

                // 4. Platform Vouchers & Coins Card
                _buildVoucherAndCoinsCard(),

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
            Navigator.pushNamed(context, AppRoutes.myAddresses);
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
                    animation: ProfileService.instance,
                    builder: (context, _) {
                      final profile = ProfileService.instance;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${profile.name} ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                TextSpan(
                                  text: profile.phone,
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
                            profile.address,
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
    final checkedItems = _cartService.items.where((i) => i.isChecked).toList();

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
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  checkedItems.isNotEmpty && checkedItems.first.storeBadge.isNotEmpty
                      ? checkedItems.first.storeBadge
                      : 'Mall',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                checkedItems.isNotEmpty && checkedItems.first.storeName.isNotEmpty
                    ? checkedItems.first.storeName
                    : 'Mikana Official Store',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),

          const SizedBox(height: 12),

          // Items List
          if (checkedItems.isEmpty)
            _buildItemRow(
              imageUrl:
                  'https://images.unsplash.com/photo-1603561591411-07134e71a2a9?auto=format&fit=crop&w=300&q=80',
              title: 'Mikana Eternal Waves Hinokari Gold Plated Bracelet & Ring Edition',
              variant: 'Hateshinai',
              price: '₱299',
              originalPrice: '₱490',
              qty: 1,
            )
          else
            ...checkedItems.map((item) {
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
            value: 'Select or enter code >',
            valueColor: const Color(0xFF94A3B8),
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildActionRow(
            label: 'Message for Seller',
            value: 'Please leave a message >',
            valueColor: const Color(0xFF94A3B8),
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildActionRow(
            label: 'E-receipt ⓘ',
            value: 'Request Now >',
            valueColor: const Color(0xFF94A3B8),
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
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  '0% PayLater (up to 3M)',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFF0284C7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      color: Color(0xFF0066FF),
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

  Widget _buildVoucherAndCoinsCard() {
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
        children: [
          // Platform Vouchers Row
          Row(
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

          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // Coins Switch Row
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined, size: 18, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              const Text(
                'Coins cannot be redeemed ⓘ',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const Spacer(),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: _useCoins,
                  onChanged: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
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
                    color: const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF00B4D8).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'COD Only',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00B4D8),
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.info_outline, size: 12, color: Color(0xFF00B4D8)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cash on Delivery Card (Active & Exclusive)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF00D2FF),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4D8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFF00B4D8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Cash on Delivery (COD)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pay in cash upon doorstep delivery',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00D2FF),
                  ),
                  child: const Icon(Icons.check, size: 13, color: Colors.white),
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
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 15, color: Color(0xFF00B4D8)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cash on Delivery is currently our only offered payment method. Please prepare exact payment upon delivery.',
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
              valueColor: const Color(0xFF0066FF)),
          const SizedBox(height: 6),
          _buildDetailRow('Shipping Discount Subtotal', '-₱${_shippingDiscount.toStringAsFixed(0)}',
              valueColor: const Color(0xFF0066FF)),

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
                  color: Color(0xFF0066FF),
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
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            color: valueColor,
          ),
        ),
      ],
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
                        color: Color(0xFF0066FF),
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

            // Vibrant Place Order Cyan Button
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D2FF),
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
