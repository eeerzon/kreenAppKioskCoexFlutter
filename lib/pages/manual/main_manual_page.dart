import 'package:appkioskcoex/helper/activity_lifecycle.dart';
import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/helper/global_widget.dart';
import 'package:appkioskcoex/models/response_model.dart';
import 'package:appkioskcoex/pages/kiosk_host.dart';
import 'package:appkioskcoex/pages/login_event_page.dart';
import 'package:appkioskcoex/helper/loading_page.dart';
import 'package:appkioskcoex/pages/manual/one_manual_fragment.dart';
import 'package:appkioskcoex/pages/manual/two_manual2_fragment.dart';
import 'package:appkioskcoex/pages/manual/two_manual_fragment.dart';
import 'package:appkioskcoex/services/api_services.dart';
import 'package:appkioskcoex/pages/scan/main_activity2_page.dart';
import 'package:appkioskcoex/pages/setting_page.dart';
import 'package:appkioskcoex/services/lang_service.dart';
import 'package:appkioskcoex/services/storage_services.dart';
import 'package:flutter/material.dart';

/// manual/MainManual.java (mode redeem "manual") -> activity_main_manual.xml
class MainManualPage extends StatefulWidget {
  const MainManualPage({super.key});

  @override
  State<MainManualPage> createState() => MainManualPageState();
}

class MainManualPageState extends State<MainManualPage> with ActivityLifecycle implements KioskHost {
  // ---- field public (dipakai fragment) ----
  @override
  String idEvent = "";
  @override
  String titleEvent = "";
  @override
  String? idTicket = "";
  @override
  String? fullName = "";
  @override
  String instansi = "";
  @override
  String answer = "";
  @override
  String jobTitle = "";
  @override
  String? email = "";
  @override
  int eventBuyer = 0;
  @override
  List<OrderFormModel>? orderForm;
  @override
  String? showQr;
  @override
  List<OrderFormModel>? formValues = [];
  @override
  bool canPrint = false;

  // ---- field private ----
  final DialogShow dialogShow = DialogShow();
  late final CustomProgressDialogue dProgress = CustomProgressDialogue(context, cancelable: false);

  String bannerTopList = "";
  String bannerBottomList = "";
  String logoList = "";
  late String language;

  final List<ModelLogo> modelLogoList = [];
  final List<SliderItem> modelBannerListTop = [];
  final List<SliderItem> modelBannerListBottom = [];
  bool imgStaticLogoVisible = false; // android:visibility="gone"
  bool rvLogoVisible = true;
  bool rlCarouselTopVisible = true;
  bool rlCarouselBottomVisible = true;

  Widget Function() fragment = () => const OneManualFragment();
  Key fragmentKey = UniqueKey();

  @override
  void initState() {
    super.initState();

    language = StorageService.getLangRaw();

    idEvent = StorageService.getIdEvent();
    titleEvent = StorageService.getTitleEvent();
    logoList = StorageService.getLogoList();
    bannerTopList = StorageService.getBannerTopList();
    bannerBottomList = StorageService.getBannerBottomList();

    dataLogoList();

    fragment = () => const OneManualFragment();
  }

  void dataLogoList() {
    final logos = parseIdImgList(logoList);
    if (logos == null) {
      imgStaticLogoVisible = true;
      rvLogoVisible = false;
    } else {
      modelLogoList.addAll(logos.map((e) => ModelLogo(id: e.$1, img: e.$2)));
      if (modelLogoList.isNotEmpty) {
        imgStaticLogoVisible = false;
        rvLogoVisible = true;
      } else {
        imgStaticLogoVisible = true;
        rvLogoVisible = false;
      }
    }

    // banner top
    final top = parseIdImgList(bannerTopList);
    if (top != null) {
      modelBannerListTop.addAll(top.map((e) => SliderItem(description: e.$1, imageUrl: e.$2)));
      rlCarouselTopVisible = modelBannerListTop.isNotEmpty;
    }

    // banner bottom
    final bottom = parseIdImgList(bannerBottomList);
    if (bottom != null) {
      modelBannerListBottom.addAll(bottom.map((e) => SliderItem(description: e.$1, imageUrl: e.$2)));
      rlCarouselBottomVisible = modelBannerListBottom.isNotEmpty;
    }
  }

