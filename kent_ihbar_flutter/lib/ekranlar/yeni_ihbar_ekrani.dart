import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../bilesenler.dart';
import '../kapsam.dart';
import '../model.dart';
import '../tema.dart';

class YeniIhbarEkrani extends StatefulWidget {
  const YeniIhbarEkrani({super.key, this.baslangicKategori});

  final Kategori? baslangicKategori;

  @override
  State<YeniIhbarEkrani> createState() => _YeniIhbarEkraniState();
}

class _YeniIhbarEkraniState extends State<YeniIhbarEkrani> {
  late Kategori? _kategori = widget.baslangicKategori;
  Uint8List? _foto;
  final _aciklama = TextEditingController();
  final _aciklamaOdak = FocusNode();
  bool _gonderildi = false;

  bool get _gonderilebilir => _kategori != null && _foto != null;

  @override
  void initState() {
    super.initState();
    _aciklamaOdak.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _aciklama.dispose();
    _aciklamaOdak.dispose();
    super.dispose();
  }

  Future<void> _fotoSec() async {
    try {
      final secim = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2048, imageQuality: 85);
      if (secim == null) return;
      final veri = await secim.readAsBytes();
      if (mounted) setState(() => _foto = veri);
    } on PlatformException {
      // Fotoğraf erişimi reddedildiyse seçim yapılmamış sayılır.
    }
  }

  void _gonder() {
    final kategori = _kategori;
    if (kategori == null) return;
    final konum = KonumKapsami.oku(context);
    final rastgele = math.Random();
    double sapma() => (rastgele.nextDouble() * 2 - 1) * 0.008;
    final yer = konum.konum ?? LatLng(OrnekVeri.bornova.latitude + sapma(), OrnekVeri.bornova.longitude + sapma());
    DurumKapsami.oku(context).ihbarEkle(
      Ihbar(
        kategori: kategori,
        durum: Durum.beklemede,
        aciklama: _aciklama.text.isEmpty ? 'Açıklama eklenmedi.' : _aciklama.text,
        adres: konum.izinVar ? 'Bulunduğun konum' : 'Bornova, İzmir',
        koordinat: yer,
        tarih: DateTime.now(),
        foto: _foto,
        benim: true,
      ),
    );
    HapticFeedback.heavyImpact();
    setState(() => _gonderildi = true);
  }

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Scaffold(
      backgroundColor: r.zemin,
      appBar: AppBar(
        backgroundColor: r.zemin,
        automaticallyImplyLeading: false,
        leadingWidth: 100,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: MetinDugme(baslik: _gonderildi ? 'Kapat' : 'Vazgeç', onPressed: () => Navigator.of(context).pop()),
        ),
        title: Text(_gonderildi ? '' : 'Yeni bildirim'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (c, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: c),
        ),
        child: _gonderildi ? _basari(r) : _form(r),
      ),
    );
  }

  // MARK: Form

  Widget _form(KIRenk r) {
    final konum = KonumKapsami.of(context);
    return SingleChildScrollView(
      key: const ValueKey('form'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(KI.space5, KI.space5, KI.space5, KI.space5 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bolum(r, 1, 'Ne gördün?', _kategoriIzgarasi(r)),
          const SizedBox(height: KI.space6),
          _bolum(r, 2, 'Fotoğraf', _fotoAlani(r)),
          const SizedBox(height: KI.space6),
          _bolum(
            r,
            3,
            'Konum',
            Kart(
              dolgu: KI.space4,
              child: Row(
                children: [
                  const IkonRozeti(ikon: Icons.share_location_rounded),
                  const SizedBox(width: KI.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          konum.izinVar ? 'Bulunduğun konum' : 'Bornova, İzmir (örnek)',
                          style: KIFont.govde(15, Agirlik.yariKalin).renk(r.metin),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          konum.izinVar ? 'GPS ile alındı' : 'Konum izni verirsen tam yer otomatik alınır',
                          style: KIFont.govde(13).renk(r.metinIkincil),
                        ),
                      ],
                    ),
                  ),
                  if (!konum.izinVar) ...[
                    const SizedBox(width: KI.space3),
                    Basilabilir(
                      onTap: konum.izinIste,
                      child: Text('İzin ver', style: KIFont.govde(14, Agirlik.kalin).renk(r.birincilMetin)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: KI.space6),
          _bolum(
            r,
            4,
            'Açıklama (isteğe bağlı)',
            GirdiKutusu(
              odakta: _aciklamaOdak.hasFocus,
              children: [SadeAlan(denetleyici: _aciklama, odak: _aciklamaOdak, ipucu: 'Örn. Kavşakta derin çukur var')],
            ),
          ),
          const SizedBox(height: KI.space6),
          BirincilDugme(baslik: 'Gönder', ikon: Icons.send_outlined, onPressed: _gonderilebilir ? _gonder : null),
          if (!_gonderilebilir) ...[
            const SizedBox(height: KI.space3),
            Text(
              _kategori == null ? 'Önce bir kategori seç.' : 'Göndermek için bir fotoğraf ekle.',
              style: KIFont.altYazi.renk(r.metinIkincil),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _kategoriIzgarasi(KIRenk r) {
    const k = Kategori.values;
    return Column(
      children: [
        for (var satir = 0; satir < k.length; satir += 2) ...[
          if (satir > 0) const SizedBox(height: KI.space3),
          Row(
            children: [
              for (var i = satir; i < satir + 2 && i < k.length; i++) ...[
                if (i > satir) const SizedBox(width: KI.space3),
                Expanded(child: _kategoriSecenegi(r, k[i])),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _kategoriSecenegi(KIRenk r, Kategori k) {
    final secili = _kategori == k;
    final renk = secili ? r.birincilMetin : r.metin;
    return Basilabilir(
      onTap: () => setState(() => _kategori = k),
      child: AnimatedContainer(
        duration: KI.sureHizli,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: KI.space4),
        decoration: BoxDecoration(
          color: secili ? r.birincilYumusak : r.yuzey,
          borderRadius: BorderRadius.circular(KI.radiusMd),
          border: Border.all(color: secili ? r.birincil : r.cizgi, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(k.ikon, size: 21, color: renk),
            const SizedBox(width: KI.space3),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(k.ad, maxLines: 1, style: KIFont.govde(14, Agirlik.yariKalin).renk(renk)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fotoAlani(KIRenk r) {
    final foto = _foto;
    return GestureDetector(
      onTap: _fotoSec,
      child: CustomPaint(
        foregroundPainter: foto == null ? _KesikliKenar(renk: r.cizgiKontrol) : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(KI.radiusLg),
          child: Container(
            height: 200,
            width: double.infinity,
            color: r.yuzey,
            child: AnimatedSwitcher(
              duration: KI.sureOrta,
              child: foto != null
                  ? Stack(
                      key: ValueKey(foto.hashCode),
                      fit: StackFit.expand,
                      children: [
                        Image.memory(foto, fit: BoxFit.cover, gaplessPlayback: true),
                        Positioned(
                          right: KI.space3,
                          bottom: KI.space3,
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: r.yuzey, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sync_rounded, size: 16, color: r.metin),
                                const SizedBox(width: 4),
                                Text('Değiştir', style: KIFont.govde(13, Agirlik.yariKalin).renk(r.metin)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('bos'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const IkonRozeti(ikon: Icons.photo_camera_outlined, boyut: 52),
                        const SizedBox(height: KI.space2),
                        Text('Fotoğraf ekle', style: KIFont.dugme.renk(r.metin)),
                        const SizedBox(height: KI.space2),
                        Text('Sorunu net gösteren bir kare seç.', style: KIFont.govdeKucuk.renk(r.metinIkincil)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bolum(KIRenk r, int no, String baslik, Widget icerik) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: r.birincil, shape: BoxShape.circle),
              child: Text('$no', style: KIFont.govde(12, Agirlik.kalin).renk(r.onBirincil)),
            ),
            const SizedBox(width: KI.space2),
            Text(baslik, style: KIFont.kartBasligi.renk(r.metin)),
          ],
        ),
        const SizedBox(height: KI.space3),
        icerik,
      ],
    );
  }

  // MARK: Başarı

  Widget _basari(KIRenk r) {
    return Padding(
      key: const ValueKey('basari'),
      padding: EdgeInsets.fromLTRB(KI.space5, KI.space5, KI.space5, KI.space5 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        children: [
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Icon(Icons.check_circle_rounded, size: 96, color: r.cozuldu),
          ),
          const SizedBox(height: KI.space4),
          Text('İhbarın iletildi', style: KIFont.ekranBasligi.renk(r.metin)),
          const SizedBox(height: KI.space4),
          Text(
            "Bornova Belediyesi'ne ulaştı. Durumu değiştiğinde sana haber vereceğiz.",
            style: KIFont.govdeMetni.renk(r.metinIkincil),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KI.space4),
          const DurumRozeti(durum: Durum.beklemede),
          const Spacer(),
          BirincilDugme(baslik: 'Tamam', onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}

/// Fotoğraf alanının kesik çizgili kenarı.
class _KesikliKenar extends CustomPainter {
  _KesikliKenar({required this.renk});

  final Color renk;

  @override
  void paint(Canvas canvas, Size size) {
    final yol = Path()
      ..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(0.75), const Radius.circular(KI.radiusLg)));
    final kalem = Paint()
      ..color = renk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in yol.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), kalem);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_KesikliKenar eski) => eski.renk != renk;
}
