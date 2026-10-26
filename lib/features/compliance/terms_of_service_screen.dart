import "package:candlestick_master/core/theme/app_theme.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Terms of Service",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go("/profile");
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppColors.accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Terms & Conditions",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Last updated: January 2026",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Prominent Disclaimer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bearish.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.bearish.withOpacity(0.35),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.bearish,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Educational Only: Candlestick Master is designed purely for informational and educational purposes. It does not provide financial or trading advice.",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildSection(
                title: "1. Acceptance of Terms",
                content:
                    "By downloading, installing, or using Candlestick Master, you agree to comply with and be bound by these Terms of Service. If you do not agree, please do not use the application.",
              ),

              _buildSection(
                title: "2. No Financial Advice",
                content:
                    "All patterns, indicators, charts, and quizzes are for education only. Trading stocks, forex, cryptocurrencies, and derivatives carries significant risk of monetary loss. Past performance or simulated results do not guarantee future market success.",
              ),

              _buildSection(
                title: "3. User Accounts",
                content:
                    "You are responsible for keeping your login credentials secure. You may delete your account and personal data at any time directly through the app.",
              ),

              _buildSection(
                title: "4. Virtual Currency & Items",
                content:
                    "XP, streaks, and virtual coins earned within the app are strictly promotional virtual items. They have no real-world cash value, cannot be redeemed for legal currency, and cannot be transferred outside the app.",
              ),

              _buildSection(
                title: "5. Intellectual Property",
                content:
                    "All visual materials, pattern illustrations, quiz questions, and software are the intellectual property of Nawaz Ashraf and are protected by applicable copyright laws.",
              ),

              _buildSection(
                title: "6. Limitation of Liability",
                content:
                    "Candlestick Master and its developer shall not be liable for any financial losses or damages resulting from your investment or trading decisions.",
              ),

              _buildSection(
                title: "7. Contact",
                content:
                    "Questions about these Terms of Service may be directed to Nawaz Ashraf at:\nnawazashraf446@gmail.com",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
