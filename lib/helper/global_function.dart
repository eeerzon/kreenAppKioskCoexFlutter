import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// =====================================================================================
// Ukuran (com.intuit.sdp / ssp)
// =====================================================================================

/// Bucket values-swXXXdp dari library sdp: 300, 330, ..., 1080 (di bawah 300 pakai nilai default).
double _sdpFactor = 1.0;

double _dpr = 1.0;

double get devicePixelRatio => _dpr;

/// Lebar terkecil layar (dp), dipakai untuk ?attr/actionBarSize (values-sw600dp = 64dp).
double _shortestSide = 360;

void initSdp(BuildContext context) {
  _dpr = MediaQuery.devicePixelRatioOf(context);
  final sw = MediaQuery.sizeOf(context).shortestSide;
  _shortestSide = sw;
  int bucket = 300;
  for (int b = 300; b <= 1080; b += 30) {
    if (sw >= b) bucket = b;
  }
  _sdpFactor = bucket / 300.0;
}

/// ?attr/actionBarSize
double get actionBarSize => _shortestSide >= 600 ? 64 : 56;

/// @dimen/_Nsdp (dp, ikut lebar layar). Dibulatkan 2 desimal seperti di dimens.xml library.
double sdp(num n) => double.parse((n * _sdpFactor).toStringAsFixed(2));

/// @dimen/_Nssp (sp, ikut lebar layar + skala font sistem).
double ssp(num n) => sdp(n) * _systemTextScale;

double _systemTextScale = 1.0;

void setSystemTextScale(double scale) => _systemTextScale = scale;

/// N sp biasa (setTextSize(15) dsb).
double sp(num n) => n * _systemTextScale;

// res/values/dimens.xml proyek: alias "__N" -> "_M"
const Map<int, int> _sdpAlias = {
  2: 1, 3: 2, 4: 3, 5: 4, 7: 5, 8: 6, 10: 7, 12: 9, 13: 10, 14: 10, 15: 11, 16: 12, 18: 13,
  20: 15, 24: 18, 25: 19, 28: 21, 30: 23, 32: 24, 36: 27, 40: 30, 48: 37, 50: 38, 55: 42,
  60: 46, 65: 50, 70: 54, 80: 62, 90: 69, 100: 77, 120: 92, 130: 100, 150: 115, 160: 123,
  180: 138, 190: 146, 200: 154, 220: 169, 230: 176, 250: 192, 300: 230,
};

// catatan: __Nssp aslinya menunjuk ke _Msdp (dp, tidak ikut skala font), kecuali __5ssp & __7ssp
const Map<int, int> _sspAlias = {
  2: 1, 8: 6, 10: 7, 11: 8, 12: 9, 14: 10, 15: 11, 16: 12, 18: 13, 20: 15, 24: 18, 25: 19,
  28: 21, 30: 23, 32: 24, 34: 26, 36: 27, 40: 30, 48: 37, 50: 38, 55: 42, 60: 46, 70: 54,
  80: 62,
};
const Map<int, int> _sspRealAlias = {5: 4, 7: 5};

/// android:textSize dibaca TextView lewat getDimensionPixelSize(): dibulatkan ke pixel bulat.
double textSizeDp(double size) => (size * _dpr).roundToDouble() / _dpr;

/// @dimen/__Nsdp
double dsdp(int n) => sdp(_sdpAlias[n]!);

/// @dimen/__Nssp
double dssp(int n) => _sspRealAlias.containsKey(n) ? ssp(_sspRealAlias[n]!) : sdp(_sspAlias[n]!);

/// Ukuran pixel bawaan Android (OnSwipeTouchListener.SWIPE_THRESHOLD dsb) dikonversi ke dp.
double px(num n) => n / _dpr;

// =====================================================================================
// ClassLib.java
// =====================================================================================

/// ClassLib.ramdon(jml, isi_string, tbh)
String ramdon(int jml, String isiString, String tbh) => ramdonString(jml, isiString, tbh);

String ramdonString(int jml, String isiString, String tbh) {
  final chars1 = isiString.split('');
  final sb1 = StringBuffer();
  final random1 = Random();
  for (int i = 0; i < jml; i++) {
    sb1.write(chars1[random1.nextInt(chars1.length)]);
  }
  return tbh + sb1.toString();
}

/// ClassLib.konv_int_str
String konvIntStr(int i) => i.toString();

// =====================================================================================
// normalizeAnswer (MainActivity2 / ScanFragment / MainManual / OneManualFragment)
// =====================================================================================

String normalizeAnswer(String? raw) {
  if (raw == null || raw.trim().isEmpty || raw == "null") {
    return "";
  }

  final trimmed = raw.trim();

  try {
    if (trimmed.startsWith("[")) {
      // Bentuk array: [...]
      final arr = json.decode(trimmed) as List;
      final sb = StringBuffer();
      for (int i = 0; i < arr.length; i++) {
        if (i > 0) {
          sb.write(", ");
        }
        sb.write(_jsonOptString(arr[i]));
      }
      return sb.toString();
    } else if (trimmed.startsWith("\"") && trimmed.endsWith("\"")) {
      // Bentuk string ber-quote ganda: "\"xxx\""
      final value = json.decode(trimmed);
      return _jsonOptString(value);
    } else {
      // String biasa
      return trimmed;
    }
  } catch (e) {
    // fallback kalau parsing gagal, buang quote manual saja
    return trimmed.replaceAll("\"", "");
  }
}

/// JSONArray.optString(i): null -> "", angka/bool -> String.valueOf, object/array -> toString JSON
String _jsonOptString(dynamic v) {
  if (v == null) return "";
  if (v is String) return v;
  if (v is double && v == v.truncateToDouble()) return v.toString();
  if (v is Map || v is List) return json.encode(v);
  return v.toString();
}

// =====================================================================================
// Tampilan (onWindowFocusChanged -> SYSTEM_UI_FLAG_IMMERSIVE_STICKY, dismissKeyboard)
// =====================================================================================

/// SET FULL SCREEN: LAYOUT_STABLE | HIDE_NAVIGATION | FULLSCREEN | IMMERSIVE_STICKY
void setFullScreen() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

/// SplashScreen tidak memanggil full screen -> status bar & navigation bar tampil.
void setNormalScreen() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
}

/// ClassLib.dismissKeyboard / LoginEvent.dismissKeyboard
void dismissKeyboard(BuildContext context) => dismissKeyboardOf(context);

void dismissKeyboardOf(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod('TextInput.hide');
}

/// ActivityCompat.finishAffinity(activity); System.exit(0);
void exitApp() {
  SystemNavigator.pop();
  exit(0);
}
