// =============================================================================
// TradeNotifier - Trading Journal State Management
// =============================================================================
// ChangeNotifier managing trade list, CRUD, statistics, and Firestore sync.
// =============================================================================

import 'package:candlestick_master/core/services/analytics_service.dart';
import 'package:candlestick_master/core/services/auth_service.dart';
import 'package:candlestick_master/core/services/firestore_service.dart';
import 'package:candlestick_master/data/repositories/trade_repository.dart';
import 'package:candlestick_master/models/trade_model.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class TradeNotifier extends ChangeNotifier {
  final TradeRepository _repository = TradeRepository();
  final FirestoreService _firestore = FirestoreService();
  final AnalyticsService _analytics = AnalyticsService();
  final _uuid = const Uuid();

  List<Trade> _trades = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  // ============================================
  // Getters
  // ============================================

  List<Trade> get trades => _trades;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  List<Trade> get openTrades =>
      _trades.where((t) => t.status == TradeStatus.open).toList();

  List<Trade> get closedTrades =>
      _trades.where((t) => t.status == TradeStatus.closed).toList();

  // ============================================
  // Statistics
  // ============================================

  int get totalTrades => _trades.length;
  int get totalOpenTrades => openTrades.length;
  int get totalClosedTrades => closedTrades.length;

  double get totalPnl {
    return closedTrades.fold(0.0, (sum, t) => sum + (t.pnl ?? 0));
  }

  int get winCount => closedTrades.where((t) => t.isProfit == true).length;
  int get lossCount => closedTrades.where((t) => t.isProfit == false).length;

  double get winRate {
    if (totalClosedTrades == 0) return 0;
    return (winCount / totalClosedTrades) * 100;
  }

  double get averagePnl {
    if (totalClosedTrades == 0) return 0;
    return totalPnl / totalClosedTrades;
  }

  double get averageRiskReward {
    final tradesWithRR =
        closedTrades.where((t) => t.riskRewardRatio != null).toList();
    if (tradesWithRR.isEmpty) return 0;
    return tradesWithRR.fold(0.0, (sum, t) => sum + t.riskRewardRatio!) /
        tradesWithRR.length;
  }

  double get bestTrade {
    if (closedTrades.isEmpty) return 0;
    return closedTrades
        .map((t) => t.pnl ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }

  double get worstTrade {
    if (closedTrades.isEmpty) return 0;
    return closedTrades
        .map((t) => t.pnl ?? 0)
        .reduce((a, b) => a < b ? a : b);
  }

  // ============================================
  // Initialization
  // ============================================

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      _trades = await _repository.getAll();
      _isInitialized = true;
      debugPrint('TradeNotifier: Loaded ${_trades.length} trades');
    } catch (e) {
      debugPrint('TradeNotifier: Init error – $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ============================================
  // CRUD
  // ============================================

  /// Add a new trade.
  Future<void> addTrade({
    required String symbol,
    required TradeType tradeType,
    required double entryPrice,
    required double quantity,
    required DateTime entryDate,
    double? exitPrice,
    DateTime? exitDate,
    double? stopLoss,
    double? takeProfit,
    String notes = '',
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final status =
        exitPrice != null ? TradeStatus.closed : TradeStatus.open;

    final trade = Trade(
      id: _uuid.v4(),
      symbol: symbol.toUpperCase().trim(),
      tradeType: tradeType,
      status: status,
      entryPrice: entryPrice,
      exitPrice: exitPrice,
      quantity: quantity,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      entryDate: entryDate,
      exitDate: exitDate,
      notes: notes.trim(),
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.upsert(trade);
    _trades.insert(0, trade);
    notifyListeners();

    await _analytics.logTradeCreated(tradeType: tradeType.name);
    await _syncTradeToCloud(trade);
  }

  /// Update an existing trade.
  Future<void> updateTrade(Trade updatedTrade) async {
    final trade = updatedTrade.copyWith(updatedAt: DateTime.now());

    await _repository.upsert(trade);

    final index = _trades.indexWhere((t) => t.id == trade.id);
    if (index != -1) {
      _trades[index] = trade;
    }
    notifyListeners();

    await _analytics.logTradeEdited();
    await _syncTradeToCloud(trade);
  }

  /// Close an open trade (set exit price and date).
  Future<void> closeTrade({
    required String tradeId,
    required double exitPrice,
    DateTime? exitDate,
  }) async {
    final index = _trades.indexWhere((t) => t.id == tradeId);
    if (index == -1) return;

    final trade = _trades[index].copyWith(
      exitPrice: exitPrice,
      exitDate: exitDate ?? DateTime.now(),
      status: TradeStatus.closed,
      updatedAt: DateTime.now(),
    );

    await _repository.upsert(trade);
    _trades[index] = trade;
    notifyListeners();

    await _syncTradeToCloud(trade);
  }

  /// Delete a trade.
  Future<void> deleteTrade(String tradeId) async {
    await _repository.delete(tradeId);
    _trades.removeWhere((t) => t.id == tradeId);
    notifyListeners();

    await _analytics.logTradeDeleted();
    await _deleteTradeFromCloud(tradeId);
  }

  // ============================================
  // Filtering
  // ============================================

  List<Trade> filterByDateRange(DateTime start, DateTime end) {
    return _trades
        .where((t) =>
            t.entryDate.isAfter(start.subtract(const Duration(days: 1))) &&
            t.entryDate.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  List<Trade> filterBySymbol(String symbol) {
    final s = symbol.toUpperCase().trim();
    return _trades.where((t) => t.symbol == s).toList();
  }

  // ============================================
  // Cloud Sync
  // ============================================

  Future<void> _syncTradeToCloud(Trade trade) async {
    final uid = AuthService().uid;
    if (uid == null) return;

    try {
      await _firestore.saveTrade(uid: uid, trade: trade);
    } catch (e) {
      debugPrint('TradeNotifier: Cloud sync failed for trade ${trade.id} – $e');
    }
  }

  Future<void> _deleteTradeFromCloud(String tradeId) async {
    final uid = AuthService().uid;
    if (uid == null) return;

    try {
      await _firestore.deleteTrade(uid: uid, tradeId: tradeId);
    } catch (e) {
      debugPrint(
          'TradeNotifier: Cloud delete failed for trade $tradeId – $e');
    }
  }

  /// Sync all local trades to Firestore.
  Future<void> syncAllToCloud() async {
    final uid = AuthService().uid;
    if (uid == null) return;

    try {
      await _firestore.syncAllTrades(uid: uid, trades: _trades);
      debugPrint('TradeNotifier: All trades synced to cloud');
    } catch (e) {
      debugPrint('TradeNotifier: Full sync failed – $e');
    }
  }

  /// Load trades from Firestore and merge with local.
  Future<void> syncFromCloud() async {
    final uid = AuthService().uid;
    if (uid == null) return;

    try {
      final cloudTrades = await _firestore.loadTrades(uid: uid);
      final localIds = _trades.map((t) => t.id).toSet();

      int added = 0;
      for (final trade in cloudTrades) {
        if (!localIds.contains(trade.id)) {
          await _repository.upsert(trade);
          _trades.add(trade);
          added++;
        }
      }

      if (added > 0) {
        _trades.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
        debugPrint('TradeNotifier: Added $added trades from cloud');
      }
    } catch (e) {
      debugPrint('TradeNotifier: Cloud sync failed – $e');
    }
  }
}
