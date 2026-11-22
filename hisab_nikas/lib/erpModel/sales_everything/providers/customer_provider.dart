import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';

final salesCustomerRepositoryProvider = Provider<SalesCustomerRepository>((ref) {
  return SalesCustomerRepository();
});

final salesCustomerListProvider =
    FutureProvider.autoDispose.family<List<SalesCustomer>, String?>((ref, search) async {
  final repo = ref.watch(salesCustomerRepositoryProvider);
  return repo.fetchCustomers(search: search);
});
