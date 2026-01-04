import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool _accepted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('disclaimer_accepted') ?? false;
    if (accepted && mounted) {
      context.go('/');
    } else {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onAccept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclaimer_accepted', true);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.warning_amber_rounded, size: 64, color: AppColors.bearish),
              const SizedBox(height: 24),
              const Text(
                "Important Disclaimer",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    "This application is for EDUCATIONAL PURPOSES ONLY.\n\n"
                    "1. No Financial Advice: The content provided in this app does not constitute financial, investment, or trading advice. You are responsible for your own financial decisions.\n\n"
                    "2. Risk Warning: Trading financial markets involves a high risk of loss. Past performance of any trading system or methodology is not necessarily indicative of future results.\n\n"
                    "3. Accuracy: While we strive for accuracy, candlestick patterns are subjective and can be interpreted differently. We do not guarantee the accuracy of any pattern detection.\n\n"
                    "By clicking 'I Agree', you acknowledge that you have read and understood this disclaimer.",
                    style: TextStyle(fontSize: 16, height: 1.5, color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                   Checkbox(
                    value: _accepted,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                         _accepted = val ?? false;
                      });
                    },
                   ),
                   const Expanded(child: Text("I have read and agree to the disclaimer")),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                  ),
                  onPressed: _accepted ? _onAccept : null,
                  child: const Text("I Agree", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
