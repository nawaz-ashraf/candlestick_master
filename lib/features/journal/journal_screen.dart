import "package:candlestick_master/core/theme/app_theme.dart";
import "package:candlestick_master/features/journal/journal_stats_screen.dart";
import "package:candlestick_master/features/journal/trade_detail_screen.dart";
import "package:candlestick_master/features/journal/trade_form_screen.dart";
import "package:candlestick_master/models/trade_model.dart";
import "package:candlestick_master/providers/trade_notifier.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

enum JournalFilter { all, open, closed, long, short }

class JournalScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const JournalScreen({super.key, this.onOpenDrawer});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  JournalFilter _filter = JournalFilter.all;

  List<Trade> _filterTrades(List<Trade> all) {
    switch (_filter) {
      case JournalFilter.all:
        return all;
      case JournalFilter.open:
        return all.where((t) => t.status == TradeStatus.open).toList();
      case JournalFilter.closed:
        return all.where((t) => t.status == TradeStatus.closed).toList();
      case JournalFilter.long:
        return all.where((t) => t.tradeType == TradeType.long).toList();
      case JournalFilter.short:
        return all.where((t) => t.tradeType == TradeType.short).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tradeNotifier = context.watch<TradeNotifier>();
    final trades = _filterTrades(tradeNotifier.trades);
    final totalPnl = tradeNotifier.totalPnl;
    final winRate = tradeNotifier.winRate;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Trading Journal"),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                tooltip: "Open Navigation Menu",
                onPressed: widget.onOpenDrawer,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.primarySoft),
            tooltip: "Sync with Cloud",
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Syncing journal with cloud..."),
                  duration: Duration(seconds: 1),
                ),
              );
              await tradeNotifier.syncFromCloud();
              await tradeNotifier.syncAllToCloud();
            },
          ),
          IconButton(
            icon: const Icon(Icons.insights, color: AppColors.primary),
            tooltip: "Analytics",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const JournalStatsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TradeFormScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text("Log Trade", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Quick Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryColumn(
                  label: "Total P&L",
                  value: "${totalPnl >= 0 ? "+" : ""}\$${totalPnl.toStringAsFixed(2)}",
                  color: totalPnl >= 0 ? AppColors.bullish : AppColors.bearish,
                ),
                Container(height: 36, width: 1, color: AppColors.divider),
                _buildSummaryColumn(
                  label: "Win Rate",
                  value: "${winRate.toStringAsFixed(1)}%",
                  color: AppColors.primary,
                ),
                Container(height: 36, width: 1, color: AppColors.divider),
                _buildSummaryColumn(
                  label: "Total Trades",
                  value: "${tradeNotifier.totalTrades}",
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip("All", JournalFilter.all),
                const SizedBox(width: 8),
                _buildFilterChip("Open", JournalFilter.open),
                const SizedBox(width: 8),
                _buildFilterChip("Closed", JournalFilter.closed),
                const SizedBox(width: 8),
                _buildFilterChip("Long", JournalFilter.long),
                const SizedBox(width: 8),
                _buildFilterChip("Short", JournalFilter.short),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Trade List or Empty State
          Expanded(
            child: tradeNotifier.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : trades.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                        itemCount: trades.length,
                        itemBuilder: (context, index) {
                          final trade = trades[index];
                          return _buildTradeCard(trade);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, JournalFilter filter) {
    final isSelected = _filter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
      onSelected: (_) {
        setState(() => _filter = filter);
      },
    );
  }

  Widget _buildTradeCard(Trade trade) {
    final isLong = trade.tradeType == TradeType.long;
    final isClosed = trade.status == TradeStatus.closed;
    final pnl = trade.pnl;
    final pnlPercent = trade.pnlPercent;
    final isProfit = trade.isProfit ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TradeDetailScreen(trade: trade)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Direction Indicator Bar
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: isLong ? AppColors.bullish : AppColors.bearish,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Symbol & Type & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          trade.symbol,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isLong ? AppColors.bullish : AppColors.bearish).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isLong ? "LONG" : "SHORT",
                            style: TextStyle(
                              color: isLong ? AppColors.bullish : AppColors.bearish,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Entry: \$${trade.entryPrice.toStringAsFixed(2)} • ${_formatDate(trade.entryDate)}",
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // P&L or Status Badge
              if (isClosed && pnl != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${pnl >= 0 ? "+" : ""}\$${pnl.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: isProfit ? AppColors.bullish : AppColors.bearish,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${pnlPercent! >= 0 ? "+" : ""}${pnlPercent.toStringAsFixed(1)}%",
                      style: TextStyle(
                        color: isProfit ? AppColors.bullish : AppColors.bearish,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                  ),
                  child: const Text(
                    "OPEN",
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.book_outlined, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 20),
            const Text(
              "No Trades Logged",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Track your executions, review risk/reward setups, and refine your edge over time.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TradeFormScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Log First Trade", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.month}/${dt.day}/${dt.year}";
  }
}
