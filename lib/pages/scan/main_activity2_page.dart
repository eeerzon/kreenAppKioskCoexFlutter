import 'package:appkioskcoex/helper/activity_lifecycle.dart';
import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/helper/global_widget.dart';
import 'package:appkioskcoex/helper/loading_page.dart';
import 'package:appkioskcoex/models/response_model.dart';
import 'package:appkioskcoex/pages/kiosk_host.dart';
import 'package:appkioskcoex/pages/device_setting_page.dart';
import 'package:appkioskcoex/pages/login_event_page.dart';
import 'package:appkioskcoex/pages/scan/make_sure_data2_fragment.dart';
import 'package:appkioskcoex/pages/scan/make_sure_data_fragment.dart';
import 'package:appkioskcoex/pages/scan/scan_fragment.dart';
import 'package:appkioskcoex/pages/setting_page.dart';
import 'package:appkioskcoex/services/api_services.dart';
import 'package:appkioskcoex/services/lang_service.dart';
import 'package:appkioskcoex/services/scanner_app_engine.dart';
import 'package:appkioskcoex/services/storage_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// MainActivity2.java (mode redeem "scan") -> activity_main2.xml
class MainActivity2Page extends StatefulWidget {
  // getIntent().getXxxExtra(Constants.SCANNER_*)
  final int scannerId;
  final String? scannerName;
  final String? scannerAddress;
  final ConnType scannerType;
  final int picklistMode;

  const MainActivity2Page({
    super.key,
    this.scannerId = -1,
    this.scannerName,
    this.scannerAddress,
    this.scannerType = ConnType.invalid,
    this.picklistMode = 0,
  });

  @override
  State<MainActivity2Page> createState() => MainActivity2PageState();
}

