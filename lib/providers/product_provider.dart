import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../data/model/product.dart';
import '../data/repository/product_repository.dart';

/// Available sorting options
enum SortType { none, priceLow, priceHigh, rating }

/// ProductProvider manages the state of products, search, filtering,
/// sorting, pagination, favorites, and CRUD operations.
class ProductProvider extends ChangeNotifier {
  final ProductRepository _repo;

  ProductProvider(this._repo) {
    _favorites = _repo.getFavorites();
  }

  // Raw product storage
  List<Product> _apiItems = [];
  List<Product> _localItems = [];
  Set<int> _favorites = {};

  // UI state variables
  bool isLoading = false;       // Initial load or pull-to-refresh
  bool isLoadingMore = false;   // Pagination infinite scroll
  bool hasMore = true;          // Whether more pages exist
  bool isOffline = false;       // True if serving cached data
  String? error;

  // Filter and sort states
  String _query = '';
  String? _selectedCategory;
  SortType sortType = SortType.none;
  bool onlyFavorites = false;
  int _skip = 0;

  // ==================== Getters ====================

  /// Dynamically computes list of all unique categories available
  List<String> get availableCategories {
    final all = [..._localItems, ..._apiItems];
    final categories = all
        .map((p) => p.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return categories;
  }

  String? get selectedCategory => _selectedCategory;

  /// Computed list of products with search, category filter, favorites filter, and sorting applied
  List<Product> get products {
    var list = [..._localItems, ..._apiItems];

    // 1. Favorites filter
    if (onlyFavorites) {
      list = list.where((p) => _favorites.contains(p.id)).toList();
    }

    // 2. Category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      list = list.where((p) => p.category.toLowerCase() == _selectedCategory!.toLowerCase()).toList();
    }

    // 3. Search query filter
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q);
      }).toList();
    }

    // 4. Sorting
    switch (sortType) {
      case SortType.priceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortType.priceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortType.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortType.none:
        break;
    }

    return list;
  }

  bool get hasAnyData => _localItems.isNotEmpty || _apiItems.isNotEmpty;

  bool isFavorite(int id) => _favorites.contains(id);

  // ==================== Data Fetching & Pagination ====================

  /// Fetches the first page of products (used on startup and Pull-to-Refresh)
  Future<void> loadFirstPage() async {
    isLoading = true;
    error = null;
    notifyListeners();

    _localItems = _repo.getLocalProducts();
    _skip = 0;

    try {
      final result = await _repo.getProducts(skip: 0);
      _apiItems = result.items;
      _skip = result.rawCount;
      hasMore = _skip < result.total && result.rawCount > 0;
      isOffline = result.fromCache;
    } catch (e) {
      error = _friendlyError(e);
    }

    isLoading = false;
    notifyListeners();
  }

  /// Fetches the next page of products (used for Infinite Scrolling / Load More)
  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repo.getProducts(skip: _skip);
      _apiItems = [..._apiItems, ...result.items];
      _skip += result.rawCount;
      hasMore = _skip < result.total && result.rawCount > 0;
      isOffline = result.fromCache;
    } catch (e) {
      error = _friendlyError(e);
    }

    isLoadingMore = false;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    if (e is SocketException || e is TimeoutException) {
      return 'No internet connection detected.\nPlease check your network and pull down to refresh.';
    }
    return 'Unable to fetch data from API.\nPlease try again later.';
  }

  // ==================== Filtering, Searching & Sorting ====================

  void setQuery(String value) {
    _query = value.trim();
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSort(SortType type) {
    sortType = type;
    notifyListeners();
  }

  void toggleOnlyFavorites() {
    onlyFavorites = !onlyFavorites;
    notifyListeners();
  }

  // ==================== Favorites ====================

  void toggleFavorite(int id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    _repo.saveFavorites(_favorites);
    notifyListeners();
  }

  // ==================== CRUD Operations ====================

  /// CREATE: Add a product locally
  void addProduct(Product product) {
    final saved = _repo.addProduct(product);
    _localItems = [saved, ..._localItems];
    notifyListeners();
  }

  /// UPDATE: Update an existing product
  void updateProduct(Product product) {
    final saved = _repo.updateProduct(product);
    _localItems = _localItems.map((e) => e.id == saved.id ? saved : e).toList();
    _apiItems = _apiItems.map((e) => e.id == saved.id ? saved : e).toList();
    notifyListeners();
  }

  /// DELETE: Remove a product
  void deleteProduct(Product product) {
    _repo.deleteProduct(product);
    _localItems = _localItems.where((e) => e.id != product.id).toList();
    _apiItems = _apiItems.where((e) => e.id != product.id).toList();
    _favorites.remove(product.id);
    _repo.saveFavorites(_favorites);
    notifyListeners();
  }

  /// Retrieve the current product instance by its ID
  Product? findById(int id) {
    for (final p in [..._localItems, ..._apiItems]) {
      if (p.id == id) return p;
    }
    return null;
  }
}
