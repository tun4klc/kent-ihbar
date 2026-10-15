import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../bilesenler.dart';
import '../model.dart';
import '../tema.dart';
import 'asistan_robotu.dart';

class SohbetMesaji {
  SohbetMesaji(this.metin, {required this.benden});

  final String metin;
  final bool benden;
}

/// Kent asistanı sohbeti. Şimdilik sunucuya bağlı değil: yanıtlar cihazdaki
/// `KentAsistani.yanit` kurallarından gelir.
class SohbetEkrani extends StatefulWidget {
  const SohbetEkrani({super.key});

  @override
  State<SohbetEkrani> createState() => _SohbetEkraniState();
}

class _SohbetEkraniState extends State<SohbetEkrani> {
  final List<SohbetMesaji> _mesajlar = [
    SohbetMesaji(
      'Merhaba! Ben Kent asistanı. Sorun bildirme, harita ya da belediye sıralaması hakkında sorabilirsin.',
      benden: false,
    ),
  ];
  final _taslak = TextEditingController();
  final _odak = FocusNode();
  final _kaydir = ScrollController();
  bool _yaziyor = false;
  Timer? _yanitZamanlayici;

  static const _oneriler = ['Nasıl ihbar ederim?', 'İhbarım ne durumda?', 'Sıralama nasıl hesaplanıyor?'];

  @override
  void initState() {
    super.initState();
    _taslak.addListener(() => setState(() {}));
    _odak.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _yanitZamanlayici?.cancel();
    _taslak.dispose();
    _odak.dispose();
    _kaydir.dispose();
    super.dispose();
  }

  bool get _bosMu => _taslak.text.trim().isEmpty;

  void _sonaKaydir() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_kaydir.hasClients) return;
      _kaydir.animateTo(_kaydir.position.maxScrollExtent, duration: KI.sureOrta, curve: KI.egriStandart);
    });
  }

  void _gonder(String metin) {
    final t = metin.trim();
    if (t.isEmpty || _yaziyor) return;
    _taslak.clear();
    setState(() {
      _mesajlar.add(SohbetMesaji(t, benden: true));
      _yaziyor = true;
    });
    _sonaKaydir();
    _yanitZamanlayici = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _yaziyor = false;
        _mesajlar.add(SohbetMesaji(KentAsistani.yanit(t), benden: false));
      });
      _sonaKaydir();
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Scaffold(
      backgroundColor: r.zemin,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Kent Asistanı'),
        actions: [
          Basilabilir(
            etiket: 'Kapat',
            onTap: () => Navigator.of(context).pop(),
            child: SizedBox(width: 48, height: 44, child: Icon(Icons.close_rounded, size: 22, color: r.birincil)),
          ),
          const SizedBox(width: KI.space2),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _kaydir,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(KI.space4, KI.space2, KI.space4, KI.space3),
              children: [
                ExcludeSemantics(
                  child: Center(
                    child: SizedBox(
                      width: 148,
                      height: 120,
                      child: RobotCizimi(cizici: (k) => Lottie(composition: k, repeat: true)),
                    ),
                  ),
                ),
                for (final m in _mesajlar) ...[const SizedBox(height: KI.space3), _Balon(key: ObjectKey(m), mesaj: m)],
                if (_yaziyor) ...[const SizedBox(height: KI.space3), const _YaziyorBalonu()],
              ],
            ),
          ),
          if (_mesajlar.length == 1)
            Padding(
              padding: const EdgeInsets.only(bottom: KI.space2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: KI.space4),
                child: Row(
                  children: [
                    for (final o in _oneriler) ...[
                      GestureDetector(
                        onTap: () => _gonder(o),
                        child: FiltreCipi(baslik: o),
                      ),
                      const SizedBox(width: KI.space2),
                    ],
                  ],
                ),
              ),
            ),
          _giris(r),
        ],
      ),
    );
  }

  Widget _giris(KIRenk r) {
    return Container(
      decoration: BoxDecoration(
        color: r.yuzey,
        border: Border(top: BorderSide(color: r.cizgi)),
      ),
      padding: EdgeInsets.fromLTRB(KI.space4, KI.space3, KI.space4, KI.space3 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: GirdiKutusu(
              odakta: _odak.hasFocus,
              hap: true,
              yukseklik: null,
              children: [
                SadeAlan(
                  denetleyici: _taslak,
                  odak: _odak,
                  ipucu: 'Bir şey sor…',
                  eylem: TextInputAction.send,
                  gonderildi: _gonder,
                  enCokSatir: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: KI.space2),
          Basilabilir(
            etiket: 'Gönder',
            onTap: _bosMu ? null : () => _gonder(_taslak.text),
            child: AnimatedContainer(
              duration: KI.sureHizli,
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: _bosMu ? r.metinSoluk : r.birincil, shape: BoxShape.circle),
              child: Icon(Icons.arrow_upward_rounded, size: 22, color: r.onBirincil),
            ),
          ),
        ],
      ),
    );
  }
}

