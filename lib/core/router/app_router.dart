// =============================================================================
// App Router - Navigation & Deep Link Configuration
// =============================================================================
// Manages all navigation routes including deep link handling for marketing.
// Deep links allow users to share patterns and be linked from ads/campaigns.
//
// Deep Link Format: https://candlestickmaster.app/pattern/{id}
// TODO: Update domain when production domain is configured
// =============================================================================

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/pattern_model.dart';
import '../../data/models/quiz_settings.dart';
import '../../presentation/providers/pattern_notifier.dart';
import '../../presentation/screens/compliance/disclaimer_screen.dart';
import '../../presentation/screens/compliance/paywall_screen.dart';
import '../../presentation/screens/detail/pattern_detail_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/quiz/quiz_screen.dart';
import '../../presentation/screens/quiz/quiz_selection_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/disclaimer', // Force disclaimer check on startup
  routes: [
    // ========================================
    // Main App Routes
    // ========================================
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    /*
    GoRoute(
      path: '/library',
      builder: (context, state) => const PatternLibraryScreen(),
    ),
    */

    // ========================================
    // Pattern Detail - Supports Deep Linking
    // ========================================
    // This route handles both:
    // 1. In-app navigation (with pattern passed via `extra`)
    // 2. Deep links (pattern looked up by ID from the path)
    GoRoute(
      path: '/pattern/:id',
      builder: (context, state) {
        // First, try to get the pattern from navigation extra (in-app)
        CandlestickPattern? pattern;
        if (state.extra is CandlestickPattern) {
          pattern = state.extra as CandlestickPattern;
        } else if (state.extra is Map<String, dynamic>) {
          pattern =
              CandlestickPattern.fromJson(state.extra as Map<String, dynamic>);
        }

        if (pattern != null) {
          return PatternDetailScreen(pattern: pattern);
        }

        // If no extra, this is a deep link - look up by ID
        final patternId = state.pathParameters['id'];
        if (patternId != null) {
          final patternsNotifier = context.read<PatternsNotifier>();
          final foundPattern = patternsNotifier.getPatternById(patternId);

          if (foundPattern != null) {
            return PatternDetailScreen(pattern: foundPattern);
          }
        }

        // Pattern not found - redirect to home
        // This handles invalid deep links gracefully
        return const HomeScreen();
      },
    ),

    // ========================================
    // Quiz Routes
    // ========================================
    GoRoute(
      path: '/quiz/select',
      builder: (context, state) => const QuizSelectionScreen(),
    ),
    GoRoute(
      path: '/quiz',
      builder: (context, state) {
        final settings = state.extra as QuizSettings?;
        return QuizScreen(settings: settings);
      },
    ),

    // ========================================
    // Compliance Routes
    // ========================================
    GoRoute(
      path: '/disclaimer',
      builder: (context, state) => const DisclaimerScreen(),
    ),
    GoRoute(
      path: '/paywall',
      builder: (context, state) => const PaywallScreen(),
    ),
  ],
);
