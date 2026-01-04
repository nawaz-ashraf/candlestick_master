import 'package:candlesticks/candlesticks.dart';
import '../../data/models/pattern_model.dart';
import 'dart:math';

class DetectionResult {
  final String patternId;
  final String patternName;
  final int index; // Index in the candle list
  final String bias;
  
  DetectionResult(this.patternId, this.patternName, this.index, this.bias);
}

class PatternDetector {
  
  List<DetectionResult> detect(List<Candle> candles) {
    List<DetectionResult> results = [];
    
    // We analyze from recent to old (index 0 is newest in `candlesticks` usually, 
    // but commonly list is sorted by date. Let's assume index 0 is NEWEST for valid check)
    // Actually `candlesticks` package usually expects 0 to be newest.
    
    for (int i = 0; i < candles.length - 2; i++) {
        final current = candles[i];
        final prev = candles[i + 1];
        // final prev2 = candles[i + 2];
        
        // 1. Hammer (Bullish)
        // Downtrend context (simplified: prev close < prev open)
        // Small body, long lower wick (>2x body), small/no upper wick
        if (_isHammer(current)) {
           // Basic trend check: previous few candles should be bearish
           results.add(DetectionResult("7", "Hammer", i, "Bullish"));
        }
        
        // 2. Bullish Engulfing
        if (_isBullishEngulfing(current, prev)) {
            results.add(DetectionResult("17", "Bullish Engulfing", i, "Bullish"));
        }
    }
    
    return results;
  }
  
  bool _isHammer(Candle c) {
    double bodySize = (c.close - c.open).abs();
    double upperWick = c.high - max(c.open, c.close);
    double lowerWick = min(c.open, c.close) - c.low;
    
    bool smallBody = bodySize < (c.high - c.low) * 0.3;
    bool longLower = lowerWick > (bodySize * 2);
    bool smallUpper = upperWick < (bodySize * 0.5); // Tolerance
    
    return smallBody && longLower && smallUpper;
  }
  
  bool _isBullishEngulfing(Candle curr, Candle prev) {
    bool prevBearish = prev.close < prev.open;
    bool currBullish = curr.close > curr.open;
    
    if (!prevBearish || !currBullish) return false;
    
    // Engulfing logic: Open < Prev Close and Close > Prev Open
    // (Crypto/24h markets often open == close, so >= or <= is safer)
    return curr.open <= prev.close && curr.close >= prev.open;
  }
}
