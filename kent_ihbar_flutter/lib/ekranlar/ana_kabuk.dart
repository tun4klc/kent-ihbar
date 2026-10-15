import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../kapsam.dart';
import '../model.dart';
import '../tema.dart';
import 'ana_sayfa.dart';
import 'asistan_robotu.dart';
import 'harita_ekrani.dart';
import 'profil_ekrani.dart';
import 'siralama_ekrani.dart';
import 'sohbet_ekrani.dart';
import 'yeni_ihbar_ekrani.dart';

// MARK: - Sekmeler

enum Sekme { anaSayfa, harita, siralama, profil }

class AnaKabuk extends StatefulWidget {
  const AnaKabuk({super.key, this.baslangicSekme = Sekme.anaSayfa});

  final Sekme baslangicSekme;

  @override
  State<AnaKabuk> createState() => _AnaKabukState();
}

class _AnaKabukState extends State<AnaKabuk> {
  late Sekme _sekme = widget.baslangicSekme;

  void _sekmeSec(Sekme s) => setState(() => _sekme = s);

  /// Misafir yeni ihbar başlatırsa giriş ekranına yönlendirilir.
  void _ihbarBaslat([Kategori? kategori]) {
    final durum = DurumKapsami.oku(context);
    if (!durum.uyeMi) {
      durum.oturum = const OturumYok();
      return;
    }
    tamEkranSayfa(context, YeniIhbarEkrani(baslangicKategori: kategori));
  }

  void _sohbetAc() => tamEkranSayfa(context, const SohbetEkrani());

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final Widget icerik = switch (_sekme) {
      Sekme.anaSayfa => AnaSayfa(
        yeniIhbar: _ihbarBaslat,
        haritayaGit: () => _sekmeSec(Sekme.harita),
        siralamayaGit: () => _sekmeSec(Sekme.siralama),
      ),
      Sekme.harita => const HaritaEkrani(),
      Sekme.siralama => SiralamaEkrani(yeniIhbar: _ihbarBaslat),
      Sekme.profil => const ProfilEkrani(),
    };
    return Scaffold(
      backgroundColor: r.zemin,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: KI.sureOrta,
              switchInCurve: KI.egriStandart,
              child: KeyedSubtree(key: ValueKey(_sekme), child: icerik),
            ),
          ),
          // Haritada sağ alt köşe harita kontrollerine ayrılmış.
          Positioned(
            right: KI.space2,
            bottom: KI.space1,
            child: AnimatedSwitcher(
              duration: KI.sureOrta,
              transitionBuilder: (c, a) => ScaleTransition(
                scale: a,
                child: FadeTransition(opacity: a, child: c),
              ),
              child: _sekme == Sekme.harita ? const SizedBox.shrink() : AsistanRobotu(ac: _sohbetAc),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AltMenu(sekme: _sekme, degisti: _sekmeSec, fab: _ihbarBaslat),
    );
  }
}

/// iOS'taki `.sheet` karşılığı: üstte boşluk bırakan, aşağı çekilerek kapanan tam boy sayfa.
Future<T?> tamEkranSayfa<T>(BuildContext context, Widget sayfa) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(KI.radiusLg))),
    builder: (_) => sayfa,
  );
}

// MARK: - Alt menü

class AltMenu extends StatefulWidget {
  const AltMenu({super.key, required this.sekme, required this.degisti, required this.fab});

  final Sekme sekme;
  final ValueChanged<Sekme> degisti;
  final VoidCallback fab;

  @override
  State<AltMenu> createState() => _AltMenuState();
}

class _AltMenuState extends State<AltMenu> with TickerProviderStateMixin {
  late final Map<Sekme, AnimationController> _ziplama = {
    for (final s in Sekme.values) s: AnimationController(vsync: this, duration: const Duration(milliseconds: 420)),
  };
  late final _bildirZiplama = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final _salla = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
  late final Timer _sallaZamanlayici;

  static const _sallaAcilari = [0.0, -14.0, 10.0, -6.0, 0.0];

