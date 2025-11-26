import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/compare_provider.dart';
import '../services/serpapi_service.dart';
import '../services/search_history_service.dart';
import '../services/recent_products_service.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';
import 'trending_screen.dart';
import 'notification_screen.dart';
import 'compare_screen.dart';
import 'ai_assistant_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  final _serpApiService = SerpApiService();
  final _searchHistoryService = SearchHistoryService();
  final _recentService = RecentProductsService();
  final _focusNode = FocusNode();

  // All search results
  List<Product> _products = [];
  // Filtered + sorted view
  List<Product> _filteredProducts = [];
  // Recently viewed
  List<Product> _recentProducts = [];

  List<String> _searchHistory = [];
  List<String> _autocompleteSuggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  String _sortBy = 'relevance';
  Timer? _debounce;

  // Filter state
  Set<String> _selectedSources = {}; // lowercased sources
  double? _minPrice;
  double? _maxPrice;
  bool _onlyWithPrice = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.read<WishlistProvider>().loadWishlist(user.uid);
    }
    _loadSearchHistory();
    _loadRecentProducts();

    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showSuggestions = true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final history =
        await _searchHistoryService.getHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _loadRecentProducts() async {
    final list =
        await _recentService.getRecentProducts();
    setState(() {
      _recentProducts = list;
    });
  }

  Future<void> _clearRecentProducts() async {
    await _recentService.clear();
    setState(() {
      _recentProducts = [];
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false)
      _debounce!.cancel();

    _debounce =
        Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isNotEmpty) {
        _getAutocompleteSuggestions();
      } else {
        setState(() {
          _autocompleteSuggestions = [];
        });
      }
    });
  }

  Future<void> _getAutocompleteSuggestions() async {
    final suggestions =
        await _serpApiService.getAutocompleteSuggestions(
      _searchController.text.trim(),
    );

    setState(() {
      _autocompleteSuggestions = suggestions;
    });
  }

  Future<void> _searchProducts([String? query]) async {
    final searchQuery =
        query ?? _searchController.text.trim();

    if (searchQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please enter a product name')),
      );
      return;
    }

    if (query != null) {
      _searchController.text = query;
    }

    setState(() {
      _showSuggestions = false;
      _isLoading = true;
      _products = [];
      _filteredProducts = [];
    });

    FocusScope.of(context).unfocus();

    print('🔍 Searching for: $searchQuery');

    try {
      await _searchHistoryService
          .saveSearch(searchQuery);
      await _loadSearchHistory();

      final products =
          await _serpApiService.searchProducts(
              searchQuery);

      _products = products;
      _applyFilters();
      setState(() {
        _isLoading = false;
      });

      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No products found. Try different keywords.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        print('✅ Loaded ${products.length} products');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('❌ Search error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyFilters() {
    List<Product> list = List.from(_products);

    if (_onlyWithPrice) {
      list = list
          .where((p) => p.priceValue != null)
          .toList();
    }

    if (_minPrice != null) {
      list = list
          .where((p) =>
              p.priceValue != null &&
              p.priceValue! >= _minPrice!)
          .toList();
    }

    if (_maxPrice != null) {
      list = list
          .where((p) =>
              p.priceValue != null &&
              p.priceValue! <= _maxPrice!)
          .toList();
    }

    if (_selectedSources.isNotEmpty) {
      list = list.where((p) {
        final src =
            (p.source ?? '').toLowerCase().trim();
        return _selectedSources.contains(src);
      }).toList();
    }

    if (_sortBy == 'price_low') {
      list.sort((a, b) {
        final av = a.priceValue;
        final bv = b.priceValue;
        if (av == null && bv == null) return 0;
        if (av == null) return 1;
        if (bv == null) return -1;
        return av.compareTo(bv);
      });
    } else if (_sortBy == 'price_high') {
      list.sort((a, b) {
        final av = a.priceValue;
        final bv = b.priceValue;
        if (av == null && bv == null) return 0;
        if (av == null) return 1;
        if (bv == null) return -1;
        return bv.compareTo(av);
      });
    }

    setState(() {
      _filteredProducts = list;
    });
  }

  Future<void> _openFilterSheet() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Search for products before applying filters.'),
        ),
      );
      return;
    }

    final sources = _products
        .map((p) => (p.source ?? '').trim())
        .where((s) => s.isNotEmpty)
        .map((s) => s.toLowerCase())
        .toSet()
        .toList()
      ..sort();

    final result =
        await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final tempSelectedSources =
            Set<String>.from(_selectedSources);
        double? tempMinPrice = _minPrice;
        double? tempMaxPrice = _maxPrice;
        bool tempOnlyWithPrice = _onlyWithPrice;

        final minCtrl = TextEditingController(
            text: tempMinPrice?.toString() ?? '');
        final maxCtrl = TextEditingController(
            text: tempMaxPrice?.toString() ?? '');

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx)
                .viewInsets
                .bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin:
                              const EdgeInsets.only(
                                  bottom: 16),
                          decoration:
                              BoxDecoration(
                            color: Colors
                                .grey.shade400,
                            borderRadius:
                                BorderRadius
                                    .circular(2),
                          ),
                        ),
                      ),
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (sources.isNotEmpty) ...[
                        Text(
                          'Sites',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children:
                              sources.map((src) {
                            final selected =
                                tempSelectedSources
                                    .contains(
                                        src);
                            return FilterChip(
                              label: Text(src),
                              selected: selected,
                              onSelected: (val) {
                                setModalState(() {
                                  if (val) {
                                    tempSelectedSources
                                        .add(src);
                                  } else {
                                    tempSelectedSources
                                        .remove(
                                            src);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Text(
                        'Price range (BDT)',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minCtrl,
                              keyboardType:
                                  TextInputType
                                      .number,
                              decoration:
                                  const InputDecoration(
                                labelText: 'Min',
                                border:
                                    OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                setModalState(() {
                                  tempMinPrice =
                                      double.tryParse(
                                              val.trim()) ??
                                          null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: maxCtrl,
                              keyboardType:
                                  TextInputType
                                      .number,
                              decoration:
                                  const InputDecoration(
                                labelText: 'Max',
                                border:
                                    OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                setModalState(() {
                                  tempMaxPrice =
                                      double.tryParse(
                                              val.trim()) ??
                                          null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        title: const Text(
                            'Only show items with price'),
                        value: tempOnlyWithPrice,
                        onChanged: (val) {
                          setModalState(() {
                            tempOnlyWithPrice =
                                val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                ctx,
                                const _FilterResult
                                    .clear(),
                              );
                            },
                            child:
                                const Text('Reset'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                ctx,
                                _FilterResult(
                                  sources:
                                      tempSelectedSources,
                                  minPrice:
                                      tempMinPrice,
                                  maxPrice:
                                      tempMaxPrice,
                                  onlyWithPrice:
                                      tempOnlyWithPrice,
                                ),
                              );
                            },
                            child:
                                const Text('Apply'),
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
      },
    );

    if (result == null) return;

    setState(() {
      if (result.reset) {
        _selectedSources.clear();
        _minPrice = null;
        _maxPrice = null;
        _onlyWithPrice = false;
      } else {
        _selectedSources =
            result.sources ?? {};
        _minPrice = result.minPrice;
        _maxPrice = result.maxPrice;
        _onlyWithPrice =
            result.onlyWithPrice ?? false;
      }
    });

    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider =
        context.watch<AuthProvider>();
    final wishlistProvider =
        context.watch<WishlistProvider>();
    final notificationProvider =
        context.watch<NotificationProvider>();
    final compareProvider =
        context.watch<CompareProvider>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _showSuggestions = false);
      },
      child: Scaffold(
        // Drawer with all actions (3-bar menu)
        drawer: _buildDrawer(
          context,
          wishlistProvider,
          notificationProvider,
        ),
        appBar: AppBar(
          title: const Text('MarketBujho'),
        ),
        floatingActionButton:
            compareProvider.count >= 2
                ? FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CompareScreen(
                            products:
                                compareProvider.selected,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.compare),
                    label: Text(
                        'Compare (${compareProvider.count})'),
                  )
                : null,
        body: Column(
          children: [
            // Search + suggestions + quick chips + recently viewed
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context)
                  .primaryColor
                  .withOpacity(0.05),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller:
                              _searchController,
                          focusNode: _focusNode,
                          decoration:
                              InputDecoration(
                            hintText:
                                'Search products in Bangladesh...',
                            hintStyle: TextStyle(
                                color:
                                    Colors.grey.shade600),
                            prefixIcon:
                                const Icon(Icons.search),
                            suffixIcon:
                                _searchController
                                        .text.isNotEmpty
                                    ? IconButton(
                                        icon:
                                            const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController
                                              .clear();
                                          setState(() {
                                            _autocompleteSuggestions =
                                                [];
                                            _showSuggestions =
                                                false;
                                          });
                                        },
                                      )
                                    : null,
                            filled: true,
                            fillColor: Colors.white,
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      12),
                              borderSide:
                                  BorderSide.none,
                            ),
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      12),
                              borderSide: BorderSide(
                                  color: Colors
                                      .grey.shade300),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                      12),
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          onSubmitted: (_) =>
                              _searchProducts(),
                          onTap: () {
                            setState(() =>
                                _showSuggestions = true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _searchProducts(),
                        style: ElevatedButton
                            .styleFrom(
                          padding:
                              const EdgeInsets.all(16),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    12),
                          ),
                          minimumSize:
                              const Size(56, 56),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search,
                                size: 28),
                      ),
                    ],
                  ),

                  if (_showSuggestions &&
                      _autocompleteSuggestions
                          .isNotEmpty)
                    Container(
                      margin:
                          const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount:
                            _autocompleteSuggestions
                                .length,
                        itemBuilder:
                            (context, index) {
                          final suggestion =
                              _autocompleteSuggestions[
                                  index];
                          return ListTile(
                            leading: const Icon(
                                Icons.search,
                                size: 20),
                            title: Text(suggestion),
                            onTap: () {
                              _searchProducts(
                                  suggestion);
                            },
                          );
                        },
                      ),
                    ),

                  if (_showSuggestions &&
                      _searchHistory.isNotEmpty &&
                      _autocompleteSuggestions
                          .isEmpty)
                    Container(
                      margin:
                          const EdgeInsets.only(top: 8),
                      padding:
                          const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              Text(
                                'Recent Searches',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      Colors.grey.shade700,
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await _searchHistoryService
                                      .clearHistory();
                                  await _loadSearchHistory();
                                },
                                child:
                                    const Text('Clear'),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            children:
                                _searchHistory.map(
                              (query) {
                                return FilterChip(
                                  label: Text(query),
                                  onDeleted: () async {
                                    await _searchHistoryService
                                        .removeItem(
                                            query);
                                    await _loadSearchHistory();
                                  },
                                  deleteIcon:
                                      const Icon(
                                    Icons.close,
                                    size: 18,
                                  ),
                                  backgroundColor:
                                      Colors
                                          .grey.shade100,
                                  onSelected: (_) =>
                                      _searchProducts(
                                          query),
                                );
                              },
                            ).toList(),
                          ),
                        ],
                      ),
                    ),

                  if (!_showSuggestions)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _buildQuickSearchChip(
                              'Samsung Phone'),
                          _buildQuickSearchChip(
                              'Laptop'),
                          _buildQuickSearchChip(
                              'Headphones'),
                          _buildQuickSearchChip(
                              'Smart Watch'),
                        ],
                      ),
                    ),

                  if (!_showSuggestions &&
                      _recentProducts.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              const Text(
                                'Recently viewed',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    _clearRecentProducts,
                                child:
                                    const Text('Clear'),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection:
                                  Axis.horizontal,
                              itemCount:
                                  _recentProducts.length,
                              itemBuilder:
                                  (context, index) {
                                final p =
                                    _recentProducts[
                                        index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ProductDetailsScreen(
                                          product: p,
                                        ),
                                      ),
                                    ).then((_) =>
                                        _loadRecentProducts());
                                  },
                                  child: Container(
                                    width: 160,
                                    margin: const EdgeInsets
                                        .only(
                                            right: 8),
                                    child: Card(
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                                      12)),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets
                                                .all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Expanded(
                                              child:
                                                  ClipRRect(
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                            8),
                                                child: p.thumbnail !=
                                                        null
                                                    ? Image
                                                        .network(
                                                        p.thumbnail!,
                                                        fit: BoxFit
                                                            .cover,
                                                        width:
                                                            double.infinity,
                                                        errorBuilder: (_, __, ___) => const Icon(
                                                            Icons
                                                                .image,
                                                            size:
                                                                40),
                                                      )
                                                    : Container(
                                                        color: Colors
                                                            .grey.shade200,
                                                        child:
                                                            const Center(
                                                          child:
                                                              Icon(
                                                            Icons
                                                                .image,
                                                            size:
                                                                40,
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(
                                                height:
                                                    4),
                                            Text(
                                              p.title,
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                              style:
                                                  const TextStyle(
                                                fontSize:
                                                    12,
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                              ),
                                            ),
                                            if (p.price !=
                                                null)
                                              Text(
                                                p.price!,
                                                style:
                                                    TextStyle(
                                                  fontSize:
                                                      12,
                                                  color: Theme.of(
                                                          context)
                                                      .primaryColor,
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            if (_products.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${_filteredProducts.length} products • Sort: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            Colors.grey.shade700,
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.filter_list),
                      tooltip: 'Filters',
                      onPressed: _openFilterSheet,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection:
                            Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text(
                                  'Relevance'),
                              selected:
                                  _sortBy ==
                                      'relevance',
                              onSelected: (_) {
                                setState(() =>
                                    _sortBy =
                                        'relevance');
                                _applyFilters();
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label:
                                  const Text('Price ↑'),
                              selected:
                                  _sortBy ==
                                      'price_low',
                              onSelected: (_) {
                                setState(() =>
                                    _sortBy =
                                        'price_low');
                                _applyFilters();
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label:
                                  const Text('Price ↓'),
                              selected:
                                  _sortBy ==
                                      'price_high',
                              onSelected: (_) {
                                setState(() =>
                                    _sortBy =
                                        'price_high');
                                _applyFilters();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Searching products...',
                            style: TextStyle(
                              color:
                                  Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 100,
                                color:
                                    Colors.grey.shade400,
                              ),
                              const SizedBox(
                                  height: 16),
                              Text(
                                'Search for products',
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade600,
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(
                                  height: 8),
                              Text(
                                'Find the best prices in Bangladesh',
                                style: TextStyle(
                                  color:
                                      Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _filteredProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                    Icons.filter_alt_off,
                                    size: 80,
                                    color: Colors.grey
                                        .shade400,
                                  ),
                                  const SizedBox(
                                      height: 16),
                                  Text(
                                    'No products match your filters',
                                    style: TextStyle(
                                      color: Colors.grey
                                          .shade600,
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                      height: 8),
                                  Text(
                                    'Try adjusting your filters.',
                                    style: TextStyle(
                                      color: Colors.grey
                                          .shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount:
                                  _filteredProducts
                                      .length,
                              padding:
                                  const EdgeInsets.only(
                                      bottom: 16),
                              itemBuilder:
                                  (context, index) {
                                final product =
                                    _filteredProducts[
                                        index];
                                final productId =
                                    product
                                        .link.hashCode
                                        .toString();
                                final isInCompare =
                                    compareProvider
                                        .isSelected(
                                            productId);

                                return ProductCard(
                                  product: product,
                                  isInWishlist:
                                      wishlistProvider
                                          .isInWishlist(
                                              productId),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ProductDetailsScreen(
                                          product:
                                              product,
                                        ),
                                      ),
                                    ).then((_) =>
                                        _loadRecentProducts());
                                  },
                                  onWishlistTap: () {
                                    wishlistProvider
                                        .toggleWishlist(
                                      authProvider
                                          .user!.uid,
                                      product,
                                    );

                                    ScaffoldMessenger
                                            .of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          wishlistProvider
                                                  .isInWishlist(
                                                      productId)
                                              ? 'Removed from wishlist'
                                              : 'Added to wishlist',
                                        ),
                                        duration:
                                            const Duration(
                                                seconds:
                                                    1),
                                      ),
                                    );
                                  },
                                  showCompare: true,
                                  isInCompare:
                                      isInCompare,
                                  onCompareTap: () {
                                    if (!isInCompare &&
                                        compareProvider
                                                .count >=
                                            4) {
                                      ScaffoldMessenger
                                              .of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'You can compare up to 4 products.'),
                                          duration:
                                              Duration(
                                                  seconds:
                                                      2),
                                        ),
                                      );
                                      return;
                                    }
                                    compareProvider
                                        .toggleProduct(
                                            product);
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(
    BuildContext context,
    WishlistProvider wishlistProvider,
    NotificationProvider notificationProvider,
  ) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.1),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'MarketBujho Menu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Wishlist'),
              subtitle: Text(
                '${wishlistProvider.wishlist.length} items',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const WishlistScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              subtitle: Text(
                notificationProvider.hasUnread
                    ? 'Unread notifications'
                    : 'No new notifications',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const NotificationScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.smart_toy_outlined),
              title:
                  const Text('AI Shopping Assistant'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AiAssistantScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Trending Offers'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const TrendingScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ProfileScreen(),
                  ),
                );
              },
            ),
            const Spacer(),
            Padding(
              padding:
                  const EdgeInsets.all(12.0),
              child: Text(
                'Version 1.0 • MarketBujho',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSearchChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _searchProducts(label),
      backgroundColor: Colors.blue.shade50,
      labelStyle:
          TextStyle(color: Colors.blue.shade700),
      side: BorderSide(
          color: Colors.blue.shade200),
    );
  }
}

class _FilterResult {
  final Set<String>? sources;
  final double? minPrice;
  final double? maxPrice;
  final bool? onlyWithPrice;
  final bool reset;

  const _FilterResult({
    this.sources,
    this.minPrice,
    this.maxPrice,
    this.onlyWithPrice,
    this.reset = false,
  });

  const _FilterResult.clear()
      : sources = null,
        minPrice = null,
        maxPrice = null,
        onlyWithPrice = null,
        reset = true;
}