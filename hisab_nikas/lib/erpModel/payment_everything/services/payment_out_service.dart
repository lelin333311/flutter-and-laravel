import 'dart:io' show Platform;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../payment_model/payment_out_model.dart';
import '../../party_everything/party_model/party_model.dart';
import '../../party_everything/services/party_repository.dart';
import '../../bank_everything/bank_model/bank_transaction_model.dart';
import '../../bank_everything/services/bank_repository.dart';
import '../../../config/api_config.dart';

class PaymentOutService {
  static sqflite.Database? _database;
  final PartyRepository _partyRepo = PartyRepository();
  final BankRepository _bankRepo = BankRepository();

  final List<PaymentOut> _dummyData = [];

  int _sequence = 2;

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hisab_nikas_payment_out.db');
    return _database!;
  }

  Future<sqflite.Database> _initDB(String filePath) async {
    if (kIsWeb) {
      final factory = databaseFactoryFfiWeb;
      final dbPath = await factory.getDatabasesPath();
      final path = join(dbPath, filePath);
      return await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _createDB,
          onUpgrade: _upgradeDB,
        ),
      );
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      final factory = databaseFactoryFfi;
      final dbPath = await factory.getDatabasesPath();
      final path = join(dbPath, filePath);
      return await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _createDB,
          onUpgrade: _upgradeDB,
        ),
      );
    } else {
      final dbPath = await sqflite.getDatabasesPath();
      final path = join(dbPath, filePath);
      return await sqflite.openDatabase(
        path,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }
  }

  Future<void> _createDB(sqflite.Database db, int version) async {
    await db.execute('''
      CREATE TABLE payment_out (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        party_id INTEGER NOT NULL,
        party_name TEXT,
        invoice_no TEXT,
        amount REAL NOT NULL,
        discount REAL NOT NULL,
        net_amount REAL NOT NULL,
        payment_method_id INTEGER NOT NULL,
        reference_no TEXT,
        payment_date TEXT NOT NULL,
        description TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(
    sqflite.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.delete(
        'payment_out',
        where: 'invoice_no = ?',
        whereArgs: ['POUT-202505-0001'],
      );
    }
  }

  Future<void> _fetchFromLaravelAndCache() async {
    try {
      final apiBase = ApiConfig.baseUrl.endsWith('/v1')
          ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 3)
          : ApiConfig.baseUrl;
      final response = await http
          .get(Uri.parse('$apiBase/transactions'), headers: ApiConfig.headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      final data = decoded is Map
          ? (decoded['data'] ?? const [])
          : (decoded is List ? decoded : const []);
      if (data is! List) return;

      final parties = await _partyRepo.fetchParties(type: 'supplier');
      final db = kIsWeb ? null : await database;

      for (final item in data.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        if (map['type']?.toString() != 'out') continue;

        final amount =
            (map['amount'] is num
                    ? map['amount'] as num
                    : num.tryParse(map['amount']?.toString() ?? '0') ?? 0)
                .toDouble();
        final serverPartyId = int.tryParse(map['party_id']?.toString() ?? '');
        final partyMatches = parties.where(
          (party) => party.serverId == serverPartyId,
        );
        final localPartyId = partyMatches.isEmpty
            ? 0
            : partyMatches.first.id ?? 0;
        final resolvedPartyName =
            map['party_name']?.toString().trim().isNotEmpty == true
            ? map['party_name'].toString()
            : partyMatches.isEmpty
            ? null
            : partyMatches.first.name;
        final remoteId = int.tryParse(map['id']?.toString() ?? '');
        final invoiceNo = map['category']?.toString().trim().isNotEmpty == true
            ? map['category'].toString()
            : 'PO-${remoteId ?? DateTime.now().millisecondsSinceEpoch}';
        final payment = PaymentOut(
          id: remoteId,
          partyId: localPartyId,
          partyName: resolvedPartyName,
          invoiceNo: invoiceNo,
          amount: amount,
          discount: 0,
          netAmount: amount,
          paymentMethodId: _paymentMethodId(map['payment_method']),
          referenceNo: null,
          paymentDate:
              map['transaction_date']?.toString() ??
              DateTime.now().toIso8601String().substring(0, 10),
          description: map['description']?.toString(),
        );

        if (db != null) {
          final existing = await db.query(
            'payment_out',
            where: 'invoice_no = ?',
            whereArgs: [payment.invoiceNo],
            limit: 1,
          );
          final row = payment.toJson()..remove('id');
          if (existing.isEmpty) {
            await db.insert('payment_out', row);
          } else {
            await db.update(
              'payment_out',
              row,
              where: 'id = ?',
              whereArgs: [existing.first['id']],
            );
          }
        } else {
          _dummyData.removeWhere(
            (existing) => existing.invoiceNo == payment.invoiceNo,
          );
          _dummyData.insert(0, payment);
        }
      }
    } catch (e) {
      debugPrint('Laravel Payment Out fetch failed: $e');
    }
  }

  int _paymentMethodId(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'bank':
        return 2;
      case 'card':
        return 3;
      case 'mobile_banking':
        return 4;
      default:
        return 1;
    }
  }

  String generateInvoiceNo(DateTime date) {
    final ym = DateFormat("yyyyMM").format(date);
    final seqStr = _sequence.toString().padLeft(4, '0');
    return 'PO-$ym-$seqStr';
  }

  Future<List<PaymentOut>> getAll({String search = ''}) async {
    await _fetchFromLaravelAndCache();
    if (!kIsWeb) {
      try {
        final db = await database;
        String? whereClause;
        List<dynamic>? whereArgs;

        if (search.trim().isNotEmpty) {
          final q = '%${search.trim().toLowerCase()}%';
          whereClause = 'LOWER(party_name) LIKE ? OR LOWER(invoice_no) LIKE ? OR LOWER(description) LIKE ?';
          whereArgs = [q, q, q];
        }

        final maps = await db.query(
          'payment_out',
          where: whereClause,
          whereArgs: whereArgs,
          orderBy: 'id DESC',
        );

        if (maps.isNotEmpty) {
          final list = maps.map((e) => PaymentOut.fromJson(e)).toList();
          _dummyData.clear();
          _dummyData.addAll(list);
          _sequence = list.length + 1;
          return list;
        }
      } catch (e) {
        debugPrint('SQLite PaymentOut error: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 50));
    if (search.isEmpty) {
      return List.from(_dummyData);
    }
    return _dummyData.where((item) {
      final nameMatch =
          item.partyName?.toLowerCase().contains(search.toLowerCase()) ?? false;
      final invMatch =
          item.invoiceNo?.toLowerCase().contains(search.toLowerCase()) ?? false;
      final descMatch =
          item.description?.toLowerCase().contains(search.toLowerCase()) ??
          false;
      return nameMatch || invMatch || descMatch;
    }).toList();
  }

  Future<void> create(PaymentOut data) async {
    final invNo = (data.invoiceNo == null || data.invoiceNo!.trim().isEmpty)
        ? generateInvoiceNo(
            DateTime.tryParse(data.paymentDate) ?? DateTime.now(),
          )
        : data.invoiceNo;

    final newEntry = PaymentOut(
      id: data.id ?? DateTime.now().millisecondsSinceEpoch,
      partyId: data.partyId,
      partyName: data.partyName,
      invoiceNo: invNo,
      amount: data.amount,
      discount: data.discount,
      paymentMethodId: data.paymentMethodId,
      referenceNo: data.referenceNo,
      paymentDate: data.paymentDate,
      description: data.description,
    );

    _sequence++;

    // 1. Save to SQLite
    if (!kIsWeb) {
      try {
        final db = await database;
        final map = newEntry.toJson();
        map.remove('id');
        final insertedId = await db.insert('payment_out', map);
        final persistedEntry = PaymentOut(
          id: insertedId,
          partyId: newEntry.partyId,
          partyName: newEntry.partyName,
          invoiceNo: newEntry.invoiceNo,
          amount: newEntry.amount,
          discount: newEntry.discount,
          paymentMethodId: newEntry.paymentMethodId,
          referenceNo: newEntry.referenceNo,
          paymentDate: newEntry.paymentDate,
          description: newEntry.description,
        );
        _dummyData.removeWhere(
          (item) =>
              item.id == persistedEntry.id ||
              item.invoiceNo == persistedEntry.invoiceNo,
        );
        _dummyData.insert(0, persistedEntry);
      } catch (e) {
        debugPrint('SQLite insert payment_out error: $e');
        _dummyData.insert(0, newEntry);
      }
    } else {
      _dummyData.insert(0, newEntry);
    }

    final synced = await _syncToLaravel(newEntry);
    if (!synced) {
      if (!kIsWeb) {
        try {
          final db = await database;
          await db.delete(
            'payment_out',
            where: 'invoice_no = ?',
            whereArgs: [newEntry.invoiceNo],
          );
        } catch (_) {}
      }
      _dummyData.removeWhere((item) => item.invoiceNo == newEntry.invoiceNo);
      throw Exception(
        'Payment saved locally but Laravel sync failed. Check Laravel server.',
      );
    }

    // 2. Cross-module: Update Supplier Balance (Deduct payment from supplier due)
    if (newEntry.partyId > 0 && newEntry.netAmount > 0) {
      try {
        final parties = await _partyRepo.fetchParties();
        final pIdx = parties.indexWhere((p) => p.id == newEntry.partyId);
        if (pIdx != -1) {
          final party = parties[pIdx];
          final updatedBalance = party.openingBalance - newEntry.netAmount;
          await _partyRepo.updateParty(
            party.id!,
            party.copyWith(openingBalance: updatedBalance),
          );
        }
      } catch (e) {
        debugPrint('PaymentOut party update error: $e');
      }
    }

    // 3. Cross-module: Post Cash/Bank Outflow Transaction
    if (newEntry.netAmount > 0) {
      try {
        final accounts = await _bankRepo.fetchAccounts();
        if (accounts.isNotEmpty) {
          final targetAccount = accounts.first;
          await _bankRepo.createTransaction(
            BankTransaction(
              transactionNo: 'TRX-${newEntry.invoiceNo}',
              fromAccountId: targetAccount.id,
              fromAccountName: targetAccount.accountName,
              type: 'withdrawal',
              amount: newEntry.netAmount,
              date: DateTime.tryParse(newEntry.paymentDate) ?? DateTime.now(),
              voucherNo: newEntry.invoiceNo,
              referenceNo: newEntry.referenceNo,
              note:
                  'Payment made to ${newEntry.partyName ?? "Supplier/Vendor"}: ${newEntry.description ?? ""}'
                      .trim(),
            ),
          );
        }
      } catch (e) {
        debugPrint('PaymentOut bank transaction error: $e');
      }
    }
  }

  Future<bool> _syncToLaravel(PaymentOut payment) async {
    try {
      int? serverPartyId;
      if (payment.partyId > 0) {
        final party = await _partyRepo.getLocalPartyById(payment.partyId);
        serverPartyId = party?.serverId;
      }
      final method = switch (payment.paymentMethodId) {
        2 => 'bank',
        3 => 'card',
        4 => 'mobile_banking',
        _ => 'cash',
      };
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/payments/out/sync'),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'payments': [
                {
                  'party_id': serverPartyId,
                  'party_name': payment.partyName,
                  'amount': payment.netAmount,
                  'payment_method': method,
                  'category': payment.invoiceNo,
                  'description': payment.description,
                  'transaction_date': payment.paymentDate,
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint(
          'Laravel Payment Out sync failed: ${response.statusCode} ${response.body}',
        );
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Laravel Payment Out sync exception: $e');
      return false;
    }
  }

  Future<int?> _findRemoteTransactionId(PaymentOut payment) async {
    try {
      final apiBase = ApiConfig.baseUrl.endsWith('/v1')
          ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 3)
          : ApiConfig.baseUrl;
      final response = await http
          .get(Uri.parse('$apiBase/transactions'), headers: ApiConfig.headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      final data = decoded is Map
          ? (decoded['data'] ?? const [])
          : (decoded is List ? decoded : const []);
      if (data is! List) return null;
      for (final item in data.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        if (map['type']?.toString() == 'out' &&
            map['category']?.toString() == payment.invoiceNo) {
          return int.tryParse(map['id']?.toString() ?? '');
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _syncUpdate(int id, PaymentOut data) async {
    try {
      final db = await database;
      final rows = await db.query(
        'payment_out',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      final oldPayment = rows.isEmpty ? data : PaymentOut.fromJson(rows.first);
      final remoteId = await _findRemoteTransactionId(oldPayment);
      if (remoteId == null) return;
      final apiBase = ApiConfig.baseUrl.endsWith('/v1')
          ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 3)
          : ApiConfig.baseUrl;
      await http
          .put(
            Uri.parse('$apiBase/transactions/$remoteId'),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'party_name': data.partyName,
              'amount': data.netAmount,
              'payment_method': switch (data.paymentMethodId) {
                2 => 'bank',
                3 => 'card',
                4 => 'mobile_banking',
                _ => 'cash',
              },
              'category': data.invoiceNo,
              'description': data.description,
              'transaction_date': data.paymentDate,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Laravel Payment Out update failed: $e');
    }
  }

  Future<void> _syncDelete(int id) async {
    try {
      final db = await database;
      final rows = await db.query(
        'payment_out',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final payment = PaymentOut.fromJson(rows.first);
      final remoteId = await _findRemoteTransactionId(payment);
      if (remoteId == null) return;
      final apiBase = ApiConfig.baseUrl.endsWith('/v1')
          ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 3)
          : ApiConfig.baseUrl;
      await http
          .delete(
            Uri.parse('$apiBase/transactions/$remoteId'),
            headers: ApiConfig.headers,
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Laravel Payment Out delete failed: $e');
    }
  }

  Future<void> update(int id, PaymentOut data) async {
    await _syncUpdate(id, data);
    if (!kIsWeb) {
      try {
        final db = await database;
        await db.update(
          'payment_out',
          data.toJson(),
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (e) {
        debugPrint('SQLite update payment_out error: $e');
      }
    }
    final index = _dummyData.indexWhere((item) => item.id == id);
    if (index != -1) {
      _dummyData[index] = data;
    }
  }

  Future<void> delete(int id) async {
    await _syncDelete(id);
    if (!kIsWeb) {
      try {
        final db = await database;
        await db.delete('payment_out', where: 'id = ?', whereArgs: [id]);
      } catch (e) {
        debugPrint('SQLite delete payment_out error: $e');
      }
    }
    _dummyData.removeWhere((item) => item.id == id);
  }

  /// Fetches only real supplier parties from Laravel/local cache.
  Future<List<Party>> getParties() async {
    try {
      final suppliers = await _partyRepo.fetchParties(type: 'supplier');
      if (suppliers.isNotEmpty) {
        return suppliers;
      }
      final allParties = await _partyRepo.fetchParties();
      if (allParties.isNotEmpty) {
        return allParties
            .where((party) => party.type == 'supplier' || party.type == 'both')
            .toList();
      }
    } catch (e) {
      debugPrint('PaymentOutService getParties error: $e');
    }
    return const [];
  }
}
