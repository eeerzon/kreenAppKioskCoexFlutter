import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// =====================================================================================
// Model (com.zebra.scannercontrol.DCSScannerInfo, helpers/AvailableScanner, helpers/Barcode)
// =====================================================================================

/// DCSSDKDefs.DCSSDK_CONN_TYPES
enum ConnType { invalid, btNormal, usbSnapi, btLe, usbCdc }

ConnType _connTypeFromName(String? name) {
  switch (name) {
    case 'DCSSDK_CONNTYPE_BT_NORMAL':
      return ConnType.btNormal;
    case 'DCSSDK_CONNTYPE_USB_SNAPI':
      return ConnType.usbSnapi;
    case 'DCSSDK_CONNTYPE_BT_LE':
      return ConnType.btLe;
    case 'DCSSDK_CONNTYPE_USB_CDC':
      return ConnType.usbCdc;
    default:
      return ConnType.invalid;
  }
}

class DCSScannerInfo {
  final int scannerID;
  final String? scannerName;
  final String? scannerModel;
  final String? scannerHWSerialNumber;
  final bool isActive;
  final bool isAutoCommunicationSessionReestablishment;
  final ConnType connectionType;

  const DCSScannerInfo({
    required this.scannerID,
    this.scannerName,
    this.scannerModel,
    this.scannerHWSerialNumber,
    this.isActive = false,
    this.isAutoCommunicationSessionReestablishment = false,
    this.connectionType = ConnType.invalid,
  });

  factory DCSScannerInfo.fromMap(Map map) => DCSScannerInfo(
        scannerID: map['scannerId'] as int,
        scannerName: map['scannerName'] as String?,
        scannerModel: map['scannerModel'] as String?,
        scannerHWSerialNumber: map['scannerHWSerialNumber'] as String?,
        isActive: map['active'] as bool? ?? false,
        isAutoCommunicationSessionReestablishment: map['autoCommunicationSessionReestablishment'] as bool? ?? false,
        connectionType: _connTypeFromName(map['connectionType'] as String?),
      );
}

/// helpers/AvailableScanner.java
class AvailableScanner implements Comparable<AvailableScanner> {
  int scannerId;
  String? scannerName;
  String? scannerAddress;
  bool connected;
  bool autoReconnection;
  ConnType connectionType;
  bool isConnectable = false;

  AvailableScanner(this.scannerId, this.scannerName, this.scannerAddress, this.connected, this.autoReconnection,
      this.connectionType);

  /// new AvailableScanner(DCSScannerInfo)
  factory AvailableScanner.fromInfo(DCSScannerInfo info) => AvailableScanner(
        info.scannerID,
        info.scannerName,
        info.scannerHWSerialNumber,
        info.isActive,
        info.isAutoCommunicationSessionReestablishment,
        info.connectionType,
      );

  /// equals(): dibandingkan berdasarkan scannerName
  @override
  bool operator ==(Object other) => other is AvailableScanner && other.scannerName == scannerName;

  @override
  int get hashCode => scannerName.hashCode;

  @override
  int compareTo(AvailableScanner other) => (scannerName ?? '').compareTo(other.scannerName ?? '');
}

/// helpers/Barcode.java
class Barcode {
  final Uint8List barcodeData;
  final int barcodeType;
  final int fromScannerID;

  Barcode(this.barcodeData, this.barcodeType, this.fromScannerID);
}

// =====================================================================================
// ScannerAppEngine delegates
// =====================================================================================

mixin IScannerAppEngineDevListDelegate {
  bool scannersListHasBeenUpdated();
}

mixin IScannerAppEngineDevConnectionsDelegate {
  bool scannerHasAppeared(int scannerID);

  bool scannerHasDisappeared(int scannerID);

  bool scannerHasConnected(int scannerID);

  bool scannerHasDisconnected(int scannerID);
}

mixin IScannerAppEngineDevEventsDelegate {
  void scannerBarcodeEvent(Uint8List barcodeData, int barcodeType, int scannerID);
}

// =====================================================================================
// Application.java (state global) + BaseActivity (API ke SDK + dataHandler)
// =====================================================================================

