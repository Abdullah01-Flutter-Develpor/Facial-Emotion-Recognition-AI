# EmoSense AI

EmoSense AI is a Flutter app for facial emotion analysis, with Firebase sign-in, saved analysis history, insights, and AI chat.

## Project layout

- `lib/app/` — app routes and navigation
- `lib/core/` — shared services, state, constants, and theme
- `lib/features/` — feature screens and their widgets/models
- `lib/ml/` — emotion classification integration
- `assets/branding/` — app logo and launcher artwork
- `assets/animation/` — Lottie animations
- `assets/models/` — on-device ONNX model
- `functions/` — Firebase Cloud Functions source
- `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` — Flutter platform projects

## Run or build for Android

```powershell
flutter pub get
flutter run
flutter build apk --release
```

The release APK is written to `build/app/outputs/flutter-apk/app-release.apk`.
