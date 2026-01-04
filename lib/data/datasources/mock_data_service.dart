import 'dart:math';
import 'package:candlesticks/candlesticks.dart';

class MockDataService {
  static List<Candle> generateCandles({int count = 100}) {
    List<Candle> candles = [];
    DateTime now = DateTime.now();
    Random random = Random();
    double currentPrice = 150.0;

    for (int i = 0; i < count; i++) {
      // Simulate price movement
      double open = currentPrice;
      double close = open * (1 + (random.nextDouble() - 0.5) * 0.02);
      double high = max(open, close) * (1 + random.nextDouble() * 0.01);
      double low = min(open, close) * (1 - random.nextDouble() * 0.01);
      double volume = 1000 + random.nextDouble() * 5000;

      // Ensure some specific patterns appear occasionally for testing
      // E.g., make a Hammer at index 10
      if (i == 10) {
         // Hammer: Small body at top, long lower wick
         close = open * 1.001; // Small bull body
         high = close; // No upper wick
         low = open * 0.98; // Long lower wick
      }
      
       // Engulfing at index 20
      if (i == 20) {
         // Bullish Engulfing
         // Previous (19) should be small red (already gen'd random)
         // Current: Open below prev close, close above prev open
         double prevClose = candles.first.close; 
         double prevOpen = candles.first.open;
         
         open = prevClose * 0.995;
         close = prevOpen * 1.005;
         high = close * 1.001;
         low = open * 0.999;
      }

      candles.insert(0, Candle(
        date: now.subtract(Duration(minutes: 5 * i)),
        high: high,
        low: low,
        open: open,
        close: close,
        volume: volume,
      ));
      
      currentPrice = close;
    }
    return candles;
  }
}
