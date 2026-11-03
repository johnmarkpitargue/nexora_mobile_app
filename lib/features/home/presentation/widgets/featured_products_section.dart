import 'package:flutter/material.dart';
import 'product_card.dart';
import '../../../../core/services/shop_service.dart';

class DailyDiscoverSection extends StatefulWidget {
  final String? selectedCategory;
  final VoidCallback? onLoadMore;

  const DailyDiscoverSection({
    super.key,
    this.selectedCategory,
    this.onLoadMore,
  });

  static List<ProductModel> get allProducts => ShopService.instance.products;

  @override
  State<DailyDiscoverSection> createState() => _DailyDiscoverSectionState();
}

class _DailyDiscoverSectionState extends State<DailyDiscoverSection> {
  @override
  void initState() {
    super.initState();
    ShopService.instance.addListener(_onServiceUpdate);
    _loadCatalog();
  }

  @override
  void didUpdateWidget(covariant DailyDiscoverSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      _loadCatalog();
    }
  }

  @override
  void dispose() {
    ShopService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _loadCatalog() {
    ShopService.instance.loadCatalogRemote(category: widget.selectedCategory).catchError((_) => <ProductModel>[]);
  }

  @override
  Widget build(BuildContext context) {
    final products = ShopService.instance.products;
    final isLoading = ShopService.instance.isLoadingCatalog;
    final error = ShopService.instance.catalogError;
    final selectedCategory = widget.selectedCategory;

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
                            : 'DISCOVER (${selectedCategory.toUpperCase()})',
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Live Catalog',
                style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (isLoading && products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else if (error != null && products.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to load products: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loadCatalog,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            )
          else if (products.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 40),
                  const SizedBox(height: 8),
                  const Text(
                    'No products found in this category',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _loadCatalog,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            )
          else ...[
            // Product Grid Layout
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.50,
              ),
              itemBuilder: (context, index) {
                return ProductCard(product: products[index]);
              },
            ),

            if (widget.onLoadMore != null) ...[
              const SizedBox(height: 16),
              Center(
                child: InkWell(
                  onTap: widget.onLoadMore,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'Load More',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
