import 'dart:async';
import 'dart:io';

import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/helper/global_widget.dart';
import 'package:appkioskcoex/pages/login_event_page.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// SplashScreen.java -> activity_splash_screen.xml
class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  //Set waktu lama splashscreen
  static const int timeSplash = 3000;

  String appVersion = "V.1.0";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    setNormalScreen();

    deleteCache();

    delay();

    // binding.tvVersion.setText("V " + BuildConfig.VERSION_NAME)
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => appVersion = "V ${info.version}");
    });
  }

  void delay() {
    _timer = Timer(const Duration(milliseconds: timeSplash), () {
      if (!mounted) return;
      // FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_NO_ANIMATION + finish()
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const LoginEventPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    });
  }

  static Future<void> deleteCache() async {
    try {
      final dir = await getTemporaryDirectory();
      await deleteDir(dir);
    } catch (e) {
      // diabaikan
    }
  }

  static Future<bool> deleteDir(Directory dir) async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Image.asset('assets/images/logo_kreen.png', width: dsdp(200), height: dsdp(70)),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: dsdp(20)),
              child: Column(
                children: [
                  // FrogoLoadingIndicatorView BallPulseIndicator (__50sdp, colorPrimary)
                  SizedBox(width: dsdp(50), height: dsdp(50), child: const BallPulseIndicator(color: colorPrimary)),
                  SizedBox(height: dsdp(20)),
                  AText(appVersion, font: AFont.bold, size: dssp(20), color: textPrimary, bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// BallPulseIndicator (frogo-loading-indicator-view)
class BallPulseIndicator extends StatefulWidget {
  final Color color;

  const BallPulseIndicator({super.key, required this.color});

  @override
  State<BallPulseIndicator> createState() => _BallPulseIndicatorState();
}

class _BallPulseIndicatorState extends State<BallPulseIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 750))..repeat();

  // BallPulseIndicator: delays = {120, 240, 360}, scale 1 -> 0.3 -> 1 dalam 750ms
  static const List<int> delays = [120, 240, 360];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  double _scale(int delayMs) {
    final t = ((controller.value * 750 - delayMs) % 750) / 750;
    return t < 0.3 ? 1 - (0.7 * t / 0.3) : 0.3 + 0.7 * ((t - 0.3) / 0.7);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      const circleSpacing = 4.0;
      final radius = (width - circleSpacing * 2) / 6;
      return AnimatedBuilder(
        animation: controller,
        builder: (_, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final d in delays)
              Transform.scale(
                scale: _scale(d),
                child: Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      );
    });
  }
}
