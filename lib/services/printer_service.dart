import 'package:appkioskcoex/models/response_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Jembatan ke Brother Print SDK (BrotherPrintLibrary.aar) + TemplatePdf (android.graphics.pdf.PdfDocument).
///
/// Template PDF digambar di native memakai utils/TemplatePdf.java asli (tidak diubah) supaya hasil
/// label sama persis dengan app Android asli. Kapan print, template mana, dan navigasi setelahnya tetap di Dart.
class PrinterService {
  static const MethodChannel _channel = MethodChannel('id.kreen.android.appkioskcoex/printer');

  /// TemplatePdf.buildPdf2(getContext(), filename, title, subtitle, id_ticket, job_title, event_buyer, answer)
  static Future<String?> buildPdf2(String filename, String? title, String? subtitle, String? idTicket,
      String? jobtitle, int eventBuyer, String? answer) {
    return _channel.invokeMethod<String>('buildPdf2', {
      'filename': filename,
      'title': title,
      'subtitle': subtitle,
      'idTicket': idTicket,
      'jobtitle': jobtitle,
      'eventBuyer': eventBuyer,
      'answer': answer,
    });
  }

  /// TemplatePdf.buildPdfDynamicQrCenter(getContext(), filename, id_ticket, formValuess, "", full_name, email)
  static Future<String?> buildPdfDynamicQrCenter(String filename, String? idTicket, List<OrderFormModel>? formValues,
      String answer, String? fullName, String? email) {
    return _channel.invokeMethod<String>('buildPdfDynamicQrCenter', {
      'filename': filename,
      'idTicket': idTicket,
      'formValues': (formValues ?? []).map((e) => e.toPdfMap()).toList(),
      'answer': answer,
      'fullName': fullName,
      'email': email,
    });
  }

  /// TemplatePdf.buildPdf1(...) (tidak mengembalikan path)
  static Future<void> buildPdf1(String filename, String? title, String? subtitle, String? idTicket, String? jobtitle,
      int eventBuyer, String? answer) {
    return _channel.invokeMethod('buildPdf1', {
      'filename': filename,
      'title': title,
      'subtitle': subtitle,
      'idTicket': idTicket,
      'jobtitle': jobtitle,
      'eventBuyer': eventBuyer,
      'answer': answer,
    });
  }

  /// TemplatePdf.buildPdfDynamic(context, filename, id_ticket, detailValues)
  static Future<String?> buildPdfDynamic(String filename, String? idTicket, List<String> detailValues) {
    return _channel.invokeMethod<String>('buildPdfDynamic', {
      'filename': filename,
      'idTicket': idTicket,
      'detailValues': detailValues,
    });
  }

  /// TemplatePdf.buildPdfDynamicQr(context, filename, id_ticket, detailValues, answer)
  static Future<String?> buildPdfDynamicQr(String filename, String? idTicket, List<String> detailValues, String answer) {
    return _channel.invokeMethod<String>('buildPdfDynamicQr', {
      'filename': filename,
      'idTicket': idTicket,
      'detailValues': detailValues,
      'answer': answer,
    });
  }

  /// buildPdf* private fragment asli (FragmentPdfTemplates.java): buildPdf, buildPdf2, buildPdf_,
  /// buildPdf2_, buildPdf2_2, buildPdf2_mulitlineCenter, buildPdf2_mulitlineCenterQrcode, buildPdf_final,
  /// buildPdf_MakeSureData2Fragment, buildPdfMfinal.
  static Future<String?> fragmentPdf(
    String name, {
    required String filename,
    String? title,
    String? subtitle,
    String? idTicket,
    String? jobtitle,
    int eventBuyer = 0,
    String answer = "",
    List<String>? detailValues,
  }) {
    return _channel.invokeMethod<String>('fragmentPdf', {
      'name': name,
      'filename': filename,
      'title': title,
      'subtitle': subtitle,
      'idTicket': idTicket,
      'jobtitle': jobtitle,
      'eventBuyer': eventBuyer,
      'answer': answer,
      'detailValues': detailValues,
    });
  }

  /// BarcodeEncoder().encodeBitmap(contents, BarcodeFormat.QR_CODE, size, size) -> PNG
  static Future<Uint8List?> encodeQrPng(String? contents, int size) async {
    try {
      return await _channel.invokeMethod<Uint8List>('encodeQrPng', {'contents': contents, 'size': size});
    } catch (e) {
      debugPrint('encodeQrPng: $e');
      return null;
    }
  }

  /// printPdfNET(): print lewat jaringan (192.168.67.86) file /storage/emulated/0/namecard.pdf
  static Future<bool> printPdfNET() async {
    try {
      final result = await _channel.invokeMethod<Map>('printPdfNET');
      return result?['started'] == true && result?['errorCode'] == 'ERROR_NONE';
    } catch (e) {
      debugPrint('printPdfNET: $e');
      return false;
    }
  }

  /// Bagian "Specify printer ... Connect, then print" di printPdfUSB().
  ///
  /// Return true kalau printer.startCommunication() berhasil dan
  /// result.errorCode == PrinterInfo.ErrorCode.ERROR_NONE.
  static Future<bool> printPdfUSB(String file) async {
    try {
      final result = await _channel.invokeMethod<Map>('printPdfUSB', {'file': file});
      final started = result?['started'] == true;
      final errorCode = result?['errorCode'] as String?;
      if (started && errorCode != 'ERROR_NONE') debugPrint("ERROR - $errorCode");
      return started && errorCode == 'ERROR_NONE';
    } catch (e) {
      debugPrint('printPdfUSB: $e');
      return false;
    }
  }
}
