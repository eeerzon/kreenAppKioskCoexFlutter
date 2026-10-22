package id.kreen.android.appkioskcoex

import android.app.Activity
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.brother.ptouch.sdk.LabelInfo
import com.brother.ptouch.sdk.Printer
import com.brother.ptouch.sdk.PrinterInfo
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Jembatan ke Brother Print SDK (BrotherPrintLibrary.aar) + TemplatePdf.java / FragmentPdfTemplates.java.
 *
 * printPdfUSB() di sini = bagian "Specify printer ... Connect, then print" dari
 * MakeSureData2Fragment / Completed2Fragment / TwoManual2Fragment / ThreeManualFragment.
 * Keputusan template & navigasi setelah print tetap di Dart.
 */
class PrinterBridge(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "id.kreen.android.appkioskcoex/printer")
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // utils/TemplatePdf.java (file asli, tidak diubah)
            "buildPdf1" -> {
                TemplatePdf.buildPdf1(
                    activity, call.argument("filename"), call.argument("title"), call.argument("subtitle"),
                    call.argument("idTicket"), call.argument("jobtitle"), call.argument<Int>("eventBuyer") ?: 0,
                    call.argument("answer"),
                )
                result.success(null)
            }

            "buildPdf2" -> result.success(
                TemplatePdf.buildPdf2(
                    activity, call.argument("filename"), call.argument("title"), call.argument("subtitle"),
                    call.argument("idTicket"), call.argument("jobtitle"), call.argument<Int>("eventBuyer") ?: 0,
                    call.argument("answer"),
                )
            )

            "buildPdfDynamic" -> result.success(
                TemplatePdf.buildPdfDynamic(
                    activity, call.argument("filename"), call.argument("idTicket"),
                    call.argument<List<String>>("detailValues"),
                )
            )

            "buildPdfDynamicQr" -> result.success(
                TemplatePdf.buildPdfDynamicQr(
                    activity, call.argument("filename"), call.argument("idTicket"),
                    call.argument<List<String>>("detailValues"), call.argument("answer"),
                )
            )

            "buildPdfDynamicQrCenter" -> result.success(
                TemplatePdf.buildPdfDynamicQrCenter(
                    activity, call.argument("filename"), call.argument("idTicket"),
                    toOrderForms(call.argument<List<Map<String, Any?>>>("formValues")),
                    call.argument("answer"), call.argument("fullName"), call.argument("email"),
                )
            )

            // buildPdf* private dari fragment asli (FragmentPdfTemplates.java)
            "fragmentPdf" -> {
                val name = call.argument<String>("name")!!
                val eventBuyer = call.argument<Int>("eventBuyer") ?: 0
                val answer = call.argument<String>("answer") ?: ""
                val filename = call.argument<String>("filename")
                val idTicket = call.argument<String>("idTicket")
                val path = if (name == "buildPdfMfinal") {
                    FragmentPdfTemplates.buildPdfMfinal(
                        activity, eventBuyer, answer, filename, idTicket, call.argument<List<String>>("detailValues")
                    )
                } else {
                    val m = FragmentPdfTemplates::class.java.getMethod(
                        name, android.content.Context::class.java, Int::class.javaPrimitiveType, String::class.java,
                        String::class.java, String::class.java, String::class.java, String::class.java, String::class.java,
                    )
                    m.invoke(
                        null, activity, eventBuyer, answer, filename, call.argument<String>("title"),
                        call.argument<String>("subtitle"), idTicket, call.argument<String>("jobtitle"),
                    ) as String?
                }
                result.success(path)
            }

            // PdfPreviewActivity: BarcodeEncoder().encodeBitmap(idTicket, QR_CODE, size, size)
            "encodeQrPng" -> {
                try {
                    val size = call.argument<Int>("size") ?: 400
                    val bitmap = com.journeyapps.barcodescanner.BarcodeEncoder()
                        .encodeBitmap(call.argument<String>("contents"), com.google.zxing.BarcodeFormat.QR_CODE, size, size)
                    val out = java.io.ByteArrayOutputStream()
                    bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, out)
                    result.success(out.toByteArray())
                } catch (e: Exception) {
                    e.printStackTrace()
                    result.success(null)
                }
            }

            "printPdfUSB" -> printPdfUSB(call, result)

            "printPdfNET" -> printPdfNET(call, result)

            else -> result.notImplemented()
        }
    }

    private fun toOrderForms(list: List<Map<String, Any?>>?): List<OrderFormModel> =
        (list ?: emptyList()).map {
            OrderFormModel().apply {
                question = it["question"] as String?
                answer = it["answer"] as String?
            }
        }

    /** printPdfNET(): QL_820NWB via jaringan (ip 192.168.67.86), mencetak /storage/emulated/0/namecard.pdf */
    private fun printPdfNET(call: MethodCall, result: MethodChannel.Result) {
        // Specify printer
        val printer = Printer()
        val settings = printer.printerInfo
        settings.printerModel = PrinterInfo.Model.QL_820NWB
        settings.port = PrinterInfo.Port.NET
        settings.ipAddress = "192.168.67.86"
        settings.workPath = "storage/emulated/0/"

        // Print Settings
        settings.labelNameIndex = LabelInfo.QL700.W62.ordinal
        settings.printMode = PrinterInfo.PrintMode.FIT_TO_PAGE
        settings.orientation = PrinterInfo.Orientation.PORTRAIT
        settings.isAutoCut = true
        printer.printerInfo = settings

        // Connect, then print
        Thread {
            var started = false
            var errorCode: String? = null
            if (printer.startCommunication()) {
                started = true
                val status = printer.printPdfFile("/storage/emulated/0/namecard.pdf", 1)
                errorCode = status.errorCode.name
                printer.endCommunication()
            }
            mainHandler.post { result.success(mapOf("started" to started, "errorCode" to errorCode)) }
        }.start()
    }

    private fun printPdfUSB(call: MethodCall, result: MethodChannel.Result) {
        val file = call.argument<String>("file")!!

        // Specify printer
        val printer = Printer()

        //prepare usb connection
        val usbManager = activity.getSystemService(Context.USB_SERVICE) as UsbManager
        val usbDevice = printer.getUsbDevice(usbManager)
        val permissionIntent = PendingIntent.getBroadcast(activity, 0, Intent(ACTION_USB_PERMISSION), intentFlags)
        if (usbDevice != null) {
            usbManager.requestPermission(usbDevice, permissionIntent)
        }

        //print setting
        val settings = printer.printerInfo
        settings.printerModel = PrinterInfo.Model.QL_820NWB
        settings.port = PrinterInfo.Port.USB
        settings.workPath = "storage/emulated/0/"

        // Print Settings
        settings.labelNameIndex = LabelInfo.QL700.W62.ordinal
        settings.printMode = PrinterInfo.PrintMode.FIT_TO_PAGE
        settings.orientation = PrinterInfo.Orientation.PORTRAIT
        settings.isAutoCut = true
        printer.printerInfo = settings

        // Connect, then print
        Thread {
            var started = false
            var errorCode: String? = null
            if (printer.startCommunication()) {
                started = true
                val status = printer.printPdfFile(file, 1)
                errorCode = status.errorCode.name
                if (status.errorCode != PrinterInfo.ErrorCode.ERROR_NONE) {
                    Log.d("TAG", "ERROR - " + status.errorCode)
                }
                printer.endCommunication()
            }
            mainHandler.post {
                result.success(mapOf("started" to started, "errorCode" to errorCode))
            }
        }.start()
    }

    companion object {
        private const val ACTION_USB_PERMISSION = "com.android.example.USB_PERMISSION"
        private val intentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
    }
}
