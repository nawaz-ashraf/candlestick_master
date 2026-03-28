import 'package:candlestick_master/core/utils/level_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LevelUtils', () {
    test('level 1 starts at 0 XP and needs 100 XP', () {
      final info = LevelUtils.fromXp(0);

      expect(info.level, 1);
      expect(info.xpIntoCurrentLevel, 0);
      expect(info.xpForNextLevel, 100);
      expect(info.xpToNextLevel, 100);
    });

    test('100 XP enters level 2 with 200 XP required for next level', () {
      final info = LevelUtils.fromXp(100);

      expect(info.level, 2);
      expect(info.xpIntoCurrentLevel, 0);
      expect(info.xpForNextLevel, 200);
      expect(info.xpToNextLevel, 200);
    });

    test('299 XP is level 2 with 1 XP remaining to level 3', () {
      final info = LevelUtils.fromXp(299);

      expect(info.level, 2);
      expect(info.xpIntoCurrentLevel, 199);
      expect(info.xpForNextLevel, 200);
      expect(info.xpToNextLevel, 1);
    });

    test('300 XP reaches level 3', () {
      final info = LevelUtils.fromXp(300);

      expect(info.level, 3);
      expect(info.xpIntoCurrentLevel, 0);
      expect(info.xpForNextLevel, 300);
      expect(info.xpToNextLevel, 300);
    });
  });
}
