import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/models/shop_models.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/profile_service.dart';
import 'package:nexora_flutter_app/core/services/shop_service.dart';
import 'package:nexora_flutter_app/core/widgets/nexora_widgets.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/product_card.dart';

class ProductReviewsPage extends StatefulWidget {
  final ProductModel product;
  final String? initialVariant;

  const ProductReviewsPage({
    super.key,
    required this.product,
    this.initialVariant,
  });

  @override
  State<ProductReviewsPage> createState() => _ProductReviewsPageState();
}

class _ProductReviewsPageState extends State<ProductReviewsPage> {
  String _selectedFilter = 'All';

  String get _productKey =>
      widget.product.id.isNotEmpty ? widget.product.id : widget.product.title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: ShopService.instance,
      builder: (context, _) {
        final allReviews = ShopService.instance.getReviewsForProduct(
          _productKey,
          widget.product.reviews,
        );
        final averageRating = ShopService.instance.getProductAverageRating(
          _productKey,
          widget.product.rating,
        );
        final breakdown = ShopService.instance.getProductRatingBreakdown(_productKey);

        List<ProductReviewModel> filtered = allReviews;
        if (_selectedFilter == 'With Photos') {
          filtered = allReviews
              .where((r) => r.reviewImages.isNotEmpty || r.reviewImageBytes.isNotEmpty)
              .toList();
        } else if (_selectedFilter == '5 Star') {
          filtered = allReviews.where((r) => r.rating >= 4.8).toList();
        } else if (_selectedFilter == '4 Star') {
          filtered =
              allReviews.where((r) => r.rating >= 3.8 && r.rating < 4.8).toList();
        } else if (_selectedFilter == '3 Star') {
          filtered =
              allReviews.where((r) => r.rating >= 2.8 && r.rating < 3.8).toList();
        } else if (_selectedFilter == '2 Star') {
          filtered =
              allReviews.where((r) => r.rating >= 1.8 && r.rating < 2.8).toList();
        } else if (_selectedFilter == '1 Star') {
          filtered = allReviews.where((r) => r.rating < 1.8).toList();
        }

        final withPhotosCount = allReviews
            .where((r) => r.reviewImages.isNotEmpty || r.reviewImageBytes.isNotEmpty)
            .length;
        final fiveStarCount = allReviews.where((r) => r.rating >= 4.8).length;
        final fourStarCount =
            allReviews.where((r) => r.rating >= 3.8 && r.rating < 4.8).length;
        final threeStarCount =
            allReviews.where((r) => r.rating >= 2.8 && r.rating < 3.8).length;
        final lowStarCount = allReviews.where((r) => r.rating < 2.8).length;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: NexoraAppBar(
            titleText: 'Ratings & Reviews',
            showBottomDivider: true,
            actions: [
              IconButton(
                tooltip: 'Write a review',
                icon: const Icon(Icons.rate_review_outlined),
                onPressed: () => _openWriteReviewSheet(context),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openWriteReviewSheet(context),
            backgroundColor: const Color(0xFF0066FF),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.rate_review_rounded, size: 20),
            label: const Text(
              'Write a Review',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product mini summary card
                _buildProductSummaryCard(context, averageRating, allReviews.length),
                const SizedBox(height: 16),

                // Overall rating & breakdown score banner
                _buildOverallRatingCard(context, averageRating, breakdown, allReviews.length),
                const SizedBox(height: 16),

                // Filter chips row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'All (${allReviews.length})',
                        isSelected: _selectedFilter == 'All',
                        onTap: () => setState(() => _selectedFilter = 'All'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        '📷 With Photos ($withPhotosCount)',
                        isSelected: _selectedFilter == 'With Photos',
                        onTap: () => setState(() => _selectedFilter = 'With Photos'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        '5 ★ ($fiveStarCount)',
                        isSelected: _selectedFilter == '5 Star',
                        onTap: () => setState(() => _selectedFilter = '5 Star'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        '4 ★ ($fourStarCount)',
                        isSelected: _selectedFilter == '4 Star',
                        onTap: () => setState(() => _selectedFilter = '4 Star'),
                      ),
                      if (threeStarCount > 0) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          '3 ★ ($threeStarCount)',
                          isSelected: _selectedFilter == '3 Star',
                          onTap: () => setState(() => _selectedFilter = '3 Star'),
                        ),
                      ],
                      if (lowStarCount > 0) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          '1-2 ★ ($lowStarCount)',
                          isSelected: _selectedFilter == '1 Star',
                          onTap: () => setState(() => _selectedFilter = '1 Star'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Section header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reviews (${filtered.length})',
                      style: TextStyle(
                        fontFamily: NexoraTheme.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _selectedFilter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Reviews list
                if (filtered.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 48,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No reviews found for this filter.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to share your thoughts on this product!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openWriteReviewSheet(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.rate_review, size: 16),
                          label: const Text('Write a Review'),
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map((rev) => _buildReviewItem(context, rev)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductSummaryCard(
    BuildContext context,
    double avgRating,
    int totalReviews,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: widget.product.imageUrl.isNotEmpty
                ? Image.network(
                    widget.product.imageUrl,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 54,
                      height: 54,
                      color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                      child: const Icon(Icons.shopping_bag, color: Color(0xFF0066FF)),
                    ),
                  )
                : Container(
                    width: 54,
                    height: 54,
                    color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                    child: const Icon(Icons.shopping_bag, color: Color(0xFF0066FF)),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: NexoraTheme.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 3),
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '•  $totalReviews verified review${totalReviews == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildOverallRatingCard(
    BuildContext context,
    double avgRating,
    Map<int, double> breakdown,
    int totalReviews,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (idx) {
                  final filled = idx < avgRating.floor();
                  final half = !filled && idx < avgRating;
                  return Icon(
                    half ? Icons.star_half_rounded : Icons.star_rounded,
                    size: 16,
                    color: const Color(0xFFF59E0B),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                'Based on $totalReviews rate${totalReviews == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _buildStarProgressBar(context, '5', breakdown[5] ?? 0.85),
                _buildStarProgressBar(context, '4', breakdown[4] ?? 0.10),
                _buildStarProgressBar(context, '3', breakdown[3] ?? 0.03),
                _buildStarProgressBar(context, '2', breakdown[2] ?? 0.01),
                _buildStarProgressBar(context, '1', breakdown[1] ?? 0.01),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarProgressBar(BuildContext context, String star, double pct) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Text(
            star,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
          const SizedBox(width: 6),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
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
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              '${(pct * 100).toInt()}%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0066FF)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0066FF)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, ProductReviewModel rev) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLiked = ShopService.instance.hasLikedReview(rev.id);
    final helpful = ShopService.instance.getReviewHelpfulCount(rev.id, rev.helpfulCount);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: rev.avatarColor,
                child: Text(
                  rev.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rev.userName,
                      style: TextStyle(
                        fontFamily: NexoraTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (idx) {
                            return Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: idx < rev.rating.round()
                                  ? const Color(0xFFF59E0B)
                                  : (isDark
                                      ? const Color(0xFF475569)
                                      : const Color(0xFFCBD5E1)),
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          rev.date,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rev.variantName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                'Variation: ${rev.variantName}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            rev.comment,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: theme.colorScheme.onSurface,
            ),
          ),
          // Attached Images
          if (rev.reviewImages.isNotEmpty || rev.reviewImageBytes.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  ...rev.reviewImageBytes.map((bytes) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _showFullImageDialog(context, bytes: bytes),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              bytes,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )),
                  ...rev.reviewImages.map((url) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _showFullImageDialog(context, url: url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              url,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 76,
                                height: 76,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, size: 24),
                              ),
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => ShopService.instance.toggleReviewLike(rev.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isLiked
                        ? const Color(0xFF0066FF).withValues(alpha: 0.12)
                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isLiked
                          ? const Color(0xFF0066FF)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                        size: 13,
                        color: isLiked ? const Color(0xFF0066FF) : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Helpful ($helpful)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isLiked ? const Color(0xFF0066FF) : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullImageDialog(BuildContext context, {String? url, Uint8List? bytes}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.contain)
                  : (url != null ? Image.network(url, fit: BoxFit.contain) : const SizedBox.shrink()),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openWriteReviewSheet(BuildContext context) {
    showWriteProductReviewModal(
      context,
      product: widget.product,
      initialVariant: widget.initialVariant,
      productKey: _productKey,
    );
  }
}

void showWriteProductReviewModal(
  BuildContext context, {
  required ProductModel product,
  String? initialVariant,
  required String productKey,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => WriteReviewBottomSheet(
      product: product,
      initialVariant: initialVariant,
      productKey: productKey,
    ),
  );
}

class WriteReviewBottomSheet extends StatefulWidget {
  final ProductModel product;
  final String? initialVariant;
  final String productKey;

  const WriteReviewBottomSheet({
    super.key,
    required this.product,
    this.initialVariant,
    required this.productKey,
  });

  @override
  State<WriteReviewBottomSheet> createState() => _WriteReviewBottomSheetState();
}

class _WriteReviewBottomSheetState extends State<WriteReviewBottomSheet> {
  int _rating = 5;
  late final TextEditingController _commentCtrl;
  String _selectedVariant = '';
  final List<Uint8List> _attachedImageBytes = [];
  bool _isPicking = false;
  String? _error;

  final List<String> _quickChips = [
    'Superb Quality',
    'Fast Delivery',
    'Worth the Price',
    'Legit & Authentic',
    'Very Responsive Seller',
    'Well Packaged',
  ];

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController();
    if (widget.initialVariant != null && widget.initialVariant!.isNotEmpty) {
      _selectedVariant = widget.initialVariant!;
    } else if (widget.product.variantGroups != null &&
        widget.product.variantGroups!.isNotEmpty &&
        widget.product.variantGroups!.first.options.isNotEmpty) {
      _selectedVariant = widget.product.variantGroups!.first.options.first.name;
    } else {
      _selectedVariant = 'Standard Edition';
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _getRatingLabel(int r) {
    switch (r) {
      case 1:
        return '1 Star - Terrible';
      case 2:
        return '2 Stars - Poor';
      case 3:
        return '3 Stars - Fair';
      case 4:
        return '4 Stars - Good';
      case 5:
        return '5 Stars - Amazing!';
      default:
        return '$r Stars';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_attachedImageBytes.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos allowed per review')),
      );
      return;
    }
    try {
      setState(() => _isPicking = true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _attachedImageBytes.add(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _submitReview() {
    setState(() => _error = null);
    final comment = _commentCtrl.text.trim();
    if (comment.isEmpty) {
      setState(() => _error = 'Please write a brief comment describing your experience.');
      return;
    }

    final buyer = BuyerAccountService.instance.currentBuyer;
    final profile = ProfileService.instance;
    final userName = (buyer != null && buyer.fullName.trim().isNotEmpty)
        ? buyer.fullName.trim()
        : (profile.name.trim().isNotEmpty ? profile.name.trim() : 'Alex Rivera');

    final initials = userName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();

    ShopService.instance.addProductReview(
      productIdOrTitle: widget.productKey,
      userName: userName,
      initials: initials.isNotEmpty ? initials : 'NB',
      avatarColor: const Color(0xFF0066FF),
      rating: _rating.toDouble(),
      comment: comment,
      variantName: _selectedVariant,
      reviewImageBytes: List.from(_attachedImageBytes),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Thank you! Your rating and review have been posted.'),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        media.viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rate & Review Product',
                  style: TextStyle(
                    fontFamily: NexoraTheme.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.product.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Rating Stars Picker
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (idx) {
                      final starNum = idx + 1;
                      final isSelected = starNum <= _rating;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = starNum),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.star_rounded,
                            size: 38,
                            color: isSelected
                                ? const Color(0xFFF59E0B)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRatingLabel(_rating),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Variation selector if product has variant options
            if (widget.product.variantGroups != null &&
                widget.product.variantGroups!.isNotEmpty) ...[
              Text(
                'Purchased Variation',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.product.variantGroups!.first.options.map((opt) {
                  final isSel = _selectedVariant == opt.name;
                  return ChoiceChip(
                    label: Text(opt.name),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setState(() => _selectedVariant = opt.name);
                    },
                    selectedColor: const Color(0xFF0066FF).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? const Color(0xFF0066FF) : theme.colorScheme.onSurface,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Comment text area
            Text(
              'Your Review',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'What did you like or dislike about this product? How is the build quality and performance?',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _quickChips.map((chip) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(
                        '+ $chip',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFEEF2FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFC7D2FE),
                        ),
                      ),
                      onPressed: () {
                        final current = _commentCtrl.text.trim();
                        if (current.isEmpty) {
                          _commentCtrl.text = chip;
                        } else {
                          _commentCtrl.text = '$current. $chip';
                        }
                        _commentCtrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: _commentCtrl.text.length),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Photo Upload
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Photos (${_attachedImageBytes.length}/5)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Optional',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // Add button
                  if (_attachedImageBytes.length < 5)
                    GestureDetector(
                      onTap: _isPicking
                          ? null
                          : () => _showPickerModal(context),
                      child: Container(
                        width: 70,
                        height: 70,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF0066FF),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_rounded,
                              size: 22,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Image previews
                  ...List.generate(_attachedImageBytes.length, (idx) {
                    final bytes = _attachedImageBytes[idx];
                    return Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          margin: const EdgeInsets.only(right: 10),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Image.memory(bytes, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => setState(() => _attachedImageBytes.removeAt(idx)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Submit Button
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D2FF), Color(0xFF0066FF)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Submit Rating & Review',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: Theme.of(ctx).colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0066FF)),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF0066FF)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
