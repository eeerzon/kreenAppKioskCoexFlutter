import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/pages/kiosk_host.dart';
import 'package:appkioskcoex/pages/manual/main_manual_page.dart';
import 'package:appkioskcoex/pages/manual/one_manual_fragment.dart';
import 'package:appkioskcoex/pages/shared_fragment_views.dart';
import 'package:appkioskcoex/services/printer_service.dart';
import 'package:flutter/material.dart';

/// manual/ThreeManualFragment.java -> fragment_three_manual.xml
class ThreeManualFragment extends StatefulWidget {
  const ThreeManualFragment({super.key});

  @override
  State<ThreeManualFragment> createState() => _ThreeManualFragmentState();
}

class _ThreeManualFragmentState extends State<ThreeManualFragment> {
  late final MainManualPageState activity = KioskHost.of(context) as MainManualPageState;

  String? fullName, email, idTicket;
  String answer = "";
  String instansi = "";
  String jobTitle = "";
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

  /// Reprint memakai TemplatePdf.buildPdf2 (template tanpa QR code), sama seperti app asli.
  Future<void> printPdfUSB(String filename, String? title, String subtitle, String? idTicket, String jobtitle) async {
    setState(() => btnReprintEnabled = false);

    final file = await PrinterService.buildPdf2(filename, title, subtitle, idTicket, jobTitle, eventBuyer, answer);

    if (file != null) {
      // Connect, then print (thread terpisah). Sukses -> tetap di halaman ini.
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
      // normalnya
      onReprint: () => printPdfUSB("namecard", fullName, instansi, idTicket, jobTitle),
      onCompleted: () => activity.replaceFragment(() => const OneManualFragment()),
    );
  }
}
