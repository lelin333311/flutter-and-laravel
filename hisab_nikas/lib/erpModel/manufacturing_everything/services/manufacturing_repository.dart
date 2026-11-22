import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../../product_everything/services/product_repository.dart';
import '../models/manufacturing_batch_model.dart';

class ManufacturingRepository {
  static sqflite.Database? _database;
  final ProductRepository _productRepo = ProductRepository();

  static final List<ManufacturingBatch> _memoryBatches = [
    ManufacturingBatch(
      id: 1,
      batchNo: 'BATCH-202611-0001',
      date: DateTime.now().subtract(const Duration(days: 1)),
      processType: 'পরিষ্কার + শুকানো + গুঁড়া করা',
      rawMaterialId: 1,
      rawMaterialName: 'আস্ত শুকনো হলুদ (Raw Turmeric)',
      rawMaterialKg: 500,
      wastageKg: 25, // ৫% অপচয়/ঘাটতি
      outputProductId: 2,
      outputProductName: 'হলুদ গুঁড়া (Turmeric Powder)',
      outputFinishedKg: 475,
      packetSize: '500g',
      totalPackets: 950,
      millingCost: 1500,
      electricityCost: 800,
      laborCost: 1200,
      totalBatchCost: 3500,
      unitCostPerKg: 185.50,
      status: 'COMPLETED',
    ),
  ];

  static int _nextBatchSeq = 2;

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hisab_nikas_manufacturing.db');
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
      CREATE TABLE manufacturing_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_no TEXT NOT NULL,
        date TEXT NOT NULL,
        process_type TEXT,
        raw_material_id INTEGER,
        raw_material_name TEXT,
        raw_material_kg REAL,
        wastage_kg REAL,
        output_product_id INTEGER,
        output_product_name TEXT,
        output_finished_kg REAL,
        packet_size TEXT,
        total_packets INTEGER,
        milling_cost REAL,
        electricity_cost REAL,
        labor_cost REAL,
        total_batch_cost REAL,
        unit_cost_per_kg REAL,
        status TEXT
      )
    ''');

    for (final batch in _memoryBatches) {
      final map = batch.toJson();
      map.remove('id');
      await db.insert('manufacturing_batches', map);
    }
  }

  Future<List<ManufacturingBatch>> fetchBatches({String? search}) async {
    if (!kIsWeb) {
      try {
        final db = await database;
        String? whereClause;
        List<dynamic>? whereArgs;

        if (search != null && search.trim().isNotEmpty) {
          final q = '%${search.trim().toLowerCase()}%';
          whereClause =
              'LOWER(batch_no) LIKE ? OR LOWER(raw_material_name) LIKE ? OR LOWER(output_product_name) LIKE ?';
          whereArgs = [q, q, q];
        }

        final maps = await db.query(
          'manufacturing_batches',
          where: whereClause,
          whereArgs: whereArgs,
          orderBy: 'id DESC',
        );

        if (maps.isNotEmpty) {
          final list = maps.map((e) => ManufacturingBatch.fromJson(e)).toList();
          _memoryBatches.clear();
          _memoryBatches.addAll(list);
          _nextBatchSeq = list.length + 1;
          return list;
        }
      } catch (e) {
        debugPrint('SQLite ManufacturingBatch error: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 50));
    if (search == null || search.trim().isEmpty) {
      return List.unmodifiable(_memoryBatches);
    }
    final q = search.trim().toLowerCase();
    return _memoryBatches.where((b) {
      return b.batchNo.toLowerCase().contains(q) ||
          b.rawMaterialName.toLowerCase().contains(q) ||
          b.outputProductName.toLowerCase().contains(q);
    }).toList();
  }

  Future<String> generateNextBatchNo() async {
    final nextNum = _nextBatchSeq++;
    final datePrefix =
        "${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}";
    return 'BATCH-$datePrefix-${nextNum.toString().padLeft(4, '0')}';
  }

  /// Creates a new Manufacturing Processing Batch:
  /// 1. Deducts Raw Material Stock (Stock Out: rawMaterialKg)
  /// 2. Increases Finished Goods Stock (Stock In: outputFinishedKg)
  /// 3. Updates Unit Cost Price for Finished Product
  Future<ManufacturingBatch> createBatch(ManufacturingBatch batch) async {
    final nextNo = await generateNextBatchNo();
    final batchNo =
        batch.batchNo.isNotEmpty ? batch.batchNo : nextNo;

    ManufacturingBatch record = batch.copyWith(
      id: batch.id ?? DateTime.now().millisecondsSinceEpoch,
      batchNo: batchNo,
    );

    // 1. Deduct Raw Material Stock from Database
    try {
      final allProducts = await _productRepo.fetchProducts();
      final rawIndex =
          allProducts.indexWhere((p) => p.id == record.rawMaterialId);
      if (rawIndex != -1) {
        final rawProd = allProducts[rawIndex];
        final newRawStock = (rawProd.currentStock - record.rawMaterialKg)
            .clamp(0, double.infinity)
            .toDouble();
        await _productRepo.updateProduct(
            rawProd.id!, rawProd.copyWith(currentStock: newRawStock));
      }
    } catch (_) {}

    // 2. Increase Finished Powder / Output Goods Stock in Database
    try {
      final allProducts = await _productRepo.fetchProducts();
      final outputIndex =
          allProducts.indexWhere((p) => p.id == record.outputProductId);
      if (outputIndex != -1) {
        final outputProd = allProducts[outputIndex];
        final newFinishedStock = outputProd.currentStock + record.outputFinishedKg;
        await _productRepo.updateProduct(
          outputProd.id!,
          outputProd.copyWith(
            currentStock: newFinishedStock,
            purchasePrice: record.unitCostPerKg > 0
                ? record.unitCostPerKg
                : outputProd.purchasePrice,
          ),
        );
      }
    } catch (_) {}

    // 3. Persist to SQLite
    if (!kIsWeb) {
      try {
        final db = await database;
        final map = record.toJson();
        map.remove('id');
        final insertedId = await db.insert('manufacturing_batches', map);
        record = record.copyWith(id: insertedId);
      } catch (e) {
        debugPrint('SQLite insert batch error: $e');
      }
    }

    _memoryBatches.insert(0, record);
    return record;
  }
}
