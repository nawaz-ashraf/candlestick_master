import 'package:candlestick_master/core/constants/learning_constants.dart';
import 'package:candlestick_master/core/theme/app_theme.dart';
import 'package:candlestick_master/core/utils/progression_utils.dart';
import 'package:candlestick_master/data/repositories/challenge_repository.dart';
import 'package:candlestick_master/models/challenge_model.dart';
import 'package:candlestick_master/providers/gamification_notifier.dart';
import 'package:candlestick_master/providers/pattern_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChallengeLibraryScreen extends StatefulWidget {
  const ChallengeLibraryScreen({super.key});

  @override
  State<ChallengeLibraryScreen> createState() => _ChallengeLibraryScreenState();
}

class _ChallengeLibraryScreenState extends State<ChallengeLibraryScreen> {
  ContentDifficulty _selectedDifficulty = ContentDifficulty.basic;

  @override
  Widget build(BuildContext context) {
    return Consumer2<GamificationNotifier, PatternsNotifier>(
      builder: (context, gamification, patternsNotifier, _) {
        final patternTitles = patternsNotifier.patterns
            .map((pattern) => pattern.name)
            .where((title) => title.trim().isNotEmpty)
            .toList(growable: false);

        final allChallenges =
            ChallengeRepository().getChallenges(patternTitles: patternTitles);
        final completedPracticeCount = allChallenges
            .where((challenge) =>
                gamification.completedChallenges.contains(challenge.id))
            .length;
        final groupedByDifficulty =
            ProgressionUtils.groupChallengesByDifficulty(allChallenges);

        final totalByDifficulty = <ContentDifficulty, int>{
          for (final difficulty in LearningConstants.difficultyOrder)
            difficulty: groupedByDifficulty[difficulty]!.length,
        };

        final completedByDifficulty = <ContentDifficulty, int>{
          for (final difficulty in LearningConstants.difficultyOrder)
            difficulty: groupedByDifficulty[difficulty]!
                .where((challenge) =>
                    gamification.completedChallenges.contains(challenge.id))
                .length,
        };

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.read<GamificationNotifier>().syncUnlockedDifficulties(
                module: LearningConstants.moduleChallenge,
                completedByDifficulty: completedByDifficulty,
                totalByDifficulty: totalByDifficulty,
              );
        });

        final selectedChallenges = groupedByDifficulty[_selectedDifficulty] ??
            const <ChallengeModel>[];

        final isSelectedDifficultyUnlocked = gamification.isDifficultyUnlocked(
          module: LearningConstants.moduleChallenge,
          difficulty: _selectedDifficulty,
        );

        return Column(
          children: [
            _buildHeader(completedPracticeCount, allChallenges.length),
            _buildDifficultySelector(
                gamification, completedByDifficulty, totalByDifficulty),
            Expanded(
              child: isSelectedDifficultyUnlocked
                  ? _buildChallengeList(
                      context,
                      selectedChallenges,
                      gamification,
                    )
                  : _buildLockedState(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int completedChallenges, int totalChallenges) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.9),
            AppColors.primarySoft.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_moon, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Challenge Library',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedChallenges / $totalChallenges completed',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector(
    GamificationNotifier gamification,
    Map<ContentDifficulty, int> completedByDifficulty,
    Map<ContentDifficulty, int> totalByDifficulty,
  ) {
    return SizedBox(
      height: 64,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: LearningConstants.difficultyOrder.map((difficulty) {
          final isSelected = difficulty == _selectedDifficulty;
          final isUnlocked = gamification.isDifficultyUnlocked(
            module: LearningConstants.moduleChallenge,
            difficulty: difficulty,
          );
          final completed = completedByDifficulty[difficulty] ?? 0;
          final total = totalByDifficulty[difficulty] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedDifficulty = difficulty);
              },
              avatar: Icon(
                isUnlocked ? Icons.lock_open : Icons.lock,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              label: Text('${difficulty.label}  $completed/$total'),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.transparent,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLockedState() {
    final unlockHint = LearningConstants.unlockRuleText(_selectedDifficulty);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              '${_selectedDifficulty.label} Challenges Locked',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              unlockHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeList(
    BuildContext context,
    List<ChallengeModel> challenges,
    GamificationNotifier gamification,
  ) {
    if (challenges.isEmpty) {
      return const Center(
        child: Text(
          'No challenges in this difficulty yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: challenges.length,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        final isCompleted =
            gamification.completedChallenges.contains(challenge.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCompleted
                  ? AppColors.bullish.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.15),
              child: Icon(
                isCompleted ? Icons.check : Icons.quiz,
                color: isCompleted ? AppColors.bullish : AppColors.primary,
              ),
            ),
            title: Text(
              'Challenge ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              challenge.question,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('+${challenge.xpReward} XP',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    )),
                if (isCompleted)
                  const Text('Done',
                      style: TextStyle(
                        color: AppColors.bullish,
                        fontSize: 11,
                      )),
              ],
            ),
            onTap: () => _openChallengeAttempt(context, challenge, isCompleted),
          ),
        );
      },
    );
  }

  Future<void> _openChallengeAttempt(
    BuildContext context,
    ChallengeModel challenge,
    bool isCompleted,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChallengeAttemptSheet(
        challenge: challenge,
        alreadyCompleted: isCompleted,
      ),
    );
  }
}

class _ChallengeAttemptSheet extends StatefulWidget {
  final ChallengeModel challenge;
  final bool alreadyCompleted;

  const _ChallengeAttemptSheet({
    required this.challenge,
    required this.alreadyCompleted,
  });

  @override
  State<_ChallengeAttemptSheet> createState() => _ChallengeAttemptSheetState();
}

class _ChallengeAttemptSheetState extends State<_ChallengeAttemptSheet> {
  int? _selected;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final isCorrect = _submitted && _selected == challenge.correctAnswer;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Practice Challenge',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  '+${challenge.xpReward} XP',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              challenge.question,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...List.generate(challenge.options.length, (index) {
              final option = challenge.options[index];
              final selected = _selected == index;

              Color border = AppColors.divider;
              Color bg = Colors.transparent;

              if (_submitted) {
                if (index == challenge.correctAnswer) {
                  border = AppColors.bullish;
                  bg = AppColors.bullish.withOpacity(0.15);
                } else if (selected) {
                  border = AppColors.bearish;
                  bg = AppColors.bearish.withOpacity(0.15);
                }
              } else if (selected) {
                border = AppColors.primary;
                bg = AppColors.primary.withOpacity(0.1);
              }

              return InkWell(
                onTap: _submitted
                    ? null
                    : () {
                        setState(() => _selected = index);
                      },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                    color: bg,
                  ),
                  child: Text(option),
                ),
              );
            }),
            const SizedBox(height: 8),
            if (_submitted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isCorrect
                      ? AppColors.bullish.withOpacity(0.12)
                      : AppColors.bearish.withOpacity(0.12),
                ),
                child: Text(
                  challenge.explanation,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _submitted ? () => Navigator.of(context).pop() : _onSubmit,
                child: Text(_submitted ? 'Close' : 'Submit Answer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    final selected = _selected;
    if (selected == null) return;

    setState(() => _submitted = true);

    final challenge = widget.challenge;
    final isCorrect = selected == challenge.correctAnswer;

    if (isCorrect) {
      await context.read<GamificationNotifier>().completeChallenge(
            challengeId: challenge.id,
            xpReward: widget.alreadyCompleted ? 0 : challenge.xpReward,
          );
    }

    if (!mounted) return;
    final message = isCorrect
        ? widget.alreadyCompleted
            ? 'Correct! Challenge already completed earlier.'
            : 'Correct! +${challenge.xpReward} XP'
        : 'Not quite. Review the explanation and try another challenge.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
