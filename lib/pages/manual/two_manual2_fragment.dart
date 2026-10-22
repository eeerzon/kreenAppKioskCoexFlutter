import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/models/response_model.dart';
import 'package:appkioskcoex/pages/kiosk_host.dart';
import 'package:appkioskcoex/pages/manual/main_manual_page.dart';
import 'package:appkioskcoex/pages/manual/one_manual_fragment.dart';
import 'package:appkioskcoex/pages/manual/three_manual_fragment.dart';
import 'package:appkioskcoex/pages/pdf_preview_page.dart';
import 'package:appkioskcoex/pages/shared_fragment_views.dart';
import 'package:appkioskcoex/services/lang_service.dart';
import 'package:appkioskcoex/services/printer_service.dart';
import 'package:flutter/material.dart';

/// manual/TwoManual2Fragment.java -> fragment_two_manual2.xml
class TwoManual2Fragment extends StatefulWidget {
  final String idEvent; // getArguments().getString("id_event", "")

  const TwoManual2Fragment({super.key, this.idEvent = ""});

  @override
  State<TwoManual2Fragment> createState() => _TwoManual2FragmentState();
}

class _TwoManual2FragmentState extends State<TwoManual2Fragment> {
  late final MainManualPageState activity = KioskHost.of(context) as MainManualPageState;

  String? fullName, email, idTicket;
  String answer = "";
  String? instansi, jobTitle;
  List<OrderFormModel>? orderForms;
  String? showQr;
  List<OrderFormModel>? formValuess;

  bool canPrint = false;
  bool btnPrintEnabled = true;
  bool _created = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;

    canPrint = allowedEventId == widget.idEvent;
    idTicket = activity.idTicket;
    showQr = activity.showQr;
    fullName = activity.fullName;
    email = activity.email;
    orderForms = activity.orderForm;
    formValuess = activity.formValues;

    // btnPrintPreview (PdfPreviewActivity) visibility GONE
  }

  /// btnPrintPreview (visibility GONE di layout) -> PdfPreviewActivity
  void onPrintPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(fullName: fullName, idTicket: idTicket, answer: answer, formValues: formValuess),
      ),
    );
  }

  void onPrint() {
    if (canPrint) {
      // === Event yang boleh print ===
      printPdfUSB("namecard", fullName, instansi, idTicket, jobTitle, showQr);
    } else {
      activity.replaceFragment(() => const OneManualFragment());
    }
  }

  Future<void> printPdfUSB(String filename, String? title, String? subtitle, String? idTicket, String? jobtitle,
      String? showQr) async {
    setState(() => btnPrintEnabled = false);

    final file = await PrinterService.buildPdfDynamicQrCenter(filename, idTicket, formValuess, "", fullName, email);

    debugPrint("File: $file");
    if (file != null) {
      // Connect, then print (thread terpisah)
      PrinterService.printPdfUSB(file).then((success) {
        if (success) {
          activity.replaceFragment(() => const ThreeManualFragment());
        }
      });
    }

    if (mounted) setState(() => btnPrintEnabled = true);
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmDataView(
      fullName: fullName,
      email: email,
      orderForms: orderForms,
      ifYesTextSize: dsdp(15),
      printText: canPrint ? LangService.getString('print') : LangService.getString('completed'),
      printEnabled: btnPrintEnabled,
      onBack: () => activity.replaceFragment(() => const OneManualFragment()),
      onPrint: onPrint,
    );
  }
}
