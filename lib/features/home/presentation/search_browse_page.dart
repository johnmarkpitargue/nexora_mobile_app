import 'package:flutter/material.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/services/shop_service.dart';
import 'package:nexora_flutter_app/features/home/presentation/widgets/product_card.dart';

class SearchBrowsePage extends StatefulWidget {
  final String initialQuery;
  final String? initialCategory;

  const SearchBrowsePage({
    super.key,
    this.initialQuery = '',
    this.initialCategory,
  });

  @override
  State<SearchBrowsePage> createState() => _SearchBrowsePageState();
}

class _SearchBrowsePageState extends State<SearchBrowsePage> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  String _currentCategory = 'All';
  String _currentSort = 'relevance';
  String? _selectedLocation;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;

  SearchResult _searchResult = const SearchResult(products: []);
  bool _isLoading = false;

  final List<String> _categories = [
    'All',
    'Home & Living',
    'Audio',
    'Tech & Gadgets',
    'Gaming',
    'Jewelry',
    'Fashion',
  ];

  final Map<String, String> _sortOptions = {
    'relevance': 'Relevance',
    'price_asc': 'Price: Low to High',
    'price_desc': 'Price: High to Low',
    'best_selling': 'Best Selling',
    'latest': 'Latest',
  };

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    if (widget.initialCategory != null) {
      _currentCategory = widget.initialCategory!;
    }
    _executeSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _executeSearch() {
    setState(() => _isLoading = true);
    final params = SearchFilterParams(
      query: _searchController.text.trim(),
      category: _currentCategory == 'All' ? null : _currentCategory,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      location: _selectedLocation,
      sortBy: _currentSort,
    );

    final res = ShopService.instance.searchAndFilter(params);
    setState(() {
      _searchResult = res;
      _isLoading = false;
    });
  }

  void _openFilterDialog() {
    final minCtrl = TextEditingController(text: _minPrice != null ? _minPrice!.toStringAsFixed(0) : '');
    final maxCtrl = TextEditingController(text: _maxPrice != null ? _maxPrice!.toStringAsFixed(0) : '');
    String? tempLocation = _selectedLocation;
    double? tempRating = _minRating;
    String? filterError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Products',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (filterError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              filterError!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Price Range (BUY-SRCH-007)
                  const Text('Price Range (₱)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Min Price',
                            prefixText: '₱ ',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('—', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Max Price',
                            prefixText: '₱ ',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location (BUY-SRCH-008)
                  const Text('Shipped From / Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Metro Manila', 'Luzon', 'Visayas', 'Mindanao'].map((loc) {
                      final isSel = tempLocation == loc;
                      return ChoiceChip(
                        label: Text(loc),
                        selected: isSel,
                        selectedColor: const Color(0xFF00D2FF),
                        onSelected: (val) => setSheetState(() => tempLocation = val ? loc : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Rating Filter
                  const Text('Customer Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                            SizedBox(width: 4),
                            Text('4.0+ Stars'),
                          ],
                        ),
                        selected: tempRating == 4.0,
                        selectedColor: const Color(0xFF00D2FF),
                        onSelected: (val) => setSheetState(() => tempRating = val ? 4.0 : null),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                            SizedBox(width: 4),
                            Text('4.8+ Stars'),
                          ],
                        ),
                        selected: tempRating == 4.8,
                        selectedColor: const Color(0xFF00D2FF),
                        onSelected: (val) => setSheetState(() => tempRating = val ? 4.8 : null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _minPrice = null;
                              _maxPrice = null;
                              _selectedLocation = null;
                              _minRating = null;
                            });
                            Navigator.pop(ctx);
                            _executeSearch();
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final minVal = minCtrl.text.isNotEmpty ? double.tryParse(minCtrl.text) : null;
                            final maxVal = maxCtrl.text.isNotEmpty ? double.tryParse(maxCtrl.text) : null;

                            if (minVal != null && minVal < 0) {
                              setSheetState(() => filterError = 'Price cannot be negative');
                              return;
                            }
                            if (maxVal != null && maxVal < 0) {
                              setSheetState(() => filterError = 'Price cannot be negative');
                              return;
                            }
                            if (minVal != null && maxVal != null && minVal > maxVal) {
                              setSheetState(() => filterError = 'Minimum price cannot be greater than maximum price');
                              return;
                            }

                            setState(() {
                              _minPrice = minVal;
                              _maxPrice = maxVal;
                              _selectedLocation = tempLocation;
                              _minRating = tempRating;
                            });
                            Navigator.pop(ctx);
                            _executeSearch();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: const Color(0xFF050B28),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 4,
            left: 6,
            right: 12,
            bottom: 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          cursorColor: Colors.white,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) {
                            FocusScope.of(context).unfocus(); // BUY-SRCH-012: close keyboard
                            _executeSearch();
                          },
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search products, brands, categories...',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: _searchController,
                        builder: (context, _) {
                          if (_searchController.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _executeSearch();
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(Icons.close, size: 16, color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                    onPressed: _openFilterDialog,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    tooltip: 'Filter',
                  ),
                  if (_minPrice != null ||
                      _maxPrice != null ||
                      _minRating != null ||
                      _selectedLocation != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4D4F),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _executeSearch(), // BUY-SRCH-013: Pull to refresh
        child: Column(
          children: [
            // Category Bar (BUY-SRCH-001)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final cat = _categories[i];
                    final isSel = _currentCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentCategory = cat);
                        _executeSearch();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF0066FF) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Sort & Applied Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF8FAFC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${_searchResult.products.length} products found',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _currentSort,
                    underline: const SizedBox(),
                    isDense: true,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0066FF)),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0066FF)),
                    items: _sortOptions.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _currentSort = val);
                        _executeSearch();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Typo Suggestion Banner (BUY-SRCH-004)
            if (_searchResult.typoSuggestion != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFE0F7FA),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Color(0xFF00838F), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF006064)),
                          children: [
                            TextSpan(text: '${_searchResult.typoSuggestion!} '),
                            const TextSpan(
                              text: 'Showing matching items.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Results View
            Expanded(
              child: _buildResultsContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)));
    }

    // Offline / Error View (BUY-SRCH-013)
    if (_searchResult.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                _searchResult.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _executeSearch,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResult.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'No matching products found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try checking for spelling errors or clearing filters.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemCount: _searchResult.products.length,
      itemBuilder: (ctx, idx) {
        final p = _searchResult.products[idx];
        return _buildSearchProductCard(p);
      },
    );
  }

  Widget _buildSearchProductCard(ProductModel p) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.productDetails, arguments: p);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.1,
                  child: Image.network(
                    p.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: const Color(0xFFEEECFF),
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                // Vacation Badge (BUY-SRCH-011)
                if (p.isOnVacation)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'On vacation',
                        style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                // Mall / Store badge
                if (!p.isOnVacation && p.isMall)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'MALL',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        p.price,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      if (p.originalPrice != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          p.originalPrice!,
                          style: TextStyle(
                            fontSize: 10.5,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text('${p.rating}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text(p.soldCount, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.shippingTag,
                    style: const TextStyle(fontSize: 9.5, color: Color(0xFF00BCD4), fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
