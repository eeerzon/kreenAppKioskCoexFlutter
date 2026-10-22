import 'dart:io';

import 'package:appkioskcoex/helper/activity_lifecycle.dart';
import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/helper/global_widget.dart';
import 'package:appkioskcoex/helper/loading_page.dart';
import 'package:appkioskcoex/pages/login_event_page.dart';
import 'package:appkioskcoex/pages/manual/main_manual_page.dart';
import 'package:appkioskcoex/pages/scan/main_activity2_page.dart';
import 'package:appkioskcoex/pages/setting_page.dart';
import 'package:appkioskcoex/services/lang_service.dart';
import 'package:appkioskcoex/services/scanner_app_engine.dart';
import 'package:appkioskcoex/services/storage_services.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// =====================================================================================
// Dipakai DeviceSetting & Setting (BaseActivity + BluetoothPermissionHelper)
// =====================================================================================

/// ContextCompat.checkSelfPermission(ACCESS_FINE_LOCATION) -> requestPermissions -> onRequestPermissionsResult
/// return true = permission granted (initialize()), false = denied (finish()).
Future<bool> requestFineLocation() async {
  if (!Platform.isAndroid) return true;
  if (await Permission.locationWhenInUse.isGranted) return true;
  return (await Permission.locationWhenInUse.request()).isGranted;
}

/// BluetoothPermissionHelper.hasBluetoothPermission / requestBluetoothPermission
Future<void> requestBluetoothPermission() async {
  if (!Platform.isAndroid) return;
  final connect = await Permission.bluetoothConnect.isGranted;
  final scan = await Permission.bluetoothScan.isGranted;
  if (!connect || !scan) {
    await [Permission.bluetoothConnect, Permission.bluetoothScan].request();
  }
}

/// BaseActivity.onCreate: Toast kalau Application.sdkHandler == null
void showScannerNotAvailableToastIfNeeded() {
  if (!ScannerAppEngine.sdkAvailable) {
    showToast("Scanner hardware tidak tersedia di perangkat ini", long: true);
  }
}

/// getBeeperVolume / getPickListMode: ambil isi tag `<value>` terakhir dari outXML
int? _lastXmlValue(String outXml) {
  final matches = RegExp(r'<value>([^<]*)</value>').allMatches(outXml).toList();
  if (matches.isEmpty) return null;
  return int.tryParse(matches.last.group(1)!.trim());
}

Future<int> getBeeperVolume(int scannerID) async {
  int beeperVolume = 0;
  final inXml =
      "<inArgs><scannerID>$scannerID</scannerID><cmdArgs><arg-xml><attrib_list>140</attrib_list></arg-xml></cmdArgs></inArgs>";
  final outXml = await ScannerAppEngine.executeCommand(
    'DCSSDK_RSM_ATTR_GET',
    inXml,
    scannerID,
  );
  beeperVolume = _lastXmlValue(outXml) ?? beeperVolume;
  if (beeperVolume == 0) {
    return 100;
  } else if (beeperVolume == 1) {
    return 50;
  } else {
    return 0;
  }
}

Future<int> getPickListMode(int scannerID) async {
  int attrVal = 0;
  final inXml =
      "<inArgs><scannerID>$scannerID</scannerID><cmdArgs><arg-xml><attrib_list>402</attrib_list></arg-xml></cmdArgs></inArgs>";
  final outXml = await ScannerAppEngine.executeCommand(
    'DCSSDK_RSM_ATTR_GET',
    inXml,
    scannerID,
  );
  attrVal = _lastXmlValue(outXml) ?? attrVal;
  return attrVal;
}

// =====================================================================================

/// DeviceSetting.java -> activity_device_setting.xml
class DeviceSettingPage extends StatefulWidget {
  final bool showProgress; // intent.putExtra("show_progress", true)

  const DeviceSettingPage({super.key, this.showProgress = false});

  /// public static CustomProgressDialogue dProgress (ditutup di Setting.onResume)
  static CustomProgressDialogue? dProgress;

  @override
  State<DeviceSettingPage> createState() => _DeviceSettingPageState();
}

