import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../bilesenler.dart';
import '../kapsam.dart';
import '../model.dart';
import '../tema.dart';

enum Olcut {
  genel('Genel'),
  enHizli('En hızlı'),
  memnuniyet('Memnuniyet'),
  aylik('Aylık çözüm');

  const Olcut(this.ad);
  final String ad;
}

class SiralamaEkrani extends StatefulWidget {
  const SiralamaEkrani({super.key, required this.yeniIhbar});

  final void Function([Kategori? kategori]) yeniIhbar;

  @override
  State<SiralamaEkrani> createState() => _SiralamaEkraniState();
}

class _SiralamaEkraniState extends State<SiralamaEkrani> {
  final _arama = TextEditingController();
  final _aramaOdak = FocusNode();
  Olcut _olcut = Olcut.genel;
  String? _sehir;

  @override
  void initState() {
    super.initState();
    _arama.addListener(() => setState(() {}));
    _aramaOdak.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _arama.dispose();
    _aramaOdak.dispose();
    super.dispose();
  }

  /// Türkçe alfabe sırası (Ç, Ğ, İ, Ö, Ş, Ü doğru yerde).
  static int _turkceKarsilastir(String a, String b) {
    const alfabe = 'abcçdefgğhıijklmnoöprsştuüvyz';
    int sira(String c) {
      final i = alfabe.indexOf(c);
      return i < 0 ? 100 + c.codeUnitAt(0) : i;
    }

    final x = turkceKucuk(a), y = turkceKucuk(b);
    for (var i = 0; i < x.length && i < y.length; i++) {
      final f = sira(x[i]) - sira(y[i]);
      if (f != 0) return f;
    }
    return x.length - y.length;
  }

  List<String> get _sehirler => (OrnekVeri.belediyeler.map((b) => b.sehir).toSet().toList())..sort(_turkceKarsilastir);

  List<Belediye> get _liste {
    var l = OrnekVeri.belediyeler.toList();
    if (_sehir != null) l = l.where((b) => b.sehir == _sehir).toList();
    final q = turkceKucuk(_arama.text.trim());
    if (q.isNotEmpty) {
      l = l.where((b) => turkceKucuk(b.ad).contains(q) || turkceKucuk(b.sehir).contains(q)).toList();
    }
    switch (_olcut) {
      case Olcut.genel:
        l.sort((a, b) => b.puan.compareTo(a.puan));
      case Olcut.enHizli:
        l.sort((a, b) => a.ortalamaGun.compareTo(b.ortalamaGun));
      case Olcut.memnuniyet:
        l.sort((a, b) => b.memnuniyet.compareTo(a.memnuniyet));
      case Olcut.aylik:
        l.sort((a, b) => b.aylikCozum.compareTo(a.aylikCozum));
    }
    return l;
  }