class ScannerAppEngine {
  static const MethodChannel _channel = MethodChannel('id.kreen.android.appkioskcoex/zebra');
  static const EventChannel _events = EventChannel('id.kreen.android.appkioskcoex/zebra_events');

  static StreamSubscription? _subscription;

  /// Application.sdkHandler != null
  static bool sdkAvailable = false;

  // ---- Application.java ----
  static const int scannerIdNone = -1;
  static String currentScannerName = "";
  static String currentScannerAddress = "";
  static int currentScannerId = scannerIdNone;
  static bool currentAutoReconnectionState = true;
  static bool isAnyScannerConnected = false; //True, if currently connected to any scanner
  static int currentConnectedScannerID = -1; //Track scannerId of currently connected Scanner
  static bool intentionallyDisconnected = false;
  static final List<DCSScannerInfo> mScannerInfoList = [];
  static final List<DCSScannerInfo?> mOfflineScannerInfoList = [];
  static final List<Barcode> barcodeData = [];
  static DCSScannerInfo? currentConnectedScanner;
  static DCSScannerInfo? lastConnectedScanner;

  // ---- ScannersActivity2.curAvailableScanner ----
  static AvailableScanner? curAvailableScanner;

  // ---- delegates ----
  static final List<IScannerAppEngineDevListDelegate> mDevListDelegates = [];
  static final List<IScannerAppEngineDevConnectionsDelegate> mDevConnDelegates = [];
  static final List<IScannerAppEngineDevEventsDelegate> mDevEventsDelegates = [];

  static Map<String, int> _eventMasks = {};

  /// Application.onCreate: sdkHandler = new SDKHandler(this, true)
  /// BaseActivity.onCreate: dcssdkSetDelegate(this) + initializeDcsSdkWithAppSettings()
  static Future<bool> init() async {
    _subscription ??= _events.receiveBroadcastStream().listen(_onEvent);
    try {
      sdkAvailable = await _channel.invokeMethod<bool>('init') ?? false;
    } catch (e) {
      debugPrint('ScannerAppEngine.init: $e');
      sdkAvailable = false;
    }
    if (sdkAvailable) {
      _eventMasks = Map<String, int>.from(await _channel.invokeMethod<Map>('eventMasks') ?? {});
      await initializeDcsSdkWithAppSettings();
    }
    return sdkAvailable;
  }

  /// BaseActivity.onResume: Application.sdkHandler.dcssdkSetDelegate(this)
  static Future<void> setDelegate() async {
    if (!sdkAvailable) return;
    await _channel.invokeMethod('setDelegate');
  }

  /// BaseActivity.initializeDcsSdkWithAppSettings()
  ///
  /// SharedPreferences Constants.PREFS_NAME tidak pernah diisi di app ini, jadi nilai default yang dipakai:
  /// semua MOT_SETTING_EVENT_* = true, semua MOT_SETTING_NOTIFICATION_* = false.
  static Future<void> initializeDcsSdkWithAppSettings() async {
    int notificationsMask = 0;
    notificationsMask |= (_mask('SCANNER_APPEARANCE') | _mask('SCANNER_DISAPPEARANCE'));
    notificationsMask |= (_mask('SESSION_ESTABLISHMENT') | _mask('SESSION_TERMINATION'));
    notificationsMask |= _mask('BARCODE');
    notificationsMask |= _mask('IMAGE');
    notificationsMask |= _mask('VIDEO');
    notificationsMask |= _mask('BINARY_DATA');
    await _channel.invokeMethod('subscribeForEvents', {'mask': notificationsMask});
  }

  static int _mask(String name) => _eventMasks[name] ?? 0;

  /// DeviceSetting / Setting .initializeDcsSdk()
  static Future<void> initializeDcsSdk() async {
    if (!sdkAvailable) return;
    await _channel.invokeMethod('enableAvailableScannersDetection', {'enable': true});
    await _channel.invokeMethod('setOperationalMode', {'mode': 'DCSSDK_OPMODE_BT_NORMAL'});
    await _channel.invokeMethod('setOperationalMode', {'mode': 'DCSSDK_OPMODE_SNAPI'});
    await _channel.invokeMethod('setOperationalMode', {'mode': 'DCSSDK_OPMODE_BT_LE'});
    await _channel.invokeMethod('setOperationalMode', {'mode': 'DCSSDK_OPMODE_USB_CDC'});
  }

