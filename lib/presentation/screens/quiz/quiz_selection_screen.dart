// =============================================================================
// Quiz Selection Screen - Difficulty & Length Picker
// =============================================================================
// Displays card-based UI for selecting quiz difficulty and length:
// - Easy: 5 Questions
// - Medium: 10 Questions
// - Hard: 15 Questions
// Theme-aware styling that respects global light/dark mode.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/quiz_settings.dart';

class QuizSelectionScreen extends StatelessWidget {
  const QuizSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Choose Your Challenge',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Select difficulty based on your experience level',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Difficulty Cards
              Expanded(
                child: ListView(
                  children: [
                    _DifficultyCard(
                      settings: QuizSettings.easy,
                      icon: Icons.bolt,
                      gradientColors: [
                        const Color(0xFF00C896),
                        const Color(0xFF00E0A4),
                      ],
                      onTap: () => _startQuiz(context, QuizSettings.easy),
                    ),
                    const SizedBox(height: 16),
                    _DifficultyCard(
                      settings: QuizSettings.medium,
                      icon: Icons.trending_up,
                      gradientColors: [
                        const Color(0xFFE6B566),
                        const Color(0xFFF4C430),
                      ],
                      onTap: () => _startQuiz(context, QuizSettings.medium),
                    ),
                    const SizedBox(height: 16),
                    _DifficultyCard(
                      settings: QuizSettings.hard,
                      icon: Icons.psychology,
                      gradientColors: [
                        const Color(0xFFE5533D),
                        const Color(0xFFFF6B5B),
                      ],
                      onTap: () => _startQuiz(context, QuizSettings.hard),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, QuizSettings settings) {
    context.push('/quiz', extra: settings);
  }
}

class _DifficultyCard extends StatelessWidget {
  final QuizSettings settings;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.settings,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          settings.difficultyLabel,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${settings.questionCount} Questions',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      settings.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.white.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
