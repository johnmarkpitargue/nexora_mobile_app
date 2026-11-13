import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/nexora_theme.dart';
import '../../../core/services/shop_service.dart';
import 'widgets/shopping_components.dart';

class SearchBrowsePage extends StatefulWidget {
  const SearchBrowsePage({
    super.key,
    this.initialQuery = '',
    this.initialCategory,
  });

  final String initialQuery;
  final String? initialCategory;

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

  static const _sortOptions = <String, String>{
    'relevance': 'Relevance',
    'price_asc': 'Price: Low to High',
    'price_desc': 'Price: High to Low',
    'best_selling': 'Best Selling',
    'latest': 'Latest',
  };

  List<String> get _categories {
    final values =
        ShopService.allAppProducts
            .where((product) => product.isActive)
            .map((product) => product.category)
            .toSet()
            .toList()
          ..sort();
    return ['All', ...values];
  }

  int get _activeFilterCount => [
    _minPrice,
    _maxPrice,
    _selectedLocation,
    _minRating,
  ].where((value) => value != null).length;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _currentCategory = widget.initialCategory ?? 'All';
    _executeSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _executeSearch() {
    if (mounted) setState(() => _isLoading = true);
    final result = ShopService.instance.searchAndFilter(
      SearchFilterParams(
        query: _searchController.text.trim(),
        category: _currentCategory == 'All' ? null : _currentCategory,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        location: _selectedLocation,
        sortBy: _currentSort,
      ),
    );
    if (!mounted) return;
    setState(() {
      _searchResult = result;
      _isLoading = false;
    });
  }

  Future<void> _refresh() async {
    _executeSearch();
    await Future<void>.delayed(
      NexoraMotion.resolve(context, NexoraMotion.fast),
    );
  }

