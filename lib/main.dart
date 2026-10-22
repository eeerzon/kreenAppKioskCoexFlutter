import 'dart:async';
import 'dart:ui';

import 'package:appkioskcoex/helper/foreground.dart';
import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/pages/splash_screen_page.dart';
import 'package:appkioskcoex/services/lang_service.dart';
import 'package:appkioskcoex/services/scanner_app_engine.dart';
import 'package:appkioskcoex/services/storage_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Analytics + Crashlytics (google-services)
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await StorageService.init();
  await LangService.preload();

  // AppCompat.onCreate: LanguageManager.updateResources(languageManager.getLang())
  LangService.updateResources(StorageService.getLang());

  // Application.onCreate: Foreground.init(this)
  Foreground.init();

  // Application.onCreate: sdkHandler = new SDKHandler(this, true)
  unawaited(ScannerAppEngine.init());

  // Theme.KreenAppKioskCoex: android:statusBarColor = ?attr/colorPrimaryVariant
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: colorPrimaryVariant,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KIOSKreen',
      debugShowCheckedModeBanner: false,
      // Theme.MaterialComponents.Light.NoActionBar
      theme: ThemeData(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(seedColor: colorPrimary).copyWith(
          primary: colorPrimary,
          primaryContainer: colorPrimaryVariant,
          onPrimary: white,
          secondary: colorSecondary,
          secondaryContainer: colorSecondaryVariant,
          onSecondary: black,
          surface: white,
        ),
        scaffoldBackgroundColor: white,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: colorPrimary,
          selectionHandleColor: colorPrimary,
        ),
      ),
      navigatorObservers: [activityRouteObserver],
      builder: (context, child) {
        initSdp(context);
        final media = MediaQuery.of(context);
        // ukuran teks diset dalam dp (alias __Nssp -> _Msdp); ukuran "sp" dikali skala font sistem manual
        setSystemTextScale(media.textScaler.scale(100) / 100);
        return MediaQuery(data: media.copyWith(textScaler: TextScaler.noScaling), child: child!);
      },
      home: const SplashScreenPage(),
    );
  }
}
