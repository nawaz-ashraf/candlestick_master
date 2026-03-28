# Candlestick Master (Flutter)

Candlestick Master is a habit-based, gamified learning app for candlestick pattern mastery.
It keeps the original learning and quiz functionality and extends it with XP, streaks, daily challenges, revision loops, and modular retention systems.

## Core Product Loops

- Daily habit loop: Home -> Continue Learning -> Lesson -> Quiz -> Reward -> Streak update
- Retention loop: Daily challenge reminders + streak risk reminders
- Revision loop: Wrong answers are stored and replayed in Practice Mistakes
- Monetization loop: Rewarded ad (+100 coins) and session-based interstitial structure

## Feature Highlights

- Pattern Library with categorized patterns and pattern detail pages
- Lesson Session flow with image, title, 3-4 bullet insights, and Next progression
- Quiz mode with instant feedback, score, accuracy, and XP-earned result view
- Daily Challenge (5 deterministic questions/day) with once-per-day rewards
- Streak system with best streak tracking and missed-day reset behavior
- Profile hub with level, XP, coins, achievements, and revision shortcut
- Local persistence via SharedPreferences and SQL progress history for quiz mastery
- Local notification reminders and modular FCM tap routing support

## Tech Stack

- Flutter (null-safe)
- State Management: Provider
- Navigation: GoRouter
- Local Storage: SharedPreferences + sqflite
- Notifications: flutter_local_notifications + Firebase Messaging
- Monetization: google_mobile_ads

## Project Structure

```text
lib/
├── core/
│   ├── constants/
│   │   └── reward_constants.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── services/
│   │   ├── ad_service.dart
│   │   ├── fcm_service.dart
│   │   ├── local_notification_service.dart
│   │   ├── purchase_service.dart
│   │   └── storage_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── date_utils.dart
├── data/
├── domain/
├── features/
│   ├── challenge/
│   ├── home/
│   ├── learn/
│   ├── profile/
│   ├── quiz/
│   └── revision/
├── models/
│   ├── habit_user_progress.dart
│   ├── pattern_model.dart
│   ├── quiz_question.dart
│   └── user_progress.dart
├── providers/
├── widgets/
└── main.dart
```

## Reward Rules

- Lesson completion: +10 XP
- Correct quiz answer: +20 XP
- Daily challenge completion: +30 XP and +50 coins
- Rewarded ad: +100 coins
- Level formula: `level = xp ~/ 100`

## Startup Integration

`main.dart` initializes systems in this order:

1. Firebase core
2. AdService initialize + session start
3. FCMService initialize (with router callback)
4. Local notifications initialize + schedule daily reminders
5. Provider notifiers initialize and load persisted state

## Daily Challenge Behavior

- Uses deterministic date seed so users get a stable 5-question challenge per day
- Marks completion by date key (`yyyy-MM-dd`)
- Reward can only be claimed once per day

## Ad Behavior

- Rewarded ads are available from Profile
- Interstitials are session-gated and tracked in SharedPreferences
- Quiz flow does not show ads during question answering or result

## Run Locally

```bash
flutter pub get
flutter run
```

## Tests

Run all tests:

```bash
flutter test
```

Added notifier tests validate:

- persistence across restarts
- daily reset behavior
- streak update logic
- XP/reward math correctness
- malformed/null persisted data safety
