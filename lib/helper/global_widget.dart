import 'dart:async';
import 'dart:math' as math;

import 'package:appkioskcoex/helper/global_function.dart';
import 'package:appkioskcoex/helper/global_var.dart';
import 'package:appkioskcoex/models/response_model.dart';
import 'package:appkioskcoex/services/lang_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

// =====================================================================================
// Teks (TextView Android + includeFontPadding)
// =====================================================================================

/// Font resource Android (@font/...). [roboto] = font default sistem (tanpa fontFamily).
enum AFont { poppins, medium, semibold, bold, roboto, robotoMedium }

class _FontMetrics {
  final String family;
  final FontWeight weight;
  final double yMax, yMin, ascent, descent; // per 1000 unitsPerEm
  const _FontMetrics(this.family, this.weight, this.yMax, this.yMin, this.ascent, this.descent);
}

// Nilai dari tabel head / hhea masing-masing file TTF di res/font
const Map<AFont, _FontMetrics> _metrics = {
  AFont.poppins: _FontMetrics(poppins, FontWeight.w400, 1076, -439, 1115, -525),
  AFont.medium: _FontMetrics(poppinsMedium, FontWeight.w500, 1077, -582, 1050, -350),
  AFont.semibold: _FontMetrics(poppinsSemiBold, FontWeight.w600, 1100, -476, 1115, -525),
  AFont.bold: _FontMetrics(poppinsBold, FontWeight.w700, 1115, -525, 1115, -525),
  // Roboto sistem (unitsPerEm 2048: yMax 2163, yMin -555, ascent 1900, descent -500)
  AFont.roboto: _FontMetrics('', FontWeight.w400, 1056.15, -270.99, 927.73, -244.14),
  // sans-serif-medium
  AFont.robotoMedium: _FontMetrics('', FontWeight.w500, 1056.15, -270.99, 927.73, -244.14),
};

/// TextView. [size] dalam dp (logical px); untuk ukuran sp pakai ssp()/sp().
class AText extends StatelessWidget {
  final String text;
  final AFont font;
  final double size;
  final Color color;
  final bool bold; // android:textStyle="bold"
  final TextAlign align;
  final int? maxLines;
  final bool ellipsize;
  final double letterSpacing; // em

  const AText(
    this.text, {
    super.key,
    this.font = AFont.roboto,
    required this.size,
    this.color = defaultTextColor,
    this.bold = false,
    this.align = TextAlign.start,
    this.maxLines,
    this.ellipsize = false,
    this.letterSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final m = _metrics[font]!;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    // Paint.getFontMetricsInt(): top=floor, ascent/descent=round, bottom=ceil (dalam px)
    // getDimensionPixelSize(): ukuran font dibulatkan ke pixel bulat
    final px = (size * dpr).roundToDouble();
    final fontSize = px / dpr;
    final topPx = (m.yMax / 1000 * px).ceilToDouble();
    final bottomPx = (-m.yMin / 1000 * px).ceilToDouble();
    final ascPx = (m.ascent / 1000 * px).roundToDouble();
    final descPx = (-m.descent / 1000 * px).roundToDouble();

    // Fake bold kalau textStyle=bold tapi file font tidak bold (seperti Minikin)
    final weight = bold && m.weight.value < 600 ? FontWeight.w700 : m.weight;

    return _FontPadding(
      top: (topPx - ascPx) / dpr,
      bottom: (bottomPx - descPx) / dpr,
      child: Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        overflow: ellipsize ? TextOverflow.ellipsis : null,
        style: TextStyle(
          fontFamily: m.family.isEmpty ? null : m.family,
          fontWeight: weight,
          fontSize: fontSize,
          color: color,
          height: (ascPx + descPx) / px,
          leadingDistribution: TextLeadingDistribution.even,
          letterSpacing: letterSpacing * fontSize,
        ),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: true,
          applyHeightToLastDescent: true,
        ),
      ),
    );
  }
}

