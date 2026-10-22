import 'dart:math' as math;

import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/helper/global_widget.dart';
import 'package:appkioskcoex/models/response_model.dart';
import 'package:appkioskcoex/services/lang_service.dart';
import 'package:flutter/material.dart';

/// NestedScrollView fillViewport + LinearLayout gravity="center"
class CenteredScroll extends StatelessWidget {
  final Widget child;

  const CenteredScroll({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      );
    });
  }
}

/// fragment_make_sure_data2.xml / fragment_two_manual2.xml
class ConfirmDataView extends StatelessWidget {
  final String? fullName;
  final String? email;
  final List<OrderFormModel>? orderForms;
  final double ifYesTextSize; // __14ssp (scan) / __15sdp (manual)
  final String printText;
  final bool printEnabled;
  final VoidCallback onBack;
  final VoidCallback onPrint;

  const ConfirmDataView({
    super.key,
    required this.fullName,
    required this.email,
    required this.orderForms,
    required this.ifYesTextSize,
    required this.printText,
    required this.printEnabled,
    required this.onBack,
    required this.onPrint,
  });

  Widget _button(String text, Color color, VoidCallback? onTap) {
    return Padding(
      padding: EdgeInsets.all(dsdp(13)),
      child: CardTextButton(
        text: text,
        background: color,
        strokeColor: color,
        textColor: white,
        textSize: dsdp(14),
        padding: EdgeInsets.symmetric(horizontal: dsdp(30), vertical: dsdp(10)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CenteredScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: dsdp(10)),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: dsdp(10)),
                  child: SvgIcon('ic_check_circle', width: dsdp(60), height: dsdp(60), tint: colorGreen),
                ),
                SizedBox(
                  width: double.infinity,
                  child: AText(LangService.getString('scan_successful'),
                      font: AFont.bold, size: dssp(16), color: textPrimary, bold: true, align: TextAlign.center),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: dsdp(10), left: dsdp(25), right: dsdp(25)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // layFullData -> rvData (DetailAdapter)
                DetailList(fullname: fullName, email: email, details: orderForms),
                Padding(
                  padding: EdgeInsets.only(top: dsdp(10)),
                  child: AText(LangService.getString('if_yes_please_click_the_print_button_below'),
                      font: AFont.poppins, size: ifYesTextSize, color: textPrimary, align: TextAlign.center),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _button(LangService.getString('back'), colorGray, onBack),
                    _button(printText, colorPrimary, printEnabled ? onPrint : null),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// fragment_completed2.xml / fragment_three_manual.xml
class CompletedView extends StatelessWidget {
  final double imageHeight; // __120sdp (scan) / __100sdp (manual)
  final double arrowMargin; // _2sdp (scan) / __2sdp (manual)
  final bool reprintEnabled;
  final VoidCallback onReprint;
  final VoidCallback onCompleted;

  const CompletedView({
    super.key,
    required this.imageHeight,
    required this.arrowMargin,
    required this.reprintEnabled,
    required this.onReprint,
    required this.onCompleted,
  });

  Widget _step(String image, String text) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: dsdp(5)),
        child: Column(
          children: [
            Image.asset('assets/images/$image', width: dsdp(90), height: imageHeight),
            AText(text, font: AFont.poppins, size: dssp(12), bold: true, maxLines: 3, align: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _arrow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: arrowMargin),
      child: SvgIcon('ic_right_arrow', width: dsdp(20), height: dsdp(20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CenteredScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // tv_title visibility="gone" (LinearLayout marginBottom __15sdp tetap ada)
          SizedBox(height: dsdp(15)),
          Padding(
            padding: EdgeInsets.all(dsdp(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _step('kiosk_qr.png', LangService.getString('_1_take_your_name_printed_at_the_bottom_of_the_screen')),
                SizedBox(height: imageHeight, child: Center(child: _arrow())),
                _step('kiosk_handsanitizer.png', LangService.getString('_2_use_hand_sanitizer')),
                SizedBox(height: imageHeight, child: Center(child: _arrow())),
                _step('qr_ticket.png', LangService.getString('_3_paste_your_name_on_the_id_card')),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: dsdp(15), left: dsdp(15), right: dsdp(15)),
            child: Padding(
              padding: EdgeInsets.all(dsdp(10)),
              child: _WeightedWrapRow(
                reprint: LangService.getString('reprint'),
                completed: LangService.getString('completed'),
                onReprint: reprintEnabled ? onReprint : null,
                onCompleted: onCompleted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// LinearLayout horizontal: dua MaterialCardView layout_width="wrap_content" + layout_weight="1"
/// -> lebar = lebar konten + sisa ruang dibagi rata.
class _WeightedWrapRow extends StatelessWidget {
  final String reprint;
  final String completed;
  final VoidCallback? onReprint;
  final VoidCallback onCompleted;

  const _WeightedWrapRow({
    required this.reprint,
    required this.completed,
    required this.onReprint,
    required this.onCompleted,
  });

  double _contentWidth(String text, double textSize, double padH) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: aTextStyle(AFont.medium, textSize, textPrimary)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width + padH * 2;
  }

  @override
  Widget build(BuildContext context) {
    final textSize = dssp(14);
    final padH = dsdp(15);
    final marginEnd = dsdp(15);
    return LayoutBuilder(builder: (context, constraints) {
      final w1 = _contentWidth(reprint, textSize, padH);
      final w2 = _contentWidth(completed, textSize, padH);
      final extra = math.max(0.0, constraints.maxWidth - w1 - w2 - marginEnd);
      final padding = EdgeInsets.symmetric(horizontal: padH, vertical: dsdp(10));
      return Row(
        children: [
          SizedBox(
            width: w1 + extra / 2,
            child: CardTextButton(
              text: reprint,
              background: white,
              strokeColor: colorLine,
              textColor: textPrimary,
              textSize: textSize,
              padding: padding,
              onTap: onReprint,
            ),
          ),
          SizedBox(width: marginEnd),
          SizedBox(
            width: w2 + extra / 2,
            child: CardTextButton(
              text: completed,
              background: colorPrimary,
              strokeColor: colorPrimary,
              textColor: white,
              textSize: textSize,
              padding: padding,
              onTap: onCompleted,
            ),
          ),
        ],
      );
    });
  }
}

/// fragment_make_sure_data.xml / fragment_two_manual.xml (versi lama, dipakai MakeSureDataFragment &
/// TwoManualFragment): layFullData (event_buyer > 0) atau laySimpleData + satu tombol Print.
class LegacyConfirmDataView extends StatelessWidget {
  final String? fullName;
  final String? instansi; // tv_country
  final String? jobTitle; // tv_id_ticket
  final int eventBuyer;
  final double ifYesTextSize; // __14ssp / __15sdp
  final double printWrapperPadding; // __10sdp / __15sdp
  final double printTextSize; // __14ssp / __15sdp
  final bool printEnabled;
  final VoidCallback onPrint;

  const LegacyConfirmDataView({
    super.key,
    required this.fullName,
    required this.instansi,
    required this.jobTitle,
    required this.eventBuyer,
    required this.ifYesTextSize,
    required this.printWrapperPadding,
    required this.printTextSize,
    required this.printEnabled,
    required this.onPrint,
  });

  Widget _field(String label, String? value, {int? maxLines, double top = 0}) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AText(label, font: AFont.poppins, size: dssp(12), color: textPrimary),
          AText(value ?? "",
              font: AFont.bold, size: dssp(14), color: textPrimary, bold: true, maxLines: maxLines, ellipsize: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CenteredScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: dsdp(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: dsdp(10)),
                    child: SvgIcon('ic_check_circle', width: dsdp(60), height: dsdp(60), tint: colorGreen),
                  ),
                ),
                AText(LangService.getString('scan_successful'),
                    font: AFont.bold, size: dssp(16), color: textPrimary, bold: true, align: TextAlign.center),
                AText(
                    LangService.getString(
                        'please_continue_to_comply_with_existing_health_protocols_and_check_body_temperature_as_well_as_use_hand_sanitizer_before_entering_the_venue'),
                    font: AFont.poppins,
                    size: dssp(14),
                    color: textPrimary,
                    align: TextAlign.center),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: dsdp(10), left: dsdp(25), right: dsdp(25)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (eventBuyer > 0)
                  // layFullData
                  Container(
                    color: lightGray2,
                    padding: EdgeInsets.all(dsdp(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _field(LangService.getString('full_name'), fullName),
                        _field(LangService.getString('company_name'), instansi, maxLines: 2, top: dsdp(10)),
                        _field(LangService.getString('job_title'), jobTitle, maxLines: 2, top: dsdp(10)),
                      ],
                    ),
                  )
                else
                  // laySimpleData
                  Container(
                    color: lightGray2,
                    padding: EdgeInsets.all(dsdp(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AText(LangService.getString('full_name'),
                            font: AFont.poppins, size: dssp(12), color: textPrimary, align: TextAlign.center),
                        AText(fullName ?? "",
                            font: AFont.bold, size: dssp(14), color: textPrimary, bold: true, align: TextAlign.center),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: dsdp(10)),
                  child: AText(LangService.getString('if_yes_please_click_the_print_button_below'),
                      font: AFont.poppins, size: ifYesTextSize, color: textPrimary, align: TextAlign.center),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(printWrapperPadding),
                      child: CardTextButton(
                        text: LangService.getString('print'),
                        background: colorPrimary,
                        strokeColor: colorPrimary,
                        textColor: white,
                        textSize: printTextSize,
                        padding: EdgeInsets.symmetric(horizontal: dsdp(40), vertical: dsdp(10)),
                        onTap: printEnabled ? onPrint : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
