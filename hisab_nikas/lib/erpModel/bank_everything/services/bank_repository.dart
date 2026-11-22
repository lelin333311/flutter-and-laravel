import 'package:flutter/foundation.dart';

import '../bank_model/bank_account_model.dart';
import '../bank_model/bank_loan_model.dart';
import '../bank_model/bank_transaction_model.dart';
import '../bank_model/lc_model.dart';
import 'bank_api_service.dart';
import 'bank_database_service.dart';

class BankRepository {
  final BankApiService _apiService;
  final BankDatabaseService _dbService;

  static final List<BankAccount> _memoryAccounts = [];
  static final List<BankTransaction> _memoryTransactions = [];
  static int _nextTrxSeq = 1;

  BankRepository({BankApiService? api, BankDatabaseService? db})
    : _apiService = api ?? BankApiService(),
      _dbService = db ?? BankDatabaseService.instance;

  // ---------- ACCOUNTS ----------
  Future<List<BankAccount>> fetchAccounts() async {
    try {
      final remoteList = await _apiService.fetchAccounts();
      _memoryAccounts.clear();
      _memoryAccounts.addAll(remoteList);
      if (!kIsWeb) {
        for (final account in remoteList) {
          await _cacheAccount(account);
        }
      }
      return remoteList;
    } catch (_) {
      if (!kIsWeb) {
        try {
          final localList = await _dbService.getAllAccounts().timeout(
            const Duration(seconds: 2),
          );
          if (localList.isNotEmpty) {
            _memoryAccounts.clear();
            _memoryAccounts.addAll(localList);
            return localList;
          }
        } catch (_) {}
      }
      return List.unmodifiable(_memoryAccounts);
    }
  }

  Future<BankAccount> createAccount(BankAccount account) async {
    final remote = account.id == null
        ? await _apiService.createAccount(account)
        : await _apiService.updateAccount(account);

    _memoryAccounts.removeWhere((item) => item.id == remote.id);
    _memoryAccounts.add(remote);
    await _cacheAccount(remote);
    return remote;
  }

  Future<List<BankLoan>> fetchLoans() => _apiService.fetchLoans();

  Future<BankLoan> createLoan(BankLoan loan) => _apiService.createLoan(loan);

  Future<BankLoan> updateLoan(BankLoan loan) => _apiService.updateLoan(loan);

  Future<List<ImportLC>> fetchLcs() => _apiService.fetchLcs();

  Future<ImportLC> createLc(ImportLC lc) => _apiService.createLc(lc);

  // ---------- TRANSACTIONS & RUNNING BALANCE POSTING ----------
  Future<List<BankTransaction>> fetchTransactions({int? accountId}) async {
    try {
      final remoteList = await _apiService.fetchTransactions(
        accountId: accountId,
      );
      for (final t in remoteList) {
        _memoryTransactions.removeWhere((item) => item.id == t.id);
        _memoryTransactions.add(t);
        if (!kIsWeb) {
          try {
            await _dbService.insertTransaction(t);
          } catch (error) {
            debugPrint('Bank transaction cache update failed: $error');
          }
        }
      }
      return accountId == null
          ? remoteList
          : remoteList
                .where(
                  (t) =>
                      t.fromAccountId == accountId ||
                      t.toAccountId == accountId,
                )
                .toList();
    } catch (_) {
      if (!kIsWeb) {
        try {
          final localList = await _dbService
              .getTransactions(accountId: accountId)
              .timeout(const Duration(seconds: 2));
          if (localList.isNotEmpty) return localList;
        } catch (_) {}
      }
      return accountId == null
          ? List.unmodifiable(_memoryTransactions)
          : _memoryTransactions
                .where(
                  (t) =>
                      t.fromAccountId == accountId ||
                      t.toAccountId == accountId,
                )
                .toList();
    }
  }

  Future<BankTransaction> createTransaction(BankTransaction trx) async {
    // 1. Generate Transaction No
    final datePrefix =
        "${trx.date.year}${trx.date.month.toString().padLeft(2, '0')}";
    final trxNo = trx.transactionNo.isNotEmpty
        ? trx.transactionNo
        : 'TRX-$datePrefix-${(_nextTrxSeq++).toString().padLeft(4, '0')}';

    final pending = trx.copyWith(
      id: trx.id ?? DateTime.now().millisecondsSinceEpoch,
      transactionNo: trxNo,
    );

    final remote = await _apiService.createTransaction(pending);
    _memoryTransactions.removeWhere((item) => item.id == remote.id);
    _memoryTransactions.add(remote);
    if (!kIsWeb) {
      try {
        await _dbService.insertTransaction(remote);
      } catch (error) {
        debugPrint('Bank transaction cache update failed: $error');
      }
    }
    await _refreshAccountsFromServer();
    return remote;
  }

  Future<void> reverseTransaction(BankTransaction trx) async {
    if (trx.isReversed) return;
    final transactionId = trx.id;
    if (transactionId == null) {
      throw ArgumentError.value(
        trx.id,
        'trx.id',
        'A transaction ID is required.',
      );
    }

    await _apiService.reverseTransaction(transactionId);
    final index = _memoryTransactions.indexWhere((t) => t.id == trx.id);
    if (index != -1) {
      _memoryTransactions[index] = _memoryTransactions[index].copyWith(
        isReversed: true,
        reversedAt: DateTime.now(),
      );
    }
    if (!kIsWeb) {
      try {
        await _dbService.reverseTransaction(transactionId);
      } catch (error) {
        debugPrint('Bank transaction cache update failed: $error');
      }
    }
    await _refreshAccountsFromServer();
  }

  Future<void> _refreshAccountsFromServer() async {
    try {
      final accounts = await _apiService.fetchAccounts();
      _memoryAccounts
        ..clear()
        ..addAll(accounts);
      if (!kIsWeb) {
        for (final account in accounts) {
          await _cacheAccount(account);
        }
      }
    } catch (error) {
      debugPrint('Bank account refresh after transaction failed: $error');
    }
  }

  Future<void> _cacheAccount(BankAccount account) async {
    if (kIsWeb || account.id == null) return;
    try {
      final updated = await _dbService.updateAccount(account.id!, account);
      if (updated == 0) await _dbService.insertAccount(account);
    } catch (error) {
      debugPrint('Bank account cache update failed: $error');
    }
  }
}
