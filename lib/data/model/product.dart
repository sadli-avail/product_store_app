/// Data model representing a Product in the store.
/// Converts between JSON received from the REST API / Hive and Dart objects.
class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final String brand;
  final double price;
  final double rating;
  final double discount;
  final int stock;
  final String thumbnail;
  final List<String> images;
  final bool isLocal; // True if created by the user locally
  final bool edited;  // True if edited by the user

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.brand = '',
    required this.price,
    this.rating = 0.0,
    this.discount = 0.0,
    this.stock = 0,
    this.thumbnail = '',
    this.images = const [],
    this.isLocal = false,
    this.edited = false,
  });

  /// Primary image used for display on cards and headers
  String get image {
    if (thumbnail.isNotEmpty) return thumbnail;
    if (images.isNotEmpty) return images.first;
    return '';
  }

  /// Subtitle combining brand and category (or just category if brand is empty)
  String get subtitle {
    if (brand.isNotEmpty && category.isNotEmpty) {
      return '$brand • $category';
    } else if (brand.isNotEmpty) {
      return brand;
    } else {
      return category;
    }
  }

  /// Calculate discounted price if discountPercentage > 0
  double get discountedPrice {
    if (discount <= 0) return price;
    return price * (1 - (discount / 100));
  }

  /// Factory constructor to parse JSON from the API or local storage
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      brand: (json['brand'] ?? '') as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      thumbnail: (json['thumbnail'] ?? '') as String,
      images: (json['images'] is List)
          ? List<String>.from((json['images'] as List).map((e) => e.toString()))
          : <String>[],
      isLocal: (json['isLocal'] ?? false) as bool,
      edited: (json['edited'] ?? false) as bool,
    );
  }

  /// Convert Dart Product model to JSON map for local Hive storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'brand': brand,
      'price': price,
      'rating': rating,
      'discountPercentage': discount,
      'stock': stock,
      'thumbnail': thumbnail,
      'images': images,
      'isLocal': isLocal,
      'edited': edited,
    };
  }

  /// Helper to create a modified copy of an existing product
  Product copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? brand,
    double? price,
    double? rating,
    double? discount,
    int? stock,
    String? thumbnail,
    List<String>? images,
    bool? isLocal,
    bool? edited,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      discount: discount ?? this.discount,
      stock: stock ?? this.stock,
      thumbnail: thumbnail ?? this.thumbnail,
      images: images ?? this.images,
      isLocal: isLocal ?? this.isLocal,
      edited: edited ?? this.edited,
    );
  }
}

/// Represents one page of data returned from API or local cache
class PageResult {
  final List<Product> items;
  final int total;       // Total number of items available on server
  final int rawCount;    // Items returned in this specific page
  final bool fromCache;  // True if loaded from local cache (offline)

  PageResult({
    required this.items,
    required this.total,
    required this.rawCount,
    required this.fromCache,
  });
}