class _DeviceSettingPageState extends State<DeviceSettingPage>
    with ActivityLifecycle, IScannerAppEngineDevConnectionsDelegate {
  int scannerID_ = 0;
  late String typeRedeem;
  bool ivNextEnabled = false;
  late String language;

  @override
  void initState() {
    super.initState();
    showScannerNotAvailableToastIfNeeded();

    typeRedeem = StorageService.getTypeRedeem();

    requestFineLocation().then((granted) {
      if (!mounted) return;
      if (granted) {
        initialize();
      } else {
        Navigator.maybePop(context);
      }
    });

    DeviceSettingPage.dProgress = CustomProgressDialogue(
      context,
      cancelable: false,
    );

    //language
    language = StorageService.getLangRaw();
  }

  Future<void> initialize() async {
    // Cek permission
    await requestBluetoothPermission();

    await ScannerAppEngine.initializeDcsSdk();
    ScannerAppEngine.addDevConnectionsDelegate(this);
    await ScannerAppEngine.broadcastSCAisListening();
  }

  @override
  void onResume() {
    setFullScreen();
    ScannerAppEngine.setDelegate();

    // Tutup progress dari LoginEvent
    final loginProgress = LoginEventPage.dProgress;
    if (loginProgress != null && loginProgress.isShowing) {
      loginProgress.dismiss();
    }

    typeRedeem = StorageService.getTypeRedeem();
    if (typeRedeem == typeRedeemManual) {
      setState(() => ivNextEnabled = true);
    }

    ScannerAppEngine.addDevConnectionsDelegate(this);
  }

  @override
  void onPause() {
    ScannerAppEngine.removeDevConnectiosDelegate(this);
  }

  void onLanguageChanged(String code) {
    LangService.updateResources(code);
    // recreate()
    setState(() => language = StorageService.getLangRaw());
  }

  Future<void> onNext() async {
    typeRedeem = StorageService.getTypeRedeem();
    if (typeRedeem == typeRedeemManual) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MainManualPage()),
      );
    } else {
      await ScannerAppEngine.getActiveScannersList();

      for (final scannerInfo in List.of(ScannerAppEngine.mScannerInfoList)) {
        if (scannerInfo.scannerID == scannerID_) {
          final picklistMode = await getPickListMode(scannerID_);
          await getBeeperVolume(scannerID_);

          ScannerAppEngine.isAnyScannerConnected = true;
          ScannerAppEngine.currentConnectedScannerID = scannerID_;
          ScannerAppEngine.currentConnectedScanner = scannerInfo;
          ScannerAppEngine.lastConnectedScanner =
              ScannerAppEngine.currentConnectedScanner;
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MainActivity2Page(
                scannerId: scannerInfo.scannerID,
                scannerName: scannerInfo.scannerName,
                scannerAddress: scannerInfo.scannerHWSerialNumber,
                scannerType: scannerInfo.connectionType,
                picklistMode: picklistMode,
              ),
            ),
          );
          break;
        }
      }
    }
  }

  // ---- IScannerAppEngineDevConnectionsDelegate ----

  @override
  bool scannerHasAppeared(int scannerID) => false;

  @override
  bool scannerHasDisappeared(int scannerID) => false;

  @override
  bool scannerHasConnected(int scannerID) {
    typeRedeem = StorageService.getTypeRedeem();
    if (typeRedeem == typeRedeemScan) {
      if (mounted) setState(() => ivNextEnabled = true);
      scannerID_ = scannerID;
    }
    return true;
  }

  @override
  bool scannerHasDisconnected(int scannerID) {
    ScannerAppEngine.isAnyScannerConnected = false;
    ScannerAppEngine.currentConnectedScannerID = -1;
    ScannerAppEngine.lastConnectedScanner =
        ScannerAppEngine.currentConnectedScanner;
    ScannerAppEngine.currentConnectedScanner = null;

    typeRedeem = StorageService.getTypeRedeem();
    if (typeRedeem == typeRedeemScan) {
      if (mounted) setState(() => ivNextEnabled = false);
    }
    return false;
  }

  @override
  void dispose() {
    ScannerAppEngine.removeDevConnectiosDelegate(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: Column(
        children: [
          // lyTop
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dsdp(10),
              vertical: dsdp(8),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: LanguageRadioGroup(
                language: language,
                onChanged: onLanguageChanged,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(dsdp(25)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: dsdp(10)),
                            child: Image.asset(
                              'assets/images/logo_kreen.png',
                              width: dsdp(150),
                              height: dsdp(70),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: dsdp(10)),
                            child: SizedBox(
                              width: double.infinity,
                              child: AText(
                                LangService.getString('device_setting'),
                                font: AFont.bold,
                                size: dssp(20),
                                color: textPrimary,
                                bold: true,
                                align: TextAlign.center,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: dsdp(10)),
                            child: SizedBox(
                              width: double.infinity,
                              child: AText(
                                LangService.getString(
                                  'to_continue_please_do_the_settings_first_by_clicking_the_button_below',
                                ),
                                font: AFont.poppins,
                                size: dssp(16),
                                color: textPrimary,
                                align: TextAlign.center,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: dsdp(15)),
                            child: MaterialButtonView(
                              text: LangService.getString('setting'),
                              height: dsdp(48),
                              textSize: dssp(16),
                              onPressed: () {
                                DeviceSettingPage.dProgress!.show();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SettingPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          CircleNextButton(
                            enabled: ivNextEnabled,
                            onTap: onNext,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// com.google.android.material.button.MaterialButton (Widget.MaterialComponents.Button)
/// insetTop/insetBottom 6dp, cornerRadius 4dp, textAllCaps, letterSpacing 0.0892857, elevation 2dp
class MaterialButtonView extends StatelessWidget {
  final String text;
  final double height;
  final double textSize;
  final VoidCallback onPressed;
  final bool fullWidth; // layout_width match_parent / wrap_content

  const MaterialButtonView({
    super.key,
    required this.text,
    required this.height,
    required this.textSize,
    required this.onPressed,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Material(
          color: colorPrimary,
          elevation: 2,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: onPressed,
            child: Padding(
              // Widget.MaterialComponents.Button: paddingLeft/Right 16dp, minWidth 64dp
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: AText(
                  text.toUpperCase(),
                  font: AFont.robotoMedium,
                  size: textSize,
                  color: white,
                  letterSpacing: 0.0892857,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