class MainActivity2PageState extends State<MainActivity2Page>
    with ActivityLifecycle, IScannerAppEngineDevEventsDelegate, IScannerAppEngineDevConnectionsDelegate
    implements KioskHost {
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

  bool onScan = true; // public boolean _onScan

  // ---- field private ----
  final DialogShow dialogShow = DialogShow();
  late final CustomProgressDialogue dProgress = CustomProgressDialogue(context, cancelable: false);
  final QuestionMap questionMap = QuestionMap();

  String bannerTopList = "";
  String bannerBottomList = "";
  String logoList = "";
  late String language;

  List<ModelLogo> modelLogoList = [];
  List<SliderItem> modelBannerListTop = [];
  List<SliderItem> modelBannerListBottom = [];
  bool imgStaticLogoVisible = false; // android:visibility="gone"
  bool rvLogoVisible = true;
  bool rlCarouselTopVisible = true;
  bool rlCarouselBottomVisible = true;

  Widget Function() fragment = () => const ScanFragment();
  Key fragmentKey = UniqueKey();
  Key activityKey = UniqueKey();

  int scannerID = -1;
  int iBarcodeCount = 0;

  @override
  void initState() {
    super.initState();
    showScannerNotAvailableToastIfNeeded();
    onCreate();
  }

  void onCreate() {
    language = StorageService.getLangRaw();

    idEvent = StorageService.getIdEvent();
    titleEvent = StorageService.getTitleEvent();
    logoList = StorageService.getLogoList();
    bannerTopList = StorageService.getBannerTopList();
    bannerBottomList = StorageService.getBannerBottomList();

    if (idEvent.isNotEmpty) {
      questionMap.listQuestionOrderForm(idEvent);
    }

    dataLogoList();

    fragment = () => const ScanFragment();
    fragmentKey = UniqueKey();

    // setup scan
    ScannerAppEngine.addDevConnectionsDelegate(this);
    scannerID = widget.scannerId;
    ScannerAppEngine.currentScannerId = scannerID;
    ScannerAppEngine.currentScannerName = widget.scannerName ?? "";
    ScannerAppEngine.currentScannerAddress = widget.scannerAddress ?? "";
    // Initilization
    iBarcodeCount = 0;
  }

  /// recreate() setelah ganti bahasa
  void recreate() {
    onPause();
    setState(() {
      idTicket = "";
      fullName = "";
      instansi = "";
      answer = "";
      jobTitle = "";
      email = "";
      eventBuyer = 0;
      orderForm = null;
      showQr = null;
      formValues = [];
      canPrint = false;
      onScan = true;
      activityKey = UniqueKey();
      onCreate();
    });
    onResume();
  }

  void dataLogoList() {
    modelLogoList = [];
    modelBannerListTop = [];
    modelBannerListBottom = [];

    final logos = parseIdImgList(logoList);
    if (logos != null) {
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

  void onLanguageChanged(String code) {
    LangService.updateResources(code);
    recreate();
  }

  void dialogOption() {
    showDialogOption(
      context,
      dialogShow,
      onSetting: () {
        dialogShow.dismiss();
        // FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_NO_ANIMATION + finish()
        Navigator.pushReplacement(context, _noAnimation(const SettingPage()));
      },
      onChangeEvent: () {
        dialogShow.dismiss();
        Navigator.pushReplacement(context, _noAnimation(const LoginEventPage()));
      },
      onExit: exitApp,
    );
  }

  void dialogAfterProcess(String titleMessage, String subtitleMessage, bool success) {
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
        applyLegacyRedeem(this, r);
        replaceFragment(() => const MakeSureDataFragment());
        break;
      case LegacyRedeemStatus.dataNull:
        showToast("null");
        break;
      case LegacyRedeemStatus.failed:
        dialogAfterProcess(LangService.getString('scan_failed'),
            LangService.getString('scan_was_not_successful_make_sure_you_show_a_valid_qr_code'), false);
        break;
      case LegacyRedeemStatus.jsonError:
        // (app asli: hanya log, tidak ada dialog)
        break;
    }
  }

  /// pullTrigger(View) -> android:onClick iv_banner_top (view-nya GONE)
  Future<void> pullTrigger() async {
    final inXml = "<inArgs><scannerID>$scannerID</scannerID></inArgs>";
    final out = await ScannerAppEngine.executeCommand('DCSSDK_DEVICE_PULL_TRIGGER', inXml, scannerID);
    debugPrint(out);
  }

  /// redeem_process(_id_ticket) -> dipanggil dari scannerBarcodeEvent
  Future<void> redeemProcess(String idTicket0) async {
    final idRedeem = ramdon(20, "123456789", "");
    dProgress.show();

    final response = await ApiService.fetchData(idRedeem, idTicket0, idEvent);
    if (!mounted) return;
    if (response.isFailure) {
      // Tangani kegagalan
      checkBookingJipremium(idTicket0, idEvent);
      dProgress.hide();
      return;
    }

    dProgress.hide();
    final responseModel = response.body;
    if (response.isSuccessful && responseModel != null && responseModel.success && responseModel.data != null) {
      fullName = responseModel.data!.detail?.fullname;
      email = responseModel.data!.detail?.email;
      applyRedeemResult(this, responseModel, questionMap);

      replaceFragment(() => MakeSureData2Fragment(idEvent: idEvent));
    } else {
      checkBookingJipremium(idTicket0, idEvent);
    }
  }

  Future<void> checkBookingJipremium(String idTicket0, String idEvent0) async {
    debugPrint("checkBookingJipremium DIPANGGIL, idTicket=$idTicket0");

    final response = await ApiService.checkBooking(idTicket0, idEvent0);
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
    applyRedeemResult(this, responseModel, questionMap);
    replaceFragment(() => MakeSureData2Fragment(idEvent: idEvent));
  }

  @override
  void onResume() {
    setFullScreen();
    ScannerAppEngine.setDelegate();
    ScannerAppEngine.addDevEventsDelegate(this);
    ScannerAppEngine.addDevConnectionsDelegate(this);
    addMissedBarcodes();
  }

  @override
  void onPause() {
    ScannerAppEngine.removeDevEventsDelegate(this);
    ScannerAppEngine.removeDevConnectiosDelegate(this);
  }

  @override
  void dispose() {
    ScannerAppEngine.removeDevEventsDelegate(this);
    ScannerAppEngine.removeDevConnectiosDelegate(this);
    super.dispose();
  }

  void addMissedBarcodes() {
    final data = ScannerAppEngine.barcodeData;
    if (data.length != iBarcodeCount) {
      for (int i = iBarcodeCount; i < data.length; i++) {
        scannerBarcodeEvent(data[i].barcodeData, data[i].barcodeType, data[i].fromScannerID);
      }
    }
  }

  // ---- IScannerAppEngineDevEventsDelegate ----

  @override
  void scannerBarcodeEvent(Uint8List barcodeData, int barcodeType, int scannerID) {
    ++iBarcodeCount;
    final dataScan = ScannerAppEngine.barcodeToString(barcodeData);
    if (dialogShow.isShowing) {
      dialogShow.dismiss();
    }

    if (onScan) {
      redeemProcess(dataScan);
    }
  }

  // ---- IScannerAppEngineDevConnectionsDelegate ----

  @override
  bool scannerHasAppeared(int scannerID) => false;

  @override
  bool scannerHasDisappeared(int scannerID) => true;

  @override
  bool scannerHasConnected(int scannerID) {
    ScannerAppEngine.barcodeData.clear();
    iBarcodeCount = 0;
    return false;
  }

  @override
  bool scannerHasDisconnected(int scannerID) {
    ScannerAppEngine.barcodeData.clear();
    iBarcodeCount = 0;
    if (mounted) Navigator.maybePop(context);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      resizeToAvoidBottomInset: false,
      body: KioskHostScope(
        host: this,
        child: SwipeLeftDetector(
          key: activityKey,
          onSwipeLeft: dialogOption,
          child: KioskFrame(
            showCarouselTop: rlCarouselTopVisible,
            showCarouselBottom: rlCarouselBottomVisible,
            bannerTop: modelBannerListTop,
            bannerBottom: modelBannerListBottom,
            showStaticLogo: imgStaticLogoVisible,
            showLogoList: rvLogoVisible,
            logos: modelLogoList,
            cardCornerRadius: dsdp(10), // MaterialCardView cardCornerRadius __10sdp
            cardElevation: 1,
            language: language,
            onLanguageChanged: onLanguageChanged,
            fragment: KeyedSubtree(key: fragmentKey, child: fragment()),
          ),
        ),
      ),
    );
  }
}

PageRouteBuilder _noAnimation(Widget page) => PageRouteBuilder(
      pageBuilder: (_, _, _) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );

PageRouteBuilder noAnimationRoute(Widget page) => _noAnimation(page);