/// Menambah (atau mengurangi, boleh negatif) ruang di atas/bawah teks:
/// baris pertama pakai "top" font, baris terakhir pakai "bottom" font (includeFontPadding).
class _FontPadding extends SingleChildRenderObjectWidget {
  final double top;
  final double bottom;
  const _FontPadding({required this.top, required this.bottom, required Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFontPadding(top, bottom);

  @override
  void updateRenderObject(BuildContext context, _RenderFontPadding renderObject) {
    renderObject
      ..top = top
      ..bottom = bottom;
  }
}

class _RenderFontPadding extends RenderShiftedBox {
  double _top;
  double _bottom;
  _RenderFontPadding(this._top, this._bottom) : super(null);

  set top(double v) {
    if (v == _top) return;
    _top = v;
    markNeedsLayout();
  }

  set bottom(double v) {
    if (v == _bottom) return;
    _bottom = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child!;
    c.layout(constraints.copyWith(minHeight: 0, maxHeight: double.infinity), parentUsesSize: true);
    (c.parentData! as BoxParentData).offset = Offset(0, _top);
    size = constraints.constrain(Size(c.size.width, math.max(0, c.size.height + _top + _bottom)));
  }

  @override
  double computeMinIntrinsicWidth(double height) => child!.getMinIntrinsicWidth(height);
  @override
  double computeMaxIntrinsicWidth(double height) => child!.getMaxIntrinsicWidth(height);
  @override
  double computeMinIntrinsicHeight(double width) => child!.getMinIntrinsicHeight(width) + _top + _bottom;
  @override
  double computeMaxIntrinsicHeight(double width) => child!.getMaxIntrinsicHeight(width) + _top + _bottom;
}

/// TextStyle untuk EditText (dipakai di TextField).
TextStyle aTextStyle(AFont font, double size, Color color, {bool bold = false}) {
  final m = _metrics[font]!;
  return TextStyle(
    fontFamily: m.family.isEmpty ? null : m.family,
    fontWeight: bold && m.weight.value < 600 ? FontWeight.w700 : m.weight,
    fontSize: textSizeDp(size),
    color: color,
  );
}

// =====================================================================================
// Ikon (AppCompatImageView + vector drawable + tint)
// =====================================================================================

class SvgIcon extends StatelessWidget {
  final String name;
  final double width;
  final double height;
  final Color? tint;
  final BoxFit fit;

  const SvgIcon(this.name, {super.key, required this.width, required this.height, this.tint, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: width,
      height: height,
      fit: fit,
      colorFilter: tint == null ? null : ColorFilter.mode(tint!, BlendMode.srcIn),
    );
  }
}

// =====================================================================================
// RadioGroup rg_language (rb_en: radio_left_selector, rb_id: radio_right_selector)
// =====================================================================================

class LanguageRadioGroup extends StatefulWidget {
  /// pref.getString("lang", "")
  final String language;

  /// RadioGroup.OnCheckedChangeListener -> "en" / "in"
  final ValueChanged<String> onChanged;

  const LanguageRadioGroup({super.key, required this.language, required this.onChanged});

  @override
  State<LanguageRadioGroup> createState() => _LanguageRadioGroupState();
}

class _LanguageRadioGroupState extends State<LanguageRadioGroup> {
  // android:checked="true" di rb_en
  late bool enChecked = widget.language != "in";

  void _check(bool en) {
    if (enChecked == en) return;
    setState(() => enChecked = en);
    widget.onChanged(en ? "en" : "in");
  }

  Widget _item(String text, bool checked, bool left, VoidCallback onTap) {
    final radius = Radius.circular(sdp(5));
    final borderRadius = left
        ? BorderRadius.only(topLeft: radius, bottomLeft: radius)
        : BorderRadius.only(topRight: radius, bottomRight: radius);
    return Material(
      color: checked ? colorPrimary : white,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: checked ? BorderSide.none : BorderSide(color: colorPrimary, width: sdp(1)),
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Container(
          height: dsdp(25),
          padding: EdgeInsets.symmetric(horizontal: dsdp(10)),
          alignment: Alignment.center,
          child: AText(text, size: dssp(12), color: checked ? white : colorPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _item("English", enChecked, true, () => _check(true)),
        _item("Indonesia", !enChecked, false, () => _check(false)),
      ],
    );
  }
}

// =====================================================================================
// CircleImageView ivNext (ic_arrow_right, civ_circle_background_color colorBG / colorPrimary)
// =====================================================================================

class CircleNextButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const CircleNextButton({super.key, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = dsdp(40);
    final border = dsdp(2); // civ_border_width (transparan), gambar di-inset selebar border
    return Material(
      color: enabled ? colorPrimary : colorBG,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: size,
          height: size,
          child: Padding(
            padding: EdgeInsets.all(border),
            child: const SvgIcon('ic_arrow_right', width: double.infinity, height: double.infinity, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

// =====================================================================================
// Dialog (AlertDialog.Builder + setView)
// =====================================================================================

/// Pengganti field `AlertDialog dialog_show` (isShowing() / dismiss()).
class DialogShow {
  Route<void>? _route;

  bool get isShowing => _route?.isActive ?? false;

  void show(BuildContext context, WidgetBuilder builder, {bool cancelable = true}) {
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: cancelable,
      barrierColor: const Color(0x99000000),
      useSafeArea: false,
      builder: builder,
    );
    _route = route;
    Navigator.of(context, rootNavigator: true).push(route).then((_) {
      if (identical(_route, route)) _route = null;
    });
  }

  void dismiss() {
    final route = _route;
    _route = null;
    if (route != null && route.isActive) {
      route.navigator?.removeRoute(route);
    }
  }
}

/// Window AlertDialog: windowMinWidthMinor 95% + background inset 16dp, corner 2dp, putih.
class _AlertWindow extends StatelessWidget {
  final Widget child;
  final bool transparentBackground;

  const _AlertWindow({required this.child, this.transparentBackground = false});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final minWidth = (size.width < size.height ? 0.95 : 0.65) * size.width;
    return Center(
      child: SizedBox(
        width: minWidth,
        child: Material(
          type: MaterialType.transparency,
          child: transparentBackground
              ? child
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    color: white,
                    borderRadius: BorderRadius.circular(2),
                    elevation: 24,
                    child: child,
                  ),
                ),
        ),
      ),
    );
  }
}

/// dialog_after_process(title_message, subtitle_message, success) -> layout after_process_dialog
void showDialogAfterProcess(BuildContext context, DialogShow dialogShow, String titleMessage, String subtitleMessage,
    bool success) {
  dialogShow.show(context, (_) {
    return _AlertWindow(
      child: Material(
        color: white,
        elevation: dsdp(10),
        borderRadius: BorderRadius.circular(dsdp(10)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dsdp(25), horizontal: dsdp(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: success
                    ? SvgIcon('ic_check_circle', width: dsdp(50), height: dsdp(50), tint: colorGreen)
                    : SvgIcon('ic_cancel', width: dsdp(50), height: dsdp(50), tint: colorPrimary),
              ),
              SizedBox(height: dsdp(20)),
              AText(titleMessage,
                  font: AFont.bold, size: dssp(18), color: textPrimary, bold: true, align: TextAlign.center),
              SizedBox(height: dsdp(10)),
              AText(subtitleMessage, font: AFont.poppins, size: dssp(14), align: TextAlign.center),
              // btn_submit "OK" ada di dalam LinearLayout visibility="gone"
            ],
          ),
        ),
      ),
    );
  });
}

/// dialog_option() (MainActivity2 / MainManual) -> layout dialog_option, background window transparan
void showDialogOption(
  BuildContext context,
  DialogShow dialogShow, {
  required VoidCallback onSetting,
  required VoidCallback onChangeEvent,
  required VoidCallback onExit,
}) {
  Widget button(String text, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(bottom: dsdp(15)),
      child: Material(
        color: transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: const BorderSide(color: colorLine, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: onTap,
          child: Container(
            height: dsdp(40),
            alignment: Alignment.center,
            child: AText(text, font: AFont.medium, size: dssp(16), color: textPrimary),
          ),
        ),
      ),
    );
  }

  dialogShow.show(context, (_) {
    return _AlertWindow(
      transparentBackground: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dsdp(18)),
        child: Card(
          margin: EdgeInsets.zero,
          color: white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(dsdp(18))),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dsdp(25)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: dsdp(25), bottom: dsdp(20)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: dialogShow.dismiss,
                        child: SvgIcon('ic_baseline_close_24', width: dsdp(30), height: dsdp(30), tint: black),
                      ),
                      SizedBox(width: dsdp(20)),
                      Expanded(
                        child: AText("Option", font: AFont.bold, size: ssp(14), color: textPrimary, bold: true),
                      ),
                    ],
                  ),
                ),
                button("Setting", onSetting),
                button("Change Event", onChangeEvent),
                button("Exit", onExit),
              ],
            ),
          ),
        ),
      ),
    );
  });
}

