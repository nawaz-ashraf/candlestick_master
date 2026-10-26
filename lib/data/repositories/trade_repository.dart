// =============================================================================
// TradeRepository - SQLite-backed Local Storage for Trading Journal
// =============================================================================
// Provides CRUD operations for Trade objects using sqflite.
// Data is stored locally and synced to Firestore when authenticated.
// =============================================================================

import 'package:candlestick_master/models/trade_model.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class TradeRepository {
  // Singleton
  static final TradeRepository _instance = TradeRepository._internal();
  factory TradeRepository() => _instance;
  TradeRepository._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'trades.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trades (
            id TEXT PRIMARY KEY,
            symbol TEXT NOT NULL,
            tradeType TEXT NOT NULL,
            status TEXT NOT NULL,
            entryPrice REAL NOT NULL,
            exitPrice REAL,
            quantity REAL NOT NULL,
            stopLoss REAL,
            takeProfit REAL,
            entryDate TEXT NOT NULL,
            exitDate TEXT,
            notes TEXT,
            tags TEXT,
            screenshotPath TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
        debugPrint('TradeRepository: Database created');
      },
    );
  }

  // ============================================
  // CRUD Operations
  // ============================================

  /// Insert or replace a trade.
  Future<void> upsert(Trade trade) async {
    final db = await database;
    await db.insert(
      'trades',
      trade.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('TradeRepository: Trade ${trade.id} upserted');
  }

  /// Get all trades, ordered by creation date (newest first).
  Future<List<Trade>> getAll() async {
    final db = await database;
    final maps = await db.query(
      'trades',
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Trade.fromSqliteMap(m)).toList();
  }

  /// Get a single trade by ID.
  Future<Trade?> getById(String id) async {
    final db = await database;
    final maps = await db.query(
      'trades',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Trade.fromSqliteMap(maps.first);
  }

  /// Get trades filtered by status.
  Future<List<Trade>> getByStatus(TradeStatus status) async {
    final db = await database;
    final maps = await db.query(
      'trades',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Trade.fromSqliteMap(m)).toList();
  }

  /// Get trades within a date range.
  Future<List<Trade>> getByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'trades',
      where: 'entryDate >= ? AND entryDate <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'entryDate DESC',
    );
    return maps.map((m) => Trade.fromSqliteMap(m)).toList();
  }

  /// Delete a trade by ID.
  Future<void> delete(String id) async {
    final db = await database;
    await db.delete(
      'trades',
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('TradeRepository: Trade $id deleted');
  }

  /// Delete all trades.
  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('trades');
    debugPrint('TradeRepository: All trades deleted');
  }

  /// Get trade count.
  Future<int> count() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM trades');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
