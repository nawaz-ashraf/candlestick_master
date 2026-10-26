// =============================================================================
// TradeRepository - SQLite-backed Local Storage for Trading Journal
// =============================================================================
// Provides CRUD operations for Trade objects using sqflite.
// Enforces strict user isolation via userId column on all queries and mutations.
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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trades (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL DEFAULT '',
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
        await db.execute('CREATE INDEX idx_trades_userId ON trades (userId)');
        debugPrint('TradeRepository: Database created with userId column');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE trades ADD COLUMN userId TEXT NOT NULL DEFAULT ''");
          await db.execute('CREATE INDEX IF NOT EXISTS idx_trades_userId ON trades (userId)');
          debugPrint('TradeRepository: Migrated schema to v2 with userId column');
        }
      },
    );
  }

  // ============================================
  // CRUD Operations (User-Scoped)
  // ============================================

  /// Insert or replace a trade.
  Future<void> upsert(Trade trade) async {
    final db = await database;
    await db.insert(
      'trades',
      trade.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('TradeRepository: Trade ${trade.id} upserted for user ${trade.userId}');
  }

  /// Get all trades for a specific user, ordered by creation date (newest first).
  Future<List<Trade>> getAll({required String userId}) async {
    final db = await database;
    final maps = await db.query(
      'trades',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Trade.fromSqliteMap(m)).toList();
  }

  /// Get a single trade by ID scoped to the authenticated user.
  Future<Trade?> getById(String id, {required String userId}) async {
    final db = await database;
    final maps = await db.query(
      'trades',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Trade.fromSqliteMap(maps.first);
  }

  /// Get trades filtered by status for a specific user.
  Future<List<Trade>> getByStatus(TradeStatus status, {required String userId}) async {
    final db = await database;
    final maps = await db.query(
      'trades',
      where: 'status = ? AND userId = ?',
      whereArgs: [status.name, userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Trade.fromSqliteMap(m)).toList();
  }

  /// Get trades within a date range for a specific user.
  Future<List<Trade>> getByDateRange(DateTime start, DateTime end, {required String userId}) async {
    final db = await database;
    final maps = await db.query(
      'trades',
      where: 'entryDate >= ? AND entryDate <= ? AND userId = ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String(), userId],
      orderBy: 'entryDate DESC',
    );
    return maps.map((m) => Trade.fromSqliteMap(m)).toList();
  }

  /// Delete a trade by ID only if it belongs to the specified user.
  Future<void> delete(String id, {required String userId}) async {
    final db = await database;
    final count = await db.delete(
      'trades',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
    debugPrint('TradeRepository: Trade $id deleted for user $userId (rows affected: $count)');
  }

  /// Delete all trades for a specific user.
  Future<void> deleteAll({required String userId}) async {
    final db = await database;
    final count = await db.delete(
      'trades',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    debugPrint('TradeRepository: All trades deleted for user $userId (rows affected: $count)');
  }

  /// Get trade count for a specific user.
  Future<int> count({required String userId}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM trades WHERE userId = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
