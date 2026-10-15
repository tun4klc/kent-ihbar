import 'package:flutter/material.dart';

import 'model.dart';
import 'tema.dart';

// MARK: - Basma efekti

/// Basınca hafif küçülme, bırakınca geri dönme (SwiftUI `BasmaOlcegi` / `YayliBasma`).
class Basilabilir extends StatefulWidget {
  const Basilabilir({super.key, required this.child, this.onTap, this.olcek = 0.96, this.yayli = false, this.etiket});

  final Widget child;
  final VoidCallback? onTap;
  final double olcek;
  final bool yayli;
  final String? etiket;

  @override
  State<Basilabilir> createState() => _BasilabilirState();
}

class _BasilabilirState extends State<Basilabilir> {
  bool _basili = false;

  void _ayarla(bool b) {
    if (widget.onTap == null || _basili == b) return;
    setState(() => _basili = b);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.etiket,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _ayarla(true),
        onTapUp: (_) => _ayarla(false),
        onTapCancel: () => _ayarla(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _basili ? widget.olcek : 1,
          duration: widget.yayli ? const Duration(milliseconds: 300) : KI.sureHizli,
          curve: widget.yayli && !_basili ? Curves.easeOutBack : Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

// MARK: - Düğmeler

/// Ekranın tek birincil eylemi: `birincil` dolgu + `mavi-yansima` parlaması + üst ışık.
class BirincilDugme extends StatefulWidget {
  const BirincilDugme({super.key, required this.baslik, this.ikon, this.onPressed, this.tamGenislik = true});

  final String baslik;
  final IconData? ikon;
  final VoidCallback? onPressed;
  final bool tamGenislik;

  @override
  State<BirincilDugme> createState() => _BirincilDugmeState();
}

class _BirincilDugmeState extends State<BirincilDugme> {
  bool _basili = false;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final aktif = widget.onPressed != null;
    final on = aktif ? r.onBirincil : r.metinSoluk;
    return Semantics(
      button: true,
      enabled: aktif,
      child: GestureDetector(
        onTapDown: aktif ? (_) => setState(() => _basili = true) : null,
        onTapUp: aktif ? (_) => setState(() => _basili = false) : null,
        onTapCancel: aktif ? () => setState(() => _basili = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _basili ? 0.97 : 1,
          duration: KI.sureHizli,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: KI.sureHizli,
            constraints: const BoxConstraints(minHeight: 52),
            width: widget.tamGenislik ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: KI.space5),
            decoration: BoxDecoration(
              color: aktif ? (_basili ? r.birincilBasili : r.birincil) : r.yuzeyUst,
              borderRadius: BorderRadius.circular(KI.radiusMd),
              boxShadow: maviYansima(r, aktif),
            ),
            foregroundDecoration: aktif
                ? BoxDecoration(borderRadius: BorderRadius.circular(KI.radiusMd), gradient: yansimaIsigi)
                : null,
            child: _DugmeEtiketi(baslik: widget.baslik, ikon: widget.ikon, renk: on),
          ),
        ),
      ),
    );
  }
}

class IkincilDugme extends StatelessWidget {
  const IkincilDugme({super.key, required this.baslik, this.ikon, this.onPressed, this.tamGenislik = true});

  final String baslik;
  final IconData? ikon;
  final VoidCallback? onPressed;
  final bool tamGenislik;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Basilabilir(
      onTap: onPressed,
      olcek: 0.97,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        width: tamGenislik ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: KI.space5),
        decoration: BoxDecoration(
          color: r.yuzey,
          borderRadius: BorderRadius.circular(KI.radiusMd),
          border: Border.all(color: r.birincil, width: 1.5),
        ),
        child: _DugmeEtiketi(baslik: baslik, ikon: ikon, renk: r.birincilMetin),
      ),
    );
  }
}

class MetinDugme extends StatefulWidget {
  const MetinDugme({super.key, required this.baslik, this.onPressed});

  final String baslik;
  final VoidCallback? onPressed;

  @override
  State<MetinDugme> createState() => _MetinDugmeState();
}

class _MetinDugmeState extends State<MetinDugme> {
  bool _basili = false;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final aktif = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: aktif,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: aktif ? (_) => setState(() => _basili = true) : null,
        onTapUp: aktif ? (_) => setState(() => _basili = false) : null,
        onTapCancel: aktif ? () => setState(() => _basili = false) : null,
        onTap: widget.onPressed,
        child: Opacity(
          opacity: _basili ? 0.6 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: KI.space3),
            alignment: Alignment.center,
            child: Text(widget.baslik, style: KIFont.dugme.renk(aktif ? r.birincilMetin : r.metinSoluk)),
          ),
        ),
      ),
    );
  }
}

