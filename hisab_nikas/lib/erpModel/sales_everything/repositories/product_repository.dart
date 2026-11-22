import '../../product_everything/product_model/product_model.dart';
import '../../product_everything/services/product_repository.dart' as main_product_repo;

class SalesProductRepository {
  final main_product_repo.ProductRepository _mainRepo =
      main_product_repo.ProductRepository();

  Future<List<Product>> fetchProducts({String? search}) async {
    return await _mainRepo.fetchProducts(search: search);
  }
}
