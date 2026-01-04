import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Go Premium")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.star, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
              "Unlock Full Potential",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildFeatureRow("Unless Unlimited Practice"),
            _buildFeatureRow("Remove Ads"),
            _buildFeatureRow("Advanced Patterns"),
            _buildFeatureRow("Real-time Alerts"),
            const Spacer(),
            ElevatedButton(
               style: ElevatedButton.styleFrom(
                 backgroundColor: AppColors.primary,
                 padding: const EdgeInsets.symmetric(vertical: 16),
               ),
               onPressed: () {
                 // Trigger purchase flow
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Purchase Initiated...")));
               },
               child: const Text("Subscribe - \$4.99/mo", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Maybe Later", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.bullish),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