/// Basit anahtar kelime kuralları — gerçek bir asistan servisi bağlanınca değiştirilecek.
abstract final class KentAsistani {
  static String yanit(String soru) {
    final s = turkceKucuk(soru);
    bool varMi(List<String> k) => k.any(s.contains);
    if (varMi(['ihbar', 'bildir', 'sorun', 'nasıl'])) {
      return 'Ana sayfadaki "Sorun mu gördün?" kartına ya da alttaki Bildir düğmesine dokun. Kategori seç, fotoğraf ekle; konumu otomatik alırız ve ihbarın ilgili belediyeye iletilir.';
    }
    if (varMi(['durum', 'ne oldu', 'takip'])) {
      return 'Gönderdiğin ihbarları ana sayfadaki "Bildirimlerim" bölümünde Açık ve Çözülen olarak takip edebilirsin.';
    }
    if (varMi(['sıralama', 'puan', 'belediye'])) {
      return 'Belediyeler çözüm hızı, vatandaş memnuniyeti ve aylık çözülen ihbar sayısına göre 100 üzerinden puanlanır. Sıralama sekmesinde ölçütü değiştirebilirsin.';
    }
    if (varMi(['harita', 'yakın', 'çevre'])) {
      return "Canlı Harita'da çevrendeki ihbarları durumlarına göre görebilirsin. Konum izni verirsen ilçene odaklanır.";
    }
    if (varMi(['merhaba', 'selam'])) {
      return 'Merhaba! Sana nasıl yardımcı olabilirim?';
    }
    return 'Bunu henüz bilmiyorum. İhbar oluşturma, ihbar takibi, harita ve belediye sıralaması hakkında yardımcı olabilirim.';
  }
}

class _Balon extends StatelessWidget {
  const _Balon({super.key, required this.mesaj});

  final SohbetMesaji mesaj;

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final benden = mesaj.benden;
    final balon = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: benden ? r.birincil : r.yuzey,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(benden ? 18 : 6),
          bottomRight: Radius.circular(benden ? 6 : 18),
        ),
        boxShadow: benden
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Text(mesaj.metin, style: KIFont.govde(15).renk(benden ? r.onBirincil : r.metin)),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: KI.sureOrta,
      curve: KI.egriStandart,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
      ),
      child: Row(
        children: [
          if (benden) const SizedBox(width: 48),
          Flexible(
            child: Align(alignment: benden ? Alignment.centerRight : Alignment.centerLeft, child: balon),
          ),
          if (!benden) const SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Videodaki "•••" baloncuğu.
class _YaziyorBalonu extends StatefulWidget {
  const _YaziyorBalonu();

  @override
  State<_YaziyorBalonu> createState() => _YaziyorBalonuState();
}

class _YaziyorBalonuState extends State<_YaziyorBalonu> {
  int _faz = 0;
  late final Timer _zaman;

  @override
  void initState() {
    super.initState();
    _zaman = Timer.periodic(const Duration(milliseconds: 300), (_) => setState(() => _faz = (_faz + 1) % 3));
  }

  @override
  void dispose() {
    _zaman.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Semantics(
      label: 'Asistan yazıyor',
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: r.yuzey, borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: r.birincil.withValues(alpha: _faz == i ? 1 : 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
