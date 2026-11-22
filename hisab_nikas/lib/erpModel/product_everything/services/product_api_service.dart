import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../party_everything/services/api_config.dart';
import '../product_model/product_model.dart';

class ProductApiException implements Exception {
  final String message;
  final int? statusCode;
  ProductApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ProductApiService {
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  ProductApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  // ---------- READ (list) ----------
  Future<List<Product>> fetchProducts({
    String? search,
    String? category,
  }) async {
    final res = await _client
        .get(
          _uri('/products', {
            'per_page': '1000',
            if (search != null && search.isNotEmpty) 'search': search,
            if (category != null && category.isNotEmpty && category != 'All')
              'category': category,
          }),
          headers: _headers,
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw ProductApiException(_extractError(res), res.statusCode);
    }

    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? decoded['data'] : decoded;
    final list = (raw as List? ?? const [])
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return list;
  }

  // ---------- READ (single) ----------
  Future<Product> fetchProduct(int id) async {
    final res = await _client
        .get(_uri('/products/$id'), headers: _headers)
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw ProductApiException(_extractError(res), res.statusCode);
    }
    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? decoded['data'] : decoded;
    return Product.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  // ---------- CREATE ----------
  Future<Product> createProduct(Product product) async {
    final res = await _client
        .post(
          _uri('/products/sync'),
          headers: _headers,
          body: jsonEncode(product.toJson()),
        )
        .timeout(_timeout);

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw ProductApiException(_extractError(res), res.statusCode);
    }
    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? (decoded['data'] ?? decoded) : decoded;
    return Product.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  // ---------- UPDATE ----------
  Future<Product> updateProduct(int id, Product product) async {
    final res = await _client
        .put(
          _uri('/products/$id'),
          headers: _headers,
          body: jsonEncode(product.toJson()),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw ProductApiException(_extractError(res), res.statusCode);
    }
    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? (decoded['data'] ?? decoded) : decoded;
    return Product.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  // ---------- DELETE ----------
  Future<void> deleteProduct(int id) async {
    final res = await _client
        .delete(_uri('/products/$id'), headers: _headers)
        .timeout(_timeout);

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw ProductApiException(_extractError(res), res.statusCode);
    }
  }

  // ---------- helpers ----------
  dynamic _safeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _extractError(http.Response res) {
    final decoded = _safeJson(res.body);
    if (decoded is Map) {
      final errors = decoded['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return errors.values
            .map((v) => (v is List ? v.join(', ') : v.toString()))
            .join('\n');
      }
      if (decoded['message'] != null) return decoded['message'].toString();
    }
    return 'Request failed (${res.statusCode})';
  }
}
