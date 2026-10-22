import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_widget.dart';
import 'package:flutter/material.dart';

/// MainActivity.java -> activity_main.xml
///
/// Activity kosong "Hello World!" yang dibuka ScannersActivity2 setelah scanner terhubung /
/// gagal terhubung, dan dari onBackPressed() saat ada scanner terhubung.
/// (Tidak override onWindowFocusChanged -> status bar & navigation bar tampil.)
class MainActivityPage extends StatefulWidget {
  const MainActivityPage({super.key});

  @override
  State<MainActivityPage> createState() => _MainActivityPageState();
}

class _MainActivityPageState extends State<MainActivityPage> {
  @override
  void initState() {
    super.initState();
    setNormalScreen();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Center(child: AText("Hello World!", size: 14))),
    );
  }
}
