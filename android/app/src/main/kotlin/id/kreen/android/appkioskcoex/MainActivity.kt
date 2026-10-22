package id.kreen.android.appkioskcoex

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var zebraBridge: ZebraBridge? = null
    private var printerBridge: PrinterBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        zebraBridge = ZebraBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        printerBridge = PrinterBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        zebraBridge?.dispose()
        printerBridge?.dispose()
        super.onDestroy()
    }
}
