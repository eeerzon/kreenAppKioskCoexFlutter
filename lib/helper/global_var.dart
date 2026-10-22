import 'package:flutter/material.dart';

export 'secrets.dart';

// ganti value sesuai kebutuhan
//====================================================================================

// Dulu disimpan di native-key.cpp (Config.RestServ)
// const String baseUrl = "https://dev.kreenconnect.com/kreenapi/event/"; // DEV
const String baseUrl = "https://kreenconnect.com/kreenapi/event/"; // LIVE

// Config.java
const String urlBookingRedeem = "${baseUrl}booking_redeem3_coex_kiosk";
const String urlCheckEvent = "${baseUrl}kiosk-check-event";

// JipremiumRetrofitClient
const String baseUrlJipremium = "https://jipremium.com/api/";

// jipremiumSecretKey & kreenConnectSecretKey ada di secrets.dart (tidak di-commit)

// MakeSureData2Fragment / TwoManual2Fragment.ALLOWED_EVENT_ID (event yang boleh print)
const String allowedEventId = "FWSCMNHJGCBHYDJOQ961";

// ClassLib.time_out() -> 10000 ms (Volley); Retrofit kreenconnect pakai default OkHttp 10 detik
const Duration timeOut = Duration(milliseconds: 10000);
// JipremiumRetrofitClient: connect/read/write timeout 30 detik
const Duration timeOutJipremium = Duration(seconds: 30);

// Key SharedPreferences "data" (Config.java)
const String typeRedeemSp = "type_redeem";
const String idEventSp = "id_event";
const String titleEventSp = "title_event";
const String bannerTopSp = "banner_top";
const String bannerBottomSp = "banner_bottom";
const String logoListSp = "logo_list";
const String bannerTopListSp = "banner_top_list";
const String bannerBottomListSp = "banner_bottom_list";
const String langSp = "lang";

// type_redeem
const String typeRedeemManual = "manual";
const String typeRedeemScan = "scan";

// Bahasa aktif aplikasi (LanguageManager). "in" = Indonesia, selain itu = default (English).
ValueNotifier<String> langNotifier = ValueNotifier('en');

// Dipakai ActivityLifecycle untuk onResume/onPause per halaman
final RouteObserver<PageRoute> activityRouteObserver = RouteObserver<PageRoute>();

// res/values/colors.xml
const Color colorPrimaryNight = Color(0xFFED5B60);
const Color colorPrimary = Color(0xFFE01A21);
const Color colorPrimaryVariant = Color(0xFFE01A21);
const Color colorSecondary = Color(0xFF03DAC5);
const Color colorSecondaryVariant = Color(0xFF018786);
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color colorGray = Color(0xFF828186);
const Color colorBG = Color(0xFFECECEC);
const Color colorLine = Color(0xFFDADCE0);
const Color colorOrange = Color(0xFFF2994A);
const Color colorGreen = Color(0xFF219653);
const Color textPrimary = Color(0xFF3E3E3E);
const Color fontColor = Color(0xFF333D47);
const Color inactiveText = Color(0xFF7E868C);
const Color blue = Color(0xFF007CB0);
const Color placeholderBg = Color(0xFFDDDDDD);
const Color lightGray2 = Color(0xFFF7F7F7);

// @android:color/...
const Color darkerGray = Color(0xFFAAAAAA);
const Color transparent = Color(0x00000000);
// ?android:textColorPrimary / textColorHint (Theme.MaterialComponents.Light)
const Color defaultTextColor = Color(0xDE000000);
const Color defaultHintColor = Color(0x61000000);
// @color/primary_text_dark
const Color primaryTextDark = Color(0xFFFFFFFF);

// res/font
const String poppins = 'Poppins';
const String poppinsMedium = 'PoppinsMedium';
const String poppinsSemiBold = 'PoppinsSemiBold';
const String poppinsBold = 'PoppinsBold';
