import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../product_model/product_model.dart';

class ProductDatabaseService {
  static final ProductDatabaseService instance = ProductDatabaseService._init();
  static Database? _database;

  ProductDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hisab_nikas_products.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
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
      // Android / iOS
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

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER UNIQUE,
        name TEXT NOT NULL,
        code TEXT,
        barcode TEXT,
        category TEXT,
        brand TEXT,
        unit TEXT,
        purchase_price REAL,
        last_purchase_price REAL,
        average_cost REAL,
        supplier_name TEXT,
        sale_price REAL,
        wholesale_price REAL,
        discount REAL,
        vat_tax_percent REAL,
        current_stock REAL,
        opening_stock REAL,
        min_stock_warning REAL,
        warehouse TEXT,
        batch_no TEXT,
        mfg_date TEXT,
        expiry_date TEXT,
        lc_no TEXT,
        lc_bank TEXT,
        origin_country TEXT,
        import_cost REAL,
        customs_duty REAL,
        freight_cost REAL,
        landing_cost REAL,
        image_url TEXT,
        description TEXT,
        is_active INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final columns = await db.rawQuery('PRAGMA table_info(products)');
      if (!columns.any((column) => column['name'] == 'server_id')) {
        await db.execute('ALTER TABLE products ADD COLUMN server_id INTEGER');
        await db.execute(
          'CREATE UNIQUE INDEX idx_products_server_id ON products(server_id)',
        );
      }
    }
  }

  Future<List<Product>> getAllProducts({String? search, String? category}) async {
    final db = await instance.database;
    List<dynamic> whereArgs = [];
    List<String> conditions = [];

    if (search != null && search.trim().isNotEmpty) {
      conditions.add('(name LIKE ? OR code LIKE ? OR barcode LIKE ? OR category LIKE ? OR brand LIKE ?)');
      final query = '%${search.trim()}%';
      whereArgs.addAll([query, query, query, query, query]);
    }

    if (category != null && category.isNotEmpty && category != 'All') {
      conditions.add('category = ?');
      whereArgs.add(category);
    }

    final whereClause = conditions.isEmpty ? null : conditions.join(' AND ');

    final result = await db.query(
      'products',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id DESC',
    );

    return result.map((json) => Product.fromJson(json)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Product.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<Product> insertProduct(Product product) async {
    final db = await instance.database;
    final json = product.toDatabaseJson();
    final id = await db.insert('products', json, conflictAlgorithm: ConflictAlgorithm.replace);
    return product.copyWith(id: id);
  }

  Future<Product> upsertRemoteProduct(
    Product remoteProduct, {
    int? localId,
  }) async {
    final serverId = remoteProduct.serverId ?? remoteProduct.id;
    if (serverId == null) {
      throw ArgumentError.value(
        remoteProduct.id,
        'remoteProduct.id',
        'A server ID is required to cache a remote product.',
      );
    }

    final db = await instance.database;
    var maps = localId == null
        ? <Map<String, Object?>>[]
        : await db.query(
            'products',
            where: 'id = ?',
            whereArgs: [localId],
            limit: 1,
          );
    if (maps.isEmpty) {
      maps = await db.query(
        'products',
        where: 'server_id = ?',
        whereArgs: [serverId],
        limit: 1,
      );
    }
    if (maps.isEmpty && remoteProduct.code.isNotEmpty) {
      maps = await db.query(
        'products',
        where: 'code = ?',
        whereArgs: [remoteProduct.code],
        limit: 1,
      );
    }

    final existingId = maps.isEmpty ? null : maps.first['id'] as int;
    final product = remoteProduct.copyWith(
      id: existingId,
      serverId: serverId,
    );
    if (existingId == null) return insertProduct(product);

    await db.update(
      'products',
      product.toDatabaseJson(),
      where: 'id = ?',
      whereArgs: [existingId],
    );
    return product;
  }

  Future<int> updateProduct(int id, Product product) async {
    final db = await instance.database;
    final json = product.toDatabaseJson();
    return await db.update(
      'products',
      json,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> replaceAll(List<Product> products) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('products');
      for (final p in products) {
        final json = p.toDatabaseJson();
        if (p.id != null) {
          json['id'] = p.id;
        }
        await txn.insert('products', json, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
