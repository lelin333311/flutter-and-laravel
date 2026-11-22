import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../bank_model/bank_account_model.dart';
import '../bank_model/bank_transaction_model.dart';
import '../services/bank_api_service.dart';
import '../services/bank_database_service.dart';
import '../services/bank_repository.dart';

// ---------------- Infrastructure Providers ----------------

final bankHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final bankApiServiceProvider = Provider<BankApiService>((ref) {
  return BankApiService(client: ref.watch(bankHttpClientProvider));
});

final bankDatabaseServiceProvider = Provider<BankDatabaseService>((ref) {
  return BankDatabaseService.instance;
});

final bankRepositoryProvider = Provider<BankRepository>((ref) {
  return BankRepository(
    api: ref.watch(bankApiServiceProvider),
    db: ref.watch(bankDatabaseServiceProvider),
  );
});

// ---------------- Accounts Provider ----------------

final bankAccountsProvider =
    FutureProvider.autoDispose<List<BankAccount>>((ref) async {
  final repo = ref.watch(bankRepositoryProvider);
  return repo.fetchAccounts();
});

// ---------------- Transactions Provider ----------------

final bankTransactionsProvider =
    FutureProvider.autoDispose.family<List<BankTransaction>, int?>((ref, accountId) async {
  final repo = ref.watch(bankRepositoryProvider);
  return repo.fetchTransactions(accountId: accountId);
});

// ---------------- Actions ----------------

final bankActionsProvider = Provider<BankActions>((ref) => BankActions(ref));

class BankActions {
  final Ref _ref;
  BankActions(this._ref);

  Future<BankAccount> saveAccount(BankAccount account) async {
    final repo = _ref.read(bankRepositoryProvider);
    final result = await repo.createAccount(account);
    _ref.invalidate(bankAccountsProvider);
    return result;
  }

  Future<BankTransaction> createTransaction(BankTransaction trx) async {
    final repo = _ref.read(bankRepositoryProvider);
    final result = await repo.createTransaction(trx);
    _ref.invalidate(bankAccountsProvider);
    _ref.invalidate(bankTransactionsProvider);
    return result;
  }

  Future<void> reverseTransaction(BankTransaction trx) async {
    final repo = _ref.read(bankRepositoryProvider);
    await repo.reverseTransaction(trx);
    _ref.invalidate(bankAccountsProvider);
    _ref.invalidate(bankTransactionsProvider);
  }
}
