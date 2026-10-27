import 'dart:io';

import 'package:candlestick_master/data/repositories/indicator_repository.dart';
import 'package:candlestick_master/models/indicator_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Indicator Diagrams & Repository Mapping Tests', () {
    late IndicatorRepository repository;

    setUp(() {
      repository = IndicatorRepository();
    });

    test('Loads all 31 supported indicators with complete metadata', () {
      final indicators = repository.getIndicators();
      expect(indicators.length, equals(31));

      for (final indicator in indicators) {
        expect(indicator.id.trim(), isNotEmpty,
            reason: 'Indicator id should not be empty');
        expect(indicator.title.trim(), isNotEmpty,
            reason: 'Indicator ${indicator.id} should have a title');
        expect(indicator.definition.trim(), isNotEmpty,
            reason: 'Indicator ${indicator.id} should have a definition');
        expect(indicator.difficulty.trim(), isNotEmpty,
            reason: 'Indicator ${indicator.id} should have difficulty');
        expect(indicator.useCase.trim(), isNotEmpty,
            reason: 'Indicator ${indicator.id} should have a use case');
        expect(indicator.keyPoints, isNotEmpty,
            reason: 'Indicator ${indicator.id} should have key points');
      }
    });

    test('Every indicator has a unique, non-empty image diagram path', () {
      final indicators = repository.getIndicators();
      final seenIds = <String>{};
      final seenImages = <String>{};

      for (final indicator in indicators) {
        expect(seenIds.add(indicator.id), isTrue,
            reason: 'Duplicate indicator ID found: ${indicator.id}');

        expect(indicator.image.trim(), isNotEmpty,
            reason: 'Indicator ${indicator.id} has empty image path');

        expect(indicator.image.startsWith('assets/images/indicators/'), isTrue,
            reason: 'Indicator ${indicator.id} image path should be in assets/images/indicators/');

        expect(seenImages.add(indicator.image), isTrue,
            reason: 'Duplicate diagram path found: ${indicator.image} is shared between indicators!');
      }
    });

    test('All 31 referenced indicator diagram assets exist on disk with valid file size', () {
      final indicators = repository.getIndicators();

      for (final indicator in indicators) {
        final file = File(indicator.image);
        expect(file.existsSync(), isTrue,
            reason: 'Asset file does not exist on disk: ${indicator.image}');

        final fileSize = file.lengthSync();
        expect(fileSize, greaterThan(5000),
            reason: 'Asset file ${indicator.image} is too small or empty ($fileSize bytes)');
      }
    });

    test('Key indicators match their specific educational diagrams', () {
      final indicators = repository.getIndicators();
      final map = {for (var i in indicators) i.id: i.image};

      expect(map['indicator_rsi'], equals('assets/images/indicators/rsi.png'));
      expect(map['indicator_volume'], equals('assets/images/indicators/volume.png'));
      expect(map['indicator_bollinger_bands'], equals('assets/images/indicators/bollinger_bands.png'));
      expect(map['indicator_macd'], equals('assets/images/indicators/macd.png'));
      expect(map['indicator_moving_average'], equals('assets/images/indicators/moving_average.png'));
      expect(map['indicator_vwap'], equals('assets/images/indicators/vwap.png'));
      expect(map['indicator_adx'], equals('assets/images/indicators/adx.png'));
      expect(map['indicator_stochastic'], equals('assets/images/indicators/stochastic.png'));
      expect(map['indicator_zigzag'], equals('assets/images/indicators/zigzag.png'));
      expect(map['indicator_atr'], equals('assets/images/indicators/atr.png'));
      expect(map['indicator_supertrend'], equals('assets/images/indicators/supertrend.png'));
      expect(map['indicator_ichimoku'], equals('assets/images/indicators/ichimoku_cloud.png'));
      expect(map['indicator_fibonacci_retracement'], equals('assets/images/indicators/fibonacci_retracement.png'));
    });

    test('IndicatorModel serialization roundtrip preserves image diagram path', () {
      const model = IndicatorModel(
        id: 'test_rsi',
        title: 'Relative Strength Index',
        difficulty: 'basic',
        image: 'assets/images/indicators/rsi.png',
        definition: 'Momentum oscillator that measures speed and change of price.',
        useCase: 'Identify overbought and oversold conditions.',
        keyPoints: ['Overbought at 70', 'Oversold at 30'],
      );

      final json = model.toJson();
      expect(json['image'], equals('assets/images/indicators/rsi.png'));

      final fromJson = IndicatorModel.fromJson(json);
      expect(fromJson.id, equals(model.id));
      expect(fromJson.title, equals(model.title));
      expect(fromJson.image, equals(model.image));
      expect(fromJson.difficulty, equals(model.difficulty));
      expect(fromJson.definition, equals(model.definition));
      expect(fromJson.useCase, equals(model.useCase));
      expect(fromJson.keyPoints, equals(model.keyPoints));
    });
  });
}
