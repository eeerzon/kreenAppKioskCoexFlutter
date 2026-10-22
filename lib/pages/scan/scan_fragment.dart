import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/helper/global_widget.dart';
import 'package:appkioskcoex/helper/loading_page.dart';
import 'package:appkioskcoex/models/response_model.dart';
import 'package:appkioskcoex/pages/kiosk_host.dart';
import 'package:appkioskcoex/pages/scan/main_activity2_page.dart';
import 'package:appkioskcoex/pages/scan/make_sure_data2_fragment.dart';
import 'package:appkioskcoex/pages/scan/make_sure_data_fragment.dart';
import 'package:appkioskcoex/services/api_services.dart';
import 'package:appkioskcoex/services/lang_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// fragment/ScanFragment.java -> fragment_scan.xml
class ScanFragment extends StatefulWidget {
  const ScanFragment({super.key});

  @override
  State<ScanFragment> createState() => _ScanFragmentState();
}

class _ScanFragmentState extends State<ScanFragment> {
  late final MainActivity2PageState activity = KioskHost.of(context) as MainActivity2PageState;

  late String idEvent;
  late String titleEvent;
  final DialogShow dialogShow = DialogShow();
  late final CustomProgressDialogue dProgress = CustomProgressDialogue(context, cancelable: false);
  final QuestionMap questionMap = QuestionMap();

  String etTicketId = "";
  bool btnSubmitEnabled = false;

  bool _created = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;

    idEvent = activity.idEvent;
    titleEvent = activity.titleEvent;

    if (idEvent.isNotEmpty) {
      listQuestionOrderForm(idEvent);
    }

    activity.onScan = true;

