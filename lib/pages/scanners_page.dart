import 'package:appkioskcoex/helper/activity_lifecycle.dart';
import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/helper/global_widget.dart';
import 'package:appkioskcoex/pages/device_setting_page.dart';
import 'package:appkioskcoex/pages/main_activity_page.dart';
import 'package:appkioskcoex/services/lang_service.dart';
import 'package:appkioskcoex/services/scanner_app_engine.dart';
import 'package:flutter/material.dart';

/// ScannersActivity2.java -> activity_scanners2.xml
class ScannersPage extends StatefulWidget {
  const ScannersPage({super.key});

  @override
  State<ScannersPage> createState() => _ScannersPageState();
}

class _ScannersPageState extends State<ScannersPage>
    with ActivityLifecycle, IScannerAppEngineDevListDelegate {
  static const int create = 0;
  static const int event = 1;

  final List<AvailableScanner> scannersList = [];
  final List<AvailableScanner> lastConnectedScannerList = [];

  bool enableLastScannerConnection = false;
  bool cmdExecTaskRunning = false;
  String lastConnectedScannerTxt = "";
  final DialogShow progressDialog = DialogShow();

  // static boolean launchFromFCS = false (tidak pernah diisi true di app ini)
  final bool launchFromFCS = false;

  @override
  void initState() {
    super.initState();
    showScannerNotAvailableToastIfNeeded();
    lastConnectedScannerTxt = LangService.getString('last_connected_scanner');

    ScannerAppEngine.addDevListDelegate(this);
    ScannerAppEngine.configureNotificationAvailable(true);

    updateScannerListView(create);
  }

  /// UpdateScannersHandler.handleMessage(msg)
  Future<void> updateScannerListView(int what) async {
    await ScannerAppEngine.updateScannersList();
    if (!mounted) return;

    scannersList.clear();
    lastConnectedScannerList.clear();
    bool enableLast = false;
    final last = ScannerAppEngine.lastConnectedScanner;
    if (last != null) {
      addToLastConnectedScannerList(
        AvailableScanner(
          last.scannerID,
          last.scannerName,
          last.scannerHWSerialNumber,
          false,
          last.isAutoCommunicationSessionReestablishment,
          last.connectionType,
        ),
      );
    }
    for (final device in ScannerAppEngine.getActualScannersList()) {
      if (device.isActive) {
        final availableScanner = AvailableScanner(
          device.scannerID,
          device.scannerName,
          device.scannerHWSerialNumber,
          true,
          device.isAutoCommunicationSessionReestablishment,
          device.connectionType,
        );
        ScannerAppEngine.currentConnectedScanner = device;
        ScannerAppEngine.lastConnectedScanner =
            ScannerAppEngine.currentConnectedScanner;
        availableScanner.isConnectable = true;
        addToLastConnectedScannerList(availableScanner);
        enableLast = true;
      } else {
        final availableScanner = AvailableScanner(
          device.scannerID,
          device.scannerName,
          device.scannerHWSerialNumber,
          false,
          device.isAutoCommunicationSessionReestablishment,
          device.connectionType,
        );
        availableScanner.isConnectable = true;
        addToAvailableScannerList(availableScanner);
      }
    }

    scannersList.sort();

    AvailableScanner? currentConnectedScannerX;

    final lastConnected = ScannerAppEngine.lastConnectedScanner;
    if (lastConnected != null) {
      AvailableScanner? lastConnectedScanner;
      for (final scanner in scannersList) {
        if (scanner.scannerId == lastConnected.scannerID) {
          lastConnectedScanner = scanner;
          scanner.isConnectable = true;
          addToLastConnectedScannerList(scanner);
          enableLast = true;
          break;
        }

        final current = ScannerAppEngine.currentConnectedScanner;
        if (current != null) {
          if (current.scannerHWSerialNumber != null &&
              current.scannerHWSerialNumber == scanner.scannerAddress) {
            currentConnectedScannerX = scanner;
          }
        }
      }
      if (lastConnectedScanner != null) {
        scannersList.remove(lastConnectedScanner);
      }
    }

    if (currentConnectedScannerX != null) {
      scannersList.remove(currentConnectedScannerX);
    }

    String lastTxt = LangService.getString('last_connected_scanner');

    if (lastConnectedScannerList.isNotEmpty) {
      if (lastConnectedScannerList[0].connected) {
        if (what == event) {
          if (!cmdExecTaskRunning) {
            ScannerAppEngine.currentScannerName =
                lastConnectedScannerList[0].scannerName ?? "";
            ScannerAppEngine.currentScannerAddress =
                lastConnectedScannerList[0].scannerAddress ?? "";
            ScannerAppEngine.currentScannerId =
                lastConnectedScannerList[0].scannerId;
            ScannerAppEngine.currentAutoReconnectionState =
                lastConnectedScannerList[0].autoReconnection;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MainActivityPage()),
            );
            showToast("Other!!");
          }
        }
        lastTxt = LangService.getString('currently_connected_scanner');
      }
    }

    setState(() {
      enableLastScannerConnection = enableLast;
      lastConnectedScannerTxt = lastTxt;
    });
  }

  void addToAvailableScannerList(AvailableScanner availableScanner) {
    if (!scannersList.contains(availableScanner)) {
      scannersList.add(availableScanner);
    }
  }

  void addToLastConnectedScannerList(AvailableScanner availableScanner) {
    lastConnectedScannerList.clear();
    lastConnectedScannerList.add(availableScanner);
  }

  void removeToLastConnectedScannerList(AvailableScanner availableScanner) {
    lastConnectedScannerList.clear();
  }

  @override
  bool scannersListHasBeenUpdated() {
    updateScannerListView(event);
    return true;
  }

  @override
  void onResume() {
    setFullScreen();
    ScannerAppEngine.setDelegate();
    ScannerAppEngine.addDevListDelegate(this);
  }

  @override
  void onPause() {
    ScannerAppEngine.removeDevListDelegate(this);
    // Device discovery is resource heavy operation.
    // Make sure to cancel the discovery when not needed.
    ScannerAppEngine.stopScanningDevices();
  }

  @override
  void dispose() {
    progressDialog.dismiss();
    ScannerAppEngine.removeDevListDelegate(this);
    super.dispose();
  }

  Future<void> connectToScanner(AvailableScanner availableScanner) async {
    for (final device in ScannerAppEngine.getActualScannersList()) {
      if (device.scannerID == availableScanner.scannerId) {
        availableScanner.autoReconnection =
            device.isAutoCommunicationSessionReestablishment;
      }
    }
    final cur = ScannerAppEngine.curAvailableScanner;
    if (!availableScanner.connected) {
      if (cur != null &&
          availableScanner.scannerAddress != cur.scannerAddress) {
        if (cur.connected) await ScannerAppEngine.disconnect(cur.scannerId);
      }
      await myAsyncTask(availableScanner);
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("Confirmation"),
          content: const Text(
            "Are you sure you want to disconnect from the device?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("NO"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                availableScanner.connected = false;
                removeToLastConnectedScannerList(availableScanner);
                final current = ScannerAppEngine.curAvailableScanner;
                if (current != null) {
                  ScannerAppEngine.disconnect(current.scannerId);
                }
                addToAvailableScannerList(availableScanner);
              },
              child: const Text("YES"),
            ),
          ],
        ),
      );
    }
  }

  /// MyAsyncTask(availableScanner).execute()
  Future<void> myAsyncTask(AvailableScanner scanner) async {
    cmdExecTaskRunning = true;
    progressDialog.show(
      context,
      (_) => const ProgressDialogView(
        message: "Connecting To scanner. Please Wait...",
      ),
      cancelable: false,
    );

    final bool b;
    if (await ScannerAppEngine.connect(scanner.scannerId)) {
      ScannerAppEngine.curAvailableScanner = scanner;
      scanner.connected = true;
      b = true;
    } else {
      ScannerAppEngine.curAvailableScanner = null;
      b = false;
    }
    cmdExecTaskRunning = false;

    progressDialog.dismiss();
    ScannerAppEngine.intentionallyDisconnected = false; // indicator disconnect
    if (!b && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MainActivityPage()),
      );
      showToast("Unable to communicate with scanner");
      scannersListHasBeenUpdated();
      ScannerAppEngine.intentionallyDisconnected = true; // indicator disconnect
    }
  }

  /// onBackPressed()
  void onBackPressed() {
    final cur = ScannerAppEngine.curAvailableScanner;
    if (ScannerAppEngine.isAnyScannerConnected && cur != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MainActivityPage()),
      );
      showToast("onBackPressed conncect!!");
    } else {
      if (launchFromFCS) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MainActivityPage()),
        );
        showToast("onBackPressed disconnect!!");
      } else {
        Navigator.pop(context);
      }
    }
  }

  // ---- layout ----

  Widget _header(String text, Color background, Color textColor) {
    return Container(
      height: dsdp(40),
      color: background,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 18), // @dimen/app_margin_left
      child: AText(text, size: dssp(16), color: textColor),
    );
  }

  Widget _divider() => Container(
    height: 0.25,
    margin: EdgeInsets.symmetric(horizontal: dsdp(15)),
    color: darkerGray,
  );

  Widget _list(List<AvailableScanner> items, bool enabled) {
    return Container(
      color: white,
      padding: EdgeInsets.only(right: dsdp(10)),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: Color(0x1F000000)),
            _ScannerRow(
              scanner: items[i],
              onTap: enabled ? () => connectToScanner(items[i]) : null,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bothEmpty = scannersList.isEmpty && lastConnectedScannerList.isEmpty;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBackPressed();
      },
      child: Scaffold(
        backgroundColor: colorBG,
        body: Column(
          children: [
            // toolbar3
            Container(
              height: actionBarSize,
              color: white,
              child: Row(
                children: [
                  SizedBox(width: dsdp(25)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgIcon(
                      'ic_arrow_left',
                      width: dsdp(25),
                      height: dsdp(25),
                      tint: textPrimary,
                    ),
                  ),
                  SizedBox(width: dsdp(20)),
                  Expanded(
                    child: AText(
                      "Device Connection",
                      font: AFont.semibold,
                      size: dsdp(18),
                      color: textPrimary,
                      bold: true,
                      maxLines: 1,
                      ellipsize: true,
                    ),
                  ),
                  SizedBox(width: dsdp(10)),
                  GestureDetector(
                    onTap: () => ScannerAppEngine.updateScannersList(),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        textPrimary,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/images/ic_action_refresh.png',
                        width: dsdp(25),
                        height: dsdp(25),
                      ),
                    ),
                  ),
                  SizedBox(width: dsdp(10)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (lastConnectedScannerList.isNotEmpty)
                      _header(lastConnectedScannerTxt, blue, white),
                    _list(
                      lastConnectedScannerList,
                      enableLastScannerConnection,
                    ),
                    _divider(),
                    _header(
                      LangService.getString('other_scanners'),
                      darkerGray,
                      const Color(0xFF4E342E),
                    ),
                    if (!bothEmpty) _list(scannersList, true),
                    _divider(),
                    if (bothEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: dsdp(20)),
                        child: Column(
                          children: [
                            AText(
                              "bt_no_scanners",
                              size: dssp(8),
                              align: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // btnConnHelp -> OnConnHelp() (kosong)
                            MaterialButtonView(
                              text: "Follow tutorial >> ",
                              height: 48,
                              textSize: 14,
                              fullWidth: false,
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// list_available_device_layout.xml (AvailableScannerListAdapter.getView)
class _ScannerRow extends StatelessWidget {
  final AvailableScanner scanner;
  final VoidCallback? onTap;

  const _ScannerRow({required this.scanner, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Widget icon;
    double serialSize = sp(12); // roboto_regular_16dp: @dimen/_12ssp -> default
    switch (scanner.connectionType) {
      case ConnType.btNormal:
      case ConnType.btLe:
        icon = Image.asset(
          scanner.connected
              ? 'assets/images/ic_action_bluetooth_connected.png'
              : 'assets/images/ic_action_bluetooth.png',
        );
        serialSize = sp(15);
        break;
      case ConnType.usbSnapi:
        icon = Image.asset('assets/images/ic_action_usb.png');
        serialSize = sp(12);
        break;
      case ConnType.usbCdc:
        icon = const SvgIcon(
          'ic_action_usb_cdc',
          width: 24,
          height: 24,
          tint: Color(0x99606166),
        );
        serialSize = ssp(12);
        break;
      case ConnType.invalid:
        icon = const SizedBox.shrink();
        serialSize = ssp(12);
        break;
    }
    final textColor = scanner.isConnectable ? fontColor : inactiveText;

    return Material(
      color: white,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            const SizedBox(width: 18),
            Expanded(
              flex: 10,
              child: SizedBox(
                height: dsdp(50),
                child: Checkbox(
                  value: scanner.connected,
                  onChanged: null,
                  fillColor: _checkboxFill(),
                ),
              ),
            ),
            SizedBox(width: dsdp(10)),
            Expanded(
              flex: 80,
              child: SizedBox(
                height: dsdp(50),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: dsdp(10)),
                      child: AText(
                        scanner.scannerName ?? "",
                        font: AFont.robotoMedium,
                        size: ssp(12),
                        color: textColor,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: dsdp(10) * 2),
                      child: AText(
                        scanner.scannerAddress ?? "",
                        size: serialSize,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: dsdp(10)),
            Expanded(
              flex: 10,
              child: SizedBox(
                height: dsdp(50),
                child: Center(child: icon),
              ),
            ),
            const SizedBox(width: 18), // @dimen/app_margin_right
          ],
        ),
      ),
    );
  }

  WidgetStateProperty<Color?> _checkboxFill() =>
      WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? colorSecondary : null,
      );
}

/// ProgressDialog STYLE_SPINNER (helpers/CustomProgressDialogOld)
class ProgressDialogView extends StatelessWidget {
  final String message;

  const ProgressDialogView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: white,
          elevation: 24,
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            width: width * 0.95 - 32,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: colorSecondary,
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: AText(message, size: sp(16))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
