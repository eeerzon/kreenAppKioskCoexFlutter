import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/helper/global_widget.dart';
import 'package:appkioskcoex/helper/loading_page.dart';
import 'package:appkioskcoex/models/response_model.dart';
import 'package:appkioskcoex/pages/kiosk_host.dart';
import 'package:appkioskcoex/pages/manual/main_manual_page.dart';
import 'package:appkioskcoex/pages/manual/two_manual2_fragment.dart';
import 'package:appkioskcoex/pages/manual/two_manual_fragment.dart';
import 'package:appkioskcoex/pages/shared_fragment_views.dart';
import 'package:appkioskcoex/services/api_services.dart';
import 'package:appkioskcoex/services/lang_service.dart';
import 'package:flutter/material.dart';

/// manual/OneManualFragment.java -> fragment_one_manual.xml
class OneManualFragment extends StatefulWidget {
  const OneManualFragment({super.key});

  @override
  State<OneManualFragment> createState() => _OneManualFragmentState();
}

class _OneManualFragmentState extends State<OneManualFragment> {
  late final MainManualPageState activity = KioskHost.of(context) as MainManualPageState;

  late String idEvent;
  late String titleEvent;
  final DialogShow dialogShow = DialogShow();
  late final CustomProgressDialogue dProgress = CustomProgressDialogue(context, cancelable: false);
  final QuestionMap questionMap = QuestionMap();

  final TextEditingController etTicketId = TextEditingController();
  final FocusNode etTicketIdFocus = FocusNode();
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

    btnSubmitEnabled = false;
  }

  @override
  void dispose() {
    dProgress.hide();
    etTicketId.dispose();
    etTicketIdFocus.dispose();
    super.dispose();
  }

  void listQuestionOrderForm(String idEvent) {
    questionMap.isQuestionMapReady = false;
    // updateSubmitButtonState(): tiket masih kosong -> disabled
    btnSubmitEnabled = false;
    questionMap.listQuestionOrderForm(idEvent);
  }

  void updateSubmitButtonState() {
    if (!mounted) return;

    final ticketId = etTicketId.text.trim();
    final isTicketFilled = ticketId.isNotEmpty;
    final canSubmit = isTicketFilled && questionMap.isQuestionMapReady;

    setState(() => btnSubmitEnabled = canSubmit);
  }

  void onSubmit() {
    dismissKeyboard(context);

    final idTicket = etTicketId.text.trim();

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

  /// redeem_process_(id_ticket) versi lama (Volley -> booking_redeem3_coex_kiosk) -> TwoManualFragment
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
        activity.replaceFragment(() => const TwoManualFragment());
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
      debugPrint("API Failure: ${response.error}");
      checkBookingJipremium(idTicket, idEvent);
      return;
    }

    dProgress.hide();
    debugPrint("respon isSuccessful: ${response.isSuccessful}");
    final responseModel = response.body;
    if (response.isSuccessful && responseModel != null && responseModel.success && responseModel.data != null) {
      applyRedeemResult(activity, responseModel, questionMap);

      activity.replaceFragment(() => TwoManual2Fragment(idEvent: idEvent));
    } else {
      debugPrint("fetchData unsuccess, fallback ke jipremium untuk id_ticket=$idTicket");
      checkBookingJipremium(idTicket, idEvent);
    }
  }

  Future<void> checkBookingJipremium(String idTicket, String idEvent) async {
    debugPrint("checkBookingJipremium DIPANGGIL, idTicket=$idTicket, idEvent $idEvent");

    final response = await ApiService.checkBooking(idTicket, idEvent);
    if (!mounted) return;
    dProgress.hide();
    if (response.isFailure) {
      debugPrint("checkBookingJipremium onFailure: ${response.error}");
      dialogAfterProcess(
          LangService.getString('connection_problem'), LangService.getString('connection_lost'), false);
      return;
    }
    debugPrint("checkBookingJipremium onResponse, code=${response.code}");
    final responseModel = response.isSuccessful ? response.body : null;

    if (responseModel != null && responseModel.success && responseModel.data != null) {
      handleSuccessData(responseModel);
    } else {
      debugPrint("checkBookingJipremium failed");
      dialogAfterProcess(LangService.getString('scan_failed'),
          LangService.getString('scan_was_not_successful_make_sure_you_show_a_valid_qr_code'), false);
    }
  }

  void handleSuccessData(ResponseModel responseModel) {
    applyRedeemResult(activity, responseModel, questionMap);
    activity.replaceFragment(() => TwoManual2Fragment(idEvent: idEvent));
  }

  @override
  Widget build(BuildContext context) {
    return ConsumeTouch(
      // binding.root.setOnTouchListener -> hideSoftInputFromWindow
      onTouch: () => dismissKeyboard(context),
      child: CenteredScroll(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: dsdp(25)),
              child: SizedBox(
                width: double.infinity,
                child: AText("${LangService.getString('welcome_to_the')} $titleEvent",
                    font: AFont.bold, size: dsdp(16), color: textPrimary, bold: true, align: TextAlign.center),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: dsdp(40)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AText(LangService.getString('please_enter_your_ticket_id'),
                      font: AFont.poppins, size: dsdp(16), color: textPrimary, align: TextAlign.center),
                  SizedBox(height: dsdp(15)),
                  AText(LangService.getString('tiket_id'), font: AFont.poppins, size: dssp(16), color: textPrimary),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: dsdp(10)),
                    // GestureDetector kosong: sentuhan di EditText tidak menutup keyboard (root onTouch)
                    child: GestureDetector(
                      onTapDown: (_) {},
                      child: FormEditText(
                        controller: etTicketId,
                        focusNode: etTicketIdFocus,
                        hint: LangService.getString('enter_ticket_id'),
                        height: dsdp(40),
                        textSize: dsdp(16),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => updateSubmitButtonState(),
                        // IME_ACTION_DONE / NEXT / ENTER -> redeem_process(text)
                        onSubmitted: (text) => redeemProcess(text),
                      ),
                    ),
                  ),
                  BackgroundTextButton(
                    text: LangService.getString('check_ticket_id'),
                    enabled: btnSubmitEnabled,
                    height: dsdp(40),
                    textSize: dsdp(16),
                    onTap: onSubmit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