  void _paylas(BuildContext context) {
    final kutu = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        text: 'Kent İhbar ile belediyeleri çözüm hızına göre karşılaştır.',
        sharePositionOrigin: kutu == null ? null : kutu.localToGlobal(Offset.zero) & kutu.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final konum = KonumKapsami.of(context);
    final liste = _liste;
    final ilkSira = liste.length >= 3 ? 3 : 0;
    final kalan = liste.skip(ilkSira).toList();

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(KI.space5, KI.space2, KI.space5, KI.space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Belediye Sıralaması', style: KIFont.ekranBasligi.renk(r.metin)),
                      const SizedBox(height: KI.space1),
                      Text('Çözüm hızı ve vatandaş memnuniyetine göre', style: KIFont.govdeKucuk.renk(r.metinIkincil)),
                    ],
                  ),
                ),
                Builder(
                  builder: (c) => Basilabilir(
                    etiket: 'Paylaş',
                    onTap: () => _paylas(c),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.ios_share_rounded, size: 22, color: r.metin),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KI.space5),
            GirdiKutusu(
              odakta: _aramaOdak.hasFocus,
              hap: true,
              children: [
                Icon(Icons.search_rounded, size: 22, color: r.metinSoluk),
                SadeAlan(
                  denetleyici: _arama,
                  odak: _aramaOdak,
                  ipucu: 'Belediye, ilçe veya şehir ara…',
                  eylem: TextInputAction.search,
                ),
                if (_arama.text.isNotEmpty)
                  Basilabilir(
                    etiket: 'Aramayı temizle',
                    onTap: _arama.clear,
                    child: Icon(Icons.cancel_rounded, size: 20, color: r.metinSoluk),
                  ),
              ],
            ),
            const SizedBox(height: KI.space5),
            // Çip satırları kenardan kenara kayar.
            LayoutBuilder(
              builder: (_, k) => SizedBox(
                height: 90,
                child: OverflowBox(
                  minWidth: k.maxWidth + 2 * KI.space5,
                  maxWidth: k.maxWidth + 2 * KI.space5,
                  child: Column(
                    children: [
                      _cipSatiri([
                        for (final o in Olcut.values)
                          GestureDetector(
                            onTap: () => setState(() => _olcut = o),
                            child: FiltreCipi(baslik: o.ad, secili: _olcut == o),
                          ),
                      ]),
                      const SizedBox(height: 10),
                      _cipSatiri([
                        GestureDetector(
                          onTap: () => setState(() => _sehir = null),
                          child: FiltreCipi(baslik: 'Tüm şehirler', secili: _sehir == null),
                        ),
                        for (final s in _sehirler)
                          GestureDetector(
                            onTap: () => setState(() => _sehir = s),
                            child: FiltreCipi(baslik: s, secili: _sehir == s),
                          ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: KI.space5),
            AnimatedSize(
              duration: KI.sureOrta,
              curve: KI.egriStandart,
              alignment: Alignment.topCenter,
              child: liste.isEmpty
                  ? SizedBox(
                      width: double.infinity,
                      child: BosDurum(
                        baslik: 'Henüz sıralama verisi yok',
                        aciklama: 'Bu aramaya uyan belediye bulunamadı. Yeterli çözülmüş ihbar olunca belediyeler burada sıralanacak.',
                        eylemAdi: 'Sorun bildir',
                        eylem: () => widget.yeniIhbar(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (liste.length >= 3) ...[
                          _LiderlerPodyumu(liderler: liste.take(3).toList(), olcut: _olcut),
                          const SizedBox(height: KI.space5),
                        ],
                        if (kalan.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(KI.radiusLg),
                            child: Kart(
                              dolgu: 0,
                              child: Column(
                                children: [
                                  for (var i = 0; i < kalan.length; i++) ...[
                                    SiralamaSatiri(sira: ilkSira + i + 1, belediye: kalan[i]),
                                    if (i < kalan.length - 1) Container(height: 1, color: r.cizgi),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: KI.space5),
                        ],
                        if (!konum.izinVar) ...[
                          IzinBandi(
                            ikon: Icons.location_disabled_rounded,
                            metin: 'Senin belediyen kaçıncı? Konum izni ver, hemen görelim.',
                            eylemAdi: konum.reddedildi ? 'Ayarlar' : 'İzin ver',
                            eylem: konum.izinIste,
                          ),
                          const SizedBox(height: KI.space5),
                        ],
                        Text(
                          'ÖRNEK VERİ',
                          style: KIFont.govde(11, Agirlik.yariKalin).copyWith(letterSpacing: 0.5, color: r.metinSoluk),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cipSatiri(List<Widget> cipler) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: KI.space5),
      child: Row(
        children: [
          for (var i = 0; i < cipler.length; i++) ...[if (i > 0) const SizedBox(width: KI.space2), cipler[i]],
        ],
      ),
    );
  }
}

/// İlk üç belediye: ortada 1., solda 2., sağda 3. — Şehir İhbar'daki "Bu ayın liderleri" kartı.
class _LiderlerPodyumu extends StatelessWidget {
  const _LiderlerPodyumu({required this.liderler, required this.olcut});

  final List<Belediye> liderler;
  final Olcut olcut;

  static const _altin = Color(0xFFFBBF24);

  /// Beyaz avatarın üstünde iki temada da okunur kalan mavi.
  static const _avatarMetin = Color(0xFF1D4ED8);

  String get _olcutEtiketi => switch (olcut) {
    Olcut.genel => 'Puan / 100',
    Olcut.enHizli => 'Ort. çözüm',
    Olcut.memnuniyet => 'Memnuniyet',
    Olcut.aylik => 'Aylık çözüm',
  };

  String _deger(Belediye b) => switch (olcut) {
    Olcut.genel => turkceOndalik(b.puan),
    Olcut.enHizli => '${turkceOndalik(b.ortalamaGun)} gün',
    Olcut.memnuniyet => '%${b.memnuniyet}',
    Olcut.aylik => turkceSayi(b.aylikCozum),
  };

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final metin = r.maviBayaz;
    return Semantics(
      label: 'Bu ayın liderleri: 1. ${liderler[0].kisaAd}, 2. ${liderler[1].kisaAd}, 3. ${liderler[2].kisaAd}',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: r.birincil,
          borderRadius: BorderRadius.circular(KI.radiusLg),
          boxShadow: maviYansima(r),
        ),
        foregroundDecoration: BoxDecoration(borderRadius: BorderRadius.circular(KI.radiusLg), gradient: yansimaIsigi),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(KI.space4, KI.space4, KI.space4, 0),
        child: Column(
          children: [
            Row(
              children: [
                Text('Bu ayın liderleri', style: KIFont.kartBasligi.renk(metin)),
                const Spacer(),
                Text(_olcutEtiketi, style: KIFont.altYazi.renk(metin.withValues(alpha: 0.8))),
              ],
            ),
            const SizedBox(height: KI.space4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _sutun(liderler[1], 2, 46, 70, 0.16, metin)),
                const SizedBox(width: 10),
                Expanded(child: _sutun(liderler[0], 1, 56, 96, 0.24, metin)),
                const SizedBox(width: 10),
                Expanded(child: _sutun(liderler[2], 3, 46, 56, 0.12, metin)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sutun(Belediye b, int sira, double avatar, double yukseklik, double dolgu, Color metin) {
    return Column(
      children: [
        if (sira == 1) ...[
          const Icon(Icons.workspace_premium_rounded, size: 22, color: _altin),
          const SizedBox(height: 6),
        ],
        Container(
          width: avatar,
          height: avatar,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: sira == 1 ? Border.all(color: _altin, width: 3) : null,
          ),
          child: Text(b.basHarfler, style: KIFont.baslik(sira == 1 ? 17 : 15).renk(_avatarMetin)),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(b.kisaAd, maxLines: 1, style: KIFont.govde(13, Agirlik.kalin).renk(metin)),
        ),
        const SizedBox(height: 6),
        Text(_deger(b), style: KIFont.govde(12, Agirlik.orta).renk(metin.withValues(alpha: 0.8))),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: yukseklik,
          padding: const EdgeInsets.only(top: 10),
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: dolgu),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(KI.radiusMd)),
          ),
          child: Text('$sira', style: KIFont.baslik(sira == 1 ? 26 : 21).renk(metin)),
        ),
      ],
    );
  }
}