  /// broadcastSCAisListening()
  static Future<void> broadcastSCAisListening() => _channel.invokeMethod('broadcastListening');

  /// configureNotificationAvailable(enable)
  static Future<void> configureNotificationAvailable(bool enable) async {
    if (!sdkAvailable) return;
    final mask = _mask('SCANNER_APPEARANCE') | _mask('SCANNER_DISAPPEARANCE');
    await _channel.invokeMethod(enable ? 'subscribeForEvents' : 'unsubscribeForEvents', {'mask': mask});
  }

  static Future<void> stopScanningDevices() async {
    if (!sdkAvailable) return;
    await _channel.invokeMethod('stopScanningDevices');
  }

  // ---- API calls for UI View Controllers ----

  static void addDevListDelegate(IScannerAppEngineDevListDelegate delegate) => mDevListDelegates.add(delegate);

  static void addDevConnectionsDelegate(IScannerAppEngineDevConnectionsDelegate delegate) {
    if (!mDevConnDelegates.contains(delegate)) mDevConnDelegates.add(delegate);
  }

  static void addDevEventsDelegate(IScannerAppEngineDevEventsDelegate delegate) {
    if (!mDevEventsDelegates.contains(delegate)) mDevEventsDelegates.add(delegate);
  }

  static void removeDevListDelegate(IScannerAppEngineDevListDelegate delegate) => mDevListDelegates.remove(delegate);

  static void removeDevConnectiosDelegate(IScannerAppEngineDevConnectionsDelegate delegate) =>
      mDevConnDelegates.remove(delegate);

  static void removeDevEventsDelegate(IScannerAppEngineDevEventsDelegate delegate) =>
      mDevEventsDelegates.remove(delegate);

  static List<DCSScannerInfo> getActualScannersList() => mScannerInfoList;

  static DCSScannerInfo? getScannerByID(int scannerId) {
    for (final scannerInfo in mScannerInfoList) {
      if (scannerInfo.scannerID == scannerId) return scannerInfo;
    }
    return null;
  }

  /// BaseActivity.updateScannersList()
  static Future<void> updateScannersList() async {
    if (!sdkAvailable) return;
    final list = await _channel.invokeMethod<List>('getScannersList') ?? [];
    mScannerInfoList
      ..clear()
      ..addAll(list.map((e) => DCSScannerInfo.fromMap(e as Map)));
  }

  /// Application.sdkHandler.dcssdkGetActiveScannersList(activeScanners)
  static Future<List<DCSScannerInfo>> getActiveScannersList() async {
    if (!sdkAvailable) return [];
    final list = await _channel.invokeMethod<List>('getActiveScannersList') ?? [];
    return list.map((e) => DCSScannerInfo.fromMap(e as Map)).toList();
  }

  /// BaseActivity.connect(scannerId) -> DCSSDK_RESULT
  static Future<bool> connect(int scannerId) async {
    if (!sdkAvailable) return false;
    if (curAvailableScanner != null) {
      await _channel.invokeMethod('terminateCommunicationSession', {'scannerId': curAvailableScanner!.scannerId});
    }
    final result = await _channel.invokeMethod<String>('establishCommunicationSession', {'scannerId': scannerId});
    return result == 'DCSSDK_RESULT_SUCCESS';
  }

  /// BaseActivity.disconnect(scannerId)
  static Future<void> disconnect(int scannerId) async {
    if (!sdkAvailable) return;
    await _channel.invokeMethod('terminateCommunicationSession', {'scannerId': scannerId});
    curAvailableScanner = null;
    intentionallyDisconnected = true;

    await updateScannersList();
  }

  /// BaseActivity.setAutoReconnectOption(scannerId, enable)
  static Future<void> setAutoReconnectOption(int scannerId, bool enable) async {
    if (!sdkAvailable) return;
    await _channel.invokeMethod('enableAutomaticSessionReestablishment', {'enable': enable, 'scannerId': scannerId});
  }

