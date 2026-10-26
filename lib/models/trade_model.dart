// =============================================================================
// Trade Model - Trading Journal Data Structure
// =============================================================================
// Immutable data class representing a single trade entry.
// Supports both Long and Short trades with P&L calculation.
// =============================================================================

enum TradeType { long, short }

enum TradeStatus { open, closed }

class Trade {
  final String id;
  final String userId;
  final String symbol;
  final TradeType tradeType;
  final TradeStatus status;

  final double entryPrice;
  final double? exitPrice;
  final double quantity;
  final double? stopLoss;
  final double? takeProfit;

  final DateTime entryDate;
  final DateTime? exitDate;

  final String notes;
  final List<String> tags;
  final String? screenshotPath;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Trade({
    required this.id,
    this.userId = '',
    required this.symbol,
    required this.tradeType,
    required this.status,
    required this.entryPrice,
    this.exitPrice,
    required this.quantity,
    this.stopLoss,
    this.takeProfit,
    required this.entryDate,
    this.exitDate,
    this.notes = '',
    this.tags = const [],
    this.screenshotPath,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================
  // Calculations
  // ============================================

  /// Calculate Profit/Loss for the trade.
  ///
  /// For open trades, returns null (no P/L until closed).
  double? get pnl {
    if (status == TradeStatus.open || exitPrice == null) return null;

    if (tradeType == TradeType.long) {
      return (exitPrice! - entryPrice) * quantity;
    } else {
      return (entryPrice - exitPrice!) * quantity;
    }
  }

  /// P&L as a percentage of entry.
  double? get pnlPercent {
    if (exitPrice == null || entryPrice == 0) return null;

    if (tradeType == TradeType.long) {
      return ((exitPrice! - entryPrice) / entryPrice) * 100;
    } else {
      return ((entryPrice - exitPrice!) / entryPrice) * 100;
    }
  }

  /// Whether this trade was profitable.
  bool? get isProfit {
    final p = pnl;
    if (p == null) return null;
    return p > 0;
  }

  /// Risk-Reward Ratio (if stopLoss and takeProfit are set).
  double? get riskRewardRatio {
    if (stopLoss == null || takeProfit == null || entryPrice == 0) return null;

    final risk = (entryPrice - stopLoss!).abs();
    final reward = (takeProfit! - entryPrice).abs();

    if (risk == 0) return null;
    return reward / risk;
  }

  // ============================================
  // Copy
  // ============================================

  Trade copyWith({
    String? id,
    String? userId,
    String? symbol,
    TradeType? tradeType,
    TradeStatus? status,
    double? entryPrice,
    double? exitPrice,
    double? quantity,
    double? stopLoss,
    double? takeProfit,
    DateTime? entryDate,
    DateTime? exitDate,
    String? notes,
    List<String>? tags,
    String? screenshotPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trade(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symbol: symbol ?? this.symbol,
      tradeType: tradeType ?? this.tradeType,
      status: status ?? this.status,
      entryPrice: entryPrice ?? this.entryPrice,
      exitPrice: exitPrice ?? this.exitPrice,
      quantity: quantity ?? this.quantity,
      stopLoss: stopLoss ?? this.stopLoss,
      takeProfit: takeProfit ?? this.takeProfit,
      entryDate: entryDate ?? this.entryDate,
      exitDate: exitDate ?? this.exitDate,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      screenshotPath: screenshotPath ?? this.screenshotPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================
  // Serialization
  // ============================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'symbol': symbol,
      'tradeType': tradeType.name,
      'status': status.name,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'quantity': quantity,
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
      'entryDate': entryDate.toIso8601String(),
      'exitDate': exitDate?.toIso8601String(),
      'notes': notes,
      'tags': tags,
      'screenshotPath': screenshotPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      tradeType: TradeType.values.firstWhere(
        (e) => e.name == json['tradeType'],
        orElse: () => TradeType.long,
      ),
      status: TradeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TradeStatus.open,
      ),
      entryPrice: (json['entryPrice'] as num?)?.toDouble() ?? 0,
      exitPrice: (json['exitPrice'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      stopLoss: (json['stopLoss'] as num?)?.toDouble(),
      takeProfit: (json['takeProfit'] as num?)?.toDouble(),
      entryDate: DateTime.tryParse(json['entryDate'] as String? ?? '') ??
          DateTime.now(),
      exitDate: json['exitDate'] != null
          ? DateTime.tryParse(json['exitDate'] as String)
          : null,
      notes: json['notes'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      screenshotPath: json['screenshotPath'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // ============================================
  // SQLite helpers
  // ============================================

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'userId': userId,
      'symbol': symbol,
      'tradeType': tradeType.name,
      'status': status.name,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'quantity': quantity,
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
      'entryDate': entryDate.toIso8601String(),
      'exitDate': exitDate?.toIso8601String(),
      'notes': notes,
      'tags': tags.join(','),
      'screenshotPath': screenshotPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Trade.fromSqliteMap(Map<String, dynamic> map) {
    return Trade(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      symbol: map['symbol'] as String? ?? '',
      tradeType: TradeType.values.firstWhere(
        (e) => e.name == map['tradeType'],
        orElse: () => TradeType.long,
      ),
      status: TradeStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TradeStatus.open,
      ),
      entryPrice: (map['entryPrice'] as num?)?.toDouble() ?? 0,
      exitPrice: (map['exitPrice'] as num?)?.toDouble(),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      stopLoss: (map['stopLoss'] as num?)?.toDouble(),
      takeProfit: (map['takeProfit'] as num?)?.toDouble(),
      entryDate: DateTime.tryParse(map['entryDate'] as String? ?? '') ??
          DateTime.now(),
      exitDate: map['exitDate'] != null
          ? DateTime.tryParse(map['exitDate'] as String)
          : null,
      notes: map['notes'] as String? ?? '',
      tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? const [],
      screenshotPath: map['screenshotPath'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
