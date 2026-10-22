import 'dart:async';

import 'package:vibration/vibration.dart';

/// ManagedVibrator.java
class ManagedVibrator {
  bool _isVibrating = false;
  Timer? _end;

  Future<bool> hasVibrator() => Vibration.hasVibrator();

  void vibrate(int milliseconds) {
    _setVibrating(true);
    Vibration.vibrate(duration: milliseconds);
    _notifyOnVibrationEnd(milliseconds);
  }

  /// vibrate(long[] pattern, int repeat [, AudioAttributes]) (repeat >= 0 -> berulang)
  void vibratePattern(List<int> pattern, int repeat) {
    _setVibrating(true);
    Vibration.vibrate(pattern: pattern, repeat: repeat);
  }

  void cancel() {
    Vibration.cancel();
    _setVibrating(false);
  }

  bool isVibrating() => _isVibrating;

  void _setVibrating(bool isVibrating) => _isVibrating = isVibrating;

  void _notifyOnVibrationEnd(int milliseconds) {
    _end?.cancel();
    _end = Timer(Duration(milliseconds: milliseconds), () => _setVibrating(false));
  }
}
