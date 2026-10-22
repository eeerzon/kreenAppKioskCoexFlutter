import 'dart:convert';

import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/models/response_model.dart';
import 'package:appkioskcoex/services/api_services.dart';
import 'package:appkioskcoex/services/storage_services.dart';
import 'package:flutter/widgets.dart';

/// Field public MainActivity2 / MainManual yang dibaca-tulis fragment lewat
/// ((MainActivity2) requireActivity()) / ((MainManual) requireActivity()).
abstract class KioskHost {
  String idEvent = "";
  String titleEvent = "";
  String? idTicket = "";
  String? fullName = "";
  String instansi = "";
  String answer = "";
  String jobTitle = "";
  String? email = "";
  int eventBuyer = 0;

  List<OrderFormModel>? orderForm;
  String? showQr;
  List<OrderFormModel>? formValues = [];

  bool canPrint = false;

  /// getSupportFragmentManager().beginTransaction().replace(R.id.fragmentContainer, fragment).commit()
  void replaceFragment(Widget Function() fragment);

  static KioskHost of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KioskHostScope>()!.host;

  static KioskHost? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KioskHostScope>()?.host;
}

class KioskHostScope extends InheritedWidget {
  final KioskHost host;

  const KioskHostScope({super.key, required this.host, required super.child});

  @override
  bool updateShouldNotify(KioskHostScope oldWidget) => !identical(host, oldWidget.host);
}

/// questionMap + isQuestionMapReady + listQuestionOrderForm() + fillQuestionText()
/// (sama di MainActivity2, ScanFragment, OneManualFragment)
class QuestionMap {
  final Map<String, String> questionMap = {};
  bool isQuestionMapReady = false;

  Future<void> listQuestionOrderForm(String idEvent) async {
    isQuestionMapReady = false;

    final response = await ApiService.listQuestionOrderForm(kreenConnectSecretKey, idEvent);

    if (response.isFailure) {
      debugPrint("QUESTION_MAP onFailure: ${response.error}");
      isQuestionMapReady = true;
      debugPrint("QUESTION_MAP isQuestionMapReady = true karena request selesai dengan error");
      return;
    }

    final body = response.body;
    if (response.isSuccessful && body != null && body.success) {
      questionMap.clear();

      final items = body.data;
      if (items != null) {
        for (final item in items) {
          final id = item.idQuestion;
          final question = item.question;
          if (id != null && id.isNotEmpty && question != null) {
            questionMap[id] = question;
          }
        }
      }
      debugPrint("QUESTION_MAP final questionMap = $questionMap");
    } else {
      debugPrint("QUESTION_MAP Failed to load question mapping");
    }

    isQuestionMapReady = true;
    debugPrint("QUESTION_MAP isQuestionMapReady = $isQuestionMapReady");
  }

  void fillQuestionText(List<OrderFormModel>? orderForm) {
    if (orderForm == null) return;
    for (final item in orderForm) {
      if ((item.question == null || item.question!.isEmpty) && item.idQuestion != null) {
        final mapped = questionMap[item.idQuestion];
        if (mapped != null) {
          item.question = mapped;
        }
      }
    }
  }
}

/// Isi field activity dari response sukses (onResponse / handleSuccessData):
/// normalizeAnswer + fillQuestionText, lalu orderForm, id_ticket, showQr, formValues, full_name, email.
void applyRedeemResult(KioskHost host, ResponseModel responseModel, QuestionMap? questionMap) {
  final data = responseModel.data!;
  final details = data.detail;
  final orderForms = details?.orderForms;

  if (orderForms != null) {
    for (final item in orderForms) {
      item.answer = normalizeAnswer(item.answer);
    }
    questionMap?.fillQuestionText(orderForms);
  }
  debugPrint("onResponse: $data");

  // ==== KONDISI PRINT ====
  host.canPrint = allowedEventId == host.idEvent;
  host.orderForm = orderForms;
  host.idTicket = data.id;
  host.showQr = data.showQr;
  host.formValues = [];
  host.formValues = orderForms;
  host.fullName = details?.fullname;
  host.email = details?.email;
}

