import 'package:candlestick_master/core/constants/learning_constants.dart';
import 'package:candlestick_master/data/repositories/indicator_repository.dart';
import 'package:candlestick_master/models/indicator_model.dart';
import 'package:candlestick_master/models/lesson_model.dart';
import 'package:candlestick_master/models/pattern_model.dart';

class LessonRepository {
  final IndicatorRepository _indicatorRepository;

  LessonRepository({IndicatorRepository? indicatorRepository})
      : _indicatorRepository = indicatorRepository ?? IndicatorRepository();

  static const List<String> _requiredPatternTitles = [
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

  static const Map<String, String> _patternDifficultyByTitle = {
    'doji': 'Basic',
    'hammer': 'Basic',
    'invertedhammer': 'Basic',
    'bullishengulfing': 'Basic',
    'bearishengulfing': 'Basic',
    'morningstar': 'Intermediate',
    'eveningstar': 'Intermediate',
    'shootingstar': 'Intermediate',
    'hangingman': 'Intermediate',
    'spinningtop': 'Intermediate',
    'harami': 'Hard',
    'piercingpattern': 'Hard',
    'darkcloudcover': 'Hard',
    'threewhitesoldiers': 'Hard',
    'threeblackcrows': 'Hard',
    'tweezertop': 'Advanced',
    'tweezerbottom': 'Advanced',
    'marubozu': 'Advanced',
    'gappatterns': 'Advanced',
    'continuationpatterns': 'Advanced',
    'reversalpatterns': 'Advanced',
  };

  static const Map<String, String> _placeholderDescriptions = {
    'Gap Patterns':
        'Gap patterns highlight areas where price opens above or below the prior close, signaling momentum or exhaustion.',
    'Continuation Patterns':
        'Continuation patterns suggest the current trend may resume after consolidation.',
    'Reversal Patterns':
        'Reversal patterns signal a potential shift in market direction after a sustained move.',
  };

  List<LessonModel> buildCandlestickLessons(List<CandlestickPattern> patterns) {
    final patternByName = <String, CandlestickPattern>{
      for (final pattern in patterns) _normalize(pattern.name): pattern,
    };

    final lessons = <LessonModel>[];
    final seenIds = <String>{};

    for (final title in _requiredPatternTitles) {
      final normalizedTitle = _normalize(title);
      final difficulty = _patternDifficultyByTitle[normalizedTitle] ??
          ContentDifficulty.basic.label;
      final matchedPattern = patternByName[normalizedTitle];
      final id = matchedPattern?.id ?? 'virtual_$normalizedTitle';

      lessons.add(
        LessonModel(
          id: id,
          title: title,
          type: LearningConstants.modulePattern,
          difficulty: difficulty,
          description: _buildDescription(title, matchedPattern),
          image: matchedPattern?.imagePath ?? '',
          keyPoints: _buildKeyPoints(title, matchedPattern),
          unlockedBy: _unlockRuleForDifficulty(difficulty),
        ),
      );

      seenIds.add(id);
    }

    for (final pattern in patterns) {
      if (pattern.category == 'General') continue;
      if (seenIds.contains(pattern.id)) continue;

      final difficulty = _mapPatternDifficulty(pattern);
      lessons.add(
        LessonModel(
          id: pattern.id,
          title: pattern.name,
          type: LearningConstants.modulePattern,
          difficulty: difficulty,
          description: _buildDescription(pattern.name, pattern),
          image: pattern.imagePath,
          keyPoints: _buildKeyPoints(pattern.name, pattern),
          unlockedBy: _unlockRuleForDifficulty(difficulty),
        ),
      );
    }

    lessons.sort((a, b) {
      final difficultyCompare = _difficultyIndex(a.difficulty)
          .compareTo(_difficultyIndex(b.difficulty));
      if (difficultyCompare != 0) return difficultyCompare;
      return a.title.compareTo(b.title);
    });

    return lessons;
  }

  List<IndicatorModel> getIndicators() {
    return _indicatorRepository.getIndicators();
  }

  List<LessonModel> buildIndicatorLessons() {
    final indicators = _indicatorRepository.getIndicators();

    return indicators
        .map(
          (indicator) => LessonModel(
            id: indicator.id,
            title: indicator.title,
            type: LearningConstants.moduleIndicator,
            difficulty: indicator.difficulty,
            description: indicator.definition,
            image: indicator.image,
            keyPoints: indicator.keyPoints,
            unlockedBy: _unlockRuleForDifficulty(indicator.difficulty),
          ),
        )
        .toList();
  }

  List<LessonModel> buildAllLessons(List<CandlestickPattern> patterns) {
    final candlestick = buildCandlestickLessons(patterns);
    final indicators = buildIndicatorLessons();
    return [...candlestick, ...indicators];
  }

  String _buildDescription(String title, CandlestickPattern? pattern) {
    final fromPattern = pattern?.description.trim() ?? '';
    if (fromPattern.isNotEmpty) {
      final normalized = fromPattern.replaceAll('\n', ' ').trim();
      if (normalized.length <= 180) {
        return normalized;
      }
      return '${normalized.substring(0, 177)}...';
    }

    return _placeholderDescriptions[title] ??
        'Learn how to identify and trade the $title setup with clear confirmation rules.';
  }

  List<String> _buildKeyPoints(String title, CandlestickPattern? pattern) {
    final keyRules = (pattern?.keyRules ?? const <String>[])
        .map((rule) => rule.replaceAll('\n', ' ').trim())
        .where((rule) => rule.isNotEmpty)
        .toList();

    if (keyRules.length >= 3) {
      return keyRules.take(4).toList();
    }

    final fallback = <String>[
      'Identify the candle body and wick structure first.',
      'Confirm the setup with surrounding market context.',
      'Plan entries and risk before acting on the signal.',
      'Avoid trading a single pattern without confirmation.',
    ];

    return {...keyRules, ...fallback}.take(4).toList();
  }

  String _unlockRuleForDifficulty(String difficulty) {
    final contentDifficulty = LearningConstants.fromDifficultyLabel(difficulty);
    return LearningConstants.unlockRuleText(contentDifficulty);
  }

  String _mapPatternDifficulty(CandlestickPattern pattern) {
    final byName = _patternDifficultyByTitle[_normalize(pattern.name)];
    if (byName != null) return byName;

    final fromPattern = pattern.difficulty.trim().toLowerCase();
    if (fromPattern.contains('beginner')) return ContentDifficulty.basic.label;
    if (fromPattern.contains('intermediate')) {
      return ContentDifficulty.intermediate.label;
    }
    if (fromPattern.contains('advanced'))
      return ContentDifficulty.advanced.label;
    if (fromPattern.contains('hard')) return ContentDifficulty.hard.label;
    return ContentDifficulty.intermediate.label;
  }

  int _difficultyIndex(String difficultyLabel) {
    final difficulty = LearningConstants.fromDifficultyLabel(difficultyLabel);
    return LearningConstants.difficultyOrder.indexOf(difficulty);
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