  void _clearFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _selectedLocation = null;
      _minRating = null;
    });
    _executeSearch();
  }

  Future<void> _openFilters() async {
    final minController = TextEditingController(
      text: _minPrice?.toStringAsFixed(0) ?? '',
    );
    final maxController = TextEditingController(
      text: _maxPrice?.toStringAsFixed(0) ?? '',
    );
    var location = _selectedLocation;
    var rating = _minRating;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  NexoraSpacing.lg,
                  NexoraSpacing.sm,
                  NexoraSpacing.lg,
                  MediaQuery.viewInsetsOf(context).bottom + NexoraSpacing.lg,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter products',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close filters',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: NexoraSpacing.lg),
                      Text(
                        'Price range',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: NexoraSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Minimum',
                                prefixText: '₱ ',
                              ),
                            ),
                          ),
                          const SizedBox(width: NexoraSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: maxController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Maximum',
                                prefixText: '₱ ',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (error != null) ...[
                        const SizedBox(height: NexoraSpacing.sm),
                        Text(
                          error!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                      const SizedBox(height: NexoraSpacing.xl),
                      Text(
                        'Ships from',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: NexoraSpacing.sm),
                      Wrap(
                        spacing: NexoraSpacing.xs,
                        runSpacing: NexoraSpacing.xs,
                        children:
                            ['Metro Manila', 'Luzon', 'Visayas', 'Mindanao']
                                .map(
                                  (value) => ChoiceChip(
                                    label: Text(value),
                                    selected: location == value,
                                    onSelected: (selected) => setSheetState(
                                      () => location = selected ? value : null,
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: NexoraSpacing.xl),
                      Text(
                        'Minimum rating',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: NexoraSpacing.sm),
                      Wrap(
                        spacing: NexoraSpacing.xs,
                        children: [4.0, 4.8]
                            .map(
                              (value) => ChoiceChip(
                                avatar: const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Color(0xFFF59E0B),
                                ),
                                label: Text('$value and up'),
                                selected: rating == value,
                                onSelected: (selected) => setSheetState(
                                  () => rating = selected ? value : null,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: NexoraSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                minController.clear();
                                maxController.clear();
                                setSheetState(() {
                                  location = null;
                                  rating = null;
                                  error = null;
                                });
                              },
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: NexoraSpacing.sm),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                final min = double.tryParse(minController.text);
                                final max = double.tryParse(maxController.text);
                                if (min != null && min < 0 ||
                                    max != null && max < 0) {
                                  setSheetState(
                                    () => error = 'Price cannot be negative.',
                                  );
                                  return;
                                }
                                if (min != null && max != null && min > max) {
                                  setSheetState(
                                    () => error = 'Minimum price cannot exceed maximum price.',
                                  );
                                  return;
                                }
                                setState(() {
                                  _minPrice = min;
                                  _maxPrice = max;
                                  _selectedLocation = location;
                                  _minRating = rating;
                                });
                                Navigator.pop(sheetContext);
                                _executeSearch();
                              },
                              child: const Text('Show results'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    minController.dispose();
    maxController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          key: const ValueKey('shopping-search-field'),
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) {
            _searchFocusNode.unfocus();
            _executeSearch();
          },
          decoration: InputDecoration(
            hintText: 'Search products and brands',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: ListenableBuilder(
              listenable: _searchController,
              builder: (context, _) {
                if (_searchController.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    _executeSearch();
                  },
                  icon: const Icon(Icons.close_rounded),
                );
              },
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainer,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NexoraRadius.control),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(NexoraRadius.control),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          Badge(
            isLabelVisible: _activeFilterCount > 0,
            label: Text('$_activeFilterCount'),
            child: IconButton(
              key: const ValueKey('shopping-filter-action'),
              tooltip: _activeFilterCount > 0
                  ? 'Filters, $_activeFilterCount active'
                  : 'Filters',
              onPressed: _openFilters,
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
          const SizedBox(width: NexoraSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: NexoraSpacing.md,
                  vertical: NexoraSpacing.xs,
                ),
                itemCount: _categories.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: NexoraSpacing.xs),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return ChoiceChip(
                    label: Text(category),
                    selected: category == _currentCategory,
                    onSelected: (_) {
                      setState(() => _currentCategory = category);
                      _executeSearch();
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NexoraSpacing.md,
                NexoraSpacing.sm,
                NexoraSpacing.sm,
                NexoraSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        '${_searchResult.products.length} ${_searchResult.products.length == 1 ? 'product' : 'products'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currentSort,
                      borderRadius: BorderRadius.circular(NexoraRadius.control),
                      items: _sortOptions.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _currentSort = value);
                        _executeSearch();
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_activeFilterCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  NexoraSpacing.md,
                  0,
                  NexoraSpacing.md,
                  NexoraSpacing.sm,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ActionChip(
                    avatar: const Icon(Icons.close_rounded, size: 16),
                    label: Text('Clear $_activeFilterCount filters'),
                    onPressed: _clearFilters,
                  ),
                ),
              ),
            if (_searchResult.typoSuggestion != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: NexoraSpacing.md,
                  vertical: NexoraSpacing.xs,
                ),
                child: Material(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(NexoraRadius.control),
                  child: Padding(
                    padding: const EdgeInsets.all(NexoraSpacing.sm),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: NexoraSpacing.xs),
                        Expanded(
                          child: Text(
                            _searchResult.typoSuggestion!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) return const ShoppingSkeletonGrid();
    final error = _searchResult.errorMessage;
    if (error != null) {
      return ShoppingEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'We couldn’t load products',
        message: error,
        actionLabel: 'Try again',
        onAction: _executeSearch,
      );
    }
    if (_searchResult.products.isEmpty) {
      return ShoppingEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matching products',
        message:
            'Try a broader search, another category, or clear your filters.',
        actionLabel: _activeFilterCount > 0 ? 'Clear filters' : null,
        onAction: _activeFilterCount > 0 ? _clearFilters : null,
      );
    }
    return ShoppingProductGrid(products: _searchResult.products);
  }
}
