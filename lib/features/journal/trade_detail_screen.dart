import "package:candlestick_master/core/theme/app_theme.dart";
import "package:candlestick_master/features/journal/trade_form_screen.dart";
import "package:candlestick_master/models/trade_model.dart";
import "package:candlestick_master/providers/trade_notifier.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

class TradeDetailScreen extends StatefulWidget {
  final Trade trade;

  const TradeDetailScreen({super.key, required this.trade});

  @override
  State<TradeDetailScreen> createState() => _TradeDetailScreenState();
}

class _TradeDetailScreenState extends State<TradeDetailScreen> {
  late Trade _trade;

  @override
  void initState() {
    super.initState();
    _trade = widget.trade;
  }

  void _refreshTrade() {
    final notifier = context.read<TradeNotifier>();
    final found = notifier.trades.firstWhere(
      (t) => t.id == _trade.id,
      orElse: () => _trade,
    );
    setState(() {
      _trade = found;
    });
  }

  Future<void> _deleteTrade() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Delete Trade", style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          "Are you sure you want to delete this trade entry? This action cannot be undone.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text("Delete", style: TextStyle(color: AppColors.bearish)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<TradeNotifier>().deleteTrade(_trade.id);
      if (mounted) {
        context.pop();
      }
    }
  }

  Future<void> _showCloseTradeDialog() async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Close Position", style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter the exit price to calculate your final P&L.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: "Exit Price",
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (double.tryParse(controller.text.trim()) != null) {
                ctx.pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text("Close"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final exitPrice = double.tryParse(controller.text.trim());
      if (exitPrice != null) {
        await context.read<TradeNotifier>().closeTrade(
          tradeId: _trade.id,
          exitPrice: exitPrice,
          exitDate: DateTime.now(),
        );
        _refreshTrade();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLong = _trade.tradeType == TradeType.long;
    final isClosed = _trade.status == TradeStatus.closed;
    final pnl = _trade.pnl;
    final pnlPercent = _trade.pnlPercent;
    final isProfit = _trade.isProfit ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_trade.symbol),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TradeFormScreen(trade: _trade),
                ),
              );
              _refreshTrade();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.bearish),
            onPressed: _deleteTrade,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // P&L Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isClosed
                    ? (isProfit
                        ? AppColors.bullish.withOpacity(0.12)
                        : AppColors.bearish.withOpacity(0.12))
                    : AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isClosed
                      ? (isProfit
                          ? AppColors.bullish.withOpacity(0.4)
                          : AppColors.bearish.withOpacity(0.4))
                      : AppColors.accent.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge: LONG / SHORT
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLong ? AppColors.bullish : AppColors.bearish,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isLong ? "LONG" : "SHORT",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isClosed ? AppColors.surfaceRaised : AppColors.accent.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isClosed ? "CLOSED" : "OPEN",
                          style: TextStyle(
                            color: isClosed ? AppColors.textSecondary : AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isClosed && pnl != null) ...[
                    Text(
                      "${pnl >= 0 ? "+" : ""}\$${pnl.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: isProfit ? AppColors.bullish : AppColors.bearish,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${pnlPercent! >= 0 ? "+" : ""}${pnlPercent.toStringAsFixed(2)}% ROI",
                      style: TextStyle(
                        color: isProfit ? AppColors.bullish : AppColors.bearish,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      "Position Currently Active",
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _showCloseTradeDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text("Close Position Now", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Key Metrics Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Trade Execution",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildMetricRow("Entry Price", "\$${_trade.entryPrice.toStringAsFixed(2)}"),
                  if (_trade.exitPrice != null)
                    _buildMetricRow("Exit Price", "\$${_trade.exitPrice!.toStringAsFixed(2)}"),
                  _buildMetricRow("Quantity / Size", _trade.quantity.toString()),
                  if (_trade.stopLoss != null)
                    _buildMetricRow("Stop Loss", "\$${_trade.stopLoss!.toStringAsFixed(2)}"),
                  if (_trade.takeProfit != null)
                    _buildMetricRow("Take Profit", "\$${_trade.takeProfit!.toStringAsFixed(2)}"),
                  if (_trade.riskRewardRatio != null)
                    _buildMetricRow("Risk/Reward Ratio", "1 : ${_trade.riskRewardRatio!.toStringAsFixed(2)}"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Timing Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dates & Timeline",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildMetricRow("Entry Date", _formatDate(_trade.entryDate)),
                  if (_trade.exitDate != null)
                    _buildMetricRow("Exit Date", _formatDate(_trade.exitDate!)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            if (_trade.tags.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tags",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _trade.tags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceRaised,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Text(
                                  "#$tag",
                                  style: const TextStyle(
                                    color: AppColors.primarySoft,
                                    fontSize: 12,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Notes Card
            if (_trade.notes.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Strategy Notes & Review",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _trade.notes,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")}";
  }
}
