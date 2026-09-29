import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _selectedPaymentIndex = 0; // 0: NexoraPay, 1: GCash, 2: Visa/Mastercard, 3: COD
  bool _usePoints = true;
  bool _voucherApplied = true;
  bool _isPlacingOrder = false;

  final CartService _cartService = CartService.instance;
  final OrderService _orderService = OrderService.instance;

  final TextEditingController _voucherController =
      TextEditingController(text: 'NEXORAWELCOME');

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  double get _subtotal {
    final checked = _cartService.items.where((i) => i.isChecked);
    if (checked.isEmpty) return 3200.0;
    return _cartService.subtotal;
  }

  double get _voucherDiscount => _voucherApplied ? 150.0 : 0.0;
  double get _pointsDiscount => _usePoints ? 50.0 : 0.0;
  double get _shippingFee => 0.0; // Free Shipping Voucher

  double get _finalTotal {
    final tot = _subtotal - _voucherDiscount - _pointsDiscount + _shippingFee;
    return tot < 0 ? 0.0 : tot;
  }

  void _handlePlaceOrder() {
    setState(() {
      _isPlacingOrder = true;
    });

    final selectedItems = _cartService.removeAndGetSelectedItems();
    final paymentMethods = [
      'Paid via NexoraPay',
      'Paid via GCash',
      'Paid via Visa/Mastercard',
      'Cash on Delivery',
    ];
    final selectedPayment = paymentMethods[_selectedPaymentIndex];
    final currentTotal = _finalTotal;

    _orderService.placeOrder(
      items: selectedItems,
      totalPrice: currentTotal,
      paymentMethod: selectedPayment,
    );

    final placedOrder = _orderService.latestActiveOrder;
    final orderId = placedOrder?.orderId ?? '#NX-89241';

    Future.delayed(const Duration(milliseconds: 1000), () {
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
                  'Order $orderId has been dispatched. Track your delivery real-time in My Orders.',
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
                      Navigator.pushReplacementNamed(context, AppRoutes.orders);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text(
                      'View Order Status',
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
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Top Custom Header App Bar
                  _buildCustomAppBar(context),
                  const SizedBox(height: 12),

                  // Step Progress Indicator
                  _buildStepIndicator(),
                  const SizedBox(height: 14),

                  // Shipping Address Card
                  _buildShippingAddressCard(),
                  const SizedBox(height: 14),

                  // Order Items Card
                  _buildOrderItemsCard(),
                  const SizedBox(height: 14),

                  // Delivery Method Card
                  _buildDeliveryMethodCard(),
                  const SizedBox(height: 14),

                  // Discounts & Rewards Card
                  _buildDiscountsCard(),
                  const SizedBox(height: 14),

                  // Payment Method Card
                  _buildPaymentMethodCard(),
                  const SizedBox(height: 16),

                  // Payment Summary Card
                  _buildPaymentSummaryCard(),
                  const SizedBox(height: 120),
                ],
              ),
            ),

            // Bottom Sticky Checkout Bar
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildBottomCheckoutBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            }
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF0F172A)),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.chat);
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CHECKOUT STEP 2 OF 3',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0066FF),
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 12, color: Color(0xFF64748B)),
                  SizedBox(width: 4),
                  Text(
                    'Encrypted 256-bit',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 3-step progress bar
          Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.66,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D2FF), Color(0xFF0066FF)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1. Bag',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0066FF),
                ),
              ),
              Text(
                '2. Review & Pay',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0066FF),
                ),
              ),
              Text(
                '3. Complete',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddressCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F7FA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF00B4D8),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Shipping Address',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening address picker...')),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'Change',
                      style: TextStyle(
                        color: Color(0xFF0066FF),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xFF0066FF),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Wrap user name and badges cleanly for narrow screens
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              const Text(
                'Alex Rivera',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Text(
                '(+63 917 123 4567)',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Default Home',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Unit 402, Lumina Heights Tower 2, Makati City, Metro Manila, 1226',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          // Delivery Instructions box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 16,
                  color: Color(0xFF00B4D8),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DELIVERY INSTRUCTIONS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'Leave with front desk / reception',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    final checkedItems = _cartService.items.where((i) => i.isChecked).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F7FA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFF00B4D8),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Order Items (${checkedItems.isEmpty ? 1 : checkedItems.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Standard Parcel',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (checkedItems.isEmpty)
            _buildOrderItemRow(
              imageUrl:
                  'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=150&q=80',
              badgeText: '75% Layout',
              title: 'Nexora Aura 75 Mechanical Keyboard',
              subtitle: 'Chalk White / Violet • Linear Switches',
              tag: '• In Stock (Direct Factory)',
              price: '₱3,200.00',
              qty: 1,
              onDecrease: () {},
              onIncrease: () {},
            )
          else
            ...checkedItems.map((item) {
              return Column(
                children: [
                  _buildOrderItemRow(
                    imageUrl: item.imageUrl,
                    badgeText: item.storeBadge.isEmpty ? 'Nexora' : item.storeBadge,
                    title: item.title,
                    subtitle: item.variant,
                    tag: '• In Stock',
                    price: '₱${(item.price * item.quantity).toStringAsFixed(2)}',
                    qty: item.quantity,
                    onDecrease: () {
                      if (item.quantity > 1) {
                        _cartService.updateQuantity(item.id, item.quantity - 1);
                      }
                    },
                    onIncrease: () {
                      _cartService.updateQuantity(item.id, item.quantity + 1);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow({
    required String imageUrl,
    required String badgeText,
    required String title,
    required String subtitle,
    required String tag,
    required String price,
    required int qty,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.shopping_bag,
                  color: Color(0xFF94A3B8),
                  size: 28,
                ),
              ),
            ),
            Positioned(
              bottom: 3,
              left: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tag,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00B4D8),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                  // Quantity Stepper Button
                  Container(
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 13),
                          onPressed: onDecrease,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                        Text(
                          '$qty',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 13),
                          onPressed: onIncrease,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F7FA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: Color(0xFF00B4D8),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Delivery Method',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Guaranteed On Time',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0891B2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Selected Delivery Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00D2FF), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F7FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.electric_rickshaw,
                    color: Color(0xFF00B4D8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          const Text(
                            'Nexora Express',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B4D8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'FAST TRACK',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '24h Delivery',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fast-track direct rider dispatch',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Color(0xFF0066FF)),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Estimated: Tomorrow, 2:00 PM - 5:00 PM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0066FF),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '₱120.00',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Covered by\nVoucher',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE4E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: Color(0xFFE11D48),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Discounts & Rewards',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Coupon Code Input Field
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer_outlined,
                          size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _voucherController,
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _voucherApplied = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  elevation: 0,
                ),
                child: const Text(
                  'Applied',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Active Voucher Chips
          if (_voucherApplied) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 12, color: Color(0xFF0066FF)),
                      const SizedBox(width: 4),
                      const Text(
                        'NEXORAWELCOME (-₱150.00 OFF)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0066FF),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _voucherApplied = false;
                          });
                        },
                        child: const Icon(Icons.close, size: 12, color: Color(0xFF0066FF)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping, size: 12, color: Color(0xFF00B4D8)),
                      SizedBox(width: 4),
                      Text(
                        'Free Shipping Applied (-₱120.00)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B4D8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Loyalty Points Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE9FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on_outlined,
                    color: Color(0xFF7C3AED),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          const Text(
                            'Nexora Loyalty Points ',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD6D6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '850 Available',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE11D48),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Redeem 850 points for ₱85.00 discount',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _usePoints,
                  onChanged: (val) {
                    setState(() {
                      _usePoints = val;
                    });
                  },
                  activeTrackColor: const Color(0xFF00D2FF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    final paymentMethods = [
      {
        'title': 'NexoraPay Balance',
        'badge': 'Fastest',
        'subtitle': 'Available balance: ₱1,850.50\n(Remainder to GCash)',
        'icon': Icons.bolt_rounded,
        'iconColor': const Color(0xFF0066FF),
      },
      {
        'title': 'GCash e-Wallet',
        'subtitle': 'Instant linking • Fast mobile checkout',
        'icon': Icons.account_balance_wallet_outlined,
        'iconColor': const Color(0xFF0891B2),
      },
      {
        'title': 'Visa / Mastercard •••• 4012',
        'subtitle': 'Expires 09/27',
        'icon': Icons.credit_card_rounded,
        'iconColor': const Color(0xFF64748B),
      },
      {
        'title': 'Cash on Delivery (COD)',
        'subtitle': 'Pay in cash upon doorstep arrival',
        'icon': Icons.payments_outlined,
        'iconColor': const Color(0xFF64748B),
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F7FA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payment_rounded,
                      color: Color(0xFF00B4D8),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const Text(
                'Zero Fee',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF00B4D8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Payment Options List
          Column(
            children: List.generate(paymentMethods.length, (index) {
              final isSelected = _selectedPaymentIndex == index;
              final item = paymentMethods[index];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPaymentIndex = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF4F9FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00D2FF) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? const Color(0xFF00B4D8) : Colors.transparent,
                          border: isSelected
                              ? null
                              : Border.all(color: const Color(0xFFCBD5E1), width: 2),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                    fontSize: 12.5,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                if (item.containsKey('badge')) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item['badge'] as String,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0066FF),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        item['icon'] as IconData,
                        color: item['iconColor'] as Color,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Merchandise Subtotal', '₱4,450.00'),
          const SizedBox(height: 6),
          _buildSummaryRow('Shipping Fee', '₱120.00'),
          const SizedBox(height: 6),
          _buildSummaryRow('Shipping Discount (Voucher)', '-₱120.00',
              valueColor: const Color(0xFF00B4D8)),
          const SizedBox(height: 6),
          if (_voucherApplied)
            _buildSummaryRow('Store Voucher (NEXORAWELCOME)', '-₱150.00',
                valueColor: const Color(0xFFE11D48)),
          const SizedBox(height: 6),
          if (_usePoints)
            _buildSummaryRow('Nexora Points Redeemed (850 pts)', '-₱85.00',
                valueColor: const Color(0xFF0066FF)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount to Pay',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                _calculateTotal(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Color(0xFF0066FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Inclusive of all local VAT & service fees',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),

          // 3 Trust Badges Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TrustBadge(icon: Icons.shield_outlined, label: 'Buyer Guard'),
                _TrustBadge(icon: Icons.sync, label: '7-Day Return'),
                _TrustBadge(icon: Icons.settings, label: '100% Genuine'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  String _calculateTotal() {
    double total = 4450.0 + 120.0 - 120.0;
    if (_voucherApplied) total -= 150.0;
    if (_usePoints) total -= 85.0;
    return '₱${total.toStringAsFixed(2)}';
  }

  Widget _buildBottomCheckoutBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TOTAL PRICE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _calculateTotal(),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0066FF),
                  ),
                ),
                const Text(
                  '🏷 Saved ₱355.00 total',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B4D8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 46,
            constraints: const BoxConstraints(maxWidth: 180),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D2FF), Color(0xFF0066FF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(23),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
              icon: _isPlacingOrder
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_outline, size: 16, color: Colors.white),
              label: Text(
                _isPlacingOrder ? 'Processing...' : 'Place Order →',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF0066FF)),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
