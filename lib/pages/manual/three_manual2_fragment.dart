import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/models/response_model.dart';
import 'package:appkioskcoex/pages/kiosk_host.dart';
import 'package:appkioskcoex/pages/manual/main_manual_page.dart';
import 'package:appkioskcoex/pages/manual/one_manual_fragment.dart';
import 'package:appkioskcoex/pages/shared_fragment_views.dart';
import 'package:appkioskcoex/services/printer_service.dart';
import 'package:flutter/material.dart';

/// manual/ThreeManual2Fragment.java -> fragment_three_manual2.xml
/// (tidak dibuka dari mana pun di app asli; reprint pakai template QR center)
class ThreeManual2Fragment extends StatefulWidget {
  const ThreeManual2Fragment({super.key});

  @override
  State<ThreeManual2Fragment> createState() => _ThreeManual2FragmentState();
}

class _ThreeManual2FragmentState extends State<ThreeManual2Fragment> {
  late final MainManualPageState activity = KioskHost.of(context) as MainManualPageState;

  String? fullName, email, idTicket;
  String? instansi, jobTitle;
  List<OrderFormModel>? orderForms;
  String? showQr;
  List<OrderFormModel>? formValuess;

  bool btnReprintEnabled = true;
  bool _created = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;

    idTicket = activity.idTicket;
    showQr = activity.showQr;
    fullName = activity.fullName;
    // sama seperti Completed2Fragment: field email tidak diisi di app asli (tercetak "null")
    email = activity.email;
    orderForms = activity.orderForm;
    formValuess = activity.formValues;
  }

  Future<void> printPdfUSB(String filename, String? title, String? subtitle, String? idTicket, String? jobtitle,
      String? showQr) async {
    setState(() => btnReprintEnabled = false);

    final file = await PrinterService.buildPdfDynamicQrCenter(filename, idTicket, formValuess, "", fullName, email);

    if (file != null) {
      PrinterService.printPdfUSB(file);
    }

    if (mounted) setState(() => btnReprintEnabled = true);
  }

  @override
  Widget build(BuildContext context) {
    return CompletedView(
      imageHeight: dsdp(100),
      arrowMargin: dsdp(2),
      reprintEnabled: btnReprintEnabled,
      onReprint: () => printPdfUSB("namecard", fullName, instansi, idTicket, jobTitle, showQr),
      onCompleted: () => activity.replaceFragment(() => const OneManualFragment()),
    );
  }
}
