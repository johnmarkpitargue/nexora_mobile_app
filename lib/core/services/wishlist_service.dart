import 'package:flutter/material.dart';
import '../../features/home/presentation/widgets/product_card.dart';

class WishlistService extends ChangeNotifier {
  static final WishlistService instance = WishlistService._internal();

  WishlistService._internal() {
    _initDefaultWishlist();
  }

  final List<ProductModel> _wishlistItems = [];

  List<ProductModel> get items => List.unmodifiable(_wishlistItems);

  int get itemCount => _wishlistItems.length;

  bool isInWishlist(String title) {
    return _wishlistItems.any((item) => item.title == title);
  }

  void toggleWishlist(ProductModel product) {
    final index = _wishlistItems.indexWhere((item) => item.title == product.title);
    if (index >= 0) {
      _wishlistItems.removeAt(index);
    } else {
      _wishlistItems.insert(0, product);
    }
    notifyListeners();
  }

  void addToWishlist(ProductModel product) {
    if (!isInWishlist(product.title)) {
      _wishlistItems.insert(0, product);
      notifyListeners();
    }
  }

  void removeFromWishlist(String title) {
    final index = _wishlistItems.indexWhere((item) => item.title == title);
    if (index >= 0) {
      _wishlistItems.removeAt(index);
      notifyListeners();
    }
  }

  void clearWishlist() {
    _wishlistItems.clear;
    notifyListeners();
  }

  void _initDefaultWishlist() {
    // Seed initial curated wishlist items matching profile's default count of 4 items
    _wishlistItems.addAll([
      const ProductModel(
        title: 'Nexora Studio Pro Wireless ANC Headphone System',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuALgo4xVz9Wo_SuIU15ulvo-3G_HtejrhhLzW9Fgxp3t8CaI9fDN_t1BdIIRcHxxXEMC-7rLUJYBpIuY-c5YZ6dEo1scBwFSm14g-9T0PjdIixf5vHFuKFaU5-JDEnk_S8XO6M25JsCrNtVix9tigvacz5nurRgwZsHt4omGOaVSmm9mBM54NxSPO4-UO5xlTtt4Xb4p2y-MJVDYmv1KBa-MXWZ1XH_wb0wGPMd0IUiLGZ54l_WY1s',
        category: 'Tech & Gadgets',
        isMall: true,
        discountTag: '-30%',
        price: '₱2,450.00',
        originalPrice: '₱3,500',
        rating: 4.9,
        soldCount: '1.8k',
        shippingTag: '2-3 Days | Metro Manila',
        hasPayLater: true,
        hasVoucher: false,
      ),
      const ProductModel(
        title: 'Nexora Apex 75% Custom Mechanical Keyboard RGB',
        imageUrl:
            'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=600&q=80',
        category: 'Gaming',
        isMall: true,
        discountTag: '-28%',
        price: '₱3,890.00',
        originalPrice: '₱5,400',
        rating: 4.9,
        soldCount: '620',
        shippingTag: '2-3 Days | Metro Manila',
        hasPayLater: true,
        hasVoucher: false,
      ),
      const ProductModel(
        title: 'Aura Minimalist Heavy Fleece Hoodie Streetwear',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDzlfM9UI-vGVUMAkUKI4WCoDpA4njq2i2bH5FsGflhVF28xwuR4599HpCZ5j6YtJKmVEHwfR2hVgWxghw8H2THFwFCT27W7Fk_z0wKe4q_kg8uwhxD9uXh8zSSoZ67ltyCehtwjAQfkdZzcDRantW9HcQz8VT_3vLB_3girMZ7tKvzHlokhxLLe-oKWduwhOBz7fV1Jgul-8KVjTL7YA5C12MOUbZqrBtVidhRBHOauvw8mO5Sfus',
        category: 'Fashion',
        isMall: true,
        discountTag: '-22%',
        price: '₱1,250.00',
        originalPrice: '₱1,600',
        rating: 4.8,
        soldCount: '840',
        shippingTag: '2-3 Days | Metro Manila',
        hasPayLater: false,
        hasVoucher: true,
      ),
      const ProductModel(
        title: 'Nexora Pulse Fit Pro Waterproof Fitness Tracker',
        imageUrl:
            'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?auto=format&fit=crop&w=600&q=80',
        category: 'Sports',
        isMall: true,
        discountTag: '-35%',
        price: '₱1,980.00',
        originalPrice: '₱3,050',
        rating: 4.7,
        soldCount: '950',
        shippingTag: '2-3 Days | Metro Manila',
        hasPayLater: true,
        hasVoucher: false,
      ),
    ]);
  }
}
