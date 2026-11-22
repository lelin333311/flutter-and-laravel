import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchase.dart';
import '../repositories/purchase_repository.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository();
});

final purchaseListProvider = FutureProvider.family<List<Purchase>, Map<String, String>>((ref, filters) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.fetchPurchases(
    search: filters['search'],
    status: filters['status'],
  );
});