  @override
  void initState() {
    super.initState();
    _sallaZamanlayici = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) _salla.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _sallaZamanlayici.cancel();
    for (final c in _ziplama.values) {
      c.dispose();
    }
    _bildirZiplama.dispose();
    _salla.dispose();
    super.dispose();
  }

  /// Sekme sırası: 0 Ana Sayfa, 1 Harita, 2 Bildir, 3 Sıralama, 4 Profil
  int _sutun(Sekme s) => switch (s) {
    Sekme.anaSayfa => 0,
    Sekme.harita => 1,
    Sekme.siralama => 3,
    Sekme.profil => 4,
  };

  double _salinim() {
    // 0,12 sn'lik dört parça: 0 → -14 → 10 → -6 → 0 derece
    final p = _salla.value * 4;
    final i = p.floor().clamp(0, 3);
    final t = Curves.easeInOut.transform(p - i);
    final derece = _sallaAcilari[i] + (_sallaAcilari[i + 1] - _sallaAcilari[i]) * t;
    return derece * math.pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Container(
      decoration: BoxDecoration(
        color: r.yuzey,
        border: Border(top: BorderSide(color: r.cizgi)),
      ),
      padding: EdgeInsets.only(top: 10, bottom: 4 + MediaQuery.paddingOf(context).bottom),
      child: LayoutBuilder(
        builder: (context, k) {
          final w = k.maxWidth / 5;
          return Stack(
            children: [
              // Aktif sekmenin arkasındaki hap: sekmeler arasında kayar.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                left: _sutun(widget.sekme) * w + (w - 56) / 2,
                top: 0,
                child: Container(
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(color: r.birincilYumusak, borderRadius: BorderRadius.circular(16)),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sekmeDugmesi(r, Sekme.anaSayfa, 'Ana Sayfa', Icons.home_outlined, Icons.home_rounded),
                  _sekmeDugmesi(r, Sekme.harita, 'Harita', Icons.map_outlined, Icons.map_rounded),
                  _bildirDugmesi(r),
                  _sekmeDugmesi(r, Sekme.siralama, 'Sıralama', Icons.bar_chart_outlined, Icons.bar_chart_rounded),
                  _sekmeDugmesi(r, Sekme.profil, 'Profil', Icons.person_outline_rounded, Icons.person_rounded),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ziplayan(AnimationController c, double yon, Widget child) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, ch) {
        // Kısa bir sıçrama: aşağı/yukarı gidip yaylanarak geri döner.
        final v = c.value;
        final dy = yon * 6 * math.sin(math.pi * 2 * v) * (1 - v);
        return Transform.translate(offset: Offset(0, dy), child: ch);
      },
      child: child,
    );
  }

  Widget _sekmeDugmesi(KIRenk r, Sekme s, String baslik, IconData ikon, IconData doluIkon) {
    final aktif = widget.sekme == s;
    final renk = aktif ? r.birincilMetin : r.metinSoluk;
    return Expanded(
      child: Semantics(
        selected: aktif,
        button: true,
        label: baslik,
        excludeSemantics: true,
        child: _BasmaOlcekli(
          olcek: 0.92,
          onTap: () {
            _ziplama[s]!.forward(from: 0);
            if (!aktif) HapticFeedback.selectionClick();
            widget.degisti(s);
          },
          child: Column(
            children: [
              SizedBox(
                width: 56,
                height: 32,
                child: _ziplayan(
                  _ziplama[s]!,
                  1,
                  AnimatedSwitcher(
                    duration: KI.sureOrta,
                    transitionBuilder: (c, a) => ScaleTransition(
                      scale: a,
                      child: FadeTransition(opacity: a, child: c),
                    ),
                    child: Icon(aktif ? doluIkon : ikon, key: ValueKey(aktif), size: 24, color: renk),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(baslik, maxLines: 1, style: KIFont.govde(12, Agirlik.yariKalin).renk(renk)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bildirDugmesi(KIRenk r) {
    return Expanded(
      child: Semantics(
        button: true,
        label: 'Sorun bildir',
        excludeSemantics: true,
        child: _BasmaOlcekli(
          olcek: 0.9,
          onTap: () {
            _bildirZiplama.forward(from: 0);
            HapticFeedback.mediumImpact();
            widget.fab();
          },
          child: Column(
            children: [
              Container(
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: r.birincil,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: maviYansima(r),
                ),
                foregroundDecoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: yansimaIsigi),
                child: _ziplayan(
                  _bildirZiplama,
                  -1,
                  AnimatedBuilder(
                    animation: _salla,
                    builder: (_, ch) =>
                        Transform.rotate(angle: _salinim(), alignment: Alignment.centerRight, child: ch),
                    child: Icon(Icons.campaign_rounded, size: 22, color: r.onBirincil),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('Bildir', style: KIFont.govde(12, Agirlik.kalin).renk(r.birincilMetin)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sekmelerde basınca hafif küçülme, bırakınca yaylanma.
class _BasmaOlcekli extends StatefulWidget {
  const _BasmaOlcekli({required this.child, required this.onTap, this.olcek = 0.92});

  final Widget child;
  final VoidCallback onTap;
  final double olcek;

  @override
  State<_BasmaOlcekli> createState() => _BasmaOlcekliState();
}

class _BasmaOlcekliState extends State<_BasmaOlcekli> {
  bool _basili = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _basili = true),
      onTapUp: (_) => setState(() => _basili = false),
      onTapCancel: () => setState(() => _basili = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _basili ? widget.olcek : 1,
        duration: const Duration(milliseconds: 300),
        curve: _basili ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}