// =====================================================================================
// Tombol
// =====================================================================================

/// MaterialTextView + background button_background / grey_background (enabled / disabled)
class BackgroundTextButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final double height;
  final double textSize;
  final AFont font;
  final bool bold;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const BackgroundTextButton({
    super.key,
    required this.text,
    required this.enabled,
    required this.height,
    required this.textSize,
    this.font = AFont.medium,
    this.bold = false,
    this.padding = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // button_background: corners 5dp, grey_background: corners _5sdp (@android:color/darker_gray)
    final radius = BorderRadius.circular(enabled ? 5 : sdp(5));
    return Material(
      color: enabled ? colorPrimary : darkerGray,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: enabled ? onTap : null,
        child: Container(
          height: height,
          padding: padding,
          alignment: Alignment.center,
          child: AText(text, font: font, size: textSize, color: primaryTextDark, bold: bold, maxLines: 1),
        ),
      ),
    );
  }
}

/// MaterialCardView (cardElevation 0dp, strokeWidth __2sdp) berisi MaterialTextView
class CardTextButton extends StatelessWidget {
  final String text;
  final Color background;
  final Color strokeColor;
  final Color textColor;
  final double textSize;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const CardTextButton({
    super.key,
    required this.text,
    required this.background,
    required this.strokeColor,
    required this.textColor,
    required this.textSize,
    required this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(dsdp(10));
    return Material(
      color: background,
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: strokeColor, width: dsdp(2))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: AText(text, font: AFont.medium, size: textSize, color: textColor, align: TextAlign.center),
        ),
      ),
    );
  }
}

