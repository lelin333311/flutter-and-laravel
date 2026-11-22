import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/sale.dart';
import '../models/sale_item.dart';

class SalesDbHelper {
  static final SalesDbHelper instance = SalesDbHelper._init();
  static Database? _database;

  SalesDbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hisab_nikas_sales_v2.db');
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
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        customer_id INTEGER NOT NULL,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        customer_address TEXT,
        subtotal REAL NOT NULL,
        discount_amount REAL NOT NULL,
        tax_amount REAL NOT NULL,
        commission_cost REAL NOT NULL,
        labor_cost REAL NOT NULL,
        additional_costs_json TEXT,
        grand_total REAL NOT NULL,
        paid_amount REAL NOT NULL,
        due_amount REAL NOT NULL,
        payment_status TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        note TEXT,
        paper_size_preference TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        product_code TEXT,
        unit TEXT NOT NULL,
        quantity_pcs_bosta REAL NOT NULL,
        weight_kg_per_unit REAL NOT NULL,
        total_kg REAL NOT NULL,
        price_per_unit REAL NOT NULL,
        price_type TEXT NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');
  }

  // ---------- SALES CRUD & ATOMIC CHECKOUT TRANSACTION ----------
  Future<List<Sale>> getAllSales({String? search, String? status}) async {
    final db = await instance.database;
    String? where;
    List<dynamic>? whereArgs;

    List<String> conditions = [];
    if (search != null && search.trim().isNotEmpty) {
      conditions.add(
        '(invoice_no LIKE ? OR customer_name LIKE ? OR customer_phone LIKE ?)',
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

    final salesMaps = await db.query(
      'sales',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );
    List<Sale> sales = [];

    for (final map in salesMaps) {
      final saleId = map['id'] as int;
      final itemMaps = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      final items = itemMaps.map((e) => SaleItem.fromJson(e)).toList();

      final saleJson = Map<String, dynamic>.from(map);
      saleJson['items'] = items.map((e) => e.toJson()).toList();

      if (saleJson['additional_costs_json'] != null &&
          saleJson['additional_costs_json'].toString().isNotEmpty) {
        try {
          final decoded =
              jsonDecode(saleJson['additional_costs_json'].toString()) as List;
          saleJson['additional_costs'] = decoded;
        } catch (_) {}
      }

      sales.add(Sale.fromJson(saleJson));
    }

    return sales;
  }

  Map<String, dynamic> _saleToDatabaseMap(Sale sale) => {
    'invoice_no': sale.invoiceNo,
    'date': sale.date.toIso8601String(),
    'customer_id': sale.customerId,
    'customer_name': sale.customerName,
    'customer_phone': sale.customerPhone,
    'customer_address': sale.customerAddress,
    'subtotal': sale.subtotal,
    'discount_amount': sale.discountAmount,
    'tax_amount': sale.taxAmount,
    'commission_cost': sale.commissionCost,
    'labor_cost': sale.laborCost,
    'additional_costs_json': jsonEncode(
      sale.additionalCosts.map((cost) => cost.toJson()).toList(),
    ),
    'grand_total': sale.grandTotal,
    'paid_amount': sale.paidAmount,
    'due_amount': sale.dueAmount,
    'payment_status': sale.paymentStatus,
    'payment_method': sale.paymentMethod,
    'note': sale.note,
    'paper_size_preference': sale.paperSizePreference,
  };

  Map<String, dynamic> _saleItemToDatabaseMap(SaleItem item, int saleId) => {
    'sale_id': saleId,
    'product_id': item.productId,
    'product_name': item.productName,
    'product_code': item.productCode,
    'unit': item.unit,
    'quantity_pcs_bosta': item.quantityPcsBosta,
    'weight_kg_per_unit': item.weightKgPerUnit,
    'total_kg': item.totalKg,
    'price_per_unit': item.pricePerUnit,
    'price_type': item.priceType,
    'subtotal': item.subtotal,
  };

  /// Atomic Checkout Transaction: Inserts Sale + Inserts Sale Items atomically
  Future<Sale> createSaleTransaction(Sale sale) async {
    final db = await instance.database;

    return await db.transaction<Sale>((txn) async {
      final saleId = await txn.insert('sales', _saleToDatabaseMap(sale));

      List<SaleItem> insertedItems = [];
      for (final item in sale.items) {
        final itemId = await txn.insert(
          'sale_items',
          _saleItemToDatabaseMap(item, saleId),
        );
        insertedItems.add(item.copyWith(id: itemId, saleId: saleId));
      }

      return sale.copyWith(id: saleId, items: insertedItems);
    });
  }

  Future<Sale> updateSaleTransaction(Sale sale) async {
    final saleId = sale.id;
    if (saleId == null) {
      throw ArgumentError.value(sale.id, 'sale.id', 'A sale ID is required.');
    }

    final db = await instance.database;
    return db.transaction<Sale>((txn) async {
      final updatedCount = await txn.update(
        'sales',
        _saleToDatabaseMap(sale),
        where: 'id = ?',
        whereArgs: [saleId],
      );
      if (updatedCount == 0) {
        throw StateError('Sale $saleId was not found in the local database.');
      }

      await txn.delete('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
      final updatedItems = <SaleItem>[];
      for (final item in sale.items) {
        final itemId = await txn.insert(
          'sale_items',
          _saleItemToDatabaseMap(item, saleId),
        );
        updatedItems.add(item.copyWith(id: itemId, saleId: saleId));
      }

      return sale.copyWith(items: updatedItems);
    });
  }

  Future<Sale> upsertRemoteSale(Sale sale) async {
    final db = await instance.database;
    return db.transaction<Sale>((txn) async {
      final existing = await txn.query(
        'sales',
        where: 'invoice_no = ?',
        whereArgs: [sale.invoiceNo],
        limit: 1,
      );
      final existingId = existing.isEmpty ? null : existing.first['id'] as int;

      final int saleId;
      if (existingId == null) {
        saleId = await txn.insert('sales', _saleToDatabaseMap(sale));
      } else {
        saleId = existingId;
        await txn.update(
          'sales',
          _saleToDatabaseMap(sale),
          where: 'id = ?',
          whereArgs: [existingId],
        );
        await txn.delete(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [existingId],
        );
      }

      final insertedItems = <SaleItem>[];
      for (final item in sale.items) {
        final itemId = await txn.insert(
          'sale_items',
          _saleItemToDatabaseMap(item, saleId),
        );
        insertedItems.add(item.copyWith(id: itemId, saleId: saleId));
      }
      return sale.copyWith(id: saleId, items: insertedItems);
    });
  }

  Future<int> getSalesCount() async {
    final db = await instance.database;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM sales');
    if (res.isNotEmpty && res.first['count'] != null) {
      return (res.first['count'] as int);
    }
    return 0;
  }

  Future<int> deleteSale(int saleId) async {
    final db = await instance.database;
    await db.delete('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
    return await db.delete('sales', where: 'id = ?', whereArgs: [saleId]);
  }
}
