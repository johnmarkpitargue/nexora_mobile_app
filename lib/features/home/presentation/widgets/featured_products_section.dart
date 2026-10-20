import 'package:flutter/material.dart';
import 'product_card.dart';
import '../../../../core/services/shop_service.dart';

class DailyDiscoverSection extends StatelessWidget {
  final String? selectedCategory;
  final VoidCallback? onLoadMore;

  const DailyDiscoverSection({
    super.key,
    this.selectedCategory,
    this.onLoadMore,
  });

  static List<ProductModel> get allProducts => ShopService.allAppProducts;

  static const List<ProductModel> legacyProducts = [
    // Tech & Gadgets / Mall
    ProductModel(
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
    // Fashion / Mall
    ProductModel(
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
    // Gaming / Tech & Gadgets
    ProductModel(
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
    // Sports / Tech
    ProductModel(
      title: 'Nexora Pulse Fit Pro Waterproof Fitness Tracker',
      imageUrl:
          'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?auto=format&fit=crop&w=600&q=80',
      category: 'Sports',
      isMall: true,
      discountTag: '-35%',
      price: '₱1,850.00',
      originalPrice: '₱2,850',
      rating: 4.8,
      soldCount: '1.4k',
      shippingTag: '2-3 Days | Metro Manila',
      hasPayLater: false,
      hasVoucher: true,
    ),
    // Tech & Gadgets / Home
    ProductModel(
      title: 'Aura Wave 360 Portable Bluetooth Speaker',
      imageUrl:
          'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=600&q=80',
      category: 'Tech & Gadgets',
      isMall: true,
      discountTag: '-18%',
      price: '₱1,490.00',
      originalPrice: '₱1,820',
      rating: 4.9,
      soldCount: '2.1k',
      shippingTag: 'Next Day Delivery | Makati City',
      hasPayLater: true,
      hasVoucher: false,
    ),
    // Home
    ProductModel(
      title: 'Aura Hydro-Shield 40oz Insulated Stainless Tumbler',
      imageUrl:
          'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=600&q=80',
      category: 'Home',
      isMall: true,
      discountTag: '-40%',
      price: '₱890.00',
      originalPrice: '₱1,470',
      rating: 4.9,
      soldCount: '3.5k',
      shippingTag: '2-3 Days | Metro Manila',
      hasPayLater: false,
      hasVoucher: true,
    ),
    // Beauty
    ProductModel(
      title: 'Nexora Glow Sonic Facial Cleansing & Massaging Brush',
      imageUrl:
          'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=600&q=80',
      category: 'Beauty',
      isMall: true,
      discountTag: '-35%',
      price: '₱1,350.00',
      originalPrice: '₱2,100',
      rating: 4.9,
      soldCount: '950',
      shippingTag: '2-3 Days | Quezon City',
      hasPayLater: true,
      hasVoucher: true,
    ),
    // Vouchers
    ProductModel(
      title: 'Nexora Official Store ₱500 Discount Voucher Card Pass',
      imageUrl:
          'https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?auto=format&fit=crop&w=600&q=80',
      category: 'Vouchers',
      isMall: true,
      discountTag: '-80%',
      price: '₱50.00',
      originalPrice: '₱500',
      rating: 5.0,
      soldCount: '12.4k',
      shippingTag: 'Instant Digital Delivery',
      hasPayLater: false,
      hasVoucher: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredProducts = selectedCategory == null || selectedCategory == 'Mall'
        ? allProducts
        : allProducts.where((p) => p.category == selectedCategory).toList();

    final displayProducts = filteredProducts.isEmpty ? allProducts : filteredProducts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        selectedCategory == null
                            ? 'DAILY DISCOVER'
                            : 'DISCOVER (${selectedCategory!.toUpperCase()})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.3,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Sulit Deals',
                        style: TextStyle(
                          color: Color(0xFFE11D48),
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Updated Just Now',
                style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Product Grid Layout
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.52,
            ),
            itemBuilder: (context, index) {
              return ProductCard(product: displayProducts[index]);
            },
          ),

          const SizedBox(height: 16),

          // Loading more recommendations button matching screenshot
          Center(
            child: InkWell(
              onTap: onLoadMore,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading more recommendations...',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
