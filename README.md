# EmoSense AI

EmoSense AI is a Flutter app for facial emotion analysis, with Firebase sign-in, saved analysis history, insights, and AI chat.

## Architecture

The app follows a feature-first MVVM structure. Each feature owns its presentation layer, while shared state, services, app navigation, and theme remain in dedicated shared folders.

```text
lib/
├── app/                 # Routes and app navigation
├── core/                # Shared constants, services, state, and theme
├── features/            # Feature-owned code
│   └── <feature>/
│       ├── data/         # Feature data sources/content
│       ├── models/       # Feature data models
│       └── presentation/
│           ├── screens/  # Screen widgets
│           ├── viewmodels/ # UI state and presentation logic
│           └── widgets/  # Feature-specific UI components
├── ml/                  # On-device emotion classification
└── main.dart             # App entry point

assets/                  # Branding, animations, and model files
functions/               # Firebase Cloud Functions
```

## Android

```powershell
flutter pub get
flutter run
flutter build apk --release
```

The release APK is written to `build/app/outputs/flutter-apk/app-release.apk`.
