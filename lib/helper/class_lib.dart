// ignore_for_file: non_constant_identifier_names

import 'dart:math';

import 'package:appkioskcoex/helper/global_function.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

/// utils/ClassLib.java
///
/// Fungsi yang bergantung langsung ke View Android (convertHTML + MyTagHandler, setTextViewHTML,
/// drawable_changecolor, calculateHashKey, deviceOnWifi) tidak diport karena tidak dipakai di app asli.
class ClassLib {
  static int konv_str_int(String s) => int.parse(s.replaceAll(RegExp(r'[\D]'), ''));

  static String konv_int_str(int i) => i.toString();

  static String konv_double_str(double d) => d.toString();

  static int konv_double_int(double d) => d.round();

  static double konv_string_double(String s) => double.parse(s);

  static int konv_string_long(String s) => int.parse(s);

  static String currencyFormat(String amount) => NumberFormat("###,###").format(double.parse(amount));

  static String ramdon(int jml, String isiString, String tbh) => ramdonString(jml, isiString, tbh);

  static String int_ramdon(int min, int max) => (Random().nextInt(max - min + 1) + min).toString();

  static String str_enter(String str, int length) {
    final sb = str.split('');
    int i = 0;
    while (true) {
      final from = i + length;
      if (from > sb.length) break;
      final idx = sb.join().indexOf(" ", from);
      if (idx == -1) break;
      sb[idx] = "\n";
      i = idx;
    }
    return sb.join();
  }

  static int time_out() => 10000;

  static int random_number_minmax(int min, int max) => Random().nextInt(max - min + 1) + min;

  static bool isNumeric(String str) => RegExp(r'^-?\d+(.\d+)?$').hasMatch(str);

  static String terbilang(int angka) {
    const nomina = ["", "Satu", "Dua", "Tiga", "Empat", "Lima", "Enam", "Tujuh", "Delapan", "Sembilan", "Sepuluh",
        "Sebelas"];
    if (angka < 12) return nomina[angka];
    if (angka >= 12 && angka <= 19) return "${nomina[angka % 10]} Belas ";
    if (angka >= 20 && angka <= 99) return "${nomina[angka ~/ 10]} Puluh ${nomina[angka % 10]}";
    if (angka >= 100 && angka <= 199) return "Seratus ${terbilang(angka % 100)}";
    if (angka >= 200 && angka <= 999) return "${nomina[angka ~/ 100]} Ratus ${terbilang(angka % 100)}";
    if (angka >= 1000 && angka <= 1999) return "Seribu ${terbilang(angka % 1000)}";
    if (angka >= 2000 && angka <= 999999) return "${terbilang(angka ~/ 1000)} Ribu ${terbilang(angka % 1000)}";
    if (angka >= 1000000 && angka <= 999999999) {
      return "${terbilang(angka ~/ 1000000)} Juta ${terbilang(angka % 1000000)}";
    }
    return "";
  }

  static String formateDateFromstring(String inputFormat, String outputFormat, String inputDate) {
    try {
      return DateFormat(outputFormat).format(DateFormat(inputFormat).parse(inputDate));
    } catch (e) {
      return "";
    }
  }

  static int dpToPx(int dp) => (dp * devicePixelRatio).toInt();

  static int pxToDp(int px) => px ~/ devicePixelRatio;

  static String? _format(String date, String to) {
    try {
      return DateFormat(to, 'en_US').format(DateFormat("yyyy-MM-dd", 'en_US').parse(date));
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  static String? format_date1(String date) => _format(date, "dd MMMM yyyy");

  static String? format_date2(String date) => _format(date, "EEE, dd MMMM yyyy");

  /// catatan: app asli selalu menambah 40 hari (parameter day tidak dipakai)
  static String add_date(String date, int day) {
    DateTime c = DateTime.now();
    try {
      c = DateFormat("yyyy-MM-dd").parse(date);
    } catch (e) {
      debugPrint(e.toString());
    }
    c = c.add(const Duration(days: 40));
    return DateFormat("yyyy-MM-dd").format(c);
  }

  static String ucWords(String sentence) {
    final sentence1 = sentence.toLowerCase();
    final sb = StringBuffer();
    for (final word in sentence1.split(" ")) {
      sb.write("${word[0].toUpperCase()}${word.substring(1)} ");
    }
    return sb.toString().trim();
  }

  static String ucFirstWord(String sentence) {
    final sentence1 = sentence.toLowerCase();
    return sentence1[0].toUpperCase() + sentence1.substring(1);
  }

  static String urlValid(String url) => url.replaceAll(" ", "%20");

  /// shakeError(context): getar 50ms (animasi TranslateAnimation dipasang oleh pemanggil)
  static Future<void> shakeError() => Vibration.vibrate(duration: 50);

  static Future<void> openBrowser(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  static List<String> stringFormatedToStringList(String s) =>
      s.substring(1, s.length - 1).replaceAll("\"", "").split(",");

  static String capitizeString(String name) {
    if (name.trim().isEmpty) return "";
    return name.substring(0, 1).toUpperCase() + name.substring(1);
  }

  static String toTheUpperCase(String givenString) {
    final sb = StringBuffer();
    for (final s in givenString.split(" ")) {
      sb.write("${s[0].toUpperCase()}${s.substring(1)} ");
    }
    return sb.toString().trim();
  }

  static String toTheUpperCaseSingle(String givenString) =>
      givenString.substring(0, 1).toUpperCase() + givenString.substring(1);

  static bool IsValidUrl(String urlString) {
    final uri = Uri.tryParse(urlString);
    return uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }

  /// scrollToViewTop / nestedscrollToViewTop (delay 100ms lalu smooth scroll)
  static void scrollToViewTop(ScrollController scroll, double childTop) {
    Future.delayed(const Duration(milliseconds: 100), () {
      scroll.animateTo(childTop, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  static void scrollToViewBottom(ScrollController scroll, double childBottom) {
    Future.delayed(const Duration(milliseconds: 100), () {
      scroll.animateTo(childBottom, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  /// phone62: catatan app asli: hasil phone.replace(...) tidak disimpan, regex "/[^+0-9]/" tidak pernah match.
  static String phone62(String phone) {
    String sPhone = "";
    if (phone.isNotEmpty) {
      if (phone.substring(0, 3) == "+62") {
        sPhone = phone;
      } else if (phone.substring(0, 1) == "0") {
        sPhone = "+62${phone.substring(1)}";
      }
    }
    return sPhone;
  }

  static void dismissKeyboard(BuildContext context) => dismissKeyboardOf(context);
}
