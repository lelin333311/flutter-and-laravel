import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manufacturing_batch_model.dart';
import '../services/manufacturing_repository.dart';

final manufacturingRepositoryProvider = Provider<ManufacturingRepository>((ref) {
  return ManufacturingRepository();
});

final manufacturingBatchListProvider = FutureProvider.family<List<ManufacturingBatch>, String>((ref, search) async {
  final repo = ref.watch(manufacturingRepositoryProvider);
  return repo.fetchBatches(search: search);
});
