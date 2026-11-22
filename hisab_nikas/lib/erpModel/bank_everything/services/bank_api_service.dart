import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../party_everything/services/api_config.dart';
import '../bank_model/bank_account_model.dart';
import '../bank_model/bank_loan_model.dart';
import '../bank_model/bank_transaction_model.dart';
import '../bank_model/lc_model.dart';

class BankApiException implements Exception {
  final String message;
  final int? statusCode;
  BankApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class BankApiService {
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  BankApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  // ---------- ACCOUNTS ----------
  Future<List<BankAccount>> fetchAccounts() async {
    final res = await _client
        .get(_uri('/bank-accounts'), headers: _headers)
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw BankApiException(_extractError(res), res.statusCode);
    }
    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? decoded['data'] : decoded;
    return (raw as List? ?? const [])
        .map((e) => BankAccount.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<BankAccount> createAccount(BankAccount account) async {
    final res = await _client
        .post(
          _uri('/bank-accounts'),
          headers: _headers,
          body: jsonEncode(account.toJson()),
        )
        .timeout(_timeout);

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw BankApiException(_extractError(res), res.statusCode);
    }
    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? (decoded['data'] ?? decoded) : decoded;
    return BankAccount.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<BankAccount> updateAccount(BankAccount account) async {
    final id = account.id;
    if (id == null) {
      throw ArgumentError.value(
        account.id,
        'account.id',
        'An account ID is required.',
      );
    }

    final res = await _client
        .put(
          _uri('/bank-accounts/$id'),
          headers: _headers,
          body: jsonEncode(account.toJson()),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw BankApiException(_extractError(res), res.statusCode);
    }
    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? (decoded['data'] ?? decoded) : decoded;
    return BankAccount.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<List<BankLoan>> fetchLoans() async {
    final res = await _client
        .get(_uri('/bank-loans'), headers: _headers)
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw BankApiException(_extractError(res), res.statusCode);
    }
    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? decoded['data'] : decoded;
    return (raw as List? ?? const [])
        .map(
          (item) => BankLoan.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<BankLoan> createLoan(BankLoan loan) async {
    final res = await _client
        .post(
          _uri('/bank-loans'),
          headers: _headers,
          body: jsonEncode(loan.toJson()),
        )
        .timeout(_timeout);
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw BankApiException(_extractError(res), res.statusCode);
    }
    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? (decoded['data'] ?? decoded) : decoded;
    return BankLoan.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<BankLoan> updateLoan(BankLoan loan) async {
    final id = loan.id;
    if (id == null) {
      throw ArgumentError.value(loan.id, 'loan.id', 'A loan ID is required.');
    }
    final res = await _client
        .patch(
          _uri('/bank-loans/$id'),
          headers: _headers,
          body: jsonEncode({
            'principal_paid': loan.principalPaid,
            'interest_paid': loan.interestPaid,
            'charges_paid': loan.chargesPaid,
            'outstanding_amount': loan.outstandingAmount,
            'status': loan.status,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw BankApiException(_extractError(res), res.statusCode);
    }
    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? (decoded['data'] ?? decoded) : decoded;
    return BankLoan.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<List<ImportLC>> fetchLcs() async {
    final res = await _client
        .get(_uri('/bank-lcs'), headers: _headers)
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw BankApiException(_extractError(res), res.statusCode);
    }
    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? decoded['data'] : decoded;
    return (raw as List? ?? const [])
        .map(
          (item) => ImportLC.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<ImportLC> createLc(ImportLC lc) async {
    final res = await _client
        .post(
          _uri('/bank-lcs'),
          headers: _headers,
          body: jsonEncode(lc.toJson()),
        )
        .timeout(_timeout);
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw BankApiException(_extractError(res), res.statusCode);
    }
    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? (decoded['data'] ?? decoded) : decoded;
    return ImportLC.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  // ---------- TRANSACTIONS ----------
  Future<List<BankTransaction>> fetchTransactions({int? accountId}) async {
    final res = await _client
        .get(
          _uri('/bank-transactions', {
            if (accountId != null) 'account_id': accountId.toString(),
          }),
          headers: _headers,
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw BankApiException(_extractError(res), res.statusCode);
    }
    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? decoded['data'] : decoded;
    return (raw as List? ?? const [])
        .map(
          (e) => BankTransaction.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<BankTransaction> createTransaction(BankTransaction transaction) async {
    final res = await _client
        .post(
          _uri('/bank-transactions'),
          headers: _headers,
          body: jsonEncode(transaction.toJson()),
        )
        .timeout(_timeout);

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw BankApiException(_extractError(res), res.statusCode);
    }
    final decoded = _safeJson(res.body);
    final raw = decoded is Map ? (decoded['data'] ?? decoded) : decoded;
    return BankTransaction.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> reverseTransaction(int id) async {
    final res = await _client
        .post(_uri('/bank-transactions/$id/reverse'), headers: _headers)
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw BankApiException(_extractError(res), res.statusCode);
    }
  }

  // helpers
  dynamic _safeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _extractError(http.Response res) {
    final decoded = _safeJson(res.body);
    if (decoded is Map) {
      final errors = decoded['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return errors.values
            .map((v) => (v is List ? v.join(', ') : v.toString()))
            .join('\n');
      }
      if (decoded['message'] != null) return decoded['message'].toString();
    }
    return 'Request failed (${res.statusCode})';
  }
}
