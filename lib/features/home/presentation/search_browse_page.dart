import 'package:flutter/material.dart';
import '../../../core/services/shop_service.dart';
import '../../../app/theme/nexora_theme.dart';
import 'widgets/product_card.dart';

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

  List<String> get _categories {
    final remoteCats = ShopService.instance.categories.map((c) => c.name).toList();
    if (remoteCats.isEmpty) {
      return const ['All'];
    }
    return ['All', ...remoteCats];
  }

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
    if (ShopService.instance.categories.isEmpty) {
      ShopService.instance.fetchCategoriesRemote().then((_) {
        if (mounted) setState(() {});
      }).catchError((_) {});
    }
    _executeSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _executeSearch() async {
    setState(() => _isLoading = true);
    final String? catParam;
    if (_currentCategory == 'All') {
      catParam = null;
    } else {
      final matched = ShopService.instance.categories.where(
        (c) => c.name.toLowerCase() == _currentCategory.toLowerCase() ||
               c.slug.toLowerCase() == _currentCategory.toLowerCase(),
      );
      catParam = matched.isNotEmpty ? matched.first.slug : _currentCategory;
    }

    final params = SearchFilterParams(
      query: _searchController.text.trim(),
      category: catParam,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      location: _selectedLocation,
      sortBy: _currentSort,
    );

    try {
      final res = await ShopService.instance.searchAndFilterRemote(params);
      if (mounted) {
        setState(() {
          _searchResult = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResult = const SearchResult(
            products: [],
            errorMessage: 'Failed to load search results. Please check your connection and try again.',
          );
          _isLoading = false;
        });
      }
    }
  }

  void _openFilterDialog() {
    final minCtrl = TextEditingController(text: _minPrice != null ? _minPrice!.toStringAsFixed(0) : '');
    final maxCtrl = TextEditingController(text: _maxPrice != null ? _maxPrice!.toStringAsFixed(0) : '');
    String? tempLocation = _selectedLocation;
    double? tempRating = _minRating;
    String? filterError;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final sheetBg = isDark ? const Color(0xFF0D1323) : Colors.white;
          final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final labelColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B);
          final inputBg = isDark ? const Color(0xFF131D38) : const Color(0xFFF8FAFC);
          final chipBg = isDark ? const Color(0xFF131D38) : const Color(0xFFF1F5F9);
          final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: isDark ? Border.all(color: borderColor, width: 1) : null,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Products',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: titleColor),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: isDark ? const Color(0xFF94A3B8) : Colors.black54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (filterError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A1215) : const Color(0xFFFFEBEB),
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
                  Text('Price Range (₱)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: labelColor)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 13, color: titleColor, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Min Price',
                            hintStyle: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                            prefixText: '₱ ',
                            prefixStyle: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('—', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.black54)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 13, color: titleColor, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Max Price',
                            hintStyle: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                            prefixText: '₱ ',
                            prefixStyle: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
                            filled: true,
                            fillColor: inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location (BUY-SRCH-008)
                  Text('Shipped From / Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: labelColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Metro Manila', 'Luzon', 'Visayas', 'Mindanao'].map((loc) {
                      final isSel = tempLocation == loc;
                      return ChoiceChip(
                        label: Text(
                          loc,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                          ),
                        ),
                        selected: isSel,
                        backgroundColor: chipBg,
                        selectedColor: const Color(0xFF0066FF),
                        side: BorderSide(color: isSel ? const Color(0xFF0066FF) : borderColor),
                        onSelected: (val) => setSheetState(() => tempLocation = val ? loc : null),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Rating Filter
                  Text('Customer Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: labelColor)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              '4.0+ Stars',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: tempRating == 4.0 ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                        selected: tempRating == 4.0,
                        backgroundColor: chipBg,
                        selectedColor: const Color(0xFF0066FF),
                        side: BorderSide(color: tempRating == 4.0 ? const Color(0xFF0066FF) : borderColor),
                        onSelected: (val) => setSheetState(() => tempRating = val ? 4.0 : null),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              '4.8+ Stars',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: tempRating == 4.8 ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                        selected: tempRating == 4.8,
                        backgroundColor: chipBg,
                        selectedColor: const Color(0xFF0066FF),
                        side: BorderSide(color: tempRating == 4.8 ? const Color(0xFF0066FF) : borderColor),
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
                            minCtrl.clear();
                            maxCtrl.clear();
                            setState(() {
                              _minPrice = null;
                              _maxPrice = null;
                              _selectedLocation = null;
                              _minRating = null;
                            });
                            Navigator.pop(ctx);
                            _executeSearch();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                            side: BorderSide(color: borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF060914) : const Color(0xFFF6F8FC);
    final headerBg = isDark ? const Color(0xFF060914) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: headerBg,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 14,
            bottom: 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: theme.colorScheme.onSurface,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          key: const ValueKey('shopping-search-field'),
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          cursorColor: theme.colorScheme.primary,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) {
                            FocusScope.of(context).unfocus(); // BUY-SRCH-012: close keyboard
                            _executeSearch();
                          },
                          style: TextStyle(
                            fontSize: 13.5,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search products, brands, categories...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
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
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
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
                    key: const ValueKey('shopping-filter-action'),
                    onPressed: _openFilterDialog,
                    tooltip: 'Filter',
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      backgroundColor: theme.colorScheme.surfaceContainerLowest,
                      minimumSize: const Size(44, 44),
                      maximumSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 20),
                  ),
                  if (_minPrice != null ||
                      _maxPrice != null ||
                      _minRating != null ||
                      _selectedLocation != null)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D4F),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: headerBg,
                            width: 1.5,
                          ),
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
              color: Theme.of(context).colorScheme.surface,
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
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentCategory = cat);
                        _executeSearch();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel
                              ? NexoraTheme.primary
                              : (isDark ? const Color(0xFF131D38) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(18),
                          border: isSel
                              ? null
                              : Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : const Color(0xFFE2E8F0),
                                ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontFamily: NexoraTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
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
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${_searchResult.products.length} products found',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: NexoraTheme.fontFamily,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _currentSort,
                    underline: const SizedBox(),
                    isDense: true,
                    dropdownColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0F1738)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 4,
                    style: TextStyle(
                      fontFamily: NexoraTheme.fontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF38BDF8)
                          : NexoraTheme.primary,
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF38BDF8)
                          : NexoraTheme.primary,
                    ),
                    items: _sortOptions.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                e.value,
                                style: TextStyle(
                                  fontFamily: NexoraTheme.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ))
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
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'No matching products found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try checking for spelling errors or clearing filters.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = switch (constraints.maxWidth) {
          >= 1080 => 5,
          >= 820 => 4,
          >= 560 => 3,
          _ => 2,
        };
        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
            crossAxisCount;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final accessibilityGrowth =
            ((textScale - 1).clamp(0.0, 1.0) * 116);
        final cardHeight = cardWidth + 168.0 + accessibilityGrowth;

        return GridView.builder(
          padding: const EdgeInsets.all(14),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: cardHeight,
          ),
          itemCount: _searchResult.products.length,
          itemBuilder: (ctx, idx) {
            return ProductCard(product: _searchResult.products[idx]);
          },
        );
      },
    );
  }
}
