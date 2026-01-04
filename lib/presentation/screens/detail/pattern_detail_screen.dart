import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/pattern_model.dart';
import '../../../core/theme/app_theme.dart';

class PatternDetailScreen extends StatelessWidget {
  final CandlestickPattern pattern;

  const PatternDetailScreen({super.key, required this.pattern});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pattern.name),
        actions: [
          // Share button for marketing deep links
          // TODO: Update domain when production deep link domain is configured
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Pattern',
            onPressed: () {
              // Deep link format for sharing
              final shareUrl = 'https://candlestickmaster.app/pattern/${pattern.id}';
              Share.share(
                'Check out the ${pattern.name} candlestick pattern!\n\n$shareUrl',
                subject: 'Candlestick Pattern: ${pattern.name}',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            if (pattern.imagePath.isNotEmpty)
              Container(
                width: double.infinity,
                height: 250,
                color: AppColors.surface,
                child: Image.asset(
                  pattern.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (c, o, s) => const Center(
                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  Row(
                    children: [
                      _buildTag(pattern.bias, _getBiasColor(pattern.bias)),
                      const SizedBox(width: 8),
                      _buildTag(pattern.category, Colors.blueGrey),
                      const SizedBox(width: 8),
                      _buildTag(pattern.difficulty, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Text("Description", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(pattern.description, style: Theme.of(context).textTheme.bodyMedium),
                  
                  const SizedBox(height: 20),
                  
                  // Key Rules
                  if (pattern.keyRules.isNotEmpty) ...[
                    Text("Key Rules", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    ...pattern.keyRules.map((rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(rule)),
                        ],
                      ),
                    )),
                  ],

                  // Trend Implication
                  if (pattern.trend.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text("Implication", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(pattern.trend, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getBiasColor(String bias) {
    if (bias == "Bullish") return AppColors.bullish;
    if (bias == "Bearish") return AppColors.bearish;
    return AppColors.neutral;
  }
}
