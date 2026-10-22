import 'package:appkioskcoex/helper/global_var.dart';
import 'package:flutter/material.dart';

/// utils/common/CustomProgressDialogue (Dialog + layout custom_progress).
///
/// show() / hide() / dismiss() boleh dipanggil berulang seperti Dialog Android:
/// show() saat sudah tampil tidak menumpuk, hide() saat tidak tampil tidak berbuat apa-apa.
class CustomProgressDialogue {
  final BuildContext context;
  final bool cancelable;
  Route<void>? _route;

  CustomProgressDialogue(this.context, {this.cancelable = true});

  bool get isShowing => _route != null;

  void show() {
    if (_route != null || !context.mounted) return;
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: cancelable,
      barrierColor: const Color(0x99000000),
      useSafeArea: false,
      builder: (_) => PopScope(
        canPop: cancelable,
        child: Center(
          child: Container(
            color: white,
            // custom_progress.xml: android:padding="10dp"
            padding: const EdgeInsets.all(10),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(color: colorPrimary, strokeWidth: 4),
            ),
          ),
        ),
      ),
    );
    _route = route;
    Navigator.of(context, rootNavigator: true).push(route).then((_) {
      if (identical(_route, route)) _route = null;
    });
  }

  void hide() {
    final route = _route;
    if (route == null) return;
    _route = null;
    if (route.isActive) {
      Navigator.of(context, rootNavigator: true).removeRoute(route);
    }
  }

  void dismiss() => hide();
}

/// utils/common/CustomProgressDialogue2 (layout custom_progress yang sama, window immersive)
typedef CustomProgressDialogue2 = CustomProgressDialogue;
