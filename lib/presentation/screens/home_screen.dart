import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/state_views.dart';
import 'detail_screen.dart';
import 'product_form_screen.dart';

/// HomeScreen: Main store interface displaying products with search, filters,
/// sorting, pagination, pull-to-refresh, offline caching indicator, and responsive grid.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();

    // Fetch initial data after widget build completes
    Future.microtask(() {
      if (mounted) {
        context.read<ProductProvider>().loadFirstPage();
      }
    });

    // Pagination: Infinite scroll listener
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Trigger next page when user scrolls within 300px of the bottom
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<ProductProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Debounced search: waits 400ms after user stops typing
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: AppConstants.debounceDurationMs),
      () {
        if (mounted) {
          context.read<ProductProvider>().setQuery(query);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.storefront_outlined),
            SizedBox(width: 8),
            Text('Product Store'),
          ],
        ),
        actions: [
          // Filter by Favorites
          IconButton(
            tooltip: 'Filter Favorites',
            onPressed: provider.toggleOnlyFavorites,
            icon: Icon(
              provider.onlyFavorites ? Icons.favorite : Icons.favorite_border,
              color: provider.onlyFavorites ? Colors.redAccent : null,
            ),
          ),

          // Sorting Menu
          PopupMenuButton<SortType>(
            tooltip: 'Sort by',
            icon: const Icon(Icons.sort_rounded),
            onSelected: (sort) => provider.setSort(sort),
            itemBuilder: (_) => [
              _buildSortItem(SortType.none, 'Default (API order)', provider.sortType),
              _buildSortItem(SortType.priceLow, 'Price: Low to High', provider.sortType),
              _buildSortItem(SortType.priceHigh, 'Price: High to Low', provider.sortType),
              _buildSortItem(SortType.rating, 'Top Rated', provider.sortType),
            ],
          ),

          // Dark Mode Toggle
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => context.read<ThemeProvider>().toggle(),
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
        ],
      ),

      // Floating Action Button to Add Product (CRUD: Create)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),

      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products by name, brand, category...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.setQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // 2. Category Filter Chips (Horizontal scrollable)
          if (provider.availableCategories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: provider.selectedCategory == null,
                      onSelected: (_) => provider.setCategory(null),
                    ),
                  ),
                  ...provider.availableCategories.map((cat) {
                    final isSelected = provider.selectedCategory?.toLowerCase() == cat.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) => provider.setCategory(isSelected ? null : cat),
                      ),
                    );
                  }),
                ],
              ),
            ),

          // 3. Offline Cache Indicator Banner
          if (provider.isOffline)
            Container(
              width: double.infinity,
              color: Colors.amber.shade800,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Offline Mode: Displaying saved local cache.',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // 4. Main Body: Loading, Error, Empty, or Product Grid
          Expanded(
            child: _buildBody(provider),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<SortType> _buildSortItem(SortType type, String title, SortType current) {
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          Icon(
            type == current ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildBody(ProductProvider provider) {
    // 1. Initial Fullscreen Loading State
    if (provider.isLoading && !provider.hasAnyData) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Error State (No cached data available)
    if (provider.error != null && !provider.hasAnyData) {
      return _wrapScrollable(
        MessageView(
          icon: Icons.wifi_off_rounded,
          title: 'Unable to Load Products',
          message: provider.error!,
          buttonText: 'Try Again',
          onPressed: () => provider.loadFirstPage(),
        ),
      );
    }

    final items = provider.products;

    // 3. Empty State (No matching results)
    if (items.isEmpty) {
      return _wrapScrollable(
        MessageView(
          icon: Icons.search_off_rounded,
          title: 'No Products Found',
          message: provider.onlyFavorites
              ? 'You have not added any products to your favorites yet.'
              : 'No items match your active search or filter criteria.',
        ),
      );
    }

    // 4. Responsive Grid with Pull-to-Refresh & Infinite Scrolling
    return RefreshIndicator(
      onRefresh: () => provider.loadFirstPage(),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              // Responsive: maxCrossAxisExtent ensures 2 columns on phone, 3-5 on tablet/desktop!
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = items[index];
                  return ProductCard(
                    product: product,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(productId: product.id),
                        ),
                      );
                    },
                  );
                },
                childCount: items.length,
              ),
            ),
          ),

          // Pagination Footer: Infinite scroll loader or "Load More" button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 90),
              child: Center(
                child: provider.isLoadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      )
                    : provider.hasMore
                        ? OutlinedButton.icon(
                            onPressed: () => provider.loadMore(),
                            icon: const Icon(Icons.arrow_downward),
                            label: const Text('Load More Products'),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'All products loaded (${items.length} total)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Wraps empty or error views in a scrollable widget so pull-to-refresh remains functional
  Widget _wrapScrollable(Widget child) {
    return RefreshIndicator(
      onRefresh: () => context.read<ProductProvider>().loadFirstPage(),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      ),
    );
  }
}