class _DugmeEtiketi extends StatelessWidget {
  const _DugmeEtiketi({required this.baslik, required this.ikon, required this.renk});

  final String baslik;
  final IconData? ikon;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (ikon != null) ...[Icon(ikon, size: 19, color: renk), const SizedBox(width: KI.space2)],
        Flexible(
          child: Text(baslik, style: KIFont.dugme.renk(renk), textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

// MARK: - Kartlar

class KategoriKutusu extends StatelessWidget {
  const KategoriKutusu({super.key, required this.kategori, required this.eylem});

  final Kategori kategori;
  final VoidCallback eylem;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Basilabilir(
      onTap: eylem,
      child: Kart(
        dolgu: KI.space3,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96, minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: KI.space1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IkonRozeti(ikon: kategori.ikon, boyut: 48, renk: kategori.renk(r), zemin: kategori.yumusak(r)),
                const SizedBox(height: 10),
                Text(kategori.ad, style: KIFont.etiket.renk(r.metin), textAlign: TextAlign.center, maxLines: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IkonRozeti extends StatelessWidget {
  const IkonRozeti({super.key, required this.ikon, this.boyut = 44, this.renk, this.zemin});

  final IconData ikon;
  final double boyut;
  final Color? renk;
  final Color? zemin;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Container(
      width: boyut,
      height: boyut,
      decoration: BoxDecoration(color: zemin ?? r.birincilYumusak, borderRadius: BorderRadius.circular(14)),
      child: Icon(ikon, size: boyut * 0.5, color: renk ?? r.birincilMetin),
    );
  }
}

enum IstatistikTuru { acik, cozulen, belediye }

class IstatistikKarti extends StatelessWidget {
  const IstatistikKarti({super.key, required this.tur, required this.deger});

  final IstatistikTuru tur;
  final int deger;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final (zemin, renk, etiket) = switch (tur) {
      IstatistikTuru.acik => (r.birincilYumusak, r.birincilMetin, 'Açık'),
      IstatistikTuru.cozulen => (r.cozulduYumusak, r.cozuldu, 'Çözülen'),
      IstatistikTuru.belediye => (r.beklemedeYumusak, r.beklemede, 'Belediye'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: KI.space4, horizontal: KI.space2),
      decoration: BoxDecoration(color: zemin, borderRadius: BorderRadius.circular(KI.radiusLg)),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: deger.toDouble()),
            duration: KI.sureYavas,
            curve: Curves.easeOut,
            builder: (_, v, _) => FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('${v.round()}', style: KIFont.sayiBuyuk.renk(renk), maxLines: 1),
            ),
          ),
          const SizedBox(height: 2),
          Text(etiket, style: KIFont.govde(13, Agirlik.orta).renk(r.metinIkincil)),
        ],
      ),
    );
  }
}

/// Bir izin ya da eksik ayar yüzünden içerik gösterilemiyorsa üstte tek satırlık bant.
class IzinBandi extends StatelessWidget {
  const IzinBandi({super.key, required this.ikon, required this.metin, required this.eylemAdi, required this.eylem});

  final IconData ikon;
  final String metin;
  final String eylemAdi;
  final VoidCallback eylem;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Container(
      padding: const EdgeInsets.all(KI.space4),
      decoration: BoxDecoration(color: r.beklemedeYumusak, borderRadius: BorderRadius.circular(KI.radiusLg)),
      child: Row(
        children: [
          Icon(ikon, size: 22, color: r.beklemede),
          const SizedBox(width: KI.space3),
          Expanded(child: Text(metin, style: KIFont.govde(14, Agirlik.orta).renk(r.metin))),
          const SizedBox(width: KI.space3),
          Basilabilir(
            onTap: eylem,
            child: Text(eylemAdi, style: KIFont.govde(14, Agirlik.kalin).renk(r.birincilMetin)),
          ),
        ],
      ),
    );
  }
}

// MARK: - Durum

class DurumGostergesi extends StatelessWidget {
  const DurumGostergesi({super.key, required this.durum, this.secili = true});

  final Durum durum;
  final bool secili;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return AnimatedOpacity(
      opacity: secili ? 1 : 0.45,
      duration: KI.sureOrta,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: r.yuzey,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: durum.renk(r), shape: BoxShape.circle),
            ),
            const SizedBox(width: KI.space2),
            Text(durum.ad, style: KIFont.etiket.renk(r.metin)),
          ],
        ),
      ),
    );
  }
}

