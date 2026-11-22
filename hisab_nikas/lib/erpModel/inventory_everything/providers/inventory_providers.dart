import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_item_model.dart';
import '../models/stock_movement_model.dart';
import '../models/warehouse_model.dart';
import '../services/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository();
});

final stockItemListProvider = FutureProvider.family<List<StockItem>, Map<String, String>>((ref, filters) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.fetchStockItems(
    search: filters['search'],
    filterStatus: filters['filterStatus'],
  );
});

final warehouseListProvider = FutureProvider<List<Warehouse>>((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.fetchWarehouses();
});

final stockMovementListProvider = FutureProvider.family<List<StockMovement>, String>((ref, search) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  return repo.fetchStockMovements(search: search);
});