  @override
  void replaceFragment(Widget Function() fragment) {
    if (!mounted) return;
    setState(() {
      this.fragment = fragment;
      fragmentKey = UniqueKey();
    });
  }

  /// Checked change Listener for Radio button language:
  /// update bahasa lalu replace fragment aktif dengan instance baru dari class yang sama
  void onLanguageChanged(String code) {
    LangService.updateResources(code);
    replaceFragment(fragment);
  }

  void dialogOption() {
    showDialogOption(
      context,
      dialogShow,
      onSetting: () {
        dialogShow.dismiss();
        // FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_NO_ANIMATION + finish()
        Navigator.pushReplacement(context, noAnimationRoute(const SettingPage()));
      },
      onChangeEvent: () {
        dialogShow.dismiss();
        Navigator.pushReplacement(context, noAnimationRoute(const LoginEventPage()));
      },
      onExit: exitApp,
    );
  }

  void dialogAfterProcess(String titleMessage, String subtitleMessage, bool success) {
    showDialogAfterProcess(context, dialogShow, titleMessage, subtitleMessage, success);
  }

  /// redeem_process_(id_ticket) versi lama (Volley): sukses -> TwoManualFragment (data tidak diparse)
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
    final r = parseLegacyRedeem(response);
    if (r.status == LegacyRedeemStatus.data || r.status == LegacyRedeemStatus.dataNull) {
      replaceFragment(() => const TwoManualFragment());
    } else if (r.status == LegacyRedeemStatus.failed) {
      dialogAfterProcess(LangService.getString('scan_failed'),
          LangService.getString('scan_was_not_successful_make_sure_you_show_a_valid_qr_code'), false);
    }
  }

  /// redeem_process(_id_ticket) (Retrofit, tanpa fallback jipremium & tanpa questionMap).
  /// Di app asli dipanggil dari klik iv_banner_top (view-nya GONE).
  Future<void> redeemProcess(String idTicket0) async {
    final canPrintBuyer = allowedEventId == idEvent;

    final idRedeem = ramdon(20, "123456789", "");
    dProgress.show();

    final response = await ApiService.fetchData(idRedeem, idTicket0, idEvent);
    if (!mounted) return;
    if (response.isFailure) {
      debugPrint("API Failure: ${response.error}");
      dialogAfterProcess(
          LangService.getString('connection_problem'), LangService.getString('connection_lost'), false);
      dProgress.hide();
      return;
    }
    dProgress.hide();
    final responseModel = response.body;
    if (response.isSuccessful && responseModel != null && responseModel.success && responseModel.data != null) {
      applyRedeemResult(this, responseModel, null);
      canPrint = canPrintBuyer;
      replaceFragment(() => TwoManual2Fragment(idEvent: idEvent));
    } else {
      dialogAfterProcess(LangService.getString('scan_failed'),
          LangService.getString('scan_was_not_successful_make_sure_you_show_a_valid_qr_code'), false);
    }
  }

  @override
  void onResume() {
    setFullScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      resizeToAvoidBottomInset: false,
      body: KioskHostScope(
        host: this,
        child: SwipeLeftDetector(
          onSwipeLeft: dialogOption,
          child: KioskFrame(
            showCarouselTop: rlCarouselTopVisible,
            showCarouselBottom: rlCarouselBottomVisible,
            bannerTop: modelBannerListTop,
            bannerBottom: modelBannerListBottom,
            showStaticLogo: imgStaticLogoVisible,
            showLogoList: rvLogoVisible,
            logos: modelLogoList,
            cardCornerRadius: sdp(5), // CardView cardCornerRadius _5sdp
            cardElevation: 2, // CardView default elevation
            language: language,
            onLanguageChanged: onLanguageChanged,
            fragment: KeyedSubtree(key: fragmentKey, child: fragment()),
          ),
        ),
      ),
    );
  }
}
