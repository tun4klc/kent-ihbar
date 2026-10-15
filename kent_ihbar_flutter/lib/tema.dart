import 'package:flutter/material.dart';

// MARK: - Renk tokenları (tasarım sistemindeki tokens.json ile birebir)

/// Açık / koyu temaya göre çözülmüş Kent İhbar renkleri.
/// Kullanım: `final r = KIRenk.of(context); r.zemin`
class KIRenk {
  const KIRenk._(this.koyu);

  final bool koyu;

  static const acikTema = KIRenk._(false);
  static const koyuTema = KIRenk._(true);

  static KIRenk of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? koyuTema : acikTema;

  /// Açık / koyu temaya göre değişen renk.
  Color sec(int acik, int koyuDeger) => Color(0xFF000000 | (koyu ? koyuDeger : acik));

  // Zemin & yüzey
  Color get zemin => sec(0xF8FAFC, 0x0B0F17);
  Color get yuzey => sec(0xFFFFFF, 0x131B2E);
  Color get yuzeyUst => sec(0xEEF2F8, 0x1B2540);
  Color get cizgi => sec(0xE2E8F0, 0x26314D);
  Color get cizgiKontrol => sec(0x7C8BA1, 0x5E6E8E);

  // Metin
  Color get metin => sec(0x0F172A, 0xF8FAFC);
  Color get metinIkincil => sec(0x475569, 0x94A3B8);
  Color get metinSoluk => sec(0x64748B, 0x7D8BA6);

  // Marka
  Color get maviRenk => sec(0x3F97FF, 0x3F97FF);
  Color get maviBayaz => sec(0xFFFFFF, 0xFFFFFF);
  Color get birincil => sec(0x2563EB, 0x3F97FF);
  Color get birincilBasili => sec(0x1D4ED8, 0x6AAEFF);
  Color get onBirincil => sec(0xFFFFFF, 0x0B0F17);
  Color get birincilYumusak => sec(0xDBEAFE, 0x172554);
  Color get birincilMetin => sec(0x1D4ED8, 0x93C5FD);
  Color get vurgu => sec(0x0E7490, 0x06B6D4);
  Color get vurguYumusak => sec(0xCFFAFE, 0x0A2A33);

  // Durum
  Color get kritik => sec(0xB91C1C, 0xF87171);
  Color get kritikYumusak => sec(0xFEE2E2, 0x3A1418);
  Color get beklemede => sec(0xB45309, 0xFBBF24);
  Color get beklemedeYumusak => sec(0xFEF3C7, 0x36290A);
  Color get cozuldu => sec(0x047857, 0x34D399);
  Color get cozulduYumusak => sec(0xD1FAE5, 0x0B2E24);
  Color get onDurum => sec(0xFFFFFF, 0x0B0F17);
  Color get odakHalkasi => sec(0x2563EB, 0x93C5FD);
}

// MARK: - Boşluk, köşe, hareket

abstract final class KI {
  // Boşluk
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;

  // Köşe
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;

  // Hareket
  static const sureHizli = Duration(milliseconds: 150);
  static const sureOrta = Duration(milliseconds: 250);
  static const sureYavas = Duration(milliseconds: 400);
  static const egriStandart = Cubic(0.2, 0, 0, 1);
}

// MARK: - Tipografi (Lexend başlık, Figtree gövde)

enum Agirlik { normal, orta, yariKalin, kalin }

abstract final class KIFont {
  static TextStyle baslik(double boyut, {bool kalin = true}) => TextStyle(
    fontFamily: 'Lexend',
    fontSize: boyut,
    fontWeight: kalin ? FontWeight.w600 : FontWeight.w400,
    height: 1.2,
  );

  static TextStyle govde(double boyut, [Agirlik agirlik = Agirlik.normal]) => TextStyle(
    fontFamily: 'Figtree',
    fontSize: boyut,
    fontWeight: switch (agirlik) {
      Agirlik.normal => FontWeight.w400,
      Agirlik.orta => FontWeight.w500,
      Agirlik.yariKalin => FontWeight.w600,
      Agirlik.kalin => FontWeight.w700,
    },
    height: 1.3,
  );