/// data_logo_list(): JSONArray(logo_list / banner_top_list / banner_bottom_list) -> {id, img}
/// return null kalau string kosong (tidak diproses sama sekali).
List<(String, String)>? parseIdImgList(String raw) {
  if (raw.isEmpty) return null;
  List arr;
  try {
    arr = json.decode(raw) as List;
  } catch (e) {
    debugPrint(e.toString());
    return [];
  }
  final result = <(String, String)>[];
  for (final item in arr) {
    try {
      final obj = item as Map;
      if (!obj.containsKey("id") || !obj.containsKey("img")) continue;
      result.add(("${obj["id"]}", "${obj["img"]}"));
    } catch (e) {
      debugPrint(e.toString());
    }
  }
  return result;
}

/// pref.getString(Config.*_SHARED_PREF, "") di onCreate MainActivity2 / MainManual
void loadEventFromPref(KioskHost host) {
  host.idEvent = StorageService.getIdEvent();
  host.titleEvent = StorageService.getTitleEvent();
}

// =====================================================================================
// redeem_process_() versi lama (Volley + JSONObject) -> MakeSureDataFragment / TwoManualFragment
// =====================================================================================

enum LegacyRedeemStatus {
  /// success == true dan data berisi object
  data,

  /// success == true tapi data == null -> Toast "null"
  dataNull,

  /// success == false
  failed,

  /// JSONException
  jsonError,
}

class LegacyRedeemResult {
  final LegacyRedeemStatus status;
  final String idTicket, fullName, email, answer, instansi, jobTitle;
  final int eventBuyer;

  const LegacyRedeemResult(this.status,
      {this.idTicket = "",
      this.fullName = "",
      this.email = "",
      this.answer = "",
      this.instansi = "",
      this.jobTitle = "",
      this.eventBuyer = 0});
}

String _jsonGetString(Map obj, String name) {
  if (!obj.containsKey(name)) throw FormatException("No value for $name");
  final v = obj[name];
  if (v is Map || v is List) return json.encode(v);
  return v == null ? "null" : v.toString();
}

int _jsonGetInt(Map obj, String name) {
  final v = obj[name];
  if (v is num) return v.toInt();
  if (v is String) {
    final d = double.tryParse(v);
    if (d != null) return d.toInt();
  }
  throw FormatException("JSONObject[$name] is not an int.");
}

LegacyRedeemResult parseLegacyRedeem(String response) {
  try {
    final jsonObject = json.decode(response) as Map;
    final success = jsonObject["success"];
    final bool ok = success is bool
        ? success
        : (success is String && (success.toLowerCase() == "true" || success.toLowerCase() == "false"))
            ? success.toLowerCase() == "true"
            : throw const FormatException("success is not a boolean");
    _jsonGetString(jsonObject, "message");

    // ngecek node error dari api
    if (!ok) return const LegacyRedeemResult(LegacyRedeemStatus.failed);

    final sOtherText = _jsonGetString(jsonObject, "data");
    if (sOtherText == "null") return const LegacyRedeemResult(LegacyRedeemStatus.dataNull);

    final otherText = jsonObject["data"];
    if (otherText is! Map) throw const FormatException("data is not a JSONObject");
    return LegacyRedeemResult(
      LegacyRedeemStatus.data,
      idTicket: _jsonGetString(otherText, "id_ticket"),
      fullName: _jsonGetString(otherText, "full_name"),
      email: _jsonGetString(otherText, "email"),
      answer: _jsonGetString(otherText, "answer"),
      instansi: _jsonGetString(otherText, "company_name"),
      jobTitle: _jsonGetString(otherText, "job_title"),
      eventBuyer: _jsonGetInt(otherText, "event_buyer"),
    );
  } catch (e) {
    debugPrint("Error1: $e");
    return const LegacyRedeemResult(LegacyRedeemStatus.jsonError);
  }
}

void applyLegacyRedeem(KioskHost host, LegacyRedeemResult r) {
  host.fullName = r.fullName;
  host.email = r.email;
  host.idTicket = r.idTicket;
  host.answer = r.answer;
  host.instansi = r.instansi;
  host.jobTitle = r.jobTitle;
  host.eventBuyer = r.eventBuyer;
}
