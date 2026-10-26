import "package:candlestick_master/core/theme/app_theme.dart";
import "package:candlestick_master/models/trade_model.dart";
import "package:candlestick_master/providers/trade_notifier.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

class JournalStatsScreen extends StatelessWidget {
  const JournalStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TradeNotifier>();
    final closedTrades = notifier.closedTrades;
    final totalClosed = notifier.totalClosedTrades;
    final totalPnl = notifier.totalPnl;
    final winRate = notifier.winRate;
    final wins = notifier.winCount;
    final losses = notifier.lossCount;

    // Long vs Short stats
    final longClosed = closedTrades.where((t) => t.tradeType == TradeType.long).toList();
    final shortClosed = closedTrades.where((t) => t.tradeType == TradeType.short).toList();
    final longWins = longClosed.where((t) => t.isProfit == true).length;
    final shortWins = shortClosed.where((t) => t.isProfit == true).length;
    final longWinRate = longClosed.isNotEmpty ? (longWins / longClosed.length) * 100 : 0.0;
    final shortWinRate = shortClosed.isNotEmpty ? (shortWins / shortClosed.length) * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Journal Analytics"),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Overview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  const Text(
                    "Cumulative Net P&L",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${totalPnl >= 0 ? "+" : ""}\$${totalPnl.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: totalPnl >= 0 ? AppColors.bullish : AppColors.bearish,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Win Rate Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Win Rate: ${winRate.toStringAsFixed(1)}%",
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "$wins W / $losses L",
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 10,
                      child: Row(
                        children: [
                          if (wins > 0)
                            Expanded(
                              flex: wins,
                              child: Container(color: AppColors.bullish),
                            ),
                          if (losses > 0)
                            Expanded(
                              flex: losses,
                              child: Container(color: AppColors.bearish),
                            ),
                          if (wins == 0 && losses == 0)
                            Expanded(
                              child: Container(color: AppColors.divider),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Performance Metrics Grid
            const Text(
              "Key Metrics",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: "Avg Trade P&L",
                    value: "\$${notifier.averagePnl.toStringAsFixed(2)}",
                    color: notifier.averagePnl >= 0 ? AppColors.bullish : AppColors.bearish,
                    icon: Icons.equalizer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: "Avg Risk/Reward",
                    value: notifier.averageRiskReward > 0
                        ? "1 : ${notifier.averageRiskReward.toStringAsFixed(2)}"
                        : "N/A",
                    color: AppColors.primary,
                    icon: Icons.balance,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: "Best Win",
                    value: "+\$${notifier.bestTrade.toStringAsFixed(2)}",
                    color: AppColors.bullish,
                    icon: Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: "Worst Loss",
                    value: "\$${notifier.worstTrade.toStringAsFixed(2)}",
                    color: AppColors.bearish,
                    icon: Icons.arrow_downward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Directional Performance (Long vs Short)
            const Text(
              "Directional Breakdown",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _buildDirectionRow(
                    label: "LONG Positions",
                    count: longClosed.length,
                    winRate: longWinRate,
                    color: AppColors.bullish,
                  ),
                  const Divider(color: AppColors.divider, height: 24),
                  _buildDirectionRow(
                    label: "SHORT Positions",
                    count: shortClosed.length,
                    winRate: shortWinRate,
                    color: AppColors.bearish,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Portfolio Overview Card
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
                    "Activity Summary",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryItem("Total Logged Trades", "${notifier.totalTrades}"),
                  _buildSummaryItem("Open Positions", "${notifier.totalOpenTrades}"),
                  _buildSummaryItem("Closed Trades", "$totalClosed"),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionRow({
    required String label,
    required int count,
    required double winRate,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Text(
          "$count trades • ${winRate.toStringAsFixed(1)}% win",
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
