import 'package:flutter/material.dart';
import 'product_card.dart';

class FeaturedProductsSection extends StatelessWidget {
  const FeaturedProductsSection({super.key});

  static const List<ProductModel> featuredProducts = [
    ProductModel(
      title: 'Nexora Studio Pro Wireless',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuALgo4xVz9Wo_SuIU15ulvo-3G_HtejrhhLzW9Fgxp3t8CaI9fDN_t1BdIIRcHxxXEMC-7rLUJYBpIuY-c5YZ6dEo1scBwFSm14g-9T0PjdIixf5vHFuKFaU5-JDEnk_S8XO6M25JsCrNtVix9tigvacz5nurRgwZsHt4omGOaVSmm9mBM54NxSPO4-UO5xlTtt4Xb4p2y-MJVDYmv1KBa-MXWZ1XH_wb0wGPMd0IUiLGZ54l_WY1s',
      tag: 'BESTSELLER',
      tagBgColor: Color(0xFF00D2FF),
      tagTextColor: Color(0xFF050B28),
      rating: 4.9,
      reviewsCount: '1.8k',
      price: '₱2,450.00',
      originalPrice: '₱3,500.00',
      discountTag: '-30%',
    ),
    ProductModel(
      title: 'Aura Minimalist Fleece Hoodie',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDzlfM9UI-vGVUMAkUKI4WCoDpA4njq2i2bH5FsGflhVF28xwuR4599HpCZ5j6YtJKmVEHwfR2hVgWxghw8H2THFwFCT27W7Fk_z0wKe4q_kg8uwhxD9uXh8zSSoZ67ltyCehtwjAQfkdZzcDRantW9HcQz8VT_3vLB_3girMZ7tKvzHlokhxLLe-oKWduwhOBz7fV1Jgul-8KVjTL7YA5C12MOUbZqrBtVidhRBHOauvw8mO5Sfus',
      tag: 'NEW DROP',
      tagBgColor: Color(0xFFE0F7FA),
      tagTextColor: Color(0xFF0891B2),
      rating: 4.8,
      reviewsCount: '840',
      price: '₱1,250.00',
      originalPrice: '₱1,600.00',
      discountTag: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Featured Products',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Hot',
                      style: TextStyle(
                        color: Color(0xFF0891B2),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {},
                child: const Row(
                  children: [
                    Text(
                      'Explore All',
                      style: TextStyle(
                        color: Color(0xFF0066FF),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Color(0xFF0066FF),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Responsive Product Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 550 ? 3 : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: featuredProducts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.56,
                ),
                itemBuilder: (context, index) {
                  return ProductCard(product: featuredProducts[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
