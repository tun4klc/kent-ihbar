import 'package:flutter/material.dart';

import '../api.dart';
import '../bilesenler.dart';
import '../kapsam.dart';
import '../tema.dart';

/// `/auth/verify` `profileCompleted: false` dönünce açılır; `/users/complete-profile`'a gönderir.
class ProfilTamamlamaEkrani extends StatefulWidget {
  const ProfilTamamlamaEkrani({super.key});

  @override
  State<ProfilTamamlamaEkrani> createState() => _ProfilTamamlamaEkraniState();
}

class _ProfilTamamlamaEkraniState extends State<ProfilTamamlamaEkrani> {
  final _ad = TextEditingController();
  final _soyad = TextEditingController();
  final _eposta = TextEditingController();
  final _adOdak = FocusNode();
  final _soyadOdak = FocusNode();
  final _epostaOdak = FocusNode();
  bool _sozlesmeler = false;
  bool _pazarlama = false;
  bool _gonderiliyor = false;

  @override
  void initState() {
    super.initState();
    for (final n in [_adOdak, _soyadOdak, _epostaOdak]) {
      n.addListener(() => setState(() {}));
    }
    for (final d in [_ad, _soyad, _eposta]) {
      d.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final d in [_ad, _soyad, _eposta]) {
      d.dispose();
    }
    for (final n in [_adOdak, _soyadOdak, _epostaOdak]) {
      n.dispose();
    }
    super.dispose();
  }

  bool get _epostaGecerli {
    final e = _eposta.text.trim();
    if (e.isEmpty) return true;
    final p = e.split('@');
    return p.length == 2 && p[0].isNotEmpty && p[1].contains('.');
  }

  bool get _gonderilebilir =>
      _ad.text.trim().isNotEmpty && _soyad.text.trim().isNotEmpty && _epostaGecerli && _sozlesmeler && !_gonderiliyor;

  Future<void> _gonder() async {
    FocusScope.of(context).unfocus();
    final gezgin = Navigator.of(context);
    setState(() => _gonderiliyor = true);
    try {
      await DurumKapsami.oku(context).profilTamamla(
        ad: _ad.text.trim(),
        soyad: _soyad.text.trim(),
        eposta: _eposta.text.trim(),
        sozlesmeler: _sozlesmeler,
        pazarlama: _pazarlama,
      );
      if (mounted) gezgin.popUntil((r) => r.isFirst);
    } on ApiHatasi catch (e) {
      if (mounted) hataGoster(context, e.mesaj);
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  Widget _alan(String etiket, TextEditingController d, FocusNode o, String ipucu, {bool eposta = false}) {
    final hata = eposta && !_epostaGecerli && !o.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AlanEtiketi(etiket),
        const SizedBox(height: 6),
        GirdiKutusu(
          odakta: o.hasFocus,
          hata: hata,
          children: [
            SadeAlan(
              denetleyici: d,
              odak: o,
              ipucu: ipucu,
              klavye: eposta ? TextInputType.emailAddress : TextInputType.name,
              otomatikDoldurma: [
                if (eposta)
                  AutofillHints.email
                else if (d == _ad)
                  AutofillHints.givenName
                else
                  AutofillHints.familyName,
              ],
              buyukHarf: eposta ? TextCapitalization.none : TextCapitalization.words,
              duzeltme: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _onay(KIRenk r, bool deger, ValueChanged<bool> degisti, String metin) {
    return InkWell(
      borderRadius: BorderRadius.circular(KI.radiusMd),
      onTap: () => degisti(!deger),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KI.space2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(value: deger, onChanged: (v) => degisti(v ?? false)),
            ),
            const SizedBox(width: KI.space3),
            Expanded(child: Text(metin, style: KIFont.govde(14).renk(r.metin))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    return Scaffold(
      backgroundColor: r.zemin,
      appBar: AppBar(backgroundColor: r.zemin, title: const Text('Profilini tamamla')),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(KI.space5, KI.space3, KI.space5, KI.space5 + MediaQuery.paddingOf(context).bottom),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'İhbarlarını belediyeye iletebilmemiz için birkaç bilgiye ihtiyacımız var.',
                style: KIFont.govde(15).renk(r.metinIkincil),
              ),
              const SizedBox(height: KI.space5),
              _alan('Ad', _ad, _adOdak, 'Adın'),
              const SizedBox(height: KI.space4),
              _alan('Soyad', _soyad, _soyadOdak, 'Soyadın'),
              const SizedBox(height: KI.space4),
              _alan('E-posta (isteğe bağlı)', _eposta, _epostaOdak, 'ornek@eposta.com', eposta: true),
              const SizedBox(height: KI.space5),
              _onay(
                r,
                _sozlesmeler,
                (v) => setState(() => _sozlesmeler = v),
                'Kullanım koşullarını, gizlilik politikasını ve KVKK aydınlatma metnini okudum, kabul ediyorum.',
              ),
              _onay(
                r,
                _pazarlama,
                (v) => setState(() => _pazarlama = v),
                'Duyuru ve kampanyalardan haberdar olmak istiyorum (isteğe bağlı).',
              ),
              const SizedBox(height: KI.space5),
              BirincilDugme(
                baslik: _gonderiliyor ? 'Kaydediliyor…' : 'Devam et',
                onPressed: _gonderilebilir ? _gonder : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
