import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'model.dart';
import 'tema.dart';

/// Damla biçimli harita pini — renk + ikon (renk körlüğü için).
/// Havada süzülür, yerdeki gölgesi buna göre daralır, ara sıra kendi ekseninde 3B döner
/// ve ucundan zemine yayılan dalgalar çıkar. Her pin `tohum` ile kendi ritminde oynar.
class HaritaPini extends StatefulWidget {
  const HaritaPini({super.key, required this.durum, this.tohum = 0});

  static const boyut = 76.0;

  final Durum durum;
  final int tohum;

  @override
  State<HaritaPini> createState() => _HaritaPiniState();
}

class _HaritaPiniState extends State<HaritaPini> with TickerProviderStateMixin {
  late final Ticker _saat;
  double _t = 0;
  late final AnimationController _belirme = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void initState() {
    super.initState();
    _saat = createTicker((gecen) => setState(() => _t = gecen.inMicroseconds / 1e6));
    Future.delayed(Duration(milliseconds: ((widget.tohum & 0xFFFF) % 7) * 60), () {
      if (mounted) _belirme.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hareketAzalt = MediaQuery.disableAnimationsOf(context);
    if (hareketAzalt && _saat.isActive) _saat.stop();
    if (!hareketAzalt && !_saat.isActive) _saat.start();
  }

  @override
  void dispose() {
    _saat.dispose();
    _belirme.dispose();
    super.dispose();
  }

  /// 0…1 arası pin başına sabit sapma — pinler aynı anda hareket etmesin.
  double get _sapma => ((widget.tohum & 0xFFFF) % 997) / 997;
  double get _dalgaSuresi => widget.durum == Durum.kritik ? 1.4 : 2.4;

  /// Her 5–8 sn'de bir, 0,9 sn süren tam tur; arada düz durur.
  double _donusAcisi(double t) {
    final periyot = 5 + _sapma * 3;
    final p = t % periyot;
    const sure = 0.9;
    if (p >= sure) return 0;
    final x = p / sure;
    final yumusak = x < 0.5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2; // easeInOutCubic
    return yumusak * 2 * math.pi;
  }

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final hareketAzalt = MediaQuery.disableAnimationsOf(context);
    final renk = widget.durum.renk(r);
    final tt = _t + _sapma * 10;
    final suzulme = hareketAzalt ? 0.0 : math.sin(tt * 2 * math.pi / 2.6) * 4; // -4…4
    final donus = hareketAzalt ? 0.0 : _donusAcisi(tt);

    return Semantics(
      label: widget.durum.ad,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _belirme, curve: Curves.easeOutBack),
        alignment: Alignment.bottomCenter,
        child: FadeTransition(
          opacity: _belirme,
          child: SizedBox(
            width: HaritaPini.boyut,
            height: HaritaPini.boyut,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                if (!hareketAzalt) ...[
                  _dalga(r, renk, (tt / _dalgaSuresi) % 1),
                  _dalga(r, renk, (tt / _dalgaSuresi + 0.5) % 1),
                ],
                // Yer gölgesi: pin yükseldikçe küçülür ve soluklaşır
                Positioned(
                  bottom: 0,
                  child: ImageFiltered(
                    imageFilter: _bulanik,
                    child: Container(
                      width: 20 - suzulme * 0.9,
                      height: 6 - suzulme * 0.25,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22 - suzulme * 0.012),
                        borderRadius: const BorderRadius.all(Radius.elliptical(10, 3)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10 + suzulme,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.003)
                      ..rotateY(donus),
                    child: _govde(r, renk),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static final _bulanik = ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5);

  static const _damlaKose = BorderRadius.only(
    topLeft: Radius.circular(17),
    bottomLeft: Radius.circular(17),
    bottomRight: Radius.circular(3),
    topRight: Radius.circular(17),
  );

  Widget _govde(KIRenk r, Color renk) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: _damlaKose,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [renk.withValues(alpha: 0.85), renk],
                ),
                boxShadow: [BoxShadow(color: renk.withValues(alpha: 0.45), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: _damlaKose,
                border: Border.all(color: r.yuzey, width: 2.5),
                // Hacim: üst-solda parlak ışık
                gradient: RadialGradient(
                  center: const Alignment(-0.44, -0.5),
                  radius: 0.55,
                  colors: [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)],
                ),
              ),
              child: DecoratedBox(
                // Alt-sağda koyu kenar
                decoration: BoxDecoration(
                  borderRadius: _damlaKose,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.22)],
                  ),
                ),
              ),
            ),
          ),
          Icon(
            widget.durum.ikon,
            size: 15,
            color: r.onDurum,
            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 1, offset: const Offset(0, 0.5))],
          ),
        ],
      ),
    );
  }

  /// Zemine yatırılmış (perspektifli) halka: içten dışa büyür ve kaybolur.
  Widget _dalga(KIRenk r, Color renk, double ilerleme) {
    final kritik = widget.durum == Durum.kritik;
    final boyut = 14 + ilerleme * (kritik ? 62 : 50);
    final yukseklik = boyut * 0.38;
    return Positioned(
      bottom: 3 - yukseklik / 2,
      child: Container(
        width: boyut,
        height: yukseklik,
        decoration: BoxDecoration(
          color: renk.withValues(alpha: (1 - ilerleme) * 0.12),
          borderRadius: BorderRadius.all(Radius.elliptical(boyut / 2, yukseklik / 2)),
          border: Border.all(
            color: renk.withValues(alpha: (1 - ilerleme) * (kritik ? 0.9 : 0.6)),
            width: 2.5 - ilerleme * 1.5,
          ),
        ),
      ),
    );
  }
}