// =====================================================================================
// EditText dengan background form_background
// =====================================================================================

class FormEditText extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final double height;
  final double textSize;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const FormEditText({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hint,
    required this.height,
    required this.textSize,
    this.keyboardType = TextInputType.emailAddress,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: colorLine, width: 1),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        maxLines: 1,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.done,
        style: aTextStyle(AFont.poppins, textSize, defaultTextColor),
        cursorColor: colorPrimary,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: aTextStyle(AFont.poppins, textSize, defaultHintColor),
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

// =====================================================================================
// LinearLayout vertical: anak layout_height="match_parent" + layout_weight
// =====================================================================================

/// Tinggi tiap anak = H + (H - n*H) * weight / totalWeight (perilaku LinearLayout kalau
/// anak ber-weight memakai match_parent, bukan 0dp).
class MatchParentWeightColumn extends StatelessWidget {
  final List<(double weight, Widget child)> children;

  const MatchParentWeightColumn({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final h = constraints.maxHeight;
      final n = children.length;
      final totalWeight = children.fold<double>(0, (s, c) => s + c.$1);
      return Column(
        children: [
          for (final c in children)
            SizedBox(
              height: math.max(0, h + (h - n * h) * c.$1 / totalWeight),
              width: double.infinity,
              child: c.$2,
            ),
        ],
      );
    });
  }
}

// =====================================================================================
// SliderView (com.smarteist:Android-Image-Slider) + SliderAdapterExample
// =====================================================================================

