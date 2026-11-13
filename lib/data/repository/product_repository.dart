import '../../core/constants.dart';
import '../datasource/local_datasource.dart';
import '../datasource/remote_datasource.dart';
import '../model/product.dart';

/// ProductRepository implements the Repository Pattern.
/// It orchestrates remote network requests and local Hive caching,
/// providing an offline-first data source for the presentation layer.
class ProductRepository {
  final RemoteDataSource remote;
  final LocalDataSource local;

  ProductRepository(this.remote, this.local);

  /// READ: Fetches a page of products.
  /// First attempts remote API fetch; if that fails (offline), falls back to local cache.
  Future<PageResult> getProducts({required int skip}) async {
    final deleted = local.deletedIds;

    try {
      // 1. Attempt to fetch from network API
      final page = await remote.fetchProducts(
        skip: skip,
        limit: AppConstants.pageSize,
      );

      final List<Product> items = [];

      for (final p in page.products) {
        // Skip items the user has previously deleted
        if (deleted.contains(p.id)) continue;

        // If user previously edited this product, preserve user edits!
        final saved = local.getProduct(p.id);
        if (saved != null && saved.edited) {
          items.add(saved);
        } else {
          // Cache the fresh API item locally for offline access
          local.saveProduct(p);
          items.add(p);
        }
      }

      return PageResult(
        items: items,
        total: page.total,
        rawCount: page.products.length,
        fromCache: false,
      );
    } catch (_) {
      // 2. Offline Fallback: Read cached products from Hive
      final cached = local
          .getAll()
          .where((p) => !p.isLocal && !deleted.contains(p.id))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      if (cached.isEmpty) {
        // No local cache available to satisfy the request; rethrow so UI displays retry view
        rethrow;
      }

      // Slice the cached list to simulate pagination
      final pagedItems = cached.skip(skip).take(AppConstants.pageSize).toList();

      return PageResult(
        items: pagedItems,
        total: cached.length,
        rawCount: pagedItems.length,
        fromCache: true,
      );
    }
  }

  /// Returns products added locally by the user
  List<Product> getLocalProducts() {
    final list = local.getAll().where((p) => p.isLocal).toList()
      ..sort((a, b) => b.id.compareTo(a.id)); // Newest first
    return list;
  }

  /// CREATE: Adds a new product locally to Hive
  Product addProduct(Product p) {
    final newProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch,
      title: p.title,
      description: p.description,
      category: p.category,
      brand: p.brand,
      price: p.price,
      rating: 5.0, // default new product rating
      discount: p.discount,
      stock: p.stock > 0 ? p.stock : 10,
      thumbnail: p.thumbnail,
      images: p.images.isNotEmpty ? p.images : (p.thumbnail.isNotEmpty ? [p.thumbnail] : []),
      isLocal: true,
      edited: false,
    );

    local.saveProduct(newProduct);
    return newProduct;
  }

  /// UPDATE: Updates an existing product and marks it as edited
  Product updateProduct(Product p) {
    final updated = p.copyWith(edited: true);
    local.saveProduct(updated);
    return updated;
  }

  /// DELETE: Removes a product from local storage and tracks its deletion
  void deleteProduct(Product p) {
    local.removeProduct(p.id);
    if (!p.isLocal) {
      local.addDeleted(p.id);
    }
  }

  /// Favorites management
  Set<int> getFavorites() => local.favorites;
  void saveFavorites(Set<int> ids) => local.saveFavorites(ids);
}
