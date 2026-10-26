import "package:candlestick_master/core/theme/app_theme.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Privacy Policy",
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
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Privacy Policy",
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
              const SizedBox(height: 20),

              _buildSection(
                title: "1. Overview",
                content:
                    "Candlestick Master is developed by Nawaz Ashraf. This Privacy Policy explains how we collect, use, and protect your information when using the mobile application.",
              ),

              _buildSection(
                title: "2. Information We Collect",
                content:
                    "• Account Details: If you create an account, we collect your email address, chosen display name, and authentication ID via Google Firebase Authentication.\n"
                    "• Learning & Quiz Progress: Your XP, levels, streak count, completed patterns, quiz scores, and coins.\n"
                    "• Trading Journal: Trading pairs, entry/exit prices, position directions, and personal trade notes stored locally via SQLite and synchronized with Firebase Firestore when logged in.\n"
                    "• Device Diagnostics: Anonymous crash reports and usage statistics via Firebase Crashlytics & Analytics to improve app stability.",
              ),

              _buildSection(
                title: "3. Advertising (Google AdMob)",
                content:
                    "The app uses Google AdMob to display banner and rewarded video ads. AdMob may process non-personally identifiable advertising identifiers (Google Advertising ID) for ad delivery and fraud prevention in accordance with Google's Privacy Policy.",
              ),

              _buildSection(
                title: "4. Data Security",
                content:
                    "All cloud communications use industry-standard HTTPS encryption. We do not sell, rent, or trade your personal information.",
              ),

              _buildSection(
                title: "5. Account Deletion & Rights",
                content:
                    "You have the right to delete your account and all associated cloud data at any time. You can perform deletion directly in the app under Profile → Account Settings → Delete Account & Data, or email us at nawazashraf446@gmail.com.",
              ),

              _buildSection(
                title: "6. Contact Developer",
                content:
                    "For any questions or privacy inquiries, contact Nawaz Ashraf at:\nnawazashraf446@gmail.com",
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