  // Tasarım sistemi stilleri
  static TextStyle get ekranBasligi => baslik(28);
  static TextStyle get bolumBasligi => baslik(20);
  static TextStyle get kartBasligi => baslik(17);
  static TextStyle get sayiBuyuk => baslik(32);
  static TextStyle get govdeMetni => govde(16);
  static TextStyle get govdeKucuk => govde(14);
  static TextStyle get dugme => govde(16, Agirlik.yariKalin);
  static TextStyle get etiket => govde(13, Agirlik.yariKalin);
  static TextStyle get altYazi => govde(12, Agirlik.orta);
}

extension TextStyleRenk on TextStyle {
  TextStyle renk(Color c) => copyWith(color: c);
}

// MARK: - Gölgeler

/// `golge-kart`
List<BoxShadow> kartGolgesi(KIRenk r) => [
  BoxShadow(
    color: Colors.black.withValues(alpha: r.koyu ? 0.35 : 0.06),
    blurRadius: r.koyu ? 24 : 18,
    offset: Offset(0, r.koyu ? 8 : 6),
  ),
];

/// Kullanıcı tanımlı `golge` tokenı — harita üzerindeki yüzen kontroller
List<BoxShadow> sertGolge(KIRenk r) => [
  BoxShadow(
    color: Colors.black.withValues(alpha: r.koyu ? 0.5 : 0.2),
    blurRadius: 2,
    offset: const Offset(3, 3),
  ),
];

/// `mavi-yansima`: mavi dış parlama
List<BoxShadow> maviYansima(KIRenk r, [bool aktif = true]) => aktif
    ? [BoxShadow(color: r.maviRenk.withValues(alpha: 0.40), blurRadius: 24, offset: const Offset(0, 10))]
    : const [];

/// Üst yarıda ince beyaz ışık — `mavi-yansima`nın yansıma katmanı.
const yansimaIsigi = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x38FFFFFF), Color(0x00FFFFFF)],
  stops: [0, 0.5],
);

/// `yuzey` zemin + `golge-kart`
class Kart extends StatelessWidget {
  const Kart({super.key, required this.child, this.dolgu = KI.space5, this.kose = KI.radiusLg});

  final Widget child;
  final double dolgu;
  final double kose;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Container(
      padding: EdgeInsets.all(dolgu),
      decoration: BoxDecoration(
        color: r.yuzey,
        borderRadius: BorderRadius.circular(kose),
        border: r.koyu ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
        boxShadow: kartGolgesi(r),
      ),
      child: child,
    );
  }
}

// MARK: - Tema

ThemeData kiTema(Brightness parlaklik) {
  final r = parlaklik == Brightness.dark ? KIRenk.koyuTema : KIRenk.acikTema;
  final temel = ThemeData(brightness: parlaklik, useMaterial3: true, fontFamily: 'Figtree');
  return temel.copyWith(
    scaffoldBackgroundColor: r.zemin,
    colorScheme: ColorScheme.fromSeed(
      seedColor: r.birincil,
      brightness: parlaklik,
    ).copyWith(primary: r.birincil, onPrimary: r.onBirincil, surface: r.yuzey, onSurface: r.metin, error: r.kritik),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: r.birincil,
      selectionColor: r.birincil.withValues(alpha: 0.3),
      selectionHandleColor: r.birincil,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      backgroundColor: r.zemin,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: r.metin,
      titleTextStyle: KIFont.govde(17, Agirlik.yariKalin).renk(r.metin),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: r.zemin,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: r.cizgiKontrol,
    ),
    dialogTheme: DialogThemeData(backgroundColor: r.yuzey, surfaceTintColor: Colors.transparent),
    popupMenuTheme: PopupMenuThemeData(
      color: r.yuzey,
      surfaceTintColor: Colors.transparent,
      textStyle: KIFont.govde(15, Agirlik.orta).renk(r.metin),
    ),
  );
}
