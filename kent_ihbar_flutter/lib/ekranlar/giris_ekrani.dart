import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bilesenler.dart';
import '../kapsam.dart';
import '../model.dart';
import '../tema.dart';

// MARK: - Giriş

enum _Yontem { telefon, eposta }

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  _Yontem _yontem = _Yontem.telefon;
  final _telefon = TextEditingController();
  final _eposta = TextEditingController();
  final _telefonOdak = FocusNode();
  final _epostaOdak = FocusNode();
  late final _kosullar = _baglanti('https://example.com/kosullar');
  late final _kvkk = _baglanti('https://example.com/kvkk');

  @override
  void initState() {
    super.initState();
    for (final n in [_telefonOdak, _epostaOdak]) {
      n.addListener(() => setState(() {}));
    }
    _telefon.addListener(() => setState(() {}));
    _eposta.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _telefon.dispose();
    _eposta.dispose();
    _telefonOdak.dispose();
    _epostaOdak.dispose();
    _kosullar.dispose();
    _kvkk.dispose();
    super.dispose();
  }

  String get _telefonRakam => _telefon.text.replaceAll(RegExp(r'\D'), '');

  bool get _epostaGecerli {
    final p = _eposta.text.split('@');
    return p.length == 2 && p[1].contains('.') && p[0].isNotEmpty;
  }

  bool get _gonderilebilir => _yontem == _Yontem.telefon ? _telefonRakam.length == 10 : _epostaGecerli;

  bool get _epostaHatali => _eposta.text.isNotEmpty && !_epostaOdak.hasFocus && !_epostaGecerli;

  String get _maskeliTelefon {
    final r = _telefonRakam;
    if (r.length != 10) return _telefon.text;
    return '+90 ${r.substring(0, 3)} ••• •• ${r.substring(8, 10)}';
  }

  void _kodGonder() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DogrulamaEkrani(hedef: _yontem == _Yontem.telefon ? _maskeliTelefon : _eposta.text),
      ),
    );
  }

  void _edevlet() {
    showAdaptiveDialog<void>(
      context: context,
      builder: (c) => AlertDialog.adaptive(
        title: const Text('e-Devlet ile giriş'),
        content: const Text(
          'Bu prototipte e-Devlet entegrasyonu bağlı değil. Gerçek kullanım için Türkiye.gov.tr resmî entegrasyonu gerekir.',
        ),
        actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Tamam'))],
      ),
    );
  }

  static TapGestureRecognizer _baglanti(String adres) =>
      TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(adres), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Scaffold(
      backgroundColor: r.zemin,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 250, width: double.infinity, child: KentIllustrasyonu()),
            Padding(
              padding: const EdgeInsets.fromLTRB(KI.space5, 0, KI.space5, KI.space6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kent İhbar', style: KIFont.baslik(32).copyWith(letterSpacing: -0.6, color: r.metin)),
                  const SizedBox(height: 6),
                  Text('Şehrini daha iyi bir yer yap.', style: KIFont.govde(15).renk(r.metinIkincil)),
                  const SizedBox(height: KI.space5),
                  _form(r),
                  const SizedBox(height: KI.space5),
                  Center(
                    child: MetinDugme(
                      baslik: 'Misafir olarak devam et',
                      onPressed: () => DurumKapsami.oku(context).oturum = const OturumMisafir(),
                    ),
                  ),
                  const SizedBox(height: KI.space5 + KI.space2),
                  _yasalMetin(r),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(KIRenk r) {
    return Kart(
      child: Column(
        children: [
          Segment<_Yontem>(
            secenekler: const [
              SegmentSecenegi(deger: _Yontem.telefon, baslik: 'Telefon', ikon: Icons.phone_outlined),
              SegmentSecenegi(deger: _Yontem.eposta, baslik: 'E-posta', ikon: Icons.mail_outline_rounded),
            ],
            secili: _yontem,
            degisti: (y) => setState(() => _yontem = y),
          ),
          const SizedBox(height: KI.space4),
          AnimatedSize(
            duration: KI.sureOrta,
            curve: KI.egriStandart,
            child: AnimatedSwitcher(
              duration: KI.sureOrta,
              child: _yontem == _Yontem.telefon ? _telefonAlani(r) : _epostaAlani(r),
            ),
          ),
          const SizedBox(height: KI.space4),
          BirincilDugme(baslik: 'Kod gönder', onPressed: _gonderilebilir ? _kodGonder : null),
          const SizedBox(height: KI.space4),
          const Ayirici('veya'),
          const SizedBox(height: KI.space4),
          IkincilDugme(baslik: 'e-Devlet ile giriş yap', ikon: Icons.account_balance_outlined, onPressed: _edevlet),
        ],
      ),
    );
  }

  Widget _telefonAlani(KIRenk r) {
    return Column(
      key: const ValueKey('telefon'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AlanEtiketi('Telefon numarası'),
        const SizedBox(height: 6),
        GirdiKutusu(
          odakta: _telefonOdak.hasFocus,
          children: [
            Text('+90', style: KIFont.govde(16, Agirlik.yariKalin).renk(r.metin)),
            Container(width: 1, height: 24, color: r.cizgi),
            Expanded(
              child: TextField(
                controller: _telefon,
                focusNode: _telefonOdak,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [TelefonBicimleyici()],
                style: KIFont.govdeMetni.renk(r.metin),
                onTapOutside: (_) => _telefonOdak.unfocus(),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: '5__ ___ __ __',
                  hintStyle: KIFont.govdeMetni.renk(r.metinSoluk),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Doğrulama kodunu SMS ile göndereceğiz.', style: KIFont.altYazi.renk(r.metinIkincil)),
      ],
    );
  }

  Widget _epostaAlani(KIRenk r) {
    return Column(
      key: const ValueKey('eposta'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AlanEtiketi('E-posta'),
        const SizedBox(height: 6),
        GirdiKutusu(
          odakta: _epostaOdak.hasFocus,
          hata: _epostaHatali,
          children: [
            Icon(Icons.mail_outline_rounded, size: 20, color: r.metinSoluk),
            SadeAlan(
              denetleyici: _eposta,
              odak: _epostaOdak,
              ipucu: 'ornek@eposta.com',
              klavye: TextInputType.emailAddress,
              otomatikDoldurma: const [AutofillHints.email],
              buyukHarf: TextCapitalization.none,
              duzeltme: false,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _epostaHatali ? 'Geçerli bir e-posta adresi gir.' : 'Giriş bağlantısı ve kodu e-postana göndereceğiz.',
          style: KIFont.altYazi.renk(_epostaHatali ? r.kritik : r.metinIkincil),
        ),
      ],
    );
  }

  Widget _yasalMetin(KIRenk r) {
    final temel = KIFont.govde(12, Agirlik.orta).renk(r.metinIkincil);
    final baglanti = KIFont.govde(12, Agirlik.kalin).renk(r.birincilMetin);
    return SizedBox(
      width: double.infinity,
      child: Text.rich(
        TextSpan(
          style: temel,
          children: [
            const TextSpan(text: 'Devam ederek '),
            TextSpan(text: 'Kullanım koşulları', style: baglanti, recognizer: _kosullar),
            const TextSpan(text: ' ve '),
            TextSpan(text: 'KVKK Aydınlatma Metni', style: baglanti, recognizer: _kvkk),
            const TextSpan(text: "'ni kabul etmiş olursun."),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// "5324182705" → "532 418 27 05"
class TelefonBicimleyici extends TextInputFormatter {
  static String bicimle(String girdi) {
    final r = girdi.replaceAll(RegExp(r'\D'), '');
    final rakamlar = r.length > 10 ? r.substring(0, 10) : r;
    final b = StringBuffer();
    for (var i = 0; i < rakamlar.length; i++) {
      if (i == 3 || i == 6 || i == 8) b.write(' ');
      b.write(rakamlar[i]);
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue eski, TextEditingValue yeni) {
    final b = bicimle(yeni.text);
    return TextEditingValue(
      text: b,
      selection: TextSelection.collapsed(offset: b.length),
    );
  }
}

// MARK: - Doğrulama kodu

class DogrulamaEkrani extends StatefulWidget {
  const DogrulamaEkrani({super.key, required this.hedef});

  final String hedef;

  @override
  State<DogrulamaEkrani> createState() => _DogrulamaEkraniState();
}

class _DogrulamaEkraniState extends State<DogrulamaEkrani> with SingleTickerProviderStateMixin {
  final _kod = TextEditingController();
  final _odak = FocusNode();
  int _kalan = 60;
  bool _hata = false;
  late final Timer _zamanlayici;
  late final AnimationController _salla = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

  @override
  void initState() {
    super.initState();
    _zamanlayici = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_kalan > 0) setState(() => _kalan--);
    });
    _odak.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _odak.requestFocus());
  }

  @override
  void dispose() {
    _zamanlayici.cancel();
    _salla.dispose();
    _kod.dispose();
    _odak.dispose();
    super.dispose();
  }

  void _degisti(String yeni) {
    setState(() => _hata = false);
    if (yeni.length == 6) _dogrula();
  }

  void _dogrula() {
    if (_kod.text.length != 6) return;
    if (_kod.text == '000000') {
      setState(() => _hata = true);
      _salla.forward(from: 0);
      _kod.clear();
      return;
    }
    _odak.unfocus();
    final durum = DurumKapsami.oku(context);
    Navigator.of(context).popUntil((r) => r.isFirst);
    durum.oturum = OturumUye(widget.hedef);
  }

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Scaffold(
      backgroundColor: r.zemin,
      body: SafeArea(
        // Büyük yazı boyutlarında taşmasın diye kaydırılabilir; normalde ekranı doldurur.
        child: LayoutBuilder(
          builder: (context, k) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(KI.space5, 0, KI.space5, KI.space4),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: k.maxHeight - KI.space4),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(-10, 0),
                      child: Basilabilir(
                        etiket: 'Geri',
                        onTap: () => Navigator.of(context).pop(),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.arrow_back_rounded, size: 24, color: r.metin),
                        ),
                      ),
                    ),
                    const SizedBox(height: KI.space5),
                    Text('Doğrulama kodu', style: KIFont.ekranBasligi.renk(r.metin)),
                    const SizedBox(height: KI.space2),
                    Text(
                      '${widget.hedef} için gönderdiğimiz 6 haneli kodu gir.',
                      style: KIFont.govde(15).renk(r.metinIkincil),
                    ),
                    const SizedBox(height: KI.space5),
                    Stack(
                      children: [
                        // Gerçek giriş: görünmez alan, SMS kodunu otomatik doldurur.
                        Opacity(
                          opacity: 0.01,
                          child: TextField(
                            controller: _kod,
                            focusNode: _odak,
                            keyboardType: TextInputType.number,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            onChanged: _degisti,
                            showCursor: false,
                            enableInteractiveSelection: false,
                            decoration: const InputDecoration(border: InputBorder.none),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _salla,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(8 * math.sin(_salla.value * math.pi * 4), 0),
                            child: child,
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _odak.requestFocus(),
                            child: ListenableBuilder(
                              listenable: _kod,
                              builder: (_, _) => Row(
                                children: [
                                  for (var i = 0; i < 6; i++) ...[
                                    if (i > 0) const SizedBox(width: 10),
                                    Expanded(child: _kutu(r, i)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KI.space3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _hata ? 'Kod hatalı, tekrar dene.' : 'Kod gelmedi mi?',
                            style: KIFont.altYazi.renk(_hata ? r.kritik : r.metinIkincil),
                          ),
                        ),
                        MetinDugme(
                          baslik: _kalan > 0
                              ? 'Tekrar gönder · 0:${_kalan.toString().padLeft(2, '0')}'
                              : 'Tekrar gönder',
                          onPressed: _kalan > 0 ? null : () => setState(() => _kalan = 60),
                        ),
                      ],
                    ),
                    const SizedBox(height: KI.space5),
                    Text(
                      'Prototip: 000000 dışındaki herhangi bir 6 haneli kod kabul edilir.',
                      style: KIFont.altYazi.renk(r.metinSoluk),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(KI.space4),
                      decoration: BoxDecoration(
                        color: r.birincilYumusak,
                        borderRadius: BorderRadius.circular(KI.radiusLg),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_outlined, size: 22, color: r.birincilMetin),
                          const SizedBox(width: KI.space3),
                          Expanded(
                            child: Text(
                              'Kodu kimseyle paylaşma. Belediye çalışanları kodunu asla sormaz.',
                              style: KIFont.govde(14, Agirlik.orta).renk(r.metin),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KI.space5),
                    ListenableBuilder(
                      listenable: _kod,
                      builder: (_, _) =>
                          BirincilDugme(baslik: 'Doğrula', onPressed: _kod.text.length < 6 ? null : _dogrula),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kutu(KIRenk r, int i) {
    final rakamlar = _kod.text;
    final dolu = i < rakamlar.length;
    final aktif = _odak.hasFocus && i == math.min(rakamlar.length, 5) && !dolu;
    return AnimatedContainer(
      duration: KI.sureHizli,
      curve: Curves.easeOut,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: r.yuzey,
        borderRadius: BorderRadius.circular(KI.radiusMd),
        border: Border.all(color: _hata ? r.kritik : ((dolu || aktif) ? r.birincil : r.cizgiKontrol), width: 1.5),
        boxShadow: [if (aktif) BoxShadow(color: r.birincilYumusak, spreadRadius: 4)],
      ),
      child: AnimatedSwitcher(
        duration: KI.sureHizli,
        transitionBuilder: (c, a) => ScaleTransition(
          scale: a,
          child: FadeTransition(opacity: a, child: c),
        ),
        child: dolu
            ? Text(rakamlar[i], key: ValueKey('r$i${rakamlar[i]}'), style: KIFont.baslik(22).renk(r.metin))
            : aktif
            ? _YanipSonenImlec(renk: r.birincil)
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _YanipSonenImlec extends StatefulWidget {
  const _YanipSonenImlec({required this.renk});

  final Color renk;

  @override
  State<_YanipSonenImlec> createState() => _YanipSonenImlecState();
}

class _YanipSonenImlecState extends State<_YanipSonenImlec> with SingleTickerProviderStateMixin {
  late final _k = AnimationController(vsync: this, duration: const Duration(milliseconds: 530))..repeat(reverse: true);

  @override
  void dispose() {
    _k.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _k.drive(Tween(begin: 1, end: 0.15)),
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(color: widget.renk, borderRadius: BorderRadius.circular(1)),
      ),
    );
  }
}

// MARK: - Kent illüstrasyonu (tokenlardan çizilen kent planı)

class KentIllustrasyonu extends StatefulWidget {
  const KentIllustrasyonu({super.key});

  @override
  State<KentIllustrasyonu> createState() => _KentIllustrasyonuState();
}

class _KentIllustrasyonuState extends State<KentIllustrasyonu> with SingleTickerProviderStateMixin {
  late final _k = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();

  @override
  void dispose() {
    _k.dispose();
    super.dispose();
  }

  Animation<double> _egri(double gecikme, double sure, Curve egri) => CurvedAnimation(
    parent: _k,
    curve: Interval(gecikme / 1.3, math.min(1, (gecikme + sure) / 1.3), curve: egri),
  );

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return ExcludeSemantics(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, k) {
            final s = k.maxWidth / 390;
            return AnimatedBuilder(
              animation: _k,
              builder: (_, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  _blok(r.birincilYumusak, -20, 40, 150, 190, s, 0),
                  _blok(r.birincil, 146, -20, 96, 250, s, 0.08),
                  _blok(r.maviRenk, 258, 70, 152, 160, s, 0.16),
                  _blok(r.birincilYumusak, 258, -20, 72, 74, s, 0.24),
                  _pin(r, 194, 200, 13, s, 0.45),
                  _pin(r, 60, 96, 9, s, 0.55),
                  _pin(r, 330, 180, 9, s, 0.65),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _blok(Color renk, double x, double y, double w, double h, double s, double gecikme) {
    final a = _egri(gecikme, 0.7, Curves.easeOutCubic).value;
    return Positioned(
      left: x * s,
      top: (y + 80 * (1 - a)) * s,
      child: Opacity(
        opacity: a.clamp(0, 1),
        child: Container(
          width: w * s,
          height: h * s,
          decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(20 * s)),
        ),
      ),
    );
  }

  Widget _pin(KIRenk r, double x, double y, double yaricap, double s, double gecikme) {
    final a = _egri(gecikme, 0.45, Curves.easeOutBack).value;
    return Positioned(
      left: (x - yaricap) * s,
      top: (y - yaricap - 40 * (1 - a)) * s,
      child: Opacity(
        opacity: a.clamp(0, 1),
        child: Container(
          width: 2 * yaricap * s,
          height: 2 * yaricap * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: r.zemin, shape: BoxShape.circle),
          child: Container(
            width: 0.8 * yaricap * s,
            height: 0.8 * yaricap * s,
            decoration: BoxDecoration(color: r.birincil, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