class DurumRozeti extends StatelessWidget {
  const DurumRozeti({super.key, required this.durum});

  final Durum durum;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final renk = durum.renk(r);
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: durum.yumusak(r), borderRadius: BorderRadius.circular(13)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(durum.ikon, size: 14, color: renk),
          const SizedBox(width: 4),
          Text(durum.ad, style: KIFont.govde(12, Agirlik.yariKalin).renk(renk)),
        ],
      ),
    );
  }
}

// MARK: - Filtre

class FiltreCipi extends StatelessWidget {
  const FiltreCipi({super.key, required this.baslik, this.ikon, this.secili = false});

  final String baslik;
  final IconData? ikon;
  final bool secili;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return AnimatedContainer(
      duration: KI.sureHizli,
      curve: Curves.easeOut,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: KI.space4),
      decoration: BoxDecoration(
        color: secili ? r.birincilYumusak : r.yuzey,
        borderRadius: BorderRadius.circular(KI.radiusMd),
        border: Border.all(color: secili ? Colors.transparent : r.cizgi, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (secili)
            Icon(Icons.check_rounded, size: 16, color: r.birincilMetin)
          else if (ikon != null)
            Icon(ikon, size: 16, color: r.metinIkincil),
          if (secili || ikon != null) const SizedBox(width: KI.space2),
          Text(baslik, style: KIFont.govde(14, Agirlik.yariKalin).renk(secili ? r.birincilMetin : r.metin)),
        ],
      ),
    );
  }
}

enum SayacTuru { acik, canli }

class SayacHapi extends StatelessWidget {
  const SayacHapi({super.key, required this.tur, required this.deger, required this.etiket});

  final SayacTuru tur;
  final int deger;
  final String etiket;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final renk = tur == SayacTuru.acik ? r.birincilMetin : r.vurgu;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: KI.space4, vertical: KI.space3),
      decoration: BoxDecoration(
        color: tur == SayacTuru.acik ? r.birincilYumusak : r.vurguYumusak,
        borderRadius: BorderRadius.circular(KI.radiusLg),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('$deger', style: KIFont.baslik(22).renk(renk)),
          const SizedBox(width: KI.space2),
          Text(etiket, style: KIFont.govde(14, Agirlik.yariKalin).renk(renk)),
        ],
      ),
    );
  }
}

// MARK: - Listeler

class MenuGrubu extends StatelessWidget {
  const MenuGrubu({super.key, this.baslik, required this.children});

  final String? baslik;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (baslik != null) ...[
          Text(baslik!, style: KIFont.baslik(15).renk(r.metinIkincil)),
          const SizedBox(height: 10),
        ],
        Kart(dolgu: 0, child: Column(children: children)),
      ],
    );
  }
}

class MenuSatiri extends StatelessWidget {
  const MenuSatiri({
    super.key,
    required this.ikon,
    required this.baslik,
    this.deger,
    this.ayiriciVar = true,
    this.onTap,
  });

  final IconData ikon;
  final String baslik;
  final String? deger;
  final bool ayiriciVar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: KI.space4),
            child: Row(
              children: [
                SizedBox(width: 24, child: Icon(ikon, size: 22, color: r.birincilMetin)),
                const SizedBox(width: KI.space4),
                Expanded(child: Text(baslik, style: KIFont.dugme.renk(r.metin))),
                if (deger != null) ...[
                  Text(deger!, style: KIFont.govde(14, Agirlik.orta).renk(r.metinIkincil)),
                  const SizedBox(width: KI.space2),
                ],
                Icon(Icons.chevron_right_rounded, size: 22, color: r.metinSoluk),
              ],
            ),
          ),
          if (ayiriciVar)
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Container(height: 1, color: r.cizgi),
            ),
        ],
      ),
    );
  }
}

class SiralamaSatiri extends StatelessWidget {
  const SiralamaSatiri({super.key, required this.sira, required this.belediye, this.senin = false});

  final int sira;
  final Belediye belediye;

