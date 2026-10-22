import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/models/response_model.dart';
import 'package:appkioskcoex/pages/kiosk_host.dart';
import 'package:appkioskcoex/pages/scan/completed2_fragment.dart';
import 'package:appkioskcoex/pages/scan/main_activity2_page.dart';
import 'package:appkioskcoex/pages/scan/scan_fragment.dart';
import 'package:appkioskcoex/pages/shared_fragment_views.dart';
import 'package:appkioskcoex/services/lang_service.dart';
import 'package:appkioskcoex/services/printer_service.dart';
import 'package:flutter/material.dart';

/// fragment/MakeSureData2Fragment.java -> fragment_make_sure_data2.xml
class MakeSureData2Fragment extends StatefulWidget {
  final String idEvent; // getArguments().getString("id_event", "")

  const MakeSureData2Fragment({super.key, this.idEvent = ""});

  @override
  State<MakeSureData2Fragment> createState() => _MakeSureData2FragmentState();
}

class _MakeSureData2FragmentState extends State<MakeSureData2Fragment> {
  late final MainActivity2PageState activity = KioskHost.of(context) as MainActivity2PageState;

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

    activity.onScan = false;
  }

  void onPrint() {
    if (canPrint) {
      // === Event yang boleh print ===
      printPdfUSB("namecard", fullName, instansi, idTicket, jobTitle, showQr);
    } else {
      activity.replaceFragment(() => const ScanFragment());
    }
  }

  Future<void> printPdfUSB(String filename, String? title, String? subtitle, String? idTicket, String? jobtitle,
      String? showQr) async {
    setState(() => btnPrintEnabled = false);

    final file = await PrinterService.buildPdfDynamicQrCenter(filename, idTicket, formValuess, "", fullName, email);

    if (file != null) {
      // Connect, then print (thread terpisah)
      PrinterService.printPdfUSB(file).then((success) {
        if (success) {
          activity.replaceFragment(() => const Completed2Fragment());
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
      ifYesTextSize: dssp(14),
      printText: canPrint ? LangService.getString('print') : LangService.getString('completed'),
      printEnabled: btnPrintEnabled,
      onBack: () => activity.replaceFragment(() => const ScanFragment()),
      onPrint: onPrint,
    );
  }
}
