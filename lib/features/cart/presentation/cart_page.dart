import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/buyer_account_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/utils/guest_auth_guard.dart';
import '../../chat/presentation/chat_detail_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isEditMode = false;
  bool _isMutating = false;
  final CartService _cartService = CartService.instance;

  @override
  void initState() {
    super.initState();
    _cartService.loadCartRemote();
  }

  int get _checkedCount => _cartService.selectedCount;
  int get _checkedItemsCount => _cartService.selectedItemsCount;
  bool get _isAllChecked => _cartService.isAllSelected;
  double get _subtotal => _cartService.subtotal;
  double get _originalSubtotal => _cartService.originalSubtotal;

  double get _totalSaved {
    if (_checkedCount == 0) return 0.0;
    final diff = _originalSubtotal - _subtotal;
    return diff > 0 ? diff : 0.0;
  }

  void _showErrorSnackBar(Object error) {
    if (!mounted) return;
    final msg = error is ApiException
        ? error.message
        : error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFDC2626),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _runCartMutation(Future<void> Function() action, {String? successMessage}) async {
    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      await action();
      if (successMessage != null && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e);
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _toggleSelectAll(bool? val) async {
    await _runCartMutation(
      () => _cartService.selectAllRemote(val ?? false),
    );
  }

  Future<void> _toggleStore(List<CartItemModel> storeItems, bool checked) async {
    final sellerId = storeItems.isNotEmpty ? storeItems.first.sellerId : null;
    if (sellerId != null) {
      await _runCartMutation(
        () => _cartService.toggleStoreCheckedRemote(sellerId, checked),
      );
    } else {
      for (final item in storeItems) {
        await _runCartMutation(
          () => _cartService.toggleItemCheckedRemote(item.id, checked),
        );
      }
    }
  }

  bool _isStoreAllChecked(List<CartItemModel> storeItems) {
    return storeItems.isNotEmpty && storeItems.every((i) => i.isChecked);
  }

  Future<void> _incrementQty(CartItemModel item) async {
    await _runCartMutation(
      () => _cartService.updateQuantityRemote(item.id, item.quantity + 1),
    );
  }

  Future<void> _decrementQty(CartItemModel item) async {
    if (item.quantity > 1) {
      await _runCartMutation(
        () => _cartService.updateQuantityRemote(item.id, item.quantity - 1),
      );
    } else {
      await _deleteItem(item);
    }
  }

  Future<void> _deleteItem(CartItemModel item) async {
    await _runCartMutation(
      () => _cartService.removeItemRemote(item.id),
      successMessage: 'Removed "${item.title}" from cart.',
    );
  }

  Future<void> _deleteSelectedItems() async {
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
    await _runCartMutation(
      () => _cartService.removeSelectedItemsRemote(),
      successMessage: 'Deleted $count item(s) from cart.',
    );
  }

  Future<void> _moveToMyLikes() async {
    if (_checkedItemsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select items to move to My Likes.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    await _runCartMutation(() async {
      final moved = await _cartService.moveSelectedToLikesRemote();
      if (mounted && moved > 0) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moved $moved item(s) to My Likes.'),
            backgroundColor: const Color(0xFF0066FF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _openSellerChat(int? sellerId, String storeName) async {
    if (sellerId == null) {
      Navigator.pushNamed(context, AppRoutes.chat);
      return;
    }
    final loggedIn = await GuestAuthGuard.requireLogin(
      context,
      title: 'Sign In to Message Seller',
      message: 'Please sign in to chat with $storeName.',
    );
    if (!loggedIn || !mounted) return;
    try {
      final conv = await ChatService.instance.startConversationRemote(sellerId);
      if (conv == null) {
        throw const ApiException(
          statusCode: 500,
          message: 'Could not open chat with this seller.',
        );
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            conversationId: conv.id,
            title: conv.title,
            subtitle: conv.subtitle,
            avatarIcon: conv.avatarIcon,
            avatarBgColor: conv.avatarBg,
            initialMessages: conv.messages.map((m) => m.toMap()).toList(),
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cartService,
      builder: (context, _) {
        final Map<String, List<CartItemModel>> groupedItems = {};
        for (final item in _cartService.items) {
          final groupKey = item.sellerId != null
              ? 'seller_${item.sellerId}'
              : 'name_${item.storeName}';
          groupedItems.putIfAbsent(groupKey, () => []).add(item);
        }

        final hasSession =
            ApiClient.instance.hasToken && BuyerAccountService.instance.isLoggedIn;

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
              if (_cartService.items.isNotEmpty)
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
                onRefresh: () async {
                  await _cartService.loadCartRemote(throwOnError: true);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        if (!hasSession)
                          _buildSignInPrompt(context)
                        else if (_cartService.cartError != null)
                          _buildErrorBanner(_cartService.cartError!)
                        else if (_cartService.isLoadingCart &&
                            _cartService.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_cartService.items.isEmpty)
                          _buildEmptyCartView(context)
                        else
                          ...groupedItems.values
                              .map((storeItems) => _buildStoreGroupCard(storeItems)),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasSession && _cartService.items.isNotEmpty)
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

  Widget _buildSignInPrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 56,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sign in to view your cart',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your cart stays synced with your Nexora account across devices.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final ok = await GuestAuthGuard.requireLogin(context);
              if (ok && mounted) {
                await _cartService.loadCartRemote();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _cartService.loadCartRemote(),
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCartView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Color(0xFFCBD5E1),
          ),
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
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreGroupCard(List<CartItemModel> items) {
    final isStoreChecked = _isStoreAllChecked(items);
    final firstItem = items.first;
    final storeName =
        firstItem.storeName.isNotEmpty ? firstItem.storeName : 'Seller Store';

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
                onTap: () => _toggleStore(items, !isStoreChecked),
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
                  onTap: firstItem.sellerId != null
                      ? () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.shop,
                            arguments: firstItem.sellerId.toString(),
                          );
                        }
                      : null,
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
                      if (firstItem.sellerId != null) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _openSellerChat(firstItem.sellerId, storeName),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 13,
                    color: Color(0xFF0066FF),
                  ),
                ),
              ),
            ],
          ),

          if (firstItem.isVacationMode) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.beach_access_rounded,
                      size: 14, color: Color(0xFFD97706)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This seller is on vacation mode and cannot accept orders right now.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Items in this store
          ...items.map((item) => _buildCartItemTile(item)),
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
              onTap: () => _runCartMutation(
                () => _cartService.toggleItemCheckedRemote(
                  item.id,
                  !item.isChecked,
                ),
              ),
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
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 10),

          // Item Info Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
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
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _deleteItem(item),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 17,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                if (item.variant.isNotEmpty && item.variant != 'Standard') ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                  const SizedBox(height: 6),
                ],

                // Price Row & Quantity Stepper
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₱${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (item.originalPrice != null)
                            Text(
                              '₱${item.originalPrice!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
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
                            onPressed:
                                _isMutating ? null : () => _decrementQty(item),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
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
                            onPressed:
                                _isMutating ? null : () => _incrementQty(item),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (item.stock != null && item.stock! <= 5) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.stock! <= 0
                        ? 'Out of stock'
                        : 'Only ${item.stock} left',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
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
            if (_isEditMode) ...[
              OutlinedButton(
                onPressed: _isMutating ? null : _moveToMyLikes,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Move to My Likes',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _isMutating ? null : _deleteSelectedItems,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            ] else ...[
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
                        '₱${_subtotal.toStringAsFixed(2)}',
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
                        horizontal: 6,
                        vertical: 2,
                      ),
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
                  onPressed: (_checkedCount == 0 || _isMutating)
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          if (!BuyerAccountService.instance.isLoggedIn ||
                              !ApiClient.instance.hasToken) {
                            final loggedIn = await GuestAuthGuard.requireLogin(
                              context,
                              title: 'Sign In to Proceed to Checkout',
                              message:
                                  'Please sign in or create an account to finalize your order, apply vouchers, and track delivery.',
                            );
                            if (!loggedIn || !mounted) return;
                          }
                          _cartService.clearDirectBuy();
                          navigator.pushNamed(AppRoutes.checkout);
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
    );
  }

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
