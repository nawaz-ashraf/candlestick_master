import 'package:candlestick_master/models/indicator_model.dart';

class IndicatorRepository {
  static final List<IndicatorModel> _indicators = [
    IndicatorModel(
      id: 'indicator_rsi',
      title: 'RSI',
      definition:
          'Relative Strength Index measures momentum by comparing recent gains and losses on a 0 to 100 scale.',
      keyPoints: [
        'Readings above 70 often signal overbought conditions.',
        'Readings below 30 often signal oversold conditions.',
        'Divergence between price and RSI can warn of trend weakness.',
      ],
      image: 'assets/images/indicators/rsi.png',
      useCase:
          'Use RSI to time entries during pullbacks and confirm momentum shifts.',
      difficulty: 'Basic',
    ),
    IndicatorModel(
      id: 'indicator_volume',
      title: 'Volume',
      definition:
          'Volume shows how many units were traded during a period and reflects participation strength.',
      keyPoints: [
        'High volume confirms stronger conviction in a move.',
        'Low volume can signal weak breakouts.',
        'Volume spikes often occur near turning points.',
      ],
      image: 'assets/images/indicators/volume.png',
      useCase:
          'Use volume to validate breakouts and avoid low-conviction price moves.',
      difficulty: 'Basic',
    ),
    IndicatorModel(
      id: 'indicator_bollinger_bands',
      title: 'Bollinger Bands',
      definition:
          'Bollinger Bands wrap price with a moving average and volatility-based upper and lower bands.',
      keyPoints: [
        'Bands widen during high volatility.',
        'Bands tighten during low volatility squeezes.',
        'Price touching a band is context, not an automatic signal.',
      ],
      image: 'assets/images/indicators/bollinger_bands.png',
      useCase:
          'Use band squeezes to anticipate expansion and pair with trend confirmation.',
      difficulty: 'Basic',
    ),
    IndicatorModel(
      id: 'indicator_zigzag',
      title: 'ZigZag',
      definition:
          'ZigZag filters small price moves and highlights major swing highs and lows.',
      keyPoints: [
        'Helps visualize market structure clearly.',
        'Not predictive by itself.',
        'Best for studying trend legs and corrections.',
      ],
      image: 'assets/images/indicators/zigzag.png',
      useCase:
          'Use ZigZag to map clear swing points before drawing support and resistance.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_moving_average',
      title: 'Moving Average',
      definition:
          'A Moving Average smooths price data to reveal direction over time.',
      keyPoints: [
        'Price above MA often signals bullish bias.',
        'Price below MA often signals bearish bias.',
        'Longer periods are smoother but lag more.',
      ],
      image: 'assets/images/indicators/moving_average.png',
      useCase: 'Use a moving average as a trend filter before taking setups.',
      difficulty: 'Basic',
    ),
    IndicatorModel(
      id: 'indicator_sma',
      title: 'Simple Moving Average (SMA)',
      definition:
          'SMA is the arithmetic mean of closing prices over a fixed period.',
      keyPoints: [
        'Simple and widely used trend benchmark.',
        'Responds slower than EMA.',
        'Popular periods include 20, 50, and 200.',
      ],
      image: 'assets/images/indicators/sma.png',
      useCase:
          'Use SMA to track broad trend direction and dynamic support/resistance.',
      difficulty: 'Basic',
    ),
    IndicatorModel(
      id: 'indicator_ema',
      title: 'Exponential Moving Average (EMA)',
      definition:
          'EMA gives more weight to recent prices, reacting faster than SMA.',
      keyPoints: [
        'Useful for shorter-term trend tracking.',
        'Can generate more frequent signals than SMA.',
        'Often combined in crossover systems.',
      ],
      image: 'assets/images/indicators/ema.png',
      useCase:
          'Use EMA for faster trend updates and pullback entries in momentum markets.',
      difficulty: 'Basic',
    ),
    IndicatorModel(
      id: 'indicator_macd',
      title: 'MACD',
      definition:
          'MACD compares two EMAs and uses a signal line to show momentum shifts.',
      keyPoints: [
        'MACD line crossing signal line can indicate momentum change.',
        'Histogram visualizes momentum expansion and contraction.',
        'Divergence can warn of weakening trend.',
      ],
      image: 'assets/images/indicators/macd.png',
      useCase:
          'Use MACD to confirm trend continuation or potential reversal momentum.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_stochastic',
      title: 'Stochastic Oscillator',
      definition:
          'Stochastic compares close price to recent high-low range to measure momentum.',
      keyPoints: [
        'Often interpreted with 80/20 zones.',
        'Crossovers can trigger momentum signals.',
        'Works best in ranges when paired with trend context.',
      ],
      image: 'assets/images/indicators/stochastic.png',
      useCase:
          'Use stochastic to time entries in consolidation and pullback phases.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_adx',
      title: 'ADX',
      definition:
          'Average Directional Index measures trend strength, not direction.',
      keyPoints: [
        'Higher ADX means stronger trend conditions.',
        'Lower ADX suggests ranging or weak trend.',
        'Often used with +DI and -DI for directional context.',
      ],
      image: 'assets/images/indicators/adx.png',
      useCase:
          'Use ADX to decide whether to apply trend-following or mean-reversion tactics.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_atr',
      title: 'ATR',
      definition:
          'Average True Range estimates average volatility over a period.',
      keyPoints: [
        'Higher ATR means larger average price movement.',
        'ATR does not indicate direction.',
        'Commonly used for stop-loss and position sizing.',
      ],
      image: 'assets/images/indicators/atr.png',
      useCase: 'Use ATR to set adaptive stops and reduce noise-based exits.',
      difficulty: 'Basic',
    ),
    IndicatorModel(
      id: 'indicator_vwap',
      title: 'VWAP',
      definition:
          'Volume Weighted Average Price tracks average traded price weighted by volume.',
      keyPoints: [
        'Common intraday benchmark for institutions.',
        'Price above VWAP can imply bullish intraday control.',
        'VWAP pullbacks are used for trend entries.',
      ],
      image: 'assets/images/indicators/vwap.png',
      useCase: 'Use VWAP for intraday bias and pullback confirmation.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_obv',
      title: 'OBV',
      definition:
          'On-Balance Volume adds or subtracts volume based on close direction to track accumulation.',
      keyPoints: [
        'Rising OBV can support bullish continuation.',
        'Falling OBV can support bearish continuation.',
        'Divergence with price may signal trend fatigue.',
      ],
      image: 'assets/images/indicators/obv.png',
      useCase:
          'Use OBV to validate whether volume supports current price trend.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_cci',
      title: 'CCI',
      definition:
          'Commodity Channel Index measures deviation from statistical average price.',
      keyPoints: [
        'Above +100 can indicate strong bullish momentum.',
        'Below -100 can indicate strong bearish momentum.',
        'Useful for spotting momentum extremes.',
      ],
      image: 'assets/images/indicators/cci.png',
      useCase: 'Use CCI to identify momentum bursts and reversal candidates.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_mfi',
      title: 'MFI',
      definition:
          'Money Flow Index combines price and volume to estimate buying and selling pressure.',
      keyPoints: [
        'Works like volume-weighted RSI.',
        'Overbought and oversold zones are commonly 80/20.',
        'Divergence can hint at potential reversals.',
      ],
      image: 'assets/images/indicators/mfi.png',
      useCase:
          'Use MFI when volume context is important for momentum decisions.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_parabolic_sar',
      title: 'Parabolic SAR',
      definition:
          'Parabolic SAR plots trailing points to indicate trend direction and stop placement.',
      keyPoints: [
        'Dots below price suggest uptrend.',
        'Dots above price suggest downtrend.',
        'Can whipsaw in sideways markets.',
      ],
      image: 'assets/images/indicators/parabolic_sar.png',
      useCase:
          'Use SAR for trend trailing stops, especially in strong directional moves.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_fibonacci_retracement',
      title: 'Fibonacci Retracement',
      definition:
          'Fibonacci Retracement marks potential pullback levels based on key mathematical ratios.',
      keyPoints: [
        'Common levels include 38.2%, 50%, and 61.8%.',
        'Works best with trend context and confluence.',
        'Not a standalone entry trigger.',
      ],
      image: 'assets/images/indicators/fibonacci_retracement.png',
      useCase:
          'Use Fibonacci levels to plan pullback entries in trending markets.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_ichimoku',
      title: 'Ichimoku Cloud',
      definition:
          'Ichimoku combines trend, momentum, and support-resistance into one multi-line system.',
      keyPoints: [
        'Cloud color and position indicate trend state.',
        'Tenkan/Kijun crosses signal momentum shifts.',
        'Future cloud helps frame potential support and resistance.',
      ],
      image: 'assets/images/indicators/ichimoku_cloud.png',
      useCase:
          'Use Ichimoku for all-in-one trend structure and signal confirmation.',
      difficulty: 'Advanced',
    ),
    IndicatorModel(
      id: 'indicator_supertrend',
      title: 'Supertrend',
      definition:
          'Supertrend uses ATR to build a directional trend line that flips on volatility-adjusted breaks.',
      keyPoints: [
        'Green mode often indicates bullish trend.',
        'Red mode often indicates bearish trend.',
        'ATR settings control sensitivity.',
      ],
      image: 'assets/images/indicators/supertrend.png',
      useCase:
          'Use Supertrend as a simple trend-following filter with adaptive stops.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_keltner',
      title: 'Keltner Channels',
      definition:
          'Keltner Channels wrap an EMA with ATR-based envelopes to show volatility-adjusted ranges.',
      keyPoints: [
        'Channel expansion reflects volatility increase.',
        'Breakouts beyond channel can indicate momentum.',
        'Useful when paired with trend filters.',
      ],
      image: 'assets/images/indicators/keltner_channels.png',
      useCase:
          'Use Keltner channels for breakout structure and pullback context.',
      difficulty: 'Advanced',
    ),
    IndicatorModel(
      id: 'indicator_donchian',
      title: 'Donchian Channels',
      definition:
          'Donchian Channels track highest high and lowest low over a rolling period.',
      keyPoints: [
        'Upper and lower bands define breakout boundaries.',
        'Useful in trend-following systems.',
        'Longer periods reduce false breaks.',
      ],
      image: 'assets/images/indicators/donchian_channels.png',
      useCase:
          'Use Donchian breakouts to catch trend continuation after consolidations.',
      difficulty: 'Advanced',
    ),
    IndicatorModel(
      id: 'indicator_hma',
      title: 'Hull Moving Average',
      definition:
          'Hull MA is designed to reduce lag while keeping smooth trend tracking.',
      keyPoints: [
        'More responsive than many standard moving averages.',
        'Can react quickly to short-term trend changes.',
        'May produce extra noise in choppy markets.',
      ],
      image: 'assets/images/indicators/hull_moving_average.png',
      useCase:
          'Use HMA when you need faster trend adaptation with moderate smoothing.',
      difficulty: 'Advanced',
    ),
    IndicatorModel(
      id: 'indicator_roc',
      title: 'Rate of Change (ROC)',
      definition:
          'ROC measures percentage change in price over a selected period.',
      keyPoints: [
        'Positive values indicate upward momentum.',
        'Negative values indicate downward momentum.',
        'Crossing zero can suggest momentum regime shifts.',
      ],
      image: 'assets/images/indicators/roc.png',
      useCase:
          'Use ROC to detect acceleration or deceleration in trend momentum.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_williams_r',
      title: 'Williams %R',
      definition:
          'Williams %R shows where price closes relative to recent high-low range.',
      keyPoints: [
        'Commonly interpreted with -20 and -80 levels.',
        'Can flag momentum extremes in ranges.',
        'Best used with trend context to avoid false reversals.',
      ],
      image: 'assets/images/indicators/williams_r.png',
      useCase:
          'Use Williams %R to time entries around short-term momentum exhaustion.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_pivot_points',
      title: 'Pivot Points',
      definition:
          'Pivot Points calculate potential intraday support and resistance levels from prior prices.',
      keyPoints: [
        'Includes central pivot plus support/resistance bands.',
        'Widely followed in intraday markets.',
        'Works best with price action confirmation.',
      ],
      image: 'assets/images/indicators/pivot_points.png',
      useCase:
          'Use pivot levels to plan reaction zones and target levels for intraday trades.',
      difficulty: 'Basic',
    ),
    IndicatorModel(
      id: 'indicator_volume_profile',
      title: 'Volume Profile',
      definition:
          'Volume Profile shows traded volume distribution by price, not by time.',
      keyPoints: [
        'High-volume nodes can act as acceptance zones.',
        'Low-volume nodes can indicate potential fast-move zones.',
        'Point of Control marks the most traded price level.',
      ],
      image: 'assets/images/indicators/volume_profile.png',
      useCase:
          'Use volume profile to identify high-probability support and resistance zones.',
      difficulty: 'Advanced',
    ),
    IndicatorModel(
      id: 'indicator_atr_trailing_stop',
      title: 'ATR Trailing Stop',
      definition:
          'ATR trailing stop adjusts stop distance based on current volatility.',
      keyPoints: [
        'Expands in high volatility to avoid premature exits.',
        'Tightens in low volatility to protect gains.',
        'Popular for trend-following position management.',
      ],
      image: 'assets/images/indicators/atr_trailing_stop.png',
      useCase:
          'Use ATR trailing stop to protect trend trades while reducing noise exits.',
      difficulty: 'Advanced',
    ),
    IndicatorModel(
      id: 'indicator_heikin_ashi',
      title: 'Heikin Ashi',
      definition:
          'Heikin Ashi uses modified candle calculations to smooth trend visualization.',
      keyPoints: [
        'Reduces noise versus standard candlesticks.',
        'Consecutive same-color candles highlight trend persistence.',
        'Can lag reversals compared to normal candles.',
      ],
      image: 'assets/images/indicators/heikin_ashi.png',
      useCase:
          'Use Heikin Ashi to stay in trends longer and filter minor pullbacks.',
      difficulty: 'Basic',
    ),
    IndicatorModel(
      id: 'indicator_trix',
      title: 'TRIX',
      definition:
          'TRIX is a triple-smoothed momentum oscillator that reduces short-term noise.',
      keyPoints: [
        'Zero-line crosses can suggest momentum direction changes.',
        'Smoother than many momentum oscillators.',
        'Useful in medium-term trend studies.',
      ],
      image: 'assets/images/indicators/trix.png',
      useCase:
          'Use TRIX for cleaner momentum tracking in trending instruments.',
      difficulty: 'Advanced',
    ),
    IndicatorModel(
      id: 'indicator_dmi',
      title: 'DMI (+DI / -DI)',
      definition:
          'Directional Movement Index uses +DI and -DI lines to estimate directional pressure.',
      keyPoints: [
        'When +DI is above -DI, buyers are stronger.',
        'When -DI is above +DI, sellers are stronger.',
        'Often paired with ADX strength reading.',
      ],
      image: 'assets/images/indicators/dmi.png',
      useCase:
          'Use DMI with ADX to align entries with stronger directional pressure.',
      difficulty: 'Intermediate',
    ),
    IndicatorModel(
      id: 'indicator_elder_ray',
      title: 'Elder Ray Index',
      definition:
          'Elder Ray separates buying power and selling power relative to a moving average.',
      keyPoints: [
        'Bull power tracks pressure above EMA.',
        'Bear power tracks pressure below EMA.',
        'Helps evaluate trend strength quality.',
      ],
      image: 'assets/images/indicators/elder_ray.png',
      useCase:
          'Use Elder Ray to confirm whether pullbacks still support broader trend direction.',
      difficulty: 'Advanced',
    ),
  ];

  List<IndicatorModel> getIndicators() {
    return List<IndicatorModel>.from(_indicators);
  }
}
