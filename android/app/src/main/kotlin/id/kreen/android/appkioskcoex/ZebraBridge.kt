package id.kreen.android.appkioskcoex

import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.zebra.scannercontrol.DCSSDKDefs
import com.zebra.scannercontrol.DCSScannerInfo
import com.zebra.scannercontrol.FirmwareUpdateEvent
import com.zebra.scannercontrol.IDcsSdkApiDelegate
import com.zebra.scannercontrol.SDKHandler
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Jembatan ke Zebra Scanner SDK (barcode_scanner_library_v2.6.6.0-release.aar).
 *
 * Pengganti Application.sdkHandler + IDcsSdkApiDelegate di BaseActivity. Native di sini hanya
 * meneruskan pemanggilan SDK; state (mScannerInfoList, delegate, currentScanner, dsb) dan logic
 * dataHandler ada di Dart (lib/services/scanner_app_engine.dart), sama seperti di BaseActivity.
 */
class ZebraBridge(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler, IDcsSdkApiDelegate {

    private val channel = MethodChannel(messenger, "id.kreen.android.appkioskcoex/zebra")
    private val eventChannel = EventChannel(messenger, "id.kreen.android.appkioskcoex/zebra_events")
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private var events: EventChannel.EventSink? = null

    init {
        channel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        executor.shutdown()
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        events = sink
    }

    override fun onCancel(arguments: Any?) {
        events = null
    }

    private fun emit(data: Map<String, Any?>) {
        mainHandler.post { events?.success(data) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Application.onCreate / BaseActivity.onCreate: new SDKHandler(this, true)
            "init" -> {
                if (sdkHandler == null) {
                    try {
                        sdkHandler = SDKHandler(activity.applicationContext, true)
                    } catch (e: SecurityException) {
                        // Terjadi di Android 12+ (API 31+) saat targetSdkVersion > 31:
                        // Zebra SDK versi lama membaca Settings.Secure.BLUETOOTH_ADDRESS
                        // yang sudah dibatasi OS sejak API 32.
                        Log.e(TAG, "SDKHandler init gagal: bluetooth_address dibatasi di SDK 32+", e)
                        sdkHandler = null
                    } catch (e: Exception) {
                        Log.e(TAG, "SDKHandler init gagal (unexpected)", e)
                        sdkHandler = null
                    }
                }
                sdkHandler?.dcssdkSetDelegate(this)
                result.success(sdkHandler != null)
            }

            "eventMasks" -> result.success(
                mapOf(
                    "SCANNER_APPEARANCE" to DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_SCANNER_APPEARANCE.value,
                    "SCANNER_DISAPPEARANCE" to DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_SCANNER_DISAPPEARANCE.value,
                    "SESSION_ESTABLISHMENT" to DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_SESSION_ESTABLISHMENT.value,
                    "SESSION_TERMINATION" to DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_SESSION_TERMINATION.value,
                    "BARCODE" to DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_BARCODE.value,
                    "IMAGE" to DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_IMAGE.value,
                    "VIDEO" to DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_VIDEO.value,
                    "BINARY_DATA" to DCSSDKDefs.DCSSDK_EVENT.DCSSDK_EVENT_BINARY_DATA.value,
                )
            )

            "setDelegate" -> {
                sdkHandler?.dcssdkSetDelegate(this)
                result.success(null)
            }

            "subscribeForEvents" -> {
                sdkHandler?.dcssdkSubsribeForEvents(call.argument<Int>("mask")!!)
                result.success(null)
            }

            "unsubscribeForEvents" -> {
                sdkHandler?.dcssdkUnsubsribeForEvents(call.argument<Int>("mask")!!)
                result.success(null)
            }

            "enableAvailableScannersDetection" -> {
                sdkHandler?.dcssdkEnableAvailableScannersDetection(call.argument<Boolean>("enable")!!)
                result.success(null)
            }

            "setOperationalMode" -> {
                val mode = DCSSDKDefs.DCSSDK_MODE.valueOf(call.argument<String>("mode")!!)
                sdkHandler?.dcssdkSetOperationalMode(mode)
                result.success(null)
            }

            // BaseActivity.updateScannersList(): available + active, lalu createFlatScannerList()
            "getScannersList" -> {
                val list = ArrayList<Map<String, Any?>>()
                sdkHandler?.let { sdk ->
                    val scannerTreeList = ArrayList<DCSScannerInfo>()
                    sdk.dcssdkGetAvailableScannersList(scannerTreeList)
                    sdk.dcssdkGetActiveScannersList(scannerTreeList)
                    for (s in scannerTreeList) addToScannerList(s, list)
                }
                result.success(list)
            }

            "getActiveScannersList" -> {
                val list = ArrayList<Map<String, Any?>>()
                sdkHandler?.let { sdk ->
                    val activeScanners = ArrayList<DCSScannerInfo>()
                    sdk.dcssdkGetActiveScannersList(activeScanners)
                    for (s in activeScanners) list.add(scannerToMap(s))
                }
                result.success(list)
            }

            // dipanggil dari AsyncTask.doInBackground di app asli -> jalankan di background thread
            "establishCommunicationSession" -> {
                val scannerId = call.argument<Int>("scannerId")!!
                executor.execute {
                    val ret = sdkHandler?.dcssdkEstablishCommunicationSession(scannerId)
                        ?: DCSSDKDefs.DCSSDK_RESULT.DCSSDK_RESULT_FAILURE
                    mainHandler.post { result.success(ret.name) }
                }
            }

            "terminateCommunicationSession" -> {
                val scannerId = call.argument<Int>("scannerId")!!
                val ret = sdkHandler?.dcssdkTerminateCommunicationSession(scannerId)
                    ?: DCSSDKDefs.DCSSDK_RESULT.DCSSDK_RESULT_FAILURE
                result.success(ret.name)
            }

            "enableAutomaticSessionReestablishment" -> {
                val ret = sdkHandler?.dcssdkEnableAutomaticSessionReestablishment(
                    call.argument<Boolean>("enable")!!, call.argument<Int>("scannerId")!!
                ) ?: DCSSDKDefs.DCSSDK_RESULT.DCSSDK_RESULT_FAILURE
                result.success(ret.name)
            }

            // BaseActivity.executeCommand(opCode, inXML, outXML, scannerID)
            "executeCommand" -> {
                val opCode = DCSSDKDefs.DCSSDK_COMMAND_OPCODE.valueOf(call.argument<String>("opCode")!!)
                val inXml = call.argument<String>("inXml")!!
                val scannerId = call.argument<Int>("scannerId")!!
                executor.execute {
                    val outXml = StringBuilder()
                    val ret = sdkHandler?.dcssdkExecuteCommandOpCodeInXMLForScanner(opCode, inXml, outXml, scannerId)
                    val success = ret == DCSSDKDefs.DCSSDK_RESULT.DCSSDK_RESULT_SUCCESS
                    mainHandler.post { result.success(mapOf("success" to success, "outXml" to outXml.toString())) }
                }
            }

            "stopScanningDevices" -> {
                sdkHandler?.dcssdkStopScanningDevices()
                result.success(null)
            }

            // broadcastSCAisListening()
            "broadcastListening" -> {
                val intent = Intent()
                intent.action = "com.zebra.scannercontrol.LISTENING_STARTED"
                activity.sendBroadcast(intent)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun addToScannerList(s: DCSScannerInfo, out: MutableList<Map<String, Any?>>) {
        out.add(scannerToMap(s))
        s.auxiliaryScanners?.values?.forEach { aux -> addToScannerList(aux, out) }
    }

    private fun scannerToMap(s: DCSScannerInfo): Map<String, Any?> = mapOf(
        "scannerId" to s.scannerID,
        "scannerName" to s.scannerName,
        "scannerModel" to s.scannerModel,
        "scannerHWSerialNumber" to s.scannerHWSerialNumber,
        "active" to s.isActive,
        "autoCommunicationSessionReestablishment" to s.isAutoCommunicationSessionReestablishment,
        "connectionType" to s.connectionType?.name,
    )

    /* ###################################################################### */
    /* ########## IDcsSdkApiDelegate Protocol implementation ################ */
    /* ###################################################################### */
    override fun dcssdkEventScannerAppeared(availableScanner: DCSScannerInfo) {
        emit(mapOf("event" to "scannerAppeared", "scanner" to scannerToMap(availableScanner)))
    }

    override fun dcssdkEventScannerDisappeared(scannerID: Int) {
        emit(mapOf("event" to "scannerDisappeared", "scannerId" to scannerID))
    }

    override fun dcssdkEventCommunicationSessionEstablished(activeScanner: DCSScannerInfo) {
        emit(mapOf("event" to "sessionEstablished", "scanner" to scannerToMap(activeScanner)))
    }

    override fun dcssdkEventCommunicationSessionTerminated(scannerID: Int) {
        emit(mapOf("event" to "sessionTerminated", "scannerId" to scannerID))
    }

    override fun dcssdkEventBarcode(barcodeData: ByteArray, barcodeType: Int, fromScannerID: Int) {
        emit(
            mapOf(
                "event" to "barcode",
                "barcodeData" to barcodeData,
                "barcodeType" to barcodeType,
                "fromScannerID" to fromScannerID,
            )
        )
    }

    override fun dcssdkEventAuxScannerAppeared(newTopology: DCSScannerInfo, auxScanner: DCSScannerInfo) {
        emit(mapOf("event" to "auxScannerAppeared", "scanner" to scannerToMap(auxScanner)))
    }

    override fun dcssdkEventFirmwareUpdate(firmwareUpdateEvent: FirmwareUpdateEvent) {}

    override fun dcssdkEventImage(imageData: ByteArray, fromScannerID: Int) {}

    override fun dcssdkEventVideo(videoFrame: ByteArray, fromScannerID: Int) {}

    override fun dcssdkEventBinaryData(binaryData: ByteArray, fromScannerID: Int) {
        Log.d(TAG, "BinaryData Event received no.of bytes : " + binaryData.size + " for Scanner ID : " + fromScannerID)
    }

    companion object {
        private const val TAG = "ZebraBridge"

        // Application.sdkHandler
        var sdkHandler: SDKHandler? = null
    }
}
