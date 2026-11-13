// Application-wide constants
class AppConstants {
  // Public REST API endpoint (DummyJSON)
  static const String apiBaseUrl = 'https://dummyjson.com/products';

  // Hive storage box names
  static const String productBoxName = 'products_box';
  static const String metaBoxName = 'meta_box';

  // Pagination default size
  static const int pageSize = 20;

  // Search debounce duration in milliseconds
  static const int debounceDurationMs = 400;
}
