import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../model/product.dart';

/// RemoteDataSource is responsible exclusively for making REST API HTTP requests.
class RemoteDataSource {
  final http.Client _client;

  RemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches a paginated slice of products from the public DummyJSON API
  Future<({List<Product> products, int total})> fetchProducts({
    required int skip,
    required int limit,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}?limit=$limit&skip=$skip');

    final response = await _client.get(url).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Network request timed out. Please check your connection.');
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List productList = data['products'] as List? ?? [];
      final int total = (data['total'] as num?)?.toInt() ?? 0;

      final products = productList
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();

      return (products: products, total: total);
    } else {
      throw Exception('Server responded with HTTP error code ${response.statusCode}');
    }
  }

  /// Searches products directly from the API endpoint
  Future<List<Product>> searchProducts(String query) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/search?q=${Uri.encodeComponent(query)}');

    final response = await _client.get(url).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Network request timed out. Please check your connection.');
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List productList = data['products'] as List? ?? [];

      return productList
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Server responded with HTTP error code ${response.statusCode}');
    }
  }
}
