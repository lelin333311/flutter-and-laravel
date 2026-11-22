import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../product_model/product_model.dart';
import '../services/product_api_service.dart';
import '../services/product_database_service.dart';
import '../services/product_repository.dart';

// ---------------- Infrastructure Providers ----------------

final productHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final productApiServiceProvider = Provider<ProductApiService>((ref) {
  return ProductApiService(client: ref.watch(productHttpClientProvider));
});

final productDatabaseServiceProvider = Provider<ProductDatabaseService>((ref) {
  return ProductDatabaseService.instance;
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    api: ref.watch(productApiServiceProvider),
    db: ref.watch(productDatabaseServiceProvider),
  );
});

// ---------------- Filter State ----------------

class ProductFilter {
  final String search;
  final String category; // All | Food | Spice | Electronics | Raw Material

  const ProductFilter({this.search = '', this.category = 'All'});

  ProductFilter copyWith({String? search, String? category}) =>
      ProductFilter(search: search ?? this.search, category: category ?? this.category);

  @override
  bool operator ==(Object other) =>
      other is ProductFilter &&
          other.search == search &&
          other.category == category;

  @override
  int get hashCode => Object.hash(search, category);
}

class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() => const ProductFilter();

  void setFilter({String? search, String? category}) {
    state = state.copyWith(search: search, category: category);
  }
}

final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>(ProductFilterNotifier.new);

// ---------------- List Provider ----------------

final productListProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final filter = ref.watch(productFilterProvider);
  final repo = ref.watch(productRepositoryProvider);
  return repo.fetchProducts(search: filter.search, category: filter.category);
});

// ---------------- Actions ----------------

final productActionsProvider =
    Provider<ProductActions>((ref) => ProductActions(ref));

class ProductActions {
  final Ref _ref;
  ProductActions(this._ref);

  Future<Product> save({Product? existing, required Product payload}) async {
    final repo = _ref.read(productRepositoryProvider);
    final Product result;
    if (existing?.id != null) {
      result = await repo.updateProduct(existing!.id!, payload);
    } else {
      result = await repo.createProduct(payload);
    }
    _ref.invalidate(productListProvider);
    return result;
  }

  Future<void> delete(int id) async {
    final repo = _ref.read(productRepositoryProvider);
    await repo.deleteProduct(id);
    _ref.invalidate(productListProvider);
  }
}
