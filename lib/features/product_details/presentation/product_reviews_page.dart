import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';
import 'package:nexora_flutter_app/core/models/shop_models.dart';
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
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _remoteReviewsPayload;

  String get _productKey =>
      widget.product.id.isNotEmpty ? widget.product.id : widget.product.title;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final pid = int.tryParse(_productKey);
    if (pid == null || pid <= 0) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ShopService.instance.fetchProductReviewsRemote(pid.toString());
      if (!mounted) return;
      setState(() {
        _remoteReviewsPayload = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load product reviews right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: ShopService.instance,
      builder: (context, _) {
        final remoteList =
            _remoteReviewsPayload?['reviews'] as List<ProductReviewModel>?;
        final allReviews = remoteList ??
            ShopService.instance.getReviewsForProduct(
              _productKey,
              widget.product.reviews,
            );
        final averageRating =
            (_remoteReviewsPayload?['average_rating'] as num?)?.toDouble() ??
                ShopService.instance.getProductAverageRating(
                  _productKey,
                  widget.product.rating,
                );
        final rawBreakdown = _remoteReviewsPayload?['breakdown'];
        final breakdown = rawBreakdown is Map<int, double>
            ? rawBreakdown
            : ShopService.instance.getProductRatingBreakdown(_productKey);

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
          appBar: const NexoraAppBar(
            titleText: 'Ratings & Reviews',
            showBottomDivider: true,
          ),
          body: RefreshIndicator(
            onRefresh: _loadReviews,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
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
                        'ðŸ“· With Photos ($withPhotosCount)',
                        isSelected: _selectedFilter == 'With Photos',
                        onTap: () => setState(() => _selectedFilter = 'With Photos'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        '5 â˜… ($fiveStarCount)',
                        isSelected: _selectedFilter == '5 Star',
                        onTap: () => setState(() => _selectedFilter = '5 Star'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        '4 â˜… ($fourStarCount)',
                        isSelected: _selectedFilter == '4 Star',
                        onTap: () => setState(() => _selectedFilter = '4 Star'),
                      ),
                      if (threeStarCount > 0) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          '3 â˜… ($threeStarCount)',
                          isSelected: _selectedFilter == '3 Star',
                          onTap: () => setState(() => _selectedFilter = '3 Star'),
                        ),
                      ],
                      if (lowStarCount > 0) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          '1-2 â˜… ($lowStarCount)',
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
                if (_isLoading && allReviews.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: NexoraLoadingSkeleton(itemCount: 3, itemHeight: 110),
                  )
                else if (_errorMessage != null && allReviews.isEmpty)
                  NexoraErrorState(
                    message: _errorMessage!,
                    onRetry: _loadReviews,
                  )
                else if (filtered.isEmpty)
                  NexoraEmptyState(
                    icon: Icons.rate_review_outlined,
                    title: allReviews.isEmpty
                        ? 'No reviews yet'
                        : 'No reviews match this filter',
                    message: allReviews.isEmpty
                        ? 'Verified buyer reviews appear after completed orders are rated.'
                        : 'Try selecting All to view all product reviews.',
                  )
                else
                  ...filtered.map((rev) => _buildReviewItem(context, rev)),
              ],
            ),
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
                      'â€¢  $totalReviews verified review${totalReviews == 1 ? '' : 's'}',
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
}
