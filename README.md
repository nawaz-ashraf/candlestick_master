# Candlestick Master - Learn & Trade (Flutter)

A comprehensive educational app for learning candlestick patterns, testing knowledge with quizzes, and practicing on interactive charts. Built with Flutter for Android (Target API 35).

## 🚀 Features
*   **Pattern Library**: 40+ patterns extracted from expert material, categorized by difficulty and trend bias.
*   **Quiz Mode**: Dynamic quizzes with scoring, streaks, and mastery tracking.
*   **Interactive Charts**: Real-time candlestick chart simulation with pinch-to-zoom.
*   **Pattern Detection**: Rule-based engine to detect patterns (Hammer, Engulfing, etc.) on the chart.
*   **Progress Tracking**: Local database to track attempts and accuracy.
*   **Premium**: Subscription logic for Ad-removal and advanced features.

## 🛠 Tech Stack
*   **Framework**: Flutter (Dart)
*   **State Management**: Riverpod
*   **Database**: sqflite (Local), Shared Preferences
*   **Navigation**: GoRouter
*   **Charts**: candlesticks package
*   **Architecture**: Clean Architecture (Layered: Presentation, Domain, Data)

## 📂 Project Structure
```
lib/
├── core/
│   ├── router/          # App navigation config
│   ├── theme/           # App colors and styles
│   └── services/        # External services (FCM, IAP)
├── data/
│   ├── datasources/     # Mock data, Asset loading
│   ├── models/          # Data classes (JSON/DB mappers)
│   └── repositories/    # Data access logic
├── domain/
│   ├── detection/       # Pattern recognition engine
│   └── logic/           # Business logic (Quiz generation)
└── presentation/
    ├── providers/       # Riverpod providers
    └── screens/         # UI Screens (Home, Library, Quiz, Chart)
assets/
    ├── patterns.json    # Extracted pattern data
    └── images/patterns/ # Generated pattern images
```

## ⚙️ Setup Instructions

### Prerequisites
*   Flutter SDK (Latest Stable)
*   Android Studio / VS Code
*   Python 3 (for data extraction scripts, optional)

### Installation
1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/candlestick-master.git
    cd candlestick-master
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the App**:
    ```bash
    flutter run
    ```

### Data Pipeline (Optional)
If you need to regenerate the pattern data from a new PDF:
1.  Place the PDF in the root directory.
2.  Run the extraction script:
    ```bash
    source ../formatted_venv/bin/activate
    python ../extract_patterns_v3.py
    ```
3.  Copy `patterns.json` and images to `assets/`.

## 📦 Building for Release
1.  **Update Version**: Update `pubspec.yaml`.
2.  **Sign App**: Configure `key.properties` and `build.gradle`.
3.  **Build Bundle**:
    ```bash
    flutter build appbundle
    ```
4.  Upload the `.aab` file to Google Play Console.

## 🤝 Contribution
1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## ⚠️ Disclaimer
This app is for educational purposes only. It does not provide financial advice. Trading carries risk.
