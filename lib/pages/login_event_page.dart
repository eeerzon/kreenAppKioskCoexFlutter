import 'dart:convert';

import 'package:appkioskcoex/helper/activity_lifecycle.dart';
import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/helper/global_widget.dart';
import 'package:appkioskcoex/helper/loading_page.dart';
import 'package:appkioskcoex/pages/device_setting_page.dart';
import 'package:appkioskcoex/services/api_services.dart';
import 'package:appkioskcoex/services/lang_service.dart';
import 'package:appkioskcoex/services/storage_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// LoginEvent.java -> activity_login_event.xml
class LoginEventPage extends StatefulWidget {
  const LoginEventPage({super.key});

  /// public static CustomProgressDialogue dProgress (ditutup di DeviceSetting.onResume)
  static CustomProgressDialogue? dProgress;

  @override
  State<LoginEventPage> createState() => _LoginEventPageState();
}

class _LoginEventPageState extends State<LoginEventPage> with ActivityLifecycle {
  final TextEditingController etEventId = TextEditingController();
  final FocusNode etEventIdFocus = FocusNode();
  final DialogShow dialogShow = DialogShow();

  bool ivNextEnabled = false;
  late String language;

  @override
  void initState() {
    super.initState();

    StorageService.setTypeRedeem(typeRedeemManual);

    if (!kIsWeb) {
      Permission.locationWhenInUse.status.then((status) {
        if (!status.isGranted) {
          // No explanation needed, we can request the permission.
          Permission.locationWhenInUse.request();
        }
      });
    }

    LoginEventPage.dProgress = CustomProgressDialogue(context, cancelable: false);

    //language
    language = StorageService.getLangRaw();
  }

  @override
  void onResume() {
    setFullScreen();
  }

  @override
  void dispose() {
    etEventId.dispose();
    etEventIdFocus.dispose();
    super.dispose();
  }

  void onTextChanged(String s) {
    setState(() => ivNextEnabled = s.isNotEmpty);
  }

  void onLanguageChanged(String code) {
    LangService.updateResources(code);
    // recreate()
    setState(() => language = StorageService.getLangRaw());
  }

  Future<void> checkEvent() async {
    final dProgress = LoginEventPage.dProgress!;
    dProgress.show();
    debugPrint("URLRequest: $urlCheckEvent");

    final String response;
    try {
      response = await ApiService.postCheckEvent(etEventId.text);
    } catch (error) {
      if (!mounted) return;
      dialogAfterProcess("Error", LangService.getString('connection_lost'), false);
      dProgress.dismiss();
      return;
    }
    if (!mounted) return;

    debugPrint("response $response");
    try {
      final jsonObject = json.decode(response) as Map<String, dynamic>;
      final bool success = _getBoolean(jsonObject, "success");
      _getString(jsonObject, "message");

      // ngecek node error dari api
      if (success) {
        if (jsonObject.containsKey("data")) {
          final jobData = jsonObject["data"];
          if (jobData is! Map) throw const FormatException("data is not a JSONObject");
          final String idEvent = _getString(jobData, "id_event");
          final String title = _getString(jobData, "title");
          _getString(jobData, "topic");
          _getString(jobData, "type_event");
          final String bannerKioskTop = _getString(jobData, "banner_kiosk_top");
          final String bannerKioskBottom = _getString(jobData, "banner_kiosk_bottom");

          String logoList = "";
          String bannerTopList = "";
          String bannerBottomList = "";

          if (jobData.containsKey("logo_list")) {
            logoList = json.encode(_getJSONArray(jobData, "logo_list"));
          }
          if (jobData.containsKey("banner_top_list")) {
            bannerTopList = json.encode(_getJSONArray(jobData, "banner_top_list"));
          }
          if (jobData.containsKey("banner_bottom_list")) {
            bannerBottomList = json.encode(_getJSONArray(jobData, "banner_bottom_list"));
          }

          StorageService.setEvent(
            idEvent: idEvent,
            title: title,
            bannerTop: bannerKioskTop,
            bannerBottom: bannerKioskBottom,
            logoList: logoList,
            bannerTopList: bannerTopList,
            bannerBottomList: bannerBottomList,
          );

          dProgress.show();

          Navigator.push(context, MaterialPageRoute(builder: (_) => const DeviceSettingPage(showProgress: true)));
        } else {
          // (app asli tidak menutup dProgress di cabang ini -> layar terkunci progress)
          dProgress.dismiss();
          dialogAfterProcess("Error", "There is something wrong!!", false);
        }
      } else {
        dProgress.dismiss();
        dialogAfterProcess("Error", LangService.getString('event_not_found'), false);
      }
    } catch (e) {
      debugPrint("Error1: $e");
      dProgress.dismiss();
      dialogAfterProcess("Error", LangService.getString('event_not_found'), false);
    }
  }

  // org.json: getBoolean / getString / getJSONArray (lempar JSONException kalau tidak ada / tipe salah)
  bool _getBoolean(Map json, String name) {
    final v = json[name];
    if (v is bool) return v;
    if (v is String && (v.toLowerCase() == "true" || v.toLowerCase() == "false")) return v.toLowerCase() == "true";
    throw FormatException("JSONObject[$name] is not a boolean.");
  }

  String _getString(Map obj, String name) {
    if (!obj.containsKey(name)) throw FormatException("No value for $name");
    final v = obj[name];
    if (v is Map || v is List) return json.encode(v);
    return v == null ? "null" : v.toString();
  }

  List _getJSONArray(Map json, String name) {
    final v = json[name];
    if (v is List) return v;
    throw FormatException("JSONObject[$name] is not a JSONArray.");
  }

  void dialogAfterProcess(String titleMessage, String subtitleMessage, bool success) {
    if (dialogShow.isShowing) {
      dialogShow.dismiss();
    }
    showDialogAfterProcess(context, dialogShow, titleMessage, subtitleMessage, success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: Column(
        children: [
          // lyTop
          Padding(
            padding: EdgeInsets.symmetric(horizontal: dsdp(10), vertical: dsdp(8)),
            child: Align(
              alignment: Alignment.centerRight,
              child: LanguageRadioGroup(language: language, onChanged: onLanguageChanged),
            ),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.all(dsdp(25)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: dsdp(10)),
                          child: Image.asset('assets/images/logo_kreen.png', width: dsdp(150), height: dsdp(70)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: dsdp(10)),
                          child: SizedBox(
                            width: double.infinity,
                            child: AText(LangService.getString('welcome_to_kreen'),
                                font: AFont.bold,
                                size: dssp(20),
                                color: textPrimary,
                                bold: true,
                                align: TextAlign.center),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: AText(LangService.getString('please_enter_your_event_id'),
                              font: AFont.poppins, size: dssp(16), color: textPrimary, align: TextAlign.center),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: dsdp(20), bottom: dsdp(15)),
                          child: FormEditText(
                            controller: etEventId,
                            focusNode: etEventIdFocus,
                            hint: LangService.getString('enter_event_id'),
                            height: dsdp(40),
                            textSize: dssp(14),
                            keyboardType: TextInputType.emailAddress,
                            onChanged: onTextChanged,
                            // IME_ACTION_DONE / NEXT / ENTER -> check_event()
                            onSubmitted: (_) => checkEvent(),
                          ),
                        ),
                        CircleNextButton(
                          enabled: ivNextEnabled,
                          onTap: () {
                            dismissKeyboard(context);
                            checkEvent();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
