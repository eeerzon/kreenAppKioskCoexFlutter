import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/pages/kiosk_host.dart';
import 'package:appkioskcoex/pages/scan/completed_fragment.dart';
import 'package:appkioskcoex/pages/scan/main_activity2_page.dart';
import 'package:appkioskcoex/pages/shared_fragment_views.dart';
import 'package:appkioskcoex/services/printer_service.dart';
import 'package:flutter/material.dart';

/// fragment/MakeSureDataFragment.java -> fragment_make_sure_data.xml
/// (versi lama; dibuka dari redeem_process_() Volley)
class MakeSureDataFragment extends StatefulWidget {
  const MakeSureDataFragment({super.key});

  @override
  State<MakeSureDataFragment> createState() => _MakeSureDataFragmentState();
}

class _MakeSureDataFragmentState extends State<MakeSureDataFragment> {
  late final MainActivity2PageState activity = KioskHost.of(context) as MainActivity2PageState;

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

    activity.onScan = false;
  }

  Future<void> printPdfUSB(String filename, String? title, String subtitle, String? idTicket, String jobtitle) async {
    setState(() => btnPrintEnabled = false);

    final file = await PrinterService.buildPdf2(filename, title, subtitle, idTicket, jobTitle, eventBuyer, answer);

    if (file != null) {
      // Connect, then print (thread terpisah)
      PrinterService.printPdfUSB(file).then((success) {
        if (success) activity.replaceFragment(() => const CompletedFragment());
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
      ifYesTextSize: dssp(14),
      printWrapperPadding: dsdp(10),
      printTextSize: dssp(14),
      printEnabled: btnPrintEnabled,
      // normalnya
      onPrint: () => printPdfUSB("namecard", fullName, instansi, idTicket, jobTitle),
    );
  }
}