class ImageSliderView extends StatefulWidget {
  final List<SliderItem> items;

  const ImageSliderView({super.key, required this.items});

  @override
  State<ImageSliderView> createState() => _ImageSliderViewState();
}

class _ImageSliderViewState extends State<ImageSliderView> {
  int current = 0;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    // app:sliderIndicatorRadius __2sdp, sliderIndicatorPadding __3sdp, sliderIndicatorMarginBottom __5sdp
    final radius = dsdp(2);
    return Container(
      color: placeholderBg,
      child: items.isEmpty
          ? null
          : Stack(
              fit: StackFit.expand,
              children: [
                CarouselSlider(
                  items: [
                    for (final item in items)
                      // image_slider_layout_item: iv_auto_image_slider scaleType fitXY
                      Image.network(
                        item.imageUrl ?? "",
                        fit: BoxFit.fill,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                  ],
                  options: CarouselOptions(
                    height: double.infinity,
                    viewportFraction: 1,
                    autoPlay: true, // sliderStartAutoCycle
                    autoPlayInterval: const Duration(seconds: 3), // sliderScrollTimeInSec
                    autoPlayAnimationDuration: const Duration(milliseconds: 600), // sliderAnimationDuration
                    autoPlayCurve: Curves.easeInOut,
                    enableInfiniteScroll: items.length > 1,
                    onPageChanged: (index, _) => setState(() => current = index),
                  ),
                ),
                // sliderIndicatorGravity="start|bottom"
                Positioned(
                  left: 12,
                  bottom: dsdp(5),
                  child: Row(
                    children: [
                      for (int i = 0; i < items.length; i++)
                        Container(
                          width: radius * 2,
                          height: radius * 2,
                          margin: EdgeInsets.only(right: i == items.length - 1 ? 0 : dsdp(3)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == current ? white : darkerGray,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// =====================================================================================
// activity_main2.xml / activity_main_manual.xml
// =====================================================================================

class KioskFrame extends StatelessWidget {
  final bool showCarouselTop; // rl_carousel_top visibility
  final bool showCarouselBottom; // rl_carousel_bottom visibility
  final List<SliderItem> bannerTop;
  final List<SliderItem> bannerBottom;
  final bool showStaticLogo; // imgStaticLogo
  final bool showLogoList; // rv_logo
  final List<ModelLogo> logos;
  final double cardCornerRadius;
  final double cardElevation;
  final String language;
  final ValueChanged<String> onLanguageChanged;
  final Key? languageKey;
  final Widget fragment;

  const KioskFrame({
    super.key,
    required this.showCarouselTop,
    required this.showCarouselBottom,
    required this.bannerTop,
    required this.bannerBottom,
    required this.showStaticLogo,
    required this.showLogoList,
    required this.logos,
    required this.cardCornerRadius,
    required this.cardElevation,
    required this.language,
    required this.onLanguageChanged,
    this.languageKey,
    required this.fragment,
  });

  @override
  Widget build(BuildContext context) {
    final middle = Column(
      children: [
        // toolbar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: dsdp(10), vertical: dsdp(8)),
          child: Stack(
            children: [
              if (showStaticLogo)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Image.asset('assets/images/logo_kreen.png', width: 100, height: 25, fit: BoxFit.scaleDown),
                ),
              Row(
                children: [
                  Expanded(
                    child: showLogoList
                        ? Padding(
                            padding: EdgeInsets.only(right: dsdp(10)),
                            child: SizedBox(
                              height: logos.isEmpty ? 0 : dsdp(28),
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [for (final logo in logos) _LogoItem(logo: logo)],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  LanguageRadioGroup(key: languageKey, language: language, onChanged: onLanguageChanged),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: const Color(0xFFE5E5E5),
            padding: EdgeInsets.all(dsdp(10)),
            child: Card(
              margin: EdgeInsets.zero,
              color: white,
              elevation: cardElevation,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardCornerRadius)),
              child: Padding(
                padding: EdgeInsets.all(dsdp(20)),
                child: SizedBox.expand(child: fragment),
              ),
            ),
          ),
        ),
      ],
    );

    return MatchParentWeightColumn(
      children: [
        if (showCarouselTop) (.6, ImageSliderView(items: bannerTop)),
        (.2, middle),
        if (showCarouselBottom) (.6, ImageSliderView(items: bannerBottom)),
      ],
    );
  }
}

/// item_logo.xml (AdapterLogo): iv_logo __70sdp x __28sdp, marginEnd __20sdp, fitStart, RoundedCorners(15)
class _LogoItem extends StatelessWidget {
  final ModelLogo logo;

  const _LogoItem({required this.logo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: dsdp(20)),
      child: SizedBox(
        width: dsdp(70),
        height: dsdp(28),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(px(15)),
            child: Image.network(
              logo.img ?? "",
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Swipe ke kiri di root -> dialog_option() (utils/OnSwipeTouchListener)
class SwipeLeftDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipeLeft;

  const SwipeLeftDetector({super.key, required this.child, required this.onSwipeLeft});

  @override
  State<SwipeLeftDetector> createState() => _SwipeLeftDetectorState();
}

class _SwipeLeftDetectorState extends State<SwipeLeftDetector> {
  Offset? _start;
  Offset? _last;

  @override
  Widget build(BuildContext context) {
    // SWIPE_THRESHOLD = 100, SWIPE_VELOCITY_THRESHOLD = 100 (pixel)
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (d) => _start = _last = d.globalPosition,
      onHorizontalDragUpdate: (d) => _last = d.globalPosition,
      onHorizontalDragEnd: (d) {
        final start = _start, last = _last;
        if (start == null || last == null) return;
        final diffX = last.dx - start.dx;
        final diffY = last.dy - start.dy;
        final velocityX = d.velocity.pixelsPerSecond.dx;
        if (diffX.abs() > diffY.abs() && diffX.abs() > px(100) && velocityX.abs() > px(100) && diffX < 0) {
          widget.onSwipeLeft();
        }
      },
      child: widget.child,
    );
  }
}

/// Root fragment yang setOnTouchListener(... return true) -> sentuhan tidak diteruskan ke root activity.
class ConsumeTouch extends StatelessWidget {
  final Widget child;
  final VoidCallback onTouch;

  const ConsumeTouch({super.key, required this.child, required this.onTouch});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onTouch(),
      onHorizontalDragStart: (_) => onTouch(),
      child: child,
    );
  }
}

// =====================================================================================
// DetailAdapter (item_header_fullname + item_detail) dalam layFullData (bg light_gray2)
// =====================================================================================

class DetailList extends StatelessWidget {
  final String? fullname;
  final String? email;
  final List<OrderFormModel>? details;

  const DetailList({super.key, this.fullname, this.email, this.details});

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(vertical: dsdp(10), horizontal: dsdp(15));
    return Container(
      color: lightGray2,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TYPE_HEADER
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AText(LangService.getString('full_name'), font: AFont.poppins, size: dssp(12), color: textPrimary),
                AText(fullname ?? "", font: AFont.bold, size: dssp(14), color: textPrimary, bold: true),
                AText("Email", font: AFont.poppins, size: dssp(12), color: textPrimary),
                AText(email ?? "", font: AFont.bold, size: dssp(14), color: textPrimary, bold: true),
              ],
            ),
          ),
          // TYPE_ITEM
          for (final item in details ?? const <OrderFormModel>[])
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AText(item.question ?? "", font: AFont.poppins, size: dssp(14), color: textPrimary),
                  AText(item.answer ?? "", font: AFont.bold, size: dssp(14), color: textPrimary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Toast.makeText(context, text, LENGTH_SHORT).show()
void showToast(String text, {bool long = false}) {
  Fluttertoast.showToast(msg: text, toastLength: long ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT);
}

/// new Handler(Looper.getMainLooper()).postDelayed(...)
Timer postDelayed(Duration delay, VoidCallback action) => Timer(delay, action);
