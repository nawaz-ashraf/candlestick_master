import "package:candlestick_master/models/trade_model.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("Trade Model Tests", () {
    test("Long trade calculates positive P&L correctly", () {
      final trade = Trade(
        id: "1",
        symbol: "BTC/USDT",
        tradeType: TradeType.long,
        status: TradeStatus.closed,
        entryPrice: 50000.0,
        exitPrice: 55000.0,
        quantity: 2.0,
        entryDate: DateTime(2026, 1, 1),
        exitDate: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      expect(trade.pnl, equals(10000.0));
      expect(trade.pnlPercent, equals(10.0));
      expect(trade.isProfit, isTrue);
    });

    test("Long trade calculates loss correctly", () {
      final trade = Trade(
        id: "2",
        symbol: "ETH/USDT",
        tradeType: TradeType.long,
        status: TradeStatus.closed,
        entryPrice: 3000.0,
        exitPrice: 2700.0,
        quantity: 1.0,
        entryDate: DateTime(2026, 1, 1),
        exitDate: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      expect(trade.pnl, equals(-300.0));
      expect(trade.pnlPercent, equals(-10.0));
      expect(trade.isProfit, isFalse);
    });

    test("Short trade calculates positive P&L correctly", () {
      final trade = Trade(
        id: "3",
        symbol: "SOL/USDT",
        tradeType: TradeType.short,
        status: TradeStatus.closed,
        entryPrice: 150.0,
        exitPrice: 120.0,
        quantity: 10.0,
        entryDate: DateTime(2026, 1, 1),
        exitDate: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      expect(trade.pnl, equals(300.0));
      expect(trade.pnlPercent, equals(20.0));
      expect(trade.isProfit, isTrue);
    });

    test("Open trade returns null P&L and isProfit", () {
      final trade = Trade(
        id: "4",
        symbol: "AAPL",
        tradeType: TradeType.long,
        status: TradeStatus.open,
        entryPrice: 180.0,
        quantity: 5.0,
        entryDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(trade.pnl, isNull);
      expect(trade.pnlPercent, isNull);
      expect(trade.isProfit, isNull);
    });

    test("Risk/Reward ratio is computed accurately", () {
      // Long: Entry 100, SL 90 (risk 10), TP 130 (reward 30) -> RR = 3.0
      final trade = Trade(
        id: "5",
        symbol: "TSLA",
        tradeType: TradeType.long,
        status: TradeStatus.open,
        entryPrice: 100.0,
        quantity: 1.0,
        stopLoss: 90.0,
        takeProfit: 130.0,
        entryDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(trade.riskRewardRatio, equals(3.0));
    });

    test("Serialization roundtrip to Map and SQLite works correctly", () {
      final original = Trade(
        id: "test-id-123",
        symbol: "NIFTY",
        tradeType: TradeType.long,
        status: TradeStatus.closed,
        entryPrice: 22000.0,
        exitPrice: 22500.0,
        quantity: 50.0,
        stopLoss: 21800.0,
        takeProfit: 22600.0,
        entryDate: DateTime(2026, 1, 10, 10, 0),
        exitDate: DateTime(2026, 1, 10, 15, 30),
        notes: "Solid breakout with volume",
        tags: ["Breakout", "Daily"],
        createdAt: DateTime(2026, 1, 10, 10, 0),
        updatedAt: DateTime(2026, 1, 10, 15, 30),
      );

      final dbMap = original.toSqliteMap();
      final fromDb = Trade.fromSqliteMap(dbMap);

      expect(fromDb.id, equals(original.id));
      expect(fromDb.symbol, equals(original.symbol));
      expect(fromDb.tradeType, equals(original.tradeType));
      expect(fromDb.status, equals(original.status));
      expect(fromDb.entryPrice, equals(original.entryPrice));
      expect(fromDb.exitPrice, equals(original.exitPrice));
      expect(fromDb.quantity, equals(original.quantity));
      expect(fromDb.notes, equals(original.notes));
      expect(fromDb.tags, equals(original.tags));
    });
  });
}
