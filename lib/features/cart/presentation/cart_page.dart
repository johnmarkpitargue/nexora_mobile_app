import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/buyer_account_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/utils/guest_auth_guard.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isEditMode = false;
  final CartService _cartService = CartService.instance;

  @override
  void initState() {
    super.initState();
    _cartService.loadCartRemote();
  }

  // Dynamic Real-time Calculations
  int get _checkedCount => _cartService.selectedCount;
  int get _checkedItemsCount => _cartService.selectedItemsCount;

  bool get _isAllChecked => _cartService.isAllSelected;

  double get _subtotal => _cartService.subtotal;
  double get _originalSubtotal => _cartService.originalSubtotal;

  double get _voucherDiscount => 0.0;

  double get _totalSaved {
    if (_checkedCount == 0) return 0.0;
    return (_originalSubtotal - _subtotal) + _voucherDiscount;
  }

  double get _finalTotal {
    if (_checkedCount == 0) return 0.0;
    final total = _subtotal - _voucherDiscount;
    return total < 0 ? 0.0 : total;
  }

  void _toggleSelectAll(bool? val) {
    _cartService.selectAllRemote(val ?? false);
  }

  void _toggleStore(String storeName, bool checked) {
    final storeItems =
        _cartService.items.where((i) => i.storeName == storeName).toList();
    final sellerId = storeItems.isNotEmpty ? storeItems.first.sellerId : null;
    if (sellerId != null) {
      _cartService.toggleStoreCheckedRemote(sellerId, checked, storeName: storeName);
    } else {
      _cartService.toggleStoreChecked(storeName, checked);
    }
  }

  bool _isStoreAllChecked(String storeName) {
    final storeItems =
        _cartService.items.where((i) => i.storeName == storeName);
    return storeItems.isNotEmpty && storeItems.every((i) => i.isChecked);
  }

  void _incrementQty(CartItemModel item) {
    _cartService.updateQuantityRemote(item.id, item.quantity + 1);
  }

  void _decrementQty(CartItemModel item) {
    if (item.quantity > 1) {
      _cartService.updateQuantityRemote(item.id, item.quantity - 1);
    } else {
      _deleteItem(item);
    }
  }

  void _deleteItem(CartItemModel item) {
    _cartService.removeItemRemote(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${item.title}" from cart.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteSelectedItems() {
    if (_checkedItemsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select items to delete.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    final count = _checkedItemsCount;
    _cartService.removeSelectedItemsRemote();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully deleted $count item(s) from cart.'),
        backgroundColor: const Color(0xFFDC2626),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _moveToMyLikes() {
    if (_checkedItemsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select items to move to My Likes.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    final count = _checkedItemsCount;
    _cartService.moveSelectedToLikes();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moved $count item(s) to My Likes! ❤️'),
        backgroundColor: const Color(0xFF0066FF),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cartService,
      builder: (context, _) {
        final Map<String, List<CartItemModel>> groupedItems = {};
        for (var item in _cartService.items) {
          groupedItems.putIfAbsent(item.storeName, () => []).add(item);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F8FC),
            elevation: 0,
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
              'Shopping Cart',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            centerTitle: false,
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditMode = !_isEditMode;
                  });
                },
                child: Text(
                  _isEditMode ? 'Done' : 'Edit',
                  style: const TextStyle(
                    color: Color(0xFF0066FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ),
              IconButton(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF050B28),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.chat);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => _cartService.loadCartRemote(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Free Shipping Banner matching reference image
                      _buildFreeShippingPromoBanner(),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Column(
                        children: [
                          if (_cartService.items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: Column(
                                children: [
                                  const Icon(Icons.shopping_bag_outlined,
                                      size: 64, color: Color(0xFFCBD5E1)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Your Shopping Cart is Empty',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Explore products and add them to your cart!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                          context, AppRoutes.home);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0066FF),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text('Start Shopping'),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...groupedItems.entries.map((entry) {
                              return _buildStoreGroupCard(
                                  entry.key, entry.value);
                            }),

                          const SizedBox(height: 10),

                          // Platform Voucher Card
                          _buildVoucherCard(),

                          const SizedBox(height: 24),

                          // You May Also Like Section
                          _buildYouMayAlsoLikeSection(),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ),

              // Bottom Fixed Action Dock with Real-time Checkout & Edit Mode
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomDock(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFreeShippingPromoBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEEF2FF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 18, color: Color(0xFF0066FF)),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                  children: [
                    TextSpan(text: 'Add '),
                    TextSpan(
                      text: '₱150.00',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0066FF),
                      ),
                    ),
                    TextSpan(text: ' more to enjoy '),
                    TextSpan(
                      text: 'Free\nShipping!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0066FF),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
                child: const Row(
                  children: [
                    Text(
                      'Shop More',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0066FF),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF0066FF)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: const LinearProgressIndicator(
              value: 0.75,
              minHeight: 4,
              backgroundColor: Color(0xFFCBD5E1),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D2FF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreGroupCard(String storeName, List<CartItemModel> items) {
    final isStoreChecked = _isStoreAllChecked(storeName);
    final firstItem = items.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header Row
          Row(
            children: [
              _buildCircularCheckbox(
                isChecked: isStoreChecked,
                onTap: () => _toggleStore(storeName, !isStoreChecked),
              ),
              const SizedBox(width: 8),
              if (firstItem.storeBadge.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    firstItem.storeBadge,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final lower = storeName.toLowerCase();
                    final shopId = lower.contains('soundmax')
                        ? 'soundmax_audio'
                        : lower.contains('mikana')
                            ? 'mikana_official'
                            : lower.contains('logitech')
                                ? 'logitech_hub'
                                : lower.contains('aura')
                                    ? 'aura_studios'
                                    : 'nexora_official';
                    Navigator.pushNamed(context, AppRoutes.shop, arguments: shopId);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          storeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.chat);
                },
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline,
                      size: 13, color: Color(0xFF0066FF)),
                ),
              ),
            ],
          ),

          // Optional Store Shipping Tag
          if (firstItem.freeShippingBadge != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 13, color: Color(0xFF00B4D8)),
                  const SizedBox(width: 4),
                  Text(
                    firstItem.freeShippingBadge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00B4D8),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Optional Store Promo Banner
          if (firstItem.storePromoBanner != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'PROMO ',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                  Text(
                    firstItem.storePromoBanner!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Items in this store
          ...items.map((item) => _buildCartItemTile(item)),

          // Optional Store Voucher row
          if (items.any((i) => i.shopVoucherText != null)) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            Row(
              children: [
                const Icon(Icons.local_offer_outlined,
                    size: 15, color: Color(0xFF0066FF)),
                const SizedBox(width: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF334155)),
                    children: [
                      const TextSpan(text: 'Shop Voucher: '),
                      TextSpan(
                        text: items.firstWhere((i) => i.shopVoucherText != null).shopVoucherText!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0066FF),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 ₱100 Shop Coupon Claimed!'),
                        backgroundColor: Color(0xFF0066FF),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Text(
                        'Claim',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0066FF),
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 15, color: Color(0xFF0066FF)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartItemTile(CartItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular Checkbox
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _buildCircularCheckbox(
              isChecked: item.isChecked,
              onTap: () =>
                  _cartService.toggleItemCheckedRemote(item.id, !item.isChecked),
            ),
          ),
          const SizedBox(width: 10),

          // Thumbnail Image
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF1F5F9),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                if (item.topPickBadge != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: const Color(0xFF004080).withValues(alpha: 0.9),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        item.topPickBadge!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Item Info Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),

                // Variant Dropdown Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          item.variant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down,
                          size: 13, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Price Row & Quantity Stepper
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₱${(item.price).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (item.discountTag != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.discountTag!,
                              style: const TextStyle(
                                color: Color(0xFF0066FF),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Quantity Stepper Control
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 14),
                            onPressed: () => _decrementQty(item),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 14),
                            onPressed: () => _incrementQty(item),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (item.originalPrice != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    '₱${item.originalPrice!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade400,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],

                if (item.subBadge != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.subBadge!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _deleteItem(item),
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.confirmation_number_outlined,
                color: Color(0xFF0066FF), size: 16),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nexora Platform Voucher',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '₱150 OFF Applied (9.9 Mega Fest)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0066FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select Platform Voucher Code')),
              );
            },
            child: const Row(
              children: [
                Text(
                  'Select Code',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066FF),
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFF0066FF)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouMayAlsoLikeSection() {
    final recs = [
      {
        'title': 'Nexora Ergonomic Precision Mouse',
        'price': '₱890.00',
        'rating': '4.9 (1.2k)',
        'tag': 'HOT',
        'imageUrl':
            'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?auto=format&fit=crop&w=300&q=80',
      },
      {
        'title': 'HyperVolt 65W GaN Dual USB-C',
        'price': '₱650.00',
        'rating': '4.8 (840)',
        'tag': '',
        'imageUrl':
            'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?auto=format&fit=crop&w=300&q=80',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'You May Also Like',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Personalized',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: recs.map((item) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF1F5F9),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        item['imageUrl']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 3),
                        Text(
                          item['rating']!,
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['price']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add,
                              size: 16, color: Color(0xFF0066FF)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomDock() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Normal Mode Shipping Voucher Bar (Hidden in Edit Mode)
          if (!_isEditMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFFEEF2FF),
              child: const Row(
                children: [
                  Icon(Icons.card_giftcard_outlined,
                      size: 14, color: Color(0xFF0066FF)),
                  SizedBox(width: 6),
                  Text(
                    'Free Shipping Voucher applied',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '-₱60.00',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                ],
              ),
            ),

          // Main Checkout / Edit Dock Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // All Select Checkbox
                Row(
                  children: [
                    _buildCircularCheckbox(
                      isChecked: _isAllChecked,
                      onTap: () => _toggleSelectAll(!_isAllChecked),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isEditMode ? 'All' : 'All\n($_checkedCount items)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // EDIT MODE BUTTONS
                if (_isEditMode) ...[
                  OutlinedButton(
                    onPressed: _moveToMyLikes,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Move to My Likes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _deleteSelectedItems,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _checkedItemsCount > 0
                          ? 'Delete ($_checkedItemsCount)'
                          : 'Delete',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]
                // NORMAL MODE BUTTON (Totals & Checkout)
                else ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Total: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '₱${_finalTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      if (_totalSaved > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F7FA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Saved ₱${_totalSaved.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF00B4D8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Gradient Check Out Button
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D2FF), Color(0xFF0066FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _checkedCount == 0
                          ? null
                          : () async {
                              // Require login if in guest mode before proceeding to checkout
                              if (!BuyerAccountService.instance.isLoggedIn) {
                                final loggedIn = await GuestAuthGuard.requireLogin(
                                  context,
                                  title: 'Sign In to Proceed to Checkout',
                                  message: 'Please sign in or create an account to finalize your order, apply vouchers, and track delivery.',
                                );
                                if (!loggedIn || !mounted) return;
                              }
                              Navigator.pushNamed(context, AppRoutes.checkout);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(
                        'Check Out ($_checkedCount)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Circular Checkbox matching exact reference image design
  Widget _buildCircularCheckbox({
    required bool isChecked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isChecked ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
          border: isChecked
              ? null
              : Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        ),
        child: isChecked
            ? const Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}
