import 'package:flutter/widgets.dart';

/// helpers/Foreground.java: status app foreground/background (dipakai BaseActivity.isInBackgroundMode)
class Foreground with WidgetsBindingObserver {
  static final Foreground _instance = Foreground._();

  Foreground._();

  bool _foreground = true;

  /// Foreground.init(application)
  static void init() => WidgetsBinding.instance.addObserver(_instance);

  static Foreground get() => _instance;

  bool isForeground() => _foreground;

  bool isBackground() => !_foreground;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
  }
}
