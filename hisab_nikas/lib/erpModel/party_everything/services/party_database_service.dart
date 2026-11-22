import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../party_model/party_model.dart';

class PartyDatabaseService {
  static final PartyDatabaseService instance = PartyDatabaseService._init();
  static Database? _database;

  PartyDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hisab_nikas_party.db');
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
      // Android / iOS (Phone & Tablet)
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
      CREATE TABLE parties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER UNIQUE,
        party_code TEXT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        opening_balance REAL,
        balance_type TEXT,
        is_active INTEGER,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final columns = await db.rawQuery('PRAGMA table_info(parties)');
      if (!columns.any((column) => column['name'] == 'server_id')) {
        await db.execute('ALTER TABLE parties ADD COLUMN server_id INTEGER');
        await db.execute(
          'CREATE UNIQUE INDEX idx_parties_server_id ON parties(server_id)',
        );
      }
    }
  }

  Future<List<Party>> getAllParties({String? search, String? type}) async {
    final db = await instance.database;
    List<dynamic> whereArgs = [];
    List<String> conditions = [];

    if (search != null && search.trim().isNotEmpty) {
      conditions.add(
        '(name LIKE ? OR party_code LIKE ? OR phone LIKE ? OR email LIKE ?)',
      );
      final query = '%${search.trim()}%';
      whereArgs.addAll([query, query, query, query]);
    }

    if (type != null && type.isNotEmpty && type != 'all') {
      conditions.add('(type = ? OR type = ?)');
      whereArgs.addAll([type, 'both']);
    }

    final whereClause = conditions.isEmpty ? null : conditions.join(' AND ');

    final result = await db.query(
      'parties',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id DESC',
    );

    return result.map((json) => Party.fromJson(json)).toList();
  }

  Future<Party?> getPartyById(int id) async {
    final db = await instance.database;
    final maps = await db.query('parties', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Party.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<Party> insertParty(Party party) async {
    final db = await instance.database;
    final id = await db.insert('parties', party.toDatabaseJson());
    return party.copyWith(id: id);
  }

  Future<Party> upsertRemoteParty(Party remoteParty, {int? localId}) async {
    final serverId = remoteParty.serverId;
    if (serverId == null) {
      throw ArgumentError.value(
        remoteParty.serverId,
        'remoteParty.serverId',
        'A server ID is required to cache a Laravel party.',
      );
    }

    final db = await instance.database;
    var maps = localId == null
        ? <Map<String, Object?>>[]
        : await db.query(
            'parties',
            where: 'id = ?',
            whereArgs: [localId],
            limit: 1,
          );
    if (maps.isEmpty) {
      maps = await db.query(
        'parties',
        where: 'server_id = ?',
        whereArgs: [serverId],
        limit: 1,
      );
    }

    if (maps.isEmpty && remoteParty.partyCode.isNotEmpty) {
      maps = await db.query(
        'parties',
        where: 'party_code = ?',
        whereArgs: [remoteParty.partyCode],
        limit: 1,
      );
    }

    if (maps.isEmpty && remoteParty.phone != null) {
      maps = await db.query(
        'parties',
        where: 'phone = ? AND type = ?',
        whereArgs: [remoteParty.phone, remoteParty.type],
        limit: 1,
      );
    }

    final existingId = maps.isEmpty ? null : maps.first['id'] as int;
    final localParty = remoteParty.copyWith(id: existingId);
    if (existingId == null) {
      return insertParty(localParty);
    }

    await db.update(
      'parties',
      localParty.toDatabaseJson(),
      where: 'id = ?',
      whereArgs: [existingId],
    );
    return localParty;
  }

  Future<void> deletePartiesMissingFromServer(List<int> serverIds) async {
    final db = await instance.database;
    if (serverIds.isEmpty) {
      await db.delete('parties', where: 'server_id IS NOT NULL');
      return;
    }

    final placeholders = List.filled(serverIds.length, '?').join(', ');
    await db.delete(
      'parties',
      where: 'server_id IS NOT NULL AND server_id NOT IN ($placeholders)',
      whereArgs: serverIds,
    );
  }

  Future<int> updateParty(int id, Party party) async {
    final db = await instance.database;
    final json = party.toDatabaseJson();
    return await db.update('parties', json, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteParty(int id) async {
    final db = await instance.database;
    return await db.delete('parties', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceAll(List<Party> parties) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('parties');
      for (final p in parties) {
        final json = p.toDatabaseJson();
        if (p.id != null) {
          json['id'] = p.id;
        }
        await txn.insert(
          'parties',
          json,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
