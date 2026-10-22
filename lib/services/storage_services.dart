import 'package:appkioskcoex/helper/global_var.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Pengganti getSharedPreferences("data", Context.MODE_PRIVATE).
///
/// Isinya di-cache di memory (seperti SharedPreferences di Android) supaya
/// getter bisa dipanggil sinkron di initState, sama seperti di onCreate.
class StorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static final Map<String, String> _cache = {};

  static Future<void> init() async {
    _cache
      ..clear()
      ..addAll(await _storage.readAll());
  }

  static String getString(String key, [String def = ""]) {
    return _cache[key] ?? def;
  }

  /// editor.putString(...).apply()
  static void putString(String key, String value) {
    _cache[key] = value;
    _storage.write(key: key, value: value);
  }

  // -----------------------------------------------------------------------------

  /// pref.getString(Config.TYPE_REDEEM_SHARED_PREF, "")
  static String getTypeRedeem() => getString(typeRedeemSp, "");

  static void setTypeRedeem(String type) => putString(typeRedeemSp, type);

  /// LanguageManager.getLang() -> sharedPreferences.getString("lang", "en")
  static String getLang() => getString(langSp, "en");

  /// pref.getString("lang", "") (dipakai untuk set radio button bahasa)
  static String getLangRaw() => getString(langSp, "");

  static void setLang(String code) => putString(langSp, code);

  static String getIdEvent() => getString(idEventSp, "");
  static String getTitleEvent() => getString(titleEventSp, "");
  static String getBannerTop() => getString(bannerTopSp, "");
  static String getBannerBottom() => getString(bannerBottomSp, "");
  static String getLogoList() => getString(logoListSp, "");
  static String getBannerTopList() => getString(bannerTopListSp, "");
  static String getBannerBottomList() => getString(bannerBottomListSp, "");

  /// LoginEvent.check_event() -> editor.putString(...) x7 lalu apply()
  static void setEvent({
    required String idEvent,
    required String title,
    required String bannerTop,
    required String bannerBottom,
    required String logoList,
    required String bannerTopList,
    required String bannerBottomList,
  }) {
    putString(idEventSp, idEvent);
    putString(titleEventSp, title);
    putString(bannerTopSp, bannerTop);
    putString(bannerBottomSp, bannerBottom);
    putString(logoListSp, logoList);
    putString(bannerTopListSp, bannerTopList);
    putString(bannerBottomListSp, bannerBottomList);
  }
}
