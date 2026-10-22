import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/pages/kiosk_host.dart';
import 'package:appkioskcoex/pages/manual/main_manual_page.dart';
import 'package:appkioskcoex/pages/manual/three_manual_fragment.dart';
import 'package:appkioskcoex/pages/shared_fragment_views.dart';
import 'package:appkioskcoex/services/printer_service.dart';
import 'package:flutter/material.dart';

/// manual/TwoManualFragment.java -> fragment_two_manual.xml
/// (versi lama; dibuka dari redeem_process_() Volley di MainManual / OneManualFragment)
class TwoManualFragment extends StatefulWidget {
  const TwoManualFragment({super.key});

  @override
  State<TwoManualFragment> createState() => _TwoManualFragmentState();
}

class _TwoManualFragmentState extends State<TwoManualFragment> {
  late final MainManualPageState activity = KioskHost.of(context) as MainManualPageState;

  String? fullName, email, idTicket;
  String answer = "", instansi = "", jobTitle = "";
  int eventBuyer = 0;
  bool btnPrintEnabled = true;
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
    setState(() => btnPrintEnabled = false);

    final file = await PrinterService.buildPdf2(filename, title, subtitle, idTicket, jobTitle, eventBuyer, answer);

    if (file != null) {
      PrinterService.printPdfUSB(file).then((success) {
        if (success) activity.replaceFragment(() => const ThreeManualFragment());
      });
    }

    if (mounted) setState(() => btnPrintEnabled = true);
  }

  @override
  Widget build(BuildContext context) {
    return LegacyConfirmDataView(
      fullName: fullName,
      instansi: instansi,
      jobTitle: jobTitle,
      eventBuyer: eventBuyer,
      ifYesTextSize: dsdp(15),
      printWrapperPadding: dsdp(15),
      printTextSize: dsdp(15),
      printEnabled: btnPrintEnabled,
      // normalnya
      onPrint: () => printPdfUSB("namecard", fullName, instansi, idTicket, jobTitle),
    );
  }
}