  /// Kullanıcının kayıtlı belediyesi mi.
  final bool senin;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Container(
      color: senin ? r.birincilYumusak : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: KI.space4, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: sira == 1
                ? Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: r.birincil, shape: BoxShape.circle),
                    child: Text('1', style: KIFont.baslik(14).renk(r.onBirincil)),
                  )
                : Text('$sira', style: KIFont.baslik(16).renk(r.metinIkincil), textAlign: TextAlign.center),
          ),
          const SizedBox(width: KI.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senin ? 'Senin ilçen · ${belediye.kisaAd}' : belediye.ad,
                  style: KIFont.govde(15, Agirlik.yariKalin).renk(r.metin),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  belediye.ortalamaGun == null
                      ? '${belediye.sehir} · henüz çözüm yok'
                      : '${belediye.sehir} · ort. ${turkceOndalik(belediye.ortalamaGun!)} gün',
                  style: KIFont.govde(13).renk(r.metinIkincil),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 4,
                    child: Stack(
                      children: [
                        Container(color: r.yuzeyUst),
                        FractionallySizedBox(
                          widthFactor: (belediye.puan / 100).clamp(0, 1),
                          child: Container(color: r.birincil),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KI.space3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(turkceOndalik(belediye.puan), style: KIFont.baslik(18).renk(r.birincilMetin)),
              Text('/100', style: KIFont.govde(11, Agirlik.orta).renk(r.metinSoluk)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Liste ya da harita boşken: neden boş olduğunu söyler ve tek bir sonraki adım sunar.
class BosDurum extends StatefulWidget {
  const BosDurum({super.key, required this.baslik, required this.aciklama, this.eylemAdi, this.eylem});

  final String baslik;
  final String aciklama;
  final String? eylemAdi;
  final VoidCallback? eylem;

  @override
  State<BosDurum> createState() => _BosDurumState();
}

class _BosDurumState extends State<BosDurum> with SingleTickerProviderStateMixin {
  late final _kontrol = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  Widget _blok(Color renk, double g, double y, double gecikme) {
    final egri = CurvedAnimation(
      parent: _kontrol,
      curve: Interval(gecikme, (gecikme + 0.7).clamp(0, 1), curve: Curves.easeOutBack),
    );
    return AnimatedBuilder(
      animation: egri,
      builder: (_, _) => Container(
        width: g,
        height: (8 + (y - 8) * egri.value).clamp(4, 120),
        decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KI.space8, horizontal: KI.space6),
      child: Column(
        children: [
          SizedBox(
            height: 104,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _blok(r.birincilYumusak, 40, 72, 0),
                const SizedBox(width: 6),
                _blok(r.birincil, 32, 100, 0.1),
                const SizedBox(width: 6),
                _blok(r.maviRenk, 24, 48, 0.2),
              ],
            ),
          ),
          const SizedBox(height: KI.space2 + KI.space3),
          Text(widget.baslik, style: KIFont.kartBasligi.renk(r.metin), textAlign: TextAlign.center),
          const SizedBox(height: KI.space3),
          Text(widget.aciklama, style: KIFont.govdeKucuk.renk(r.metinIkincil), textAlign: TextAlign.center),
          if (widget.eylemAdi != null) ...[
            const SizedBox(height: KI.space2 + KI.space3),
            IkincilDugme(
              baslik: widget.eylemAdi!,
              ikon: Icons.add_rounded,
              tamGenislik: false,
              onPressed: widget.eylem,
            ),
          ],
        ],
      ),
    );
  }
}

// MARK: - Giriş alanları

class SegmentSecenegi<T> {
  const SegmentSecenegi({required this.deger, required this.baslik, required this.ikon});

  final T deger;
  final String baslik;
  final IconData ikon;
}

class Segment<T> extends StatelessWidget {
  const Segment({super.key, required this.secenekler, required this.secili, required this.degisti});

  final List<SegmentSecenegi<T>> secenekler;
  final T secili;
  final ValueChanged<T> degisti;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final indeks = secenekler.indexWhere((s) => s.deger == secili);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: r.yuzeyUst, borderRadius: BorderRadius.circular(KI.radiusMd)),
      child: SizedBox(
        height: 40,
        child: Stack(
          children: [
            // Seçili kutu: seçenekler arasında kayar.
            AnimatedAlign(
              duration: KI.sureOrta,
              curve: KI.egriStandart,
              alignment: Alignment(secenekler.length == 1 ? 0 : -1 + 2 * indeks / (secenekler.length - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / secenekler.length,
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: r.yuzey,
                      borderRadius: BorderRadius.circular(KI.radiusSm),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final s in secenekler)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => degisti(s.deger),
                      child: Semantics(
                        button: true,
                        selected: s.deger == secili,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: KI.sureOrta,
                            style: KIFont.govde(
                              14,
                              Agirlik.yariKalin,
                            ).renk(s.deger == secili ? r.metin : r.metinIkincil),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(s.ikon, size: 16, color: s.deger == secili ? r.metin : r.metinIkincil),
                                const SizedBox(width: 6),
                                Flexible(child: Text(s.baslik, maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Giriş alanı kutusu — odakta `birincil` kenar + `birincil-yumusak` hale, hatada `kritik`.
class GirdiKutusu extends StatelessWidget {
  const GirdiKutusu({
    super.key,
    required this.odakta,
    required this.children,
    this.hata = false,
    this.hap = false,
    this.yukseklik = 52,
  });

  final bool odakta;
  final bool hata;
  final bool hap;
  final double? yukseklik;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final kenar = hata ? r.kritik : (odakta ? r.birincil : (hap ? Colors.transparent : r.cizgiKontrol));
    return AnimatedContainer(
      duration: KI.sureOrta,
      curve: Curves.easeOut,
      height: yukseklik,
      constraints: const BoxConstraints(minHeight: 52),
      padding: EdgeInsets.symmetric(horizontal: KI.space4, vertical: yukseklik == null ? 14 : 0),
      decoration: BoxDecoration(
        color: r.yuzey,
        borderRadius: BorderRadius.circular(hap ? 26 : KI.radiusMd),
        border: Border.all(color: kenar, width: 1.5),
        boxShadow: [
          if (odakta && !hata) BoxShadow(color: r.birincilYumusak, spreadRadius: 4),
          if (hap) BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: KIFont.govdeMetni.renk(r.metin),
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: KI.space3), children[i]],
          ],
        ),
      ),
    );
  }
}

/// Uygulamanın yazı stiliyle çerçevesiz metin alanı (GirdiKutusu içinde kullanılır).
class SadeAlan extends StatelessWidget {
  const SadeAlan({
    super.key,
    required this.denetleyici,
    required this.odak,
    required this.ipucu,
    this.klavye,
    this.otomatikDoldurma,
    this.buyukHarf = TextCapitalization.sentences,
    this.duzeltme = true,
    this.eylem,
    this.gonderildi,
    this.enCokSatir = 1,
  });

  final TextEditingController denetleyici;
  final FocusNode odak;
  final String ipucu;
  final TextInputType? klavye;
  final Iterable<String>? otomatikDoldurma;
  final TextCapitalization buyukHarf;
  final bool duzeltme;
  final TextInputAction? eylem;
  final ValueChanged<String>? gonderildi;
  final int enCokSatir;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Expanded(
      child: TextField(
        controller: denetleyici,
        focusNode: odak,
        keyboardType: klavye,
        autofillHints: otomatikDoldurma,
        textCapitalization: buyukHarf,
        autocorrect: duzeltme,
        enableSuggestions: duzeltme,
        textInputAction: eylem,
        onSubmitted: gonderildi,
        minLines: 1,
        maxLines: enCokSatir,
        style: KIFont.govdeMetni.renk(r.metin),
        onTapOutside: (_) => odak.unfocus(),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: ipucu,
          hintStyle: KIFont.govdeMetni.renk(r.metinSoluk),
        ),
      ),
    );
  }
}

class AlanEtiketi extends StatelessWidget {
  const AlanEtiketi(this.metin, {super.key});

  final String metin;

  @override
  Widget build(BuildContext context) => Text(metin, style: KIFont.etiket.renk(KIRenk.of(context).metinIkincil));
}

class Ayirici extends StatelessWidget {
  const Ayirici(this.metin, {super.key});

  final String metin;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: r.cizgi)),
        const SizedBox(width: KI.space3),
        Text(metin, style: KIFont.govde(13, Agirlik.orta).renk(r.metinSoluk)),
        const SizedBox(width: KI.space3),
        Expanded(child: Container(height: 1, color: r.cizgi)),
      ],
    );
  }
}

// MARK: - Geri bildirim

/// API ya da doğrulama hatasını ekranın altında kısa bir uyarıyla gösterir.
void hataGoster(BuildContext context, String mesaj) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mesaj), behavior: SnackBarBehavior.floating));
}

/// Liste yüklenirken ortada küçük dönen gösterge.
class Yukleniyor extends StatelessWidget {
  const Yukleniyor({super.key, this.yukseklik = 120});

  final double yukseklik;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: yukseklik,
      width: double.infinity,
      child: Center(child: CircularProgressIndicator.adaptive(backgroundColor: KIRenk.of(context).cizgi)),
    );
  }
}
