import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/models/response_model.dart';
import 'package:appkioskcoex/pages/kiosk_host.dart';
import 'package:appkioskcoex/pages/scan/main_activity2_page.dart';
import 'package:appkioskcoex/pages/scan/scan_fragment.dart';
import 'package:appkioskcoex/pages/shared_fragment_views.dart';
import 'package:appkioskcoex/services/printer_service.dart';
import 'package:flutter/material.dart';

/// fragment/Completed2Fragment.java -> fragment_completed2.xml
class Completed2Fragment extends StatefulWidget {
  const Completed2Fragment({super.key});

  @override
  State<Completed2Fragment> createState() => _Completed2FragmentState();
}

class _Completed2FragmentState extends State<Completed2Fragment> {
  late final MainActivity2PageState activity = KioskHost.of(context) as MainActivity2PageState;

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
    // app asli tidak mengisi field email di fragment ini, sehingga reprint mencetak teks "null"
    // di baris email. Di sini diisi dari activity supaya hasil reprint sama dengan print pertama.
    email = activity.email;
    orderForms = activity.orderForm;
    formValuess = activity.formValues;
  }

  Future<void> printPdfUSB(String filename, String? title, String? subtitle, String? idTicket, String? jobtitle,
      String? showQr) async {
    setState(() => btnReprintEnabled = false);

    final file = await PrinterService.buildPdfDynamicQrCenter(filename, idTicket, formValuess, "", fullName, email);

    if (file != null) {
      // Connect, then print (thread terpisah). Sukses -> tetap di halaman ini.
      PrinterService.printPdfUSB(file);
    }

    if (mounted) setState(() => btnReprintEnabled = true);
  }

  @override
  Widget build(BuildContext context) {
    return CompletedView(
      imageHeight: dsdp(120),
      arrowMargin: sdp(2),
      reprintEnabled: btnReprintEnabled,
      // normalnya
      onReprint: () => printPdfUSB("namecard", fullName, instansi, idTicket, jobTitle, showQr),
      onCompleted: () => activity.replaceFragment(() => const ScanFragment()),
    );
  }
}
