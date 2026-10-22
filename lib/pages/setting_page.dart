import 'dart:async';

import 'package:appkioskcoex/helper/activity_lifecycle.dart';
import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/helper/global_widget.dart';
import 'package:appkioskcoex/helper/loading_page.dart';
import 'package:appkioskcoex/pages/device_setting_page.dart';
import 'package:appkioskcoex/pages/scanners_page.dart';
import 'package:appkioskcoex/services/lang_service.dart';
import 'package:appkioskcoex/services/scanner_app_engine.dart';
import 'package:appkioskcoex/services/storage_services.dart';
import 'package:flutter/material.dart';

/// Setting.java -> activity_setting.xml
class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> with ActivityLifecycle, IScannerAppEngineDevConnectionsDelegate {
  late String typeRedeem;
  int scannerID_ = 0;

  late final CustomProgressDialogue dProgress = CustomProgressDialogue(context, cancelable: false);
  Timer? _progressTimer;

  bool rbManualChecked = false;
  bool rbScanChecked = false;
  bool layScannerVisible = true;
  bool btnSubmitEnabled = true;
  bool scannerConnected = false; // iv_scanner_status: ic_checked (hijau) / ic_warning_white_24dp (oranye)

  late String language;

  @override
  void initState() {
    super.initState();
    showScannerNotAvailableToastIfNeeded();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      dProgress.show();

      // Simulasi load data (misalnya API call atau proses berat)
      _progressTimer = postDelayed(const Duration(milliseconds: 2000), () {
        // Data sudah siap, dismiss dialog
        if (dProgress.isShowing) {
          dProgress.dismiss();
        }
      });
    });

    typeRedeem = StorageService.getTypeRedeem();

    if (typeRedeem.isEmpty) {
      setTypeRedeem(typeRedeemManual);
      disconnectScan();
    }

    rbManualChecked = false;
    rbScanChecked = false;

    if (typeRedeem == typeRedeemManual) {
      rbManualChecked = true;
      rbScanChecked = false;
      layScannerVisible = false;

      btnSubmitEnabled = true;
      disconnectScan();
    } else if (typeRedeem == typeRedeemScan) {
      rbManualChecked = false;
      rbScanChecked = true;
      layScannerVisible = true;

      //update button
      btnSubmitEnabled = true;
    }

    requestFineLocation().then((granted) {
      if (!mounted) return;
      if (granted) {
        initialize();
      } else {
        Navigator.maybePop(context);
      }
    });

    //language
    language = StorageService.getLangRaw();
  }

  void setTypeRedeem(String type) {
    StorageService.setTypeRedeem(type);
  }

  void disconnectScan() {
    ScannerAppEngine.currentScannerId = ScannerAppEngine.scannerIdNone;
    ScannerAppEngine.intentionallyDisconnected = true;
    ScannerAppEngine.disconnect(scannerID_);
    ScannerAppEngine.barcodeData.clear();
    ScannerAppEngine.isAnyScannerConnected = false;
    ScannerAppEngine.currentConnectedScannerID = -1;
    ScannerAppEngine.lastConnectedScanner = ScannerAppEngine.currentConnectedScanner;
    ScannerAppEngine.currentConnectedScanner = null;
    ScannerAppEngine.intentionallyDisconnected = true; // indicator disconnect

    if (mounted) setState(() => scannerConnected = false);
  }

  Future<void> initialize() async {
    await ScannerAppEngine.initializeDcsSdk();
    ScannerAppEngine.addDevConnectionsDelegate(this);
    await ScannerAppEngine.broadcastSCAisListening();
  }

  /// rbManual / layManual onClick
  void onManualClick() {
    setState(() {
      rbManualChecked = true;
      rbScanChecked = false;
      layScannerVisible = false;
      btnSubmitEnabled = true;
    });
    setTypeRedeem(typeRedeemManual);
    disconnectScan();
  }

  /// rbScan / layScan onClick
  void onScanClick() {
    setState(() {
      rbScanChecked = true;
      rbManualChecked = false;
      layScannerVisible = true;

      //update button
      btnSubmitEnabled = true;
    });

    typeRedeem = StorageService.getTypeRedeem();
    if (typeRedeem != typeRedeemScan) {
      setTypeRedeem(typeRedeemScan);
    }
  }

  void onSubmit() {
    if (rbManualChecked) {
      StorageService.setTypeRedeem(typeRedeemManual);
      disconnectScan();
    } else if (rbScanChecked) {
      StorageService.setTypeRedeem(typeRedeemScan);
    }
    Navigator.pop(context);
  }

  void onLanguageChanged(String code) {
    LangService.updateResources(code);
    // recreate()
    setState(() => language = StorageService.getLangRaw());
  }

  @override
  void onResume() {
    setFullScreen();
    ScannerAppEngine.setDelegate();

    // Tutup progress dari DeviceSetting
    final deviceProgress = DeviceSettingPage.dProgress;
    if (deviceProgress != null && deviceProgress.isShowing) {
      deviceProgress.dismiss();
    }

    typeRedeem = StorageService.getTypeRedeem();
    setState(() {
      if (typeRedeem == typeRedeemManual) {
        btnSubmitEnabled = true;
      } else if (typeRedeem == typeRedeemScan) {
        btnSubmitEnabled = true;
      } else {
        btnSubmitEnabled = false;
      }
    });

    ScannerAppEngine.addDevConnectionsDelegate(this);
  }

  @override
  void onPause() {
    ScannerAppEngine.removeDevConnectiosDelegate(this);
  }

  // ---- IScannerAppEngineDevConnectionsDelegate ----

  @override
  bool scannerHasAppeared(int scannerID) => false;

  @override
  bool scannerHasDisappeared(int scannerID) => false;

  @override
  bool scannerHasConnected(int scannerID) {
    typeRedeem = StorageService.getTypeRedeem();
    if (!mounted) return true;
    setState(() {
      if (typeRedeem == typeRedeemScan) {
        btnSubmitEnabled = true;
        scannerID_ = scannerID;
      }
      scannerConnected = true;
    });
    return true;
  }

  @override
  bool scannerHasDisconnected(int scannerID) {
    ScannerAppEngine.isAnyScannerConnected = false;
    ScannerAppEngine.currentConnectedScannerID = -1;
    ScannerAppEngine.lastConnectedScanner = ScannerAppEngine.currentConnectedScanner;
    ScannerAppEngine.currentConnectedScanner = null;

    typeRedeem = StorageService.getTypeRedeem();
    if (mounted) {
      setState(() {
        if (typeRedeem == typeRedeemScan) {
          btnSubmitEnabled = false;
        }
        scannerConnected = false;
      });
    }
    disconnectScan();

    return false;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    dProgress.hide();
    ScannerAppEngine.removeDevConnectiosDelegate(this);
    super.dispose();
  }

  // ---- layout ----

  Widget _sectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dsdp(20), vertical: dsdp(15)),
      child: AText(text,
          font: AFont.bold, size: dssp(16), color: textPrimary, bold: true, maxLines: 1, ellipsize: true),
    );
  }

  Widget _card({required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(left: dsdp(20), right: dsdp(20), bottom: dsdp(10)),
      child: Card(
        margin: EdgeInsets.zero,
        color: white,
        elevation: 2, // @dimen/cardview_default_elevation
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dsdp(10))),
        child: child,
      ),
    );
  }

  /// lay_manual / lay_scan: label (weight 4) + MaterialRadioButton checkbox_selector (weight 0.5)
  Widget _option({required List<Widget> labels, required bool checked, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(dsdp(15)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 40,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: labels),
              ),
              Expanded(
                flex: 5,
                child: Center(
                  child: SizedBox(
                    width: dsdp(30),
                    // ic_checked / ic_checked_blank (24dp) dengan buttonTint colorGreen
                    child: checked
                        ? const SvgIcon('ic_checked', width: 24, height: 24, tint: colorGreen)
                        : const SizedBox(width: 24, height: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBG,
      body: Stack(
        children: [
          Column(
            children: [
              // AppBarLayout -> toolbar3 (?attr/actionBarSize, putih)
              Container(
                height: actionBarSize,
                color: white,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Row(
                      children: [
                        SizedBox(width: dsdp(24)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: SvgIcon('ic_arrow_left', width: dsdp(24), height: dsdp(24), tint: textPrimary),
                        ),
                        SizedBox(width: dsdp(20)),
                        Expanded(
                          child: AText(LangService.getString('setting'),
                              font: AFont.semibold,
                              size: dssp(18),
                              color: textPrimary,
                              bold: true,
                              maxLines: 1,
                              ellipsize: true),
                        ),
                        SizedBox(width: dsdp(20)),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: LanguageRadioGroup(language: language, onChanged: onLanguageChanged),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // lay_additional_information
                      _sectionTitle(LangService.getString('type_redeem')),
                      _card(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: dsdp(10)),
                          child: Column(
                            children: [
                              _option(
                                checked: rbManualChecked,
                                onTap: onManualClick,
                                labels: [
                                  AText(LangService.getString('manual'),
                                      font: AFont.bold, size: dssp(14), color: textPrimary, bold: true),
                                ],
                              ),
                              // normal_divider
                              Container(
                                height: 0.25,
                                margin: EdgeInsets.symmetric(horizontal: dsdp(15)),
                                color: darkerGray,
                              ),
                              _option(
                                checked: rbScanChecked,
                                onTap: onScanClick,
                                labels: [
                                  AText(LangService.getString('scanner'),
                                      font: AFont.bold, size: dssp(14), color: textPrimary, bold: true),
                                  AText(
                                      LangService.getString(
                                          'if_you_choose_this_you_have_to_do_the_settings_to_connect_to_the_device_scanner'),
                                      font: AFont.poppins,
                                      size: dssp(10),
                                      color: inactiveText),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // lay_scanner
                      if (layScannerVisible) ...[
                        _sectionTitle(LangService.getString('scanner')),
                        _card(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannersPage()));
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: dsdp(10)),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: dsdp(20), vertical: dsdp(15)),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 40,
                                      child: AText(LangService.getString('setting_scanner'),
                                          font: AFont.bold,
                                          size: dssp(14),
                                          color: textPrimary,
                                          bold: true,
                                          maxLines: 2,
                                          ellipsize: true),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: scannerConnected
                                            ? SvgIcon('ic_checked',
                                                width: dsdp(24), height: dsdp(24), tint: colorGreen)
                                            : SvgIcon('ic_warning_white_24dp',
                                                width: dsdp(24), height: dsdp(24), tint: colorOrange),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          // lay_footer (layout_alignParentBottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: dsdp(2), color: colorBG),
                  Padding(
                    padding: EdgeInsets.all(dsdp(15)),
                    child: BackgroundTextButton(
                      text: LangService.getString('save'),
                      enabled: btnSubmitEnabled,
                      height: dsdp(50),
                      textSize: dssp(16),
                      onTap: onSubmit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
