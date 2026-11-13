import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants.dart';
import '../model/product.dart';

/// LocalDataSource manages on-device persistence using Hive NoSQL database.
/// Provides offline cache for products, local additions, edits, deletes, and favorites.
class LocalDataSource {
  late Box _productsBox;
  late Box _metaBox;

  /// Open required Hive boxes
  Future<void> init() async {
    _productsBox = await Hive.openBox(AppConstants.productBoxName);
    _metaBox = await Hive.openBox(AppConstants.metaBoxName);
  }

  // ==================== Products Cache & Local CRUD ====================

  /// Retrieve a single product by ID
  Product? getProduct(int id) {
    final raw = _productsBox.get(id.toString());
    if (raw == null) return null;
    try {
      if (raw is String) {
        return Product.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } else if (raw is Map) {
        return Product.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {}
    return null;
  }

  /// Retrieve all products stored in Hive
  List<Product> getAll() {
    final List<Product> items = [];
    for (final value in _productsBox.values) {
      try {
        if (value is String) {
          items.add(Product.fromJson(jsonDecode(value) as Map<String, dynamic>));
        } else if (value is Map) {
          items.add(Product.fromJson(Map<String, dynamic>.from(value)));
        }
      } catch (_) {}
    }
    return items;
  }

  /// Save or update a product in Hive
  void saveProduct(Product product) {
    _productsBox.put(product.id.toString(), jsonEncode(product.toJson()));
  }

  /// Delete a product from Hive
  void removeProduct(int id) {
    _productsBox.delete(id.toString());
  }

  // ==================== Deleted Tracking ====================

  /// Set of product IDs deleted by the user (prevents API re-populating them)
  Set<int> get deletedIds {
    final raw = _metaBox.get('deleted_ids', defaultValue: <dynamic>[]);
    if (raw is List) {
      return raw.map((e) => (e as num).toInt()).toSet();
    }
    return <int>{};
  }

  /// Mark an ID as permanently deleted
  void addDeleted(int id) {
    final set = deletedIds..add(id);
    _metaBox.put('deleted_ids', set.toList());
  }

  // ==================== Favorites ====================

  /// Retrieve set of favorite product IDs
  Set<int> get favorites {
    final raw = _metaBox.get('favorite_ids', defaultValue: <dynamic>[]);
    if (raw is List) {
      return raw.map((e) => (e as num).toInt()).toSet();
    }
    return <int>{};
  }

  /// Save favorite IDs list
  void saveFavorites(Set<int> ids) {
    _metaBox.put('favorite_ids', ids.toList());
  }

  // ==================== App Theme (Dark Mode) ====================

  /// Check whether dark mode is currently enabled
  bool get isDark => _metaBox.get('dark_theme', defaultValue: false) as bool;

  /// Save dark mode preference
  void saveDark(bool value) {
    _metaBox.put('dark_theme', value);
  }
}
