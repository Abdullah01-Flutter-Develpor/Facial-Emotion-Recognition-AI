import 'package:demo_app/core/theme/app_theme.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app_routes.dart';
import 'app/app_pages.dart';
import 'core/state/analysis_scope.dart';
import 'core/state/analysis_store.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
  } else if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    await FirebaseAppCheck.instance.activate(
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  }

  final store = AnalysisStore();
  await store.load();

  runApp(EmotionApp(store: store));
}

class EmotionApp extends StatelessWidget {
  const EmotionApp({super.key, required this.store});

  final AnalysisStore store;

  @override
  Widget build(BuildContext context) {
    return AnalysisScope(
      store: store,
      child: MaterialApp(
        title: 'EmoSense AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: AppRoutes.splash,
        routes: AppPages.routes,
      ),
    );
  }
}
