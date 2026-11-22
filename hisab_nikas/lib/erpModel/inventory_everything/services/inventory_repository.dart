import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../../product_everything/product_model/product_model.dart';
import '../../product_everything/services/product_repository.dart';
import '../models/stock_item_model.dart';
import '../models/stock_movement_model.dart';
import '../models/warehouse_model.dart';

class InventoryRepository {
  static sqflite.Database? _database;
  final ProductRepository _productRepo = ProductRepository();

  static final List<Warehouse> _memoryWarehouses = [
    const Warehouse(
      id: 1,
      name: 'Central Warehouse (মূল গুদাম)',
      code: 'WH-01',
      type: 'Main',
      managerName: 'আজিজুল হক',
      phone: '01700-112233',
      address: 'ধানমন্ডি, ঢাকা',
      capacity: 5000,
    ),
    const Warehouse(
      id: 2,
      name: 'Raw Material Store (কাঁচামাল গুদাম)',
      code: 'WH-02',
      type: 'Raw Material',
      managerName: 'কামাল হোসেন',
      phone: '01800-445566',
      address: 'তেজগাঁও, ঢাকা',
      capacity: 3000,
    ),
    const Warehouse(
      id: 3,
      name: 'Finished Goods Store (ফিনিশড গুডস গুদাম)',
      code: 'WH-03',
      type: 'Finished Goods',
      managerName: 'রফিকুল ইসলাম',
      phone: '01900-778899',
      address: 'উত্তরা, ঢাকা',
      capacity: 4000,
    ),
  ];

