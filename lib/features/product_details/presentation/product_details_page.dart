import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/routes/app_routes.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _selectedImageIndex = 0;
  bool _isFavorite = false;
  int _selectedColorIndex = 0;
  int _selectedSwitchIndex = 0;
  int _selectedLayoutIndex = 0;
  int _quantity = 1;

  final List<String> _productImages = [
    'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1618384887929-16ec33fab9ef?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1595225476474-87563907a212?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1541140590914-579f21e6b72d?auto=format&fit=crop&w=600&q=80',
  ];

  final List<Map<String, dynamic>> _colorVariants = [
    {
      'name': 'Chalk White & Violet',
      'circleColor': const Color(0xFFC4B5FD),
      'label': 'Chalk / Violet',
    },
    {
      'name': 'Midnight Navy',
      'circleColor': const Color(0xFF0F172A),
      'label': 'Midnight Navy',
    },
    {
      'name': 'Phantom Black',
      'circleColor': const Color(0xFF18181B),
      'label': 'Phantom Black',
    },
  ];

  final List<Map<String, String>> _switchOptions = [
    {
      'title': 'Gateron Pro Yellow',
      'subtitle': 'Smooth linear feel • 50g operating force',
    },
    {
      'title': 'Kailh Box White',
      'subtitle': 'Crisp acoustic clickbar • 45g force',
    },
    {
      'title': 'Silent Red Linear',
      'subtitle': 'Silenced dampeners for studio work • 45g force',
    },
  ];

  final List<String> _formFactors = ['75% Compact', 'TKL (80%)', 'Full 100%'];

  int _helpfulCount1 = 38;
  int _helpfulCount2 = 24;
  bool _voted1 = false;
  bool _voted2 = false;

  void _handleAddToCart() {
    final selectedColor = _colorVariants[_selectedColorIndex]['label'] as String;
    final selectedSwitch = _switchOptions[_selectedSwitchIndex]['title'] as String;
    final variantStr = '$selectedColor, $selectedSwitch';

    CartService.instance.addItem(
      title: 'Nexora Aura 75 Mechanical Keyboard RGB',
      variant: variantStr,
      price: 3200.00,
      imageUrl: _productImages.first,
      quantity: _quantity,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00D2FF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Added ${_quantity}x Nexora Aura 75 to Shopping Cart!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF050B28),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: const Color(0xFF00D2FF),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.cart);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Product Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? const Color(0xFFE11D48) : const Color(0xFF0F172A),
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite
                      ? 'Saved to Wishlist!'
                      : 'Removed from Wishlist'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF0F172A)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product link copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                // Main Gallery Image & Thumbnails
                _buildGallerySection(),
                const SizedBox(height: 18),

                // Title & Subtitle Header
                const Text(
                  'Nexora Aura 75 Mechanical Keyboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chalk White & Violet Edition • CNC Anodized Aluminum • Gasket Mount Hot-Swap',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Rating & Category Rank Row
                const Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                    SizedBox(width: 4),
                    Text(
                      '4.9',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '• 520 reviews',
                      style: TextStyle(
                        color: Color(0xFF0066FF),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '• 🏆 Rank #1 in Keyboards',
                      style: TextStyle(
                        color: Color(0xFF0891B2),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price Box Banner
                _buildPriceCard(),
                const SizedBox(height: 18),

                // Color Palette Selector
                _buildColorPaletteSection(),
                const SizedBox(height: 18),

                // Mechanical Switches Selector
                _buildSwitchOptionsSection(),
                const SizedBox(height: 18),

                // Form Factor Selector
                _buildFormFactorSection(),
                const SizedBox(height: 18),

                // Quantity Stepper Row
                _buildQuantitySection(),
                const SizedBox(height: 18),

                // Priority Dispatch & Warranty Banner
                _buildDispatchWarrantyCard(),
                const SizedBox(height: 20),

                // Key Spec Features Grid
                _buildSpecFeaturesGrid(),
                const SizedBox(height: 24),

                // Ratings & Reviews Section
                _buildReviewsSection(),
                const SizedBox(height: 110),
              ],
            ),
          ),

          // Bottom Action Navigation Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomActionDock(),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    return Column(
      children: [
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFEEECFF),
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  _productImages[_selectedImageIndex],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.keyboard,
                    size: 64,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              // Genuine Flagship Badge top-left
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 13, color: Color(0xFF00B4D8)),
                      SizedBox(width: 4),
                      Text(
                        'GENUINE FLAGSHIP',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00B4D8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 3D Inspection Tag bottom-left
              Positioned(
                bottom: 12,
                left: 12,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Opening 3D Interactive Inspector...')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF050B28).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.view_in_ar, size: 14, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'Studio 3D • Tap to Inspect',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Page Counter Indicator bottom-right
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_selectedImageIndex + 1}/${_productImages.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Thumbnails Carousel
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_productImages.length, (index) {
            final isSelected = _selectedImageIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImageIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0066FF) : Colors.transparent,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  _productImages[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(Icons.image, size: 20, color: Colors.grey),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '₱3,200.00',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0066FF),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₱4,000.00',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFBE123C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '-20% OFF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.whatshot, size: 14, color: Color(0xFFE11D48)),
              SizedBox(width: 4),
              Text(
                'Only 14 left in stock - order soon!',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE11D48),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Row(
            children: [
              Icon(Icons.credit_card, size: 14, color: Color(0xFF0066FF)),
              SizedBox(width: 4),
              Text(
                'Or ₱1,066.66/mo for 3 mos with 0% interest',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPaletteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Color Palette',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _colorVariants[_selectedColorIndex]['name'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Color(0xFF0066FF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_colorVariants.length, (index) {
              final isSelected = _selectedColorIndex == index;
              final variant = _colorVariants[index];

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColorIndex = index;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE0F7FA)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00D2FF)
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: variant['circleColor'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 13, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          variant['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mechanical Switches',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _switchOptions[_selectedSwitchIndex]['title']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: Color(0xFF0066FF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Column(
          children: List.generate(_switchOptions.length, (index) {
            final isSelected = _selectedSwitchIndex == index;
            final opt = _switchOptions[index];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSwitchIndex = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF050B28)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00D2FF)
                        : const Color(0xFFE2E8F0),
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
                        color: isSelected
                            ? const Color(0xFF00D2FF)
                            : Colors.transparent,
                        border: isSelected
                            ? null
                            : Border.all(
                                color: const Color(0xFFCBD5E1), width: 2),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 12, color: Color(0xFF050B28))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['title']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: isSelected ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt['subtitle']!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? const Color(0xFF94A3B8)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFormFactorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Form Factor',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_formFactors.length, (index) {
              final isSelected = _selectedLayoutIndex == index;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLayoutIndex = index;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00D2FF)
                          : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _formFactors[index],
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.w600,
                        fontSize: 11.5,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quantity',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Max 3 per customer',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 15),
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() => _quantity--);
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 15),
                  onPressed: () {
                    if (_quantity < 3) {
                      setState(() => _quantity++);
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchWarrantyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEECFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F7FA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.electric_rickshaw,
                    color: Color(0xFF00B4D8), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Nexora Priority Dispatch ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B4D8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'FASTEST',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Get it tomorrow by 4:00 PM',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'Order within 1h 48m • Dispatched from Makati Central Hub',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFCBD5E1)),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 15, color: Color(0xFF0066FF)),
                  SizedBox(width: 4),
                  Text(
                    '2-Year Official Warranty',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.sync, size: 15, color: Color(0xFF0066FF)),
                  SizedBox(width: 4),
                  Text(
                    '7-Day Free Replacement',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecFeaturesGrid() {
    final specs = [
      {
        'icon': Icons.graphic_eq,
        'title': 'Poron Gasket Mount',
        'subtitle':
            '5 layers of sound-dampening foam for pure, deep acoustics.',
      },
      {
        'icon': Icons.wifi,
        'title': 'Tri-Mode Wireless',
        'subtitle': 'Bluetooth 5.3, 2.4GHz ultra-low latency & Type-C wired.',
      },
      {
        'icon': Icons.battery_charging_full,
        'title': '4000mAh Battery',
        'subtitle':
            'Up to 240 hours continuous playtime without RGB backlight.',
      },
      {
        'icon': Icons.tune,
        'title': 'Rotary Encoder',
        'subtitle':
            'CNC Violet knob mapped to volume, zoom, or media playback.',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: specs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final item = specs[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item['icon'] as IconData,
                color: const Color(0xFF0066FF),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                item['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item['subtitle'] as String,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  height: 1.25,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.storefront, size: 16, color: Color(0xFF0066FF)),
                SizedBox(width: 4),
                Text(
                  'Official Store',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.check_circle, size: 13, color: Color(0xFF0066FF)),
              ],
            ),
            Text(
              '1.2k+ sold',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Overall score banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Column(
                children: [
                  Text(
                    '4.9',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, size: 13, color: Color(0xFFF59E0B)),
                      Icon(Icons.star, size: 13, color: Color(0xFFF59E0B)),
                      Icon(Icons.star, size: 13, color: Color(0xFFF59E0B)),
                      Icon(Icons.star, size: 13, color: Color(0xFFF59E0B)),
                      Icon(Icons.star, size: 13, color: Color(0xFFF59E0B)),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    '98% Recommended',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildStarProgressRow('5', 0.88),
                    _buildStarProgressRow('4', 0.09),
                    _buildStarProgressRow('3', 0.02),
                    _buildStarProgressRow('2', 0.01),
                    _buildStarProgressRow('1', 0.00),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Review Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildReviewFilterChip('All (520)', isSelected: true),
              const SizedBox(width: 8),
              _buildReviewFilterChip('📷 With Photos (84)', isSelected: false),
              const SizedBox(width: 8),
              _buildReviewFilterChip('🎧 Switch Sound (112)', isSelected: false),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Review Card 1
        _buildReviewCard(
          avatarColor: const Color(0xFF5038ED),
          initials: 'KV',
          userName: 'Kiko Valenzuela',
          dateText: '2d ago',
          variantText: 'Variant: Chalk White / Violet',
          comment:
              '"Hands down the cleanest sounding stock board I have ever tested. The Gateron Yellow switches came factory lubricated to absolute perfection. Zero rattle on the spacebar and the violet knob is super tactile!"',
          imageUrl:
              'https://images.unsplash.com/photo-1587829741301-dc798b83add3?auto=format&fit=crop&w=300&q=80',
          helpfulCount: _helpfulCount1,
          voted: _voted1,
          onHelpfulTap: () {
            setState(() {
              _voted1 = !_voted1;
              _helpfulCount1 += _voted1 ? 1 : -1;
            });
          },
        ),
        const SizedBox(height: 12),

        // Review Card 2
        _buildReviewCard(
          avatarColor: const Color(0xFF00B4D8),
          initials: 'MC',
          userName: 'Marianne Cruz',
          dateText: '5d ago',
          variantText: 'Variant: Chalk White / Violet',
          comment:
              '"Arrived in less than 24 hours in BGC! Packaged in heavy luxury matte presentation box with switch pullers and coiled lavender cable included. Typing experience is pillowy and deep."',
          imageUrl: null,
          helpfulCount: _helpfulCount2,
          voted: _voted2,
          onHelpfulTap: () {
            setState(() {
              _voted2 = !_voted2;
              _helpfulCount2 += _voted2 ? 1 : -1;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStarProgressRow(String starLabel, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Text(
            starLabel,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEECFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D2FF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(pct * 100).toInt()}%',
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewFilterChip(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF00D2FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required Color avatarColor,
    required String initials,
    required String userName,
    required String dateText,
    required String variantText,
    required String comment,
    required String? imageUrl,
    required int helpfulCount,
    required bool voted,
    required VoidCallback onHelpfulTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: avatarColor,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 13, color: Color(0xFF0066FF)),
                        ],
                      ),
                      const Text(
                        'Verified Buyer • Gateron Pro Yellow',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                dateText,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
              Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
              Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
              Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
              Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF334155),
              height: 1.35,
            ),
          ),
          if (imageUrl != null) ...[
            const SizedBox(height: 10),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFF1F5F9),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                variantText,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              ),
              GestureDetector(
                onTap: onHelpfulTap,
                child: Row(
                  children: [
                    Icon(
                      voted ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                      size: 13,
                      color: voted ? const Color(0xFF0066FF) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Helpful ($helpfulCount)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: voted
                            ? const Color(0xFF0066FF)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionDock() {
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
        children: [
          // Chat Icon Button
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.chat);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Color(0xFF0066FF),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Add to Cart Dark Navy Button
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _handleAddToCart,
                icon: const Icon(Icons.shopping_cart_outlined,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF050B28),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Buy Now Gradient Button
          Expanded(
            child: Container(
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
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.checkout);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Text(
                  'Buy Now • ₱3,200',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
