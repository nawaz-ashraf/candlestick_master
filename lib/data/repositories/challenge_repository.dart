import 'package:candlestick_master/core/constants/learning_constants.dart';
import 'package:candlestick_master/models/challenge_model.dart';

class ChallengeRepository {
  static final ChallengeRepository _instance = ChallengeRepository._internal();
  factory ChallengeRepository() => _instance;
  ChallengeRepository._internal();

  List<ChallengeModel> getChallenges({List<String>? patternTitles}) {
    final challenges = _buildChallengeBank(
      patternTitles: patternTitles ?? _defaultPatternTitles,
    );
    return List<ChallengeModel>.from(challenges);
  }

  List<ChallengeModel> challengesByDifficulty(
    String difficulty, {
    List<String>? patternTitles,
  }) {
    return getChallenges(patternTitles: patternTitles)
        .where((challenge) => challenge.difficulty == difficulty)
        .toList();
  }

  List<ChallengeModel> _buildChallengeBank(
      {required List<String> patternTitles}) {
    final sanitizedTitles = patternTitles.isEmpty
        ? _defaultPatternTitles
        : patternTitles.where((title) => title.trim().isNotEmpty).toList();

    final challengeBank = <ChallengeModel>[];
    var sequence = 1;

    for (final difficulty in LearningConstants.difficultyOrder) {
      final difficultyLabel = difficulty.label;
      final xpReward = _xpRewardByDifficulty(difficulty);

      for (var i = 0; i < 30; i++) {
        final pattern =
            sanitizedTitles[(i + sequence) % sanitizedTitles.length];
        final bias = _biasByPattern[_normalize(pattern)] ?? 'Neutral';
        final challenge = _buildChallengeEntry(
          sequence: sequence,
          indexInDifficulty: i,
          difficultyLabel: difficultyLabel,
          pattern: pattern,
          bias: bias,
          xpReward: xpReward,
          allPatterns: sanitizedTitles,
        );

        challengeBank.add(challenge);
        sequence += 1;
      }
    }

    return challengeBank;
  }

  ChallengeModel _buildChallengeEntry({
    required int sequence,
    required int indexInDifficulty,
    required String difficultyLabel,
    required String pattern,
    required String bias,
    required int xpReward,
    required List<String> allPatterns,
  }) {
    final challengeType = indexInDifficulty % 5;

    switch (challengeType) {
      case 0:
        final options =
            _patternOptions(pattern: pattern, allPatterns: allPatterns);
        return ChallengeModel(
          id: 'challenge_$sequence',
          difficulty: difficultyLabel,
          question:
              'Identify the setup: Which candlestick pattern are you being asked to review in this challenge?',
          options: options,
          correctAnswer: options.indexOf(pattern),
          explanation:
              '$pattern is the target pattern. Naming it quickly helps improve chart reading speed.',
          xpReward: xpReward,
        );
      case 1:
        final options = <String>[
          'Likely bullish continuation or reversal context',
          'Likely bearish continuation or reversal context',
          'Mostly indecision and confirmation needed',
          'No analysis needed before entry',
        ];
        final correctIndex = bias == 'Bullish'
            ? 0
            : bias == 'Bearish'
                ? 1
                : 2;
        return ChallengeModel(
          id: 'challenge_$sequence',
          difficulty: difficultyLabel,
          question:
              '$pattern appears near a key level. What directional bias is usually associated with this setup?',
          options: options,
          correctAnswer: correctIndex,
          explanation:
              '$pattern is generally treated as $bias. Always confirm with structure and volume before execution.',
          xpReward: xpReward,
        );
      case 2:
        final options = <String>[
          'Wait for a confirmation candle before entering',
          'Enter full size immediately without a stop',
          'Ignore broader trend and support/resistance',
          'Trade only based on one candle shape',
        ];
        return ChallengeModel(
          id: 'challenge_$sequence',
          difficulty: difficultyLabel,
          question:
              'Risk-aware decision: after spotting $pattern, what is the most disciplined next step?',
          options: options,
          correctAnswer: 0,
          explanation:
              'Confirmation reduces false signals. Structured entry and risk management improve long-term consistency.',
          xpReward: xpReward,
        );
      case 3:
        final options = <String>[
          'Confirmation + context + risk plan',
          'Pattern name only',
          'Social media opinion only',
          'Random entry with no exit rules',
        ];
        return ChallengeModel(
          id: 'challenge_$sequence',
          difficulty: difficultyLabel,
          question:
              'For $pattern, which checklist gives the highest quality setup evaluation?',
          options: options,
          correctAnswer: 0,
          explanation:
              'Reliable decisions combine pattern recognition, market context, and predefined risk controls.',
          xpReward: xpReward,
        );
      default:
        final options = <String>[
          'Potential reversal zone',
          'Guaranteed breakout in any direction',
          'Automatic profit signal',
          'Ignore because patterns never work',
        ];
        return ChallengeModel(
          id: 'challenge_$sequence',
          difficulty: difficultyLabel,
          question:
              '$pattern forms after an extended move. Which interpretation is most realistic for beginners?',
          options: options,
          correctAnswer: 0,
          explanation:
              'Many candlestick setups flag potential reversals, but confirmation is still required before execution.',
          xpReward: xpReward,
        );
    }
  }

  List<String> _patternOptions({
    required String pattern,
    required List<String> allPatterns,
  }) {
    final options = <String>[pattern];

    for (final candidate in allPatterns) {
      if (candidate == pattern) continue;
      if (options.contains(candidate)) continue;
      options.add(candidate);
      if (options.length == 4) break;
    }

    while (options.length < 4) {
      options.add(
          _defaultPatternTitles[options.length % _defaultPatternTitles.length]);
    }

    return options;
  }

  int _xpRewardByDifficulty(ContentDifficulty difficulty) {
    switch (difficulty) {
      case ContentDifficulty.basic:
        return 12;
      case ContentDifficulty.intermediate:
        return 18;
      case ContentDifficulty.hard:
        return 24;
      case ContentDifficulty.advanced:
        return 30;
    }
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static const List<String> _defaultPatternTitles = [
    'Doji',
    'Hammer',
    'Inverted Hammer',
    'Bullish Engulfing',
    'Bearish Engulfing',
    'Morning Star',
    'Evening Star',
    'Shooting Star',
    'Hanging Man',
    'Spinning Top',
    'Harami',
    'Piercing Pattern',
    'Dark Cloud Cover',
    'Three White Soldiers',
    'Three Black Crows',
    'Tweezer Top',
    'Tweezer Bottom',
    'Marubozu',
    'Gap Patterns',
    'Continuation Patterns',
    'Reversal Patterns',
  ];

  static const Map<String, String> _biasByPattern = {
    'doji': 'Neutral',
    'hammer': 'Bullish',
    'invertedhammer': 'Bullish',
    'bullishengulfing': 'Bullish',
    'bearishengulfing': 'Bearish',
    'morningstar': 'Bullish',
    'eveningstar': 'Bearish',
    'shootingstar': 'Bearish',
    'hangingman': 'Bearish',
    'spinningtop': 'Neutral',
    'harami': 'Neutral',
    'piercingpattern': 'Bullish',
    'darkcloudcover': 'Bearish',
    'threewhitesoldiers': 'Bullish',
    'threeblackcrows': 'Bearish',
    'tweezertop': 'Bearish',
    'tweezerbottom': 'Bullish',
    'marubozu': 'Neutral',
    'gappatterns': 'Neutral',
    'continuationpatterns': 'Neutral',
    'reversalpatterns': 'Neutral',
  };
}
