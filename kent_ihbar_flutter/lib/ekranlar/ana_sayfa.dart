import 'package:flutter/material.dart';

import '../bilesenler.dart';
import '../kapsam.dart';
import '../model.dart';
import '../tema.dart';

enum _Filtre { tumu, acik, cozulen }

/// Düzen Şehir Bildirim ana sayfasından: mavi üst alan (karşılama, "Sorun mu gördün?",
/// hızlı geçişler) → konum izni → genel durum → kategoriler → bildirimlerim.
class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key, required this.yeniIhbar, required this.haritayaGit, required this.siralamayaGit});

  final void Function([Kategori? kategori]) yeniIhbar;
  final VoidCallback haritayaGit;
  final VoidCallback siralamayaGit;

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  _Filtre _filtre = _Filtre.tumu;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final durum = DurumKapsami.of(context);
    final konum = KonumKapsami.of(context);
    final ustBosluk = MediaQuery.paddingOf(context).top;

    final acikSayisi = konum.izinVar ? durum.ihbarlar.where((i) => i.durum != Durum.cozuldu).length : 0;
    final cozulenSayisi = konum.izinVar ? durum.ihbarlar.where((i) => i.durum == Durum.cozuldu).length : 0;

    return Stack(
      children: [
        // Durum çubuğunun ve yukarı çekmenin arkasını da mavi tutar.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.sizeOf(context).height / 2,
          child: DecoratedBox(decoration: BoxDecoration(gradient: _UstAlanRenk.gradyan(r))),
        ),
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UstAlan(
                ustBosluk: ustBosluk,
                yeniIhbar: () => widget.yeniIhbar(),
                haritayaGit: widget.haritayaGit,
                siralamayaGit: widget.siralamayaGit,
              ),
              Container(
                color: r.zemin,
                padding: const EdgeInsets.fromLTRB(KI.space5, KI.space6, KI.space5, KI.space8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSize(
                      duration: KI.sureOrta,
                      curve: KI.egriStandart,
                      alignment: Alignment.topCenter,
                      child: konum.izinVar
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(bottom: KI.space6),
                              child: _izinKarti(r),
                            ),
                    ),
                    Text('Genel durum', style: KIFont.bolumBasligi.renk(r.metin)),
                    const SizedBox(height: KI.space3),
                    Row(
                      children: [
                        Expanded(
                          child: IstatistikKarti(tur: IstatistikTuru.acik, deger: acikSayisi),
                        ),
                        const SizedBox(width: KI.space3),
                        Expanded(
                          child: IstatistikKarti(tur: IstatistikTuru.cozulen, deger: cozulenSayisi),
                        ),
                        const SizedBox(width: KI.space3),
                        const Expanded(child: IstatistikKarti(tur: IstatistikTuru.belediye, deger: 1407)),
                      ],
                    ),
                    const SizedBox(height: KI.space6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('Kategoriler', style: KIFont.bolumBasligi.renk(r.metin)),
                        const Spacer(),
                        Basilabilir(
                          onTap: () => widget.yeniIhbar(),
                          child: Text('Tümü', style: KIFont.etiket.renk(r.birincilMetin)),
                        ),
                      ],
                    ),
                    const SizedBox(height: KI.space3),
                    _kategoriIzgarasi(),
                    const SizedBox(height: KI.space6),
                    _bildirimlerimBolumu(r, durum),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kategoriIzgarasi() {
    const k = Kategori.values;
    return Column(
      children: [
        for (var satir = 0; satir < k.length; satir += 3) ...[
          if (satir > 0) const SizedBox(height: KI.space3),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = satir; i < satir + 3; i++) ...[
                  if (i > satir) const SizedBox(width: KI.space3),
                  Expanded(
                    child: i < k.length
                        ? KategoriKutusu(kategori: k[i], eylem: () => widget.yeniIhbar(k[i]))
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // MARK: Konum izni

  Widget _izinKarti(KIRenk r) {
    final konum = KonumKapsami.of(context);
    return Basilabilir(
      onTap: konum.izinIste,
      child: Kart(
        dolgu: KI.space4,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: r.birincil, shape: BoxShape.circle),
              child: Icon(
                konum.reddedildi ? Icons.location_disabled_rounded : Icons.near_me_rounded,
                size: 18,
                color: r.onBirincil,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    konum.reddedildi ? 'Konum izni kapalı' : 'Konum izni ver',
                    style: KIFont.kartBasligi.renk(r.metin),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    konum.reddedildi ? "Ayarlar'dan açarak ilçendeki ihbarları gör." : 'İlçendeki açık ihbarları gör.',
                    style: KIFont.govdeKucuk.renk(r.metinIkincil),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 22, color: r.birincilMetin),
          ],
        ),
      ),
    );
  }

  // MARK: Bildirimlerim

  Widget _bildirimlerimBolumu(KIRenk r, UygulamaDurumu durum) {
    final benim = durum.ihbarlar.where((i) => i.benim);
    final liste = switch (_filtre) {
      _Filtre.tumu => benim.toList(),
      _Filtre.acik => benim.where((i) => i.durum != Durum.cozuldu).toList(),
      _Filtre.cozulen => benim.where((i) => i.durum == Durum.cozuldu).toList(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bildirimlerim', style: KIFont.bolumBasligi.renk(r.metin)),
        const SizedBox(height: 14),
        Segment<_Filtre>(
          secenekler: const [
            SegmentSecenegi(deger: _Filtre.tumu, baslik: 'Tümü', ikon: Icons.inbox_outlined),
            SegmentSecenegi(deger: _Filtre.acik, baslik: 'Açık', ikon: Icons.schedule_rounded),
            SegmentSecenegi(deger: _Filtre.cozulen, baslik: 'Çözülen', ikon: Icons.check_rounded),
          ],
          secili: _filtre,
          degisti: (f) => setState(() => _filtre = f),
        ),
        const SizedBox(height: 14),
        AnimatedSize(
          duration: KI.sureOrta,
          curve: KI.egriStandart,
          alignment: Alignment.topCenter,
          child: liste.isEmpty
              ? const Kart(
                  dolgu: 0,
                  child: SizedBox(
                    width: double.infinity,
                    child: BosDurum(
                      baslik: 'Henüz bildirimin yok',
                      aciklama: 'Bildirdiğin sorunları buradan takip edebilirsin.',
                    ),
                  ),
                )
              : Kart(
                  dolgu: 0,
                  child: Column(
                    children: [
                      for (var i = 0; i < liste.length; i++) ...[
                        _BildirimSatiri(ihbar: liste[i]),
                        if (i < liste.length - 1)
                          Padding(
                            padding: const EdgeInsets.only(left: 72),
                            child: Container(height: 1, color: r.cizgi),
                          ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Mavi üst alanın renkleri — iki temada da üstündeki beyaz metin okunur kalır.
abstract final class _UstAlanRenk {
  static const logo = Color(0xFF1D4ED8);

  static const ustGradyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D4ED8), Color(0xFF3F97FF)],
  );
  static const ustGradyanKoyu = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF172554), Color(0xFF1D4ED8)],
  );

  static LinearGradient gradyan(KIRenk r) => r.koyu ? ustGradyanKoyu : ustGradyan;
}

/// Mavi zemin üstünde yarı saydam "cam" kutu.
BoxDecoration _camKutu(double kose) => BoxDecoration(
  color: Colors.white.withValues(alpha: 0.14),
  borderRadius: BorderRadius.circular(kose),
  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
);

class _UstAlan extends StatelessWidget {
  const _UstAlan({
    required this.ustBosluk,
    required this.yeniIhbar,
    required this.haritayaGit,
    required this.siralamayaGit,
  });

  /// Durum çubuğu yüksekliği — mavi zemin arkasına uzanır, içerik altında başlar.
  final double ustBosluk;
  final VoidCallback yeniIhbar;
  final VoidCallback haritayaGit;
  final VoidCallback siralamayaGit;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Container(
      decoration: BoxDecoration(gradient: _UstAlanRenk.gradyan(r)),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Şehir Bildirim'deki iç içe kontur süsü
          Positioned.fill(
            child: ExcludeSemantics(
              child: LayoutBuilder(
                builder: (context, k) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final cap in [300.0, 220.0, 140.0])
                        Positioned(
                          left: k.maxWidth - 40 - cap / 2,
                          top: 190 - cap / 2,
                          child: Container(
                            width: cap,
                            height: cap,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(KI.space5, ustBosluk + KI.space3, KI.space5, KI.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
                        child: const Icon(Icons.location_on_rounded, size: 24, color: _UstAlanRenk.logo),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Merhaba', style: KIFont.baslik(22).renk(Colors.white)),
                    const Spacer(),
                    Semantics(
                      label: 'Bildirimler',
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: _camKutu(KI.radiusMd),
                        child: const Icon(Icons.notifications_none_rounded, size: 22, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Basilabilir(
                  onTap: yeniIhbar,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: _camKutu(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sorun mu gördün?', style: KIFont.baslik(20).renk(Colors.white)),
                              const SizedBox(height: 6),
                              Text(
                                'Fotoğraf çek, konumu al, saniyeler içinde birimlere ilet.',
                                style: KIFont.govde(15).renk(Colors.white.withValues(alpha: 0.9)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: KI.space3),
                        const Icon(Icons.chevron_right_rounded, size: 26, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HizliGecis(ikon: Icons.add_rounded, baslik: 'Yeni bildirim', eylem: yeniIhbar),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HizliGecis(ikon: Icons.map_outlined, baslik: 'Canlı harita', eylem: haritayaGit),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HizliGecis(ikon: Icons.bar_chart_rounded, baslik: 'Sıralama', eylem: siralamayaGit),
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

class _HizliGecis extends StatelessWidget {
  const _HizliGecis({required this.ikon, required this.baslik, required this.eylem});

  final IconData ikon;
  final String baslik;
  final VoidCallback eylem;

  @override
  Widget build(BuildContext context) {
    return Basilabilir(
      onTap: eylem,
      child: Container(
        height: 88,
        padding: const EdgeInsets.all(KI.space3),
        decoration: _camKutu(KI.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(ikon, size: 18, color: _UstAlanRenk.logo),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(baslik, maxLines: 1, style: KIFont.govde(14, Agirlik.yariKalin).renk(Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BildirimSatiri extends StatelessWidget {
  const _BildirimSatiri({required this.ihbar});

  final Ihbar ihbar;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KI.space4, vertical: KI.space3),
      child: Row(
        children: [
          IkonRozeti(ikon: ihbar.kategori.ikon, renk: ihbar.kategori.renk(r), zemin: ihbar.kategori.yumusak(r)),
          const SizedBox(width: KI.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ihbar.kategori.ad, style: KIFont.govde(15, Agirlik.yariKalin).renk(r.metin)),
                const SizedBox(height: 2),
                Text(
                  ihbar.adres,
                  style: KIFont.govde(13).renk(r.metinIkincil),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: KI.space2),
          DurumRozeti(durum: ihbar.durum),
        ],
      ),
    );
  }
}
