import 'package:flutter/foundation.dart';

import '../product_model/product_model.dart';
import 'product_api_service.dart';
import 'product_database_service.dart';

class ProductSyncException implements Exception {
  final String message;

  const ProductSyncException(this.message);

  @override
  String toString() => message;
}

class ProductRepository {
  final ProductApiService _apiService;
  final ProductDatabaseService _dbService;

  static int _nextGeneratedCode = 1;

  ProductRepository({ProductApiService? api, ProductDatabaseService? db})
    : _apiService = api ?? ProductApiService(),
      _dbService = db ?? ProductDatabaseService.instance;

  Future<List<Product>> fetchProducts({
    String? search,
    String? category,
  }) async {
    final localProducts = await _dbService.getAllProducts(
      search: search,
      category: category,
    );

    try {
      final remoteProducts = await _apiService.fetchProducts(
        search: search,
        category: category,
      );
      for (final product in remoteProducts) {
        if (product.id != null || product.serverId != null) {
          await _dbService.upsertRemoteProduct(product);
        }
      }
      return await _dbService.getAllProducts(
        search: search,
        category: category,
      );
    } catch (e) {
      debugPrint('Remote product fetch failed; showing local products: $e');
      return localProducts;
    }
  }

  Future<Product?> getLocalProductById(int id) => _dbService.getProductById(id);

  Future<Product> createProduct(Product product) async {
    final code = product.code.isNotEmpty
        ? product.code
        : 'SKU-${(_nextGeneratedCode++).toString().padLeft(4, '0')}';
    final localProduct = await _dbService.insertProduct(
      product.copyWith(code: code),
    );

    final Product remoteProduct;
    try {
      remoteProduct = await _apiService.createProduct(localProduct);
    } catch (e) {
      debugPrint('Product saved locally; Laravel save failed: $e');
      throw ProductSyncException(
        'Saved on this device, but Laravel save failed: $e',
      );
    }

    if (remoteProduct.id == null && remoteProduct.serverId == null) {
      return localProduct;
    }
    return _dbService.upsertRemoteProduct(
      remoteProduct,
      localId: localProduct.id,
    );
  }

  Future<Product> updateProduct(int id, Product product) async {
    final localProduct = await updateProductLocally(id, product);
    final serverId = localProduct.serverId;
    final Product remoteProduct;
    try {
      remoteProduct = serverId == null
          ? await _apiService.createProduct(localProduct)
          : await _apiService.updateProduct(serverId, localProduct);
    } catch (e) {
      debugPrint('Product updated locally; Laravel save failed: $e');
      throw ProductSyncException(
        'Updated on this device, but Laravel save failed: $e',
      );
    }

    if (remoteProduct.id == null && remoteProduct.serverId == null) {
      return localProduct;
    }
    return _dbService.upsertRemoteProduct(remoteProduct, localId: id);
  }

  Future<Product> updateProductLocally(int id, Product product) async {
    final existing = await _dbService.getProductById(id);
    if (existing == null) {
      throw StateError('Product $id was not found in the local database.');
    }

    final localProduct = product.copyWith(id: id, serverId: existing.serverId);
    await _dbService.updateProduct(id, localProduct);
    return localProduct;
  }

  Future<void> deleteProduct(int id) async {
    final existing = await _dbService.getProductById(id);
    if (existing == null) {
      throw StateError('Product $id was not found in the local database.');
    }

    await _dbService.deleteProduct(id);
    final serverId = existing.serverId;
    if (serverId == null) return;

    try {
      await _apiService.deleteProduct(serverId);
    } catch (e) {
      debugPrint('Product deleted locally; remote sync failed: $e');
    }
  }
}