  /// BaseActivity.executeCommand(opCode, inXML, outXML, scannerID)
  static Future<String> executeCommand(String opCode, String inXml, int scannerID) async {
    if (!sdkAvailable) return "";
    final result = await _channel.invokeMethod<Map>('executeCommand', {
      'opCode': opCode,
      'inXml': inXml,
      'scannerId': scannerID,
    });
    return result?['outXml'] as String? ?? "";
  }

  // ---- dataHandler (BaseActivity) ----

  static void _onEvent(dynamic raw) {
    final event = Map<String, dynamic>.from(raw as Map);
    switch (event['event']) {
      case 'barcode':
        final barcode = Barcode(
          event['barcodeData'] as Uint8List,
          event['barcodeType'] as int,
          event['fromScannerID'] as int,
        );
        barcodeData.add(barcode);
        for (final delegate in List.of(mDevEventsDelegates)) {
          delegate.scannerBarcodeEvent(barcode.barcodeData, barcode.barcodeType, barcode.fromScannerID);
        }
        break;

      case 'sessionEstablished':
        final activeScanner = DCSScannerInfo.fromMap(event['scanner'] as Map);
        curAvailableScanner = AvailableScanner.fromInfo(activeScanner);
        curAvailableScanner!.connected = true;
        setAutoReconnectOption(activeScanner.scannerID, true);

        /* notify connections delegates */
        for (final delegate in List.of(mDevConnDelegates)) {
          delegate.scannerHasConnected(activeScanner.scannerID);
        }

        /* update dev list */
        for (final exInfo in List.of(mScannerInfoList)) {
          if (exInfo.scannerID == activeScanner.scannerID) {
            mScannerInfoList.remove(exInfo);
            barcodeData.clear();
            break;
          }
        }
        mOfflineScannerInfoList.removeWhere((off) => off?.scannerID == activeScanner.scannerID);
        mScannerInfoList.add(activeScanner);

        /* notify dev list delegates */
        for (final delegate in List.of(mDevListDelegates)) {
          delegate.scannersListHasBeenUpdated();
        }
        break;

      case 'sessionTerminated':
        final scannerID = event['scannerId'] as int;

        /* notify connections delegates */
        for (final delegate in List.of(mDevConnDelegates)) {
          delegate.scannerHasDisconnected(scannerID);
        }

        final scannerInfo = getScannerByID(scannerID);
        mOfflineScannerInfoList.add(scannerInfo);
        if (scannerInfo != null) {
          curAvailableScanner = null;
        }
        updateScannersList().then((_) {
          /* notify dev list delegates */
          for (final delegate in List.of(mDevListDelegates)) {
            delegate.scannersListHasBeenUpdated();
          }
        });
        break;

      case 'scannerAppeared':
      case 'auxScannerAppeared':
        final availableScanner = DCSScannerInfo.fromMap(event['scanner'] as Map);
        for (final delegate in List.of(mDevConnDelegates)) {
          delegate.scannerHasAppeared(availableScanner.scannerID);
        }
        for (final exInfo in List.of(mScannerInfoList)) {
          if (exInfo.scannerID == availableScanner.scannerID) {
            mScannerInfoList.remove(exInfo);
            break;
          }
        }
        mScannerInfoList.add(availableScanner);
        for (final delegate in List.of(mDevListDelegates)) {
          delegate.scannersListHasBeenUpdated();
        }
        break;

      case 'scannerDisappeared':
        final scannerID = event['scannerId'] as int;
        for (final delegate in List.of(mDevConnDelegates)) {
          delegate.scannerHasDisappeared(scannerID);
        }
        for (final exInfo in List.of(mScannerInfoList)) {
          if (exInfo.scannerID == scannerID) {
            mScannerInfoList.remove(exInfo);
            break;
          }
        }
        for (final delegate in List.of(mDevListDelegates)) {
          delegate.scannersListHasBeenUpdated();
        }
        if (curAvailableScanner != null && scannerID == curAvailableScanner!.scannerId) {
          curAvailableScanner = null;
        }
        break;
    }
  }

  /// new String(barcodeData)
  static String barcodeToString(Uint8List data) => utf8.decode(data, allowMalformed: true);
}
