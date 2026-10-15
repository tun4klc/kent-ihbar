import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../bilesenler.dart';

/// robot.json bir kez çözülür ve tüm robot görünümleri aynı kompozisyonu (ve gömülü
/// WebP karelerini) paylaşır. Yoksa her görünüm 228 kareyi ayrı ayrı açar.
final Future<LottieComposition> robotKompozisyonu = AssetLottie('assets/lottie/robot.json').load();

/// Kompozisyon hazır olunca robotu çizer; hazır değilken yer tutucu boş alan bırakır.
class RobotCizimi extends StatelessWidget {
  const RobotCizimi({super.key, required this.cizici});

  final Widget Function(LottieComposition kompozisyon) cizici;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LottieComposition>(
      future: robotKompozisyonu,
      builder: (_, s) => s.hasData ? cizici(s.data!) : const SizedBox.expand(),
    );
  }
}

/// Sağ altta yaşayan asistan robotu (robot.json). Dokununca sohbet açılır.
class AsistanRobotu extends StatefulWidget {
  const AsistanRobotu({super.key, required this.ac});

  final VoidCallback ac;

  @override
  State<AsistanRobotu> createState() => _AsistanRobotuState();
}

class _AsistanRobotuState extends State<AsistanRobotu> with SingleTickerProviderStateMixin {
  late final _suzul = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _suzul.stop();
    } else if (!_suzul.isAnimating) {
      _suzul.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _suzul.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hareketAzalt = MediaQuery.disableAnimationsOf(context);
    return Basilabilir(
      etiket: 'Kent asistanı ile sohbet et',
      onTap: widget.ac,
      child: AnimatedBuilder(
        animation: _suzul,
        builder: (_, child) =>
            Transform.translate(offset: Offset(0, 2 - 5 * Curves.easeInOut.transform(_suzul.value)), child: child),
        child: SizedBox(
          width: 104,
          height: 84,
          child: RobotCizimi(
            cizici: (k) => hareketAzalt ? Lottie(composition: k, animate: false) : CanliRobot(kompozisyon: k),
          ),
        ),
      ),
    );
  }
}

// MARK: - Klipler

/// robot.json içindeki kare aralıkları (dosyadaki `markers` ile aynı).
/// Bekleme klipleri her seferinde farklı bir alt aralıktan, bazen geriye doğru oynatılır;
/// hareket klipleri art arda tekrar etmez. Böylece robot hep aynı sırayla hareket etmez.
enum RobotKlibi {
  bekleme1(0, 23),
  bekleme2(195, 227),
  selam(24, 49),
  yakinSelam(60, 113),
  ikiEl(128, 147),
  goz(165, 194);

  const RobotKlibi(this.bas, this.son);
  final int bas;
  final int son;

  int get uzunluk => son - bas + 1;

  static const hareketler = [selam, yakinSelam, ikiEl, goz];
}

class Oynatma {
  const Oynatma(this.bas, this.son, this.hiz);

  final double bas;
  final double son;
  final double hiz;
}

/// Sıradaki oynatmayı seçer: bekleme → hareket → bekleme … ; son iki hareket tekrar edilmez.
class KlipSecici {
  KlipSecici([math.Random? rastgele]) : _r = rastgele ?? math.Random();

  final math.Random _r;
  final List<RobotKlibi> _sonHareketler = [];
  bool _siradaBekleme = true;

  double _araliktan(double a, double b) => a + _r.nextDouble() * (b - a);
  int _tamsayi(int a, int b) => a + _r.nextInt(b - a + 1);

  Oynatma siradaki() {
    final bekleme = _siradaBekleme;
    _siradaBekleme = !_siradaBekleme;
    if (bekleme) {
      final k = _r.nextBool() ? RobotKlibi.bekleme1 : RobotKlibi.bekleme2;
      // Rastgele uzunlukta bir alt aralık, rastgele yönde
      final uzunluk = _tamsayi(math.max(10, k.uzunluk ~/ 2), k.uzunluk);
      final bas = _tamsayi(k.bas, k.son - uzunluk + 1);
      final son = bas + uzunluk - 1;
      final geri = _r.nextBool();
      return Oynatma((geri ? son : bas).toDouble(), (geri ? bas : son).toDouble(), _araliktan(0.75, 1.0));
    }
    final son2 = _sonHareketler.length > 2 ? _sonHareketler.sublist(_sonHareketler.length - 2) : _sonHareketler;
    final adaylar = RobotKlibi.hareketler.where((h) => !son2.contains(h)).toList();
    final k = adaylar.isEmpty ? RobotKlibi.selam : adaylar[_r.nextInt(adaylar.length)];
    _sonHareketler.add(k);
    return Oynatma(k.bas.toDouble(), k.son.toDouble(), _araliktan(0.9, 1.1));
  }
}

/// İki Lottie katmanı: biri oynarken sıradaki klip diğerinde başlar ve 0,3 sn'de üstüne karışır.
class CanliRobot extends StatefulWidget {
  const CanliRobot({super.key, required this.kompozisyon});

  final LottieComposition kompozisyon;

  @override
  State<CanliRobot> createState() => _CanliRobotState();
}

class _CanliRobotState extends State<CanliRobot> with TickerProviderStateMixin {
  final _secici = KlipSecici();
  late final List<AnimationController> _katmanlar = [
    AnimationController(vsync: this),
    AnimationController(vsync: this),
  ];
  int _onde = 0;

  @override
  void initState() {
    super.initState();
    _oynat(0, const Oynatma(0, 23, 0.9));
  }

  @override
  void dispose() {
    for (final k in _katmanlar) {
      k.dispose();
    }
    super.dispose();
  }

  double _ilerleme(double kare) {
    final k = widget.kompozisyon;
    return ((kare - k.startFrame) / (k.endFrame - k.startFrame)).clamp(0.0, 1.0);
  }

  void _oynat(int katman, Oynatma o) {
    final k = _katmanlar[katman];
    final kareSayisi = (o.son - o.bas).abs();
    final sure = Duration(microseconds: (kareSayisi / widget.kompozisyon.frameRate / o.hiz * 1e6).round());
    k.value = _ilerleme(o.bas);
    k.animateTo(_ilerleme(o.son), duration: sure, curve: Curves.linear).whenCompleteOrCancel(() {
      if (mounted && katman == _onde && !k.isAnimating) _sonraki();
    });
  }

  void _sonraki() {
    final arka = 1 - _onde;
    _oynat(arka, _secici.siradaki());
    setState(() => _onde = arka);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < 2; i++)
          AnimatedOpacity(
            opacity: i == _onde ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Lottie(composition: widget.kompozisyon, controller: _katmanlar[i], fit: BoxFit.contain),
          ),
      ],
    );
  }
}