  static final List<StockMovement> _memoryMovements = [
    StockMovement(
      id: 1,
      movementNo: 'MOV-202611-0001',
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: 'STOCK_IN',
      productId: 1,
      productName: 'আস্ত শুকনো হলুদ (Raw Turmeric)',
      fromWarehouse: 'Supplier',
      toWarehouse: 'Raw Material Store',
      quantityIn: 1000,
      quantityOut: 0,
      unitCost: 150,
      referenceType: 'Purchase',
      notes: 'Local Purchase Received GRN #9910',
    ),
  ];

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hisab_nikas_inventory.db');
    return _database!;
  }

  Future<sqflite.Database> _initDB(String filePath) async {
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
      return await sqflite.openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    }
  }

  Future<void> _createDB(sqflite.Database db, int version) async {
    await db.execute('''
      CREATE TABLE warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        type TEXT,
        manager_name TEXT,
        phone TEXT,
        address TEXT,
        capacity REAL,
        is_active INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movement_no TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        product_id INTEGER,
        product_name TEXT,
        from_warehouse TEXT,
        to_warehouse TEXT,
        quantity_in REAL,
        quantity_out REAL,
        unit_cost REAL,
        reference_type TEXT,
        notes TEXT
      )
    ''');

    // Seed default warehouses
    for (final wh in _memoryWarehouses) {
      final map = wh.toJson();
      map.remove('id');
      map['is_active'] = wh.isActive ? 1 : 0;
      await db.insert('warehouses', map);
    }

    // Seed default movements
    for (final mov in _memoryMovements) {
      final map = mov.toJson();
      map.remove('id');
      await db.insert('stock_movements', map);
    }
  }

  Future<List<Warehouse>> fetchWarehouses() async {
    if (!kIsWeb) {
      try {
        final db = await database;
        final maps = await db.query('warehouses', orderBy: 'id ASC');
        if (maps.isNotEmpty) {
          final list = maps.map((e) {
            final json = Map<String, dynamic>.from(e);
            json['is_active'] = (e['is_active'] == 1);
            return Warehouse.fromJson(json);
          }).toList();
          _memoryWarehouses.clear();
          _memoryWarehouses.addAll(list);
          return list;
        }
      } catch (e) {
        debugPrint('SQLite fetch warehouses error: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 50));
    return List.unmodifiable(_memoryWarehouses);
  }

  Future<Warehouse> createWarehouse(Warehouse warehouse) async {
    Warehouse newWh = warehouse.copyWith(
      id: warehouse.id ?? DateTime.now().millisecondsSinceEpoch,
    );

    if (!kIsWeb) {
      try {
        final db = await database;
        final map = newWh.toJson();
        map.remove('id');
        map['is_active'] = newWh.isActive ? 1 : 0;
        final insertedId = await db.insert('warehouses', map);
        newWh = newWh.copyWith(id: insertedId);
      } catch (e) {
        debugPrint('SQLite insert warehouse error: $e');
      }
    }

    _memoryWarehouses.add(newWh);
    return newWh;
  }

  /// Calculates Live Stock Balances across Inventory Products
  Future<List<StockItem>> fetchStockItems({String? search, String? filterStatus}) async {
    final products = await _productRepo.fetchProducts();

    final List<StockItem> stockList = products.map((p) {
      return StockItem(
        productId: p.id ?? 0,
        productName: p.name,
        productCode: p.code,
        category: p.category,
        warehouseName: 'Central Warehouse',
        unit: p.unit.isEmpty ? 'Kg' : p.unit,
        physicalStock: p.currentStock,
        reservedStock: 0,
        unitCost: p.purchasePrice,
        reorderLevel: p.minStockWarning > 0 ? p.minStockWarning : 50,
      );
    }).toList();

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      stockList.removeWhere((item) =>
          !item.productName.toLowerCase().contains(q) &&
          !item.productCode.toLowerCase().contains(q));
    }

    if (filterStatus != null && filterStatus != 'all') {
      stockList.removeWhere((item) => item.stockStatus != filterStatus);
    }

    return stockList;
  }

  Future<List<StockMovement>> fetchStockMovements({String? search}) async {
    if (!kIsWeb) {
      try {
        final db = await database;
        String? whereClause;
        List<dynamic>? whereArgs;

        if (search != null && search.trim().isNotEmpty) {
          final q = '%${search.trim().toLowerCase()}%';
          whereClause =
              'LOWER(movement_no) LIKE ? OR LOWER(product_name) LIKE ? OR LOWER(reference_type) LIKE ?';
          whereArgs = [q, q, q];
        }

        final maps = await db.query(
          'stock_movements',
          where: whereClause,
          whereArgs: whereArgs,
          orderBy: 'id DESC',
        );

        if (maps.isNotEmpty) {
          final list = maps.map((e) => StockMovement.fromJson(e)).toList();
          _memoryMovements.clear();
          _memoryMovements.addAll(list);
          return list;
        }
      } catch (e) {
        debugPrint('SQLite fetch stock_movements error: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 50));
    if (search == null || search.trim().isEmpty) {
      return List.unmodifiable(_memoryMovements);
    }
    final q = search.trim().toLowerCase();
    return _memoryMovements.where((m) {
      return m.movementNo.toLowerCase().contains(q) ||
          m.productName.toLowerCase().contains(q) ||
          m.referenceType.toLowerCase().contains(q);
    }).toList();
  }

  /// Performs Stock Transfer between Warehouses
  Future<void> transferStock({
    required Product product,
    required String fromWarehouse,
    required String toWarehouse,
    required double quantity,
    required String notes,
  }) async {
    final newMov = StockMovement(
      movementNo: 'TRF-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      type: 'TRANSFER',
      productId: product.id ?? 0,
      productName: product.name,
      fromWarehouse: fromWarehouse,
      toWarehouse: toWarehouse,
      quantityIn: quantity,
      quantityOut: quantity,
      unitCost: product.purchasePrice,
      referenceType: 'Transfer',
      notes: notes,
    );

    if (!kIsWeb) {
      try {
        final db = await database;
        final map = newMov.toJson();
        map.remove('id');
        await db.insert('stock_movements', map);
      } catch (e) {
        debugPrint('SQLite insert transfer movement error: $e');
      }
    }

    _memoryMovements.insert(0, newMov);
  }

  /// Performs Stock Adjustment (Increase or Decrease) with Audit Notes
  Future<void> adjustStock({
    required Product product,
    required String warehouseName,
    required double adjustmentQty, // Positive for Increase, Negative for Decrease
    required String reason,
  }) async {
    final isIncrease = adjustmentQty >= 0;
    final absQty = adjustmentQty.abs();

    final newMov = StockMovement(
      movementNo: 'ADJ-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      type: 'ADJUSTMENT',
      productId: product.id ?? 0,
      productName: product.name,
      fromWarehouse: isIncrease ? 'Adjustment' : warehouseName,
      toWarehouse: isIncrease ? warehouseName : 'Adjustment Disposal',
      quantityIn: isIncrease ? absQty : 0,
      quantityOut: isIncrease ? 0 : absQty,
      unitCost: product.purchasePrice,
      referenceType: 'Adjustment',
      notes: reason,
    );

    if (!kIsWeb) {
      try {
        final db = await database;
        final map = newMov.toJson();
        map.remove('id');
        await db.insert('stock_movements', map);
      } catch (e) {
        debugPrint('SQLite insert adjustment movement error: $e');
      }
    }

    _memoryMovements.insert(0, newMov);

    // Update Product Stock in Database
    final newStock = (product.currentStock + adjustmentQty).clamp(0, double.infinity).toDouble();
    await _productRepo.updateProduct(product.id!, product.copyWith(currentStock: newStock));
  }
}
