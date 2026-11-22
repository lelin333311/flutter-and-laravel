import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/purchase.dart';
import '../models/purchase_item.dart';

class PurchaseDbHelper {
  static final PurchaseDbHelper instance = PurchaseDbHelper._init();
  static Database? _database;

  PurchaseDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hisab_nikas_purchases_v1.db');
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
      final dbPath = await sqflite.getDatabasesPath();
      final path = join(dbPath, filePath);
      return await sqflite.openDatabase(path, version: 1, onCreate: _createDB);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_invoice_no TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        supplier_id INTEGER NOT NULL,
        supplier_name TEXT NOT NULL,
        supplier_phone TEXT,
        supplier_address TEXT,
        subtotal REAL NOT NULL,
        discount_amount REAL NOT NULL,
        shipping_cost REAL NOT NULL,
        labor_cost REAL NOT NULL,
        additional_costs_json TEXT,
        grand_total REAL NOT NULL,
        paid_amount REAL NOT NULL,
        due_amount REAL NOT NULL,
        payment_status TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        product_code TEXT,
        unit TEXT NOT NULL,
        quantity_pcs_bosta REAL NOT NULL,
        weight_kg_per_unit REAL NOT NULL,
        total_kg REAL NOT NULL,
        purchase_price_per_unit REAL NOT NULL,
        price_type TEXT NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES purchases (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<List<Purchase>> getAllPurchases({
    String? search,
    String? status,
  }) async {
    final db = await instance.database;
    String? where;
    List<dynamic>? whereArgs;

    List<String> conditions = [];
    if (search != null && search.trim().isNotEmpty) {
      conditions.add(
        '(purchase_invoice_no LIKE ? OR supplier_name LIKE ? OR supplier_phone LIKE ?)',
      );
      final q = '%${search.trim()}%';
      whereArgs ??= [];
      whereArgs.addAll([q, q, q]);
    }

    if (status != null && status.isNotEmpty && status != 'all') {
      conditions.add('payment_status = ?');
      whereArgs ??= [];
      whereArgs.add(status);
    }

    if (conditions.isNotEmpty) {
      where = conditions.join(' AND ');
    }

    final maps = await db.query(
      'purchases',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );
    List<Purchase> purchases = [];

    for (final map in maps) {
      final pId = map['id'] as int;
      final itemMaps = await db.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [pId],
      );
      final items = itemMaps.map((e) => PurchaseItem.fromJson(e)).toList();

      final pJson = Map<String, dynamic>.from(map);
      pJson['items'] = items.map((e) => e.toJson()).toList();

      if (pJson['additional_costs_json'] != null &&
          pJson['additional_costs_json'].toString().isNotEmpty) {
        try {
          final decoded =
              jsonDecode(pJson['additional_costs_json'].toString()) as List;
          pJson['additional_costs'] = decoded;
        } catch (_) {}
      }

      purchases.add(Purchase.fromJson(pJson));
    }

    return purchases;
  }

  /// Atomic Purchase Creation: Saves Purchase + Purchase Items + INCREASES Product Stock
  Future<Purchase> createPurchaseTransaction(Purchase purchase) async {
    final db = await instance.database;

    return await db.transaction<Purchase>((txn) async {
      final pMap = purchase.toJson();
      pMap.remove('items');
      pMap.remove('id');
      pMap['additional_costs_json'] = jsonEncode(
        purchase.additionalCosts.map((e) => e.toJson()).toList(),
      );
      pMap.remove('additional_costs');

      final purchaseId = await txn.insert('purchases', pMap);

      List<PurchaseItem> insertedItems = [];
      for (final item in purchase.items) {
        final itemMap = item.toJson();
        itemMap['purchase_id'] = purchaseId;
        itemMap.remove('id');

        final itemId = await txn.insert('purchase_items', itemMap);
        insertedItems.add(item.copyWith(id: itemId, purchaseId: purchaseId));
      }

      return purchase.copyWith(id: purchaseId, items: insertedItems);
    });
  }

  Future<int> getPurchasesCount() async {
    final db = await instance.database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM purchases');
    if (res.isNotEmpty && res.first['count'] != null) {
      return (res.first['count'] as int);
    }
    return 0;
  }

  Future<Purchase> updatePurchaseTransaction(Purchase purchase) async {
    final db = await instance.database;
    final purchaseId = purchase.id;
    if (purchaseId == null) {
      throw ArgumentError.value(
        purchase.id,
        'purchase.id',
        'A purchase ID is required.',
      );
    }

    return await db.transaction<Purchase>((txn) async {
      final pMap = purchase.toJson();
      pMap.remove('items');
      pMap.remove('id');
      pMap['additional_costs_json'] = jsonEncode(
        purchase.additionalCosts.map((e) => e.toJson()).toList(),
      );
      pMap.remove('additional_costs');

      await txn.update(
        'purchases',
        pMap,
        where: 'id = ?',
        whereArgs: [purchaseId],
      );
      await txn.delete(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );

      final insertedItems = <PurchaseItem>[];
      for (final item in purchase.items) {
        final itemMap = item.toJson();
        itemMap['purchase_id'] = purchaseId;
        itemMap.remove('id');
        final itemId = await txn.insert('purchase_items', itemMap);
        insertedItems.add(item.copyWith(id: itemId, purchaseId: purchaseId));
      }
      return purchase.copyWith(items: insertedItems);
    });
  }

  Future<int> deletePurchase(int purchaseId) async {
    final db = await instance.database;
    await db.delete(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
    return await db.delete(
      'purchases',
      where: 'id = ?',
      whereArgs: [purchaseId],
    );
  }
}