    btnSubmitEnabled = false;
  }

  void listQuestionOrderForm(String idEvent) {
    questionMap.isQuestionMapReady = false;
    // updateSubmitButtonState(): tiket masih kosong -> disabled
    btnSubmitEnabled = false;
    questionMap.listQuestionOrderForm(idEvent);
  }

  void updateSubmitButtonState() {
    if (!mounted) return;

    final ticketId = etTicketId.trim();
    final isTicketFilled = ticketId.isNotEmpty;
    final canSubmit = isTicketFilled && questionMap.isQuestionMapReady;

    setState(() => btnSubmitEnabled = canSubmit);
  }

  void onSubmit() {
    dismissKeyboard(context);

    final idTicket = etTicketId.trim();

    if (!questionMap.isQuestionMapReady) {
      showToast("Sedang memuat data pertanyaan, silakan tunggu...");
      return;
    }

    redeemProcess(idTicket);
  }

  void dialogAfterProcess(String titleMessage, String subtitleMessage, bool success) {
    if (dialogShow.isShowing) {
      dialogShow.dismiss();
    }
    showDialogAfterProcess(context, dialogShow, titleMessage, subtitleMessage, success);
  }

  /// redeem_process_(id_ticket) versi lama (Volley -> booking_redeem3_coex_kiosk) -> MakeSureDataFragment
  Future<void> redeemProcess_(String idTicket0) async {
    final idRedeem = ramdon(20, "123456789", "");
    dProgress.show();
    debugPrint("URLRequest: $urlBookingRedeem");

    final String response;
    try {
      response = await ApiService.postBookingRedeem(idRedeem, idTicket0, idEvent);
    } catch (error) {
      if (!mounted) return;
      dialogAfterProcess(
          LangService.getString('connection_problem'), LangService.getString('connection_lost'), false);
      dProgress.hide();
      return;
    }
    if (!mounted) return;
    dProgress.hide();
    debugPrint("response $response");

    final r = parseLegacyRedeem(response);
    switch (r.status) {
      case LegacyRedeemStatus.data:
        applyLegacyRedeem(activity, r);
        activity.replaceFragment(() => const MakeSureDataFragment());
        break;
      case LegacyRedeemStatus.dataNull:
        showToast("null");
        break;
      case LegacyRedeemStatus.failed:
        dialogAfterProcess(LangService.getString('scan_failed'),
            LangService.getString('scan_was_not_successful_make_sure_you_show_a_valid_qr_code'), false);
        break;
      case LegacyRedeemStatus.jsonError:
        dialogAfterProcess(LangService.getString('scan_failed'), LangService.getString('faild_redeem'), false);
        break;
    }
  }

  Future<void> redeemProcess(String idTicket) async {
    final idRedeem = ramdon(20, "123456789", "");
    dProgress.show();

    final response = await ApiService.fetchData(idRedeem, idTicket, idEvent);
    if (!mounted) return;
    if (response.isFailure) {
      debugPrint("fetchData onFailure: ${response.error}, fallback ke jipremium");
      checkBookingJipremium(idTicket, idEvent);
      return;
    }

    dProgress.hide();
    debugPrint("respon isSuccessful: ${response.isSuccessful}");
    final responseModel = response.body;
    if (response.isSuccessful && responseModel != null && responseModel.success && responseModel.data != null) {
      applyRedeemResult(activity, responseModel, questionMap);

      activity.replaceFragment(() => MakeSureData2Fragment(idEvent: idEvent));
    } else {
      debugPrint("fetchData unsuccess, fallback ke jipremium untuk id_ticket=$idTicket");
      checkBookingJipremium(idTicket, idEvent);
    }
  }

  Future<void> checkBookingJipremium(String idTicket, String idEvent) async {
    debugPrint("checkBookingJipremium DIPANGGIL, idTicket=$idTicket");

    final response = await ApiService.checkBooking(idTicket, idEvent);
    if (!mounted) return;
    dProgress.hide();
    if (response.isFailure) {
      dialogAfterProcess(
          LangService.getString('connection_problem'), LangService.getString('connection_lost'), false);
      return;
    }
    debugPrint("checkBookingJipremium onResponse, code=${response.code}");
    final responseModel = response.isSuccessful ? response.body : null;

    if (responseModel != null && responseModel.success && responseModel.data != null) {
      handleSuccessData(responseModel);
    } else {
      dialogAfterProcess(LangService.getString('scan_failed'),
          LangService.getString('scan_was_not_successful_make_sure_you_show_a_valid_qr_code'), false);
    }
  }

  void handleSuccessData(ResponseModel responseModel) {
    applyRedeemResult(activity, responseModel, questionMap);
    activity.replaceFragment(() => MakeSureData2Fragment(idEvent: idEvent));
  }

  /// buttom_sheets_answer(context, answer, title)
  void buttomSheetsAnswer(String answer, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: white,
      shape: const RoundedRectangleBorder(),
      builder: (_) => _TicketBottomSheet(
        answer: answer,
        title: title,
        onSave: (text) {
          setState(() => etTicketId = text);
          updateSubmitButtonState();
        },
      ),
    );
  }

  @override
  void dispose() {
    dProgress.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConsumeTouch(
      // binding.root.setOnTouchListener -> hideSoftInputFromWindow
      onTouch: () => dismissKeyboard(context),
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: dsdp(15)),
                  child: SizedBox(
                    width: double.infinity,
                    child: AText("${LangService.getString('welcome_to_the')} $titleEvent",
                        font: AFont.bold, size: dssp(16), color: textPrimary, bold: true, align: TextAlign.center),
                  ),
                ),
                Image.asset('assets/images/kiosk_phone.png', width: sdp(120), height: sdp(120)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: sdp(30)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AText(LangService.getString('scan_your_ticket_qr_code_first_or_enter_the_ticket_code'),
                          font: AFont.poppins, size: ssp(10), color: textPrimary, align: TextAlign.center),
                      SizedBox(height: sdp(10)),
                      AText(LangService.getString('tiket_id'), font: AFont.poppins, size: ssp(10), color: textPrimary),
                      // etTicketId (MaterialTextView, klik -> bottom sheet)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sdp(5)),
                        child: GestureDetector(
                          onTap: () => buttomSheetsAnswer(etTicketId, LangService.getString('id_ticket')),
                          child: Container(
                            height: sdp(30),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: colorLine, width: 1),
                            ),
                            alignment: Alignment.center,
                            child: AText(
                              etTicketId.isEmpty ? LangService.getString('enter_ticket_id') : etTicketId,
                              font: AFont.poppins,
                              size: ssp(11),
                              color: etTicketId.isEmpty ? defaultHintColor : defaultTextColor,
                              maxLines: 1,
                              align: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      BackgroundTextButton(
                        text: LangService.getString('submit'),
                        enabled: btnSubmitEnabled,
                        height: sdp(30),
                        textSize: ssp(11),
                        onTap: onSubmit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// layout buttom_sheets_form_single
class _TicketBottomSheet extends StatefulWidget {
  final String answer;
  final String title;
  final ValueChanged<String> onSave;

  const _TicketBottomSheet({required this.answer, required this.title, required this.onSave});

  @override
  State<_TicketBottomSheet> createState() => _TicketBottomSheetState();
}

class _TicketBottomSheetState extends State<_TicketBottomSheet> {
  static const int maxCount = 10;

  late final TextEditingController etAnswer = TextEditingController(text: widget.answer)
    ..selection = TextSelection.collapsed(offset: widget.answer.length);

  @override
  void dispose() {
    etAnswer.dispose();
    super.dispose();
  }

  bool get btnSaveEnabled => etAnswer.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // toolbar: ic_drag_bar
          Padding(
            padding: EdgeInsets.only(top: dsdp(10), bottom: dsdp(15)),
            child: const Center(child: SvgIcon('ic_drag_bar', width: 31, height: 8)),
          ),
          Padding(
            padding: EdgeInsets.only(left: dsdp(15), right: dsdp(15), top: dsdp(5), bottom: dsdp(5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: dsdp(5)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: dsdp(10)),
                    child: AText(widget.title, font: AFont.bold, size: dssp(14), color: black, bold: true),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: colorLine, width: 1),
                  ),
                  padding: EdgeInsets.all(dsdp(10)),
                  child: TextField(
                    controller: etAnswer,
                    maxLines: 1,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(maxCount),
                      // disable space in first input + disable enter
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        var text = newValue.text.replaceFirst(RegExp(r'^\s+'), '');
                        text = text.replaceAll('\n', '');
                        if (text == newValue.text) return newValue;
                        return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
                      }),
                    ],
                    style: aTextStyle(AFont.poppins, dsdp(15), const Color(0xD9000000)),
                    cursorColor: colorPrimary,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: LangService.getString('enter_ticket_id'),
                      hintStyle: aTextStyle(AFont.poppins, dsdp(15), defaultHintColor),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: dsdp(15), right: dsdp(15), top: dsdp(5), bottom: dsdp(5)),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: dsdp(5), top: dsdp(3)),
                  child: AText("${konvIntStr(etAnswer.text.length)} / $maxCount",
                      font: AFont.poppins, size: dssp(12), color: textPrimary),
                ),
                const Spacer(),
                BackgroundTextButton(
                  text: LangService.getString('save'),
                  enabled: btnSaveEnabled,
                  height: dsdp(25),
                  textSize: dssp(12),
                  font: AFont.bold,
                  bold: true,
                  padding: EdgeInsets.symmetric(horizontal: dsdp(10)),
                  onTap: () {
                    widget.onSave(etAnswer.text);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
