import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/pages/kiosk_host.dart';
import 'package:appkioskcoex/pages/scan/main_activity2_page.dart';
import 'package:appkioskcoex/pages/scan/scan_fragment.dart';
import 'package:appkioskcoex/pages/shared_fragment_views.dart';
import 'package:appkioskcoex/services/printer_service.dart';
import 'package:flutter/material.dart';

/// fragment/CompletedFragment.java -> fragment_completed.xml (versi lama)
class CompletedFragment extends StatefulWidget {
  const CompletedFragment({super.key});

  @override
  State<CompletedFragment> createState() => _CompletedFragmentState();
}

class _CompletedFragmentState extends State<CompletedFragment> {
  late final MainActivity2PageState activity = KioskHost.of(context) as MainActivity2PageState;

  String? fullName, email, idTicket;
  String answer = "", instansi = "", jobTitle = "";
  int eventBuyer = 0;
  bool btnReprintEnabled = true;
  bool _created = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;

    fullName = activity.fullName;
    email = activity.instansi;
    idTicket = activity.idTicket;
    answer = activity.answer;
    instansi = activity.instansi;
    jobTitle = activity.jobTitle;
    eventBuyer = activity.eventBuyer;
  }

  Future<void> printPdfUSB(String filename, String? title, String subtitle, String? idTicket, String jobtitle) async {
    setState(() => btnReprintEnabled = false);

    final file = await PrinterService.buildPdf2(filename, title, subtitle, idTicket, jobTitle, eventBuyer, answer);

    if (file != null) {
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
      onReprint: () => printPdfUSB("namecard", fullName, instansi, idTicket, jobTitle),
      onCompleted: () => activity.replaceFragment(() => const ScanFragment()),
    );
  }
}
