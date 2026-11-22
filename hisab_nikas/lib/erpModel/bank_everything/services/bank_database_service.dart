import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../bank_model/bank_account_model.dart';
import '../bank_model/bank_transaction_model.dart';

class BankDatabaseService {
  static final BankDatabaseService instance = BankDatabaseService._init();
  static Database? _database;

  BankDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hisab_nikas_bank.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      final factory = databaseFactoryFfiWeb;
      final dbPath = await factory.getDatabasesPath();
      final path = join(dbPath, filePath);
      return await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(version: 1, onCreate: _createDB),
      );
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      final factory = databaseFactoryFfi;
      final dbPath = await factory.getDatabasesPath();
      final path = join(dbPath, filePath);
      return await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(version: 1, onCreate: _createDB),
      );
    } else {
      // Mobile (Android / iOS)
      final dbPath = await sqflite.getDatabasesPath();
      final path = join(dbPath, filePath);
      return await sqflite.openDatabase(path, version: 1, onCreate: _createDB);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bank_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_name TEXT NOT NULL,
        account_number TEXT NOT NULL,
        bank_name TEXT NOT NULL,
        branch_name TEXT,
        account_type TEXT,
        opening_balance REAL,
        running_balance REAL,
        is_active INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE bank_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_no TEXT NOT NULL,
        from_account_id INTEGER,
        from_account_name TEXT,
        to_account_id INTEGER,
        to_account_name TEXT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        voucher_no TEXT,
        reference_no TEXT,
        debit_account TEXT,
        credit_account TEXT,
        note TEXT,
        is_reversed INTEGER,
        reversed_at TEXT,
        running_balance_after REAL,
        created_at TEXT
      )
    ''');
  }

  // ---------- BANK ACCOUNTS CRUD ----------
  Future<List<BankAccount>> getAllAccounts() async {
    final db = await instance.database;
    final result = await db.query('bank_accounts', orderBy: 'id DESC');
    return result.map((json) => BankAccount.fromJson(json)).toList();
  }

  Future<BankAccount> insertAccount(BankAccount account) async {
    final db = await instance.database;
    final json = account.toJson();
    if (account.id != null) json['id'] = account.id;
    final id = await db.insert(
      'bank_accounts',
      json,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return account.copyWith(id: id);
  }

  Future<int> updateAccount(int id, BankAccount account) async {
    final db = await instance.database;
    return await db.update(
      'bank_accounts',
      account.toJson(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateRunningBalance(int accountId, double newBalance) async {
    final db = await instance.database;
    return await db.update(
      'bank_accounts',
      {'running_balance': newBalance},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  // ---------- BANK TRANSACTIONS CRUD ----------
  Future<List<BankTransaction>> getTransactions({int? accountId}) async {
    final db = await instance.database;
    String? where;
    List<dynamic>? whereArgs;

    if (accountId != null) {
      where = 'from_account_id = ? OR to_account_id = ?';
      whereArgs = [accountId, accountId];
    }

    final result = await db.query(
      'bank_transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );
    return result.map((json) => BankTransaction.fromJson(json)).toList();
  }

  Future<BankTransaction> insertTransaction(BankTransaction transaction) async {
    final db = await instance.database;
    final json = transaction.toJson();
    if (transaction.id != null) json['id'] = transaction.id;
    final id = await db.insert(
      'bank_transactions',
      json,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return transaction.copyWith(id: id);
  }

  Future<int> reverseTransaction(int transactionId) async {
    final db = await instance.database;
    return await db.update(
      'bank_transactions',
      {'is_reversed': 1, 'reversed_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }
}
