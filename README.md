# KIOSKreen — Kreen App Kiosk COEX (Flutter)

Aplikasi kiosk self check-in / redeem tiket event Kreen, versi Flutter dari project Android native **KreenAppKioskCoex**.
Pengunjung scan QR tiket (via Zebra scanner) atau input manual, lalu kiosk mencetak label/badge lewat printer Brother.

- Package: `id.kreen.android.appkioskcoex`
- Versi: `1.14.2` (sama dengan app Android asli)
- Platform: **Android only** (bergantung pada SDK native Zebra & Brother)

## Fitur

- Login event & pengaturan device kiosk
- Scan QR tiket dengan Zebra barcode scanner (Bluetooth / USB SNAPI / USB CDC)
- Input data manual (alur 1–3 langkah) dan konfirmasi data peserta
- Cetak label/badge ke printer Brother (PDF template digambar di native)
- Multi bahasa (Indonesia / English)
- Firebase Analytics & Crashlytics

## Struktur Project

```
lib/
├── main.dart                 # entry point, init Firebase, storage, bahasa, scanner
├── helper/                   # konstanta, global var (base URL), widget & fungsi umum
├── models/                   # model response API
├── pages/
│   ├── splash_screen_page.dart, login_event_page.dart, setting_page.dart, ...
│   ├── scan/                 # alur scan QR → pastikan data → selesai
│   └── manual/               # alur input manual
└── services/
    ├── api_services.dart     # HTTP ke API Kreen / Jipremium
    ├── scanner_app_engine.dart  # MethodChannel ke Zebra Scanner SDK
    ├── printer_service.dart  # MethodChannel ke Brother Print SDK + TemplatePdf
    ├── storage_services.dart # flutter_secure_storage
    └── lang_service.dart     # load assets/lang/*.json

android/app/
├── libs/                     # BrotherPrintLibrary.aar, barcode_scanner_library_v2.6.6.0-release.aar
└── src/main/kotlin/.../      # MainActivity, PrinterBridge, ZebraBridge
```

## Requirements

- Flutter SDK dengan Dart `^3.9.2`
- JDK 17
- Android SDK (targetSdk 35)
- Perangkat Android + Zebra scanner + printer Brother untuk testing penuh

## Menjalankan

1. Siapkan file secret (tidak ikut di repo):

   ```bash
   cp lib/helper/secrets.example.dart lib/helper/secrets.dart
   ```

   Lalu isi `jipremiumSecretKey` dan `kreenConnectSecretKey` di `lib/helper/secrets.dart`.

2. Jalankan:

   ```bash
   flutter pub get
   flutter run
   ```

### Environment API

Base URL diatur di [lib/helper/global_var.dart](lib/helper/global_var.dart). Default-nya **LIVE**; untuk development, aktifkan baris `DEV` dan comment baris `LIVE`:

```dart
// const String baseUrl = "https://dev.kreenconnect.com/kreenapi/event/"; // DEV
const String baseUrl = "https://kreenconnect.com/kreenapi/event/"; // LIVE
```

## Build Release

Release harus ditandatangani dengan keystore yang sama dengan app Android asli (`Key_Store_Kreen_AppKioskCoex.keystore`) supaya bisa meng-update app yang sudah terpasang di kiosk.

1. Buat file `android/key.properties` (**jangan di-commit**, sudah ada di `.gitignore`):

   ```properties
   storeFile=/path/ke/Key_Store_Kreen_AppKioskCoex.keystore
   storePassword=...
   keyAlias=...
   keyPassword=...
   ```

2. Build:

   ```bash
   flutter build apk --release
   ```

Kalau `key.properties` tidak ada, build release otomatis memakai debug signing.

## Catatan

- `android/app/google-services.json` dibutuhkan untuk Firebase.
- Integrasi scanner dan printer berjalan lewat `MethodChannel` (`id.kreen.android.appkioskcoex/...`); logic UI & navigasi ada di Dart, sedangkan pembuatan PDF template memakai kode native asli agar hasil cetak identik dengan app Android.
