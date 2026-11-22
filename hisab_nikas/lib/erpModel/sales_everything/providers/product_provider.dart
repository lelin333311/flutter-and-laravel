import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

final salesProductRepositoryProvider = Provider<SalesProductRepository>((ref) {
  return SalesProductRepository();
});

final salesProductListProvider =
    FutureProvider.autoDispose.family<List<SalesProduct>, String?>((ref, search) async {
  final repo = ref.watch(salesProductRepositoryProvider);
  return repo.fetchProducts(search: search);
});
