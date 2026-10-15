import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../bilesenler.dart';
import '../kapsam.dart';
import '../model.dart';
import '../tema.dart';

class ProfilEkrani extends StatefulWidget {
  const ProfilEkrani({super.key});

  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  String _surum = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform()
        .then((p) {
          if (mounted) setState(() => _surum = 'Sürüm ${p.version}+${p.buildNumber}');
        })
        .catchError((_) {});
  }

  void _cikisOnayi() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (c) => CupertinoActionSheet(
        title: const Text('Çıkış yapmak istiyor musun?'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(c).pop();
              DurumKapsami.oku(context).cikisYap();
            },
            child: const Text('Çıkış yap'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.of(c).pop(), child: const Text('Vazgeç')),
      ),
    );
  }

  void _paylas(BuildContext context) {
    final kutu = context.findRenderObject() as RenderBox?;
    SharePlus.instance.share(
      ShareParams(
        text: 'Kent İhbar: şehrindeki sorunları fotoğraf ve konumla belediyene ilet.',
        sharePositionOrigin: kutu == null ? null : kutu.localToGlobal(Offset.zero) & kutu.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = KIRenk.of(context);
    final durum = DurumKapsami.of(context);
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(KI.space5, KI.space2, KI.space5, KI.space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profil', style: KIFont.ekranBasligi.renk(r.metin)),
            const SizedBox(height: KI.space5),
            _profilKarti(r, durum),
            const SizedBox(height: KI.space5),
            MenuGrubu(
              baslik: 'Hızlı erişim',
              children: [
                const MenuSatiri(ikon: Icons.help_outline_rounded, baslik: 'Sıkça sorulan sorular'),
                const MenuSatiri(ikon: Icons.language_rounded, baslik: 'Dil', deger: 'Türkçe'),
                Builder(
                  builder: (c) => MenuSatiri(
                    ikon: Icons.ios_share_rounded,
                    baslik: 'Uygulamayı paylaş',
                    ayiriciVar: false,
                    onTap: () => _paylas(c),
                  ),
                ),
              ],
            ),
            const SizedBox(height: KI.space5),
            MenuGrubu(
              baslik: 'Yasal',
              children: [
                const MenuSatiri(ikon: Icons.verified_user_outlined, baslik: 'Gizlilik ve KVKK'),
                MenuSatiri(ikon: Icons.description_outlined, baslik: 'Kullanım koşulları', ayiriciVar: durum.uyeMi),
                if (durum.uyeMi)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _cikisOnayi,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 58),
                      padding: const EdgeInsets.symmetric(horizontal: KI.space4),
                      child: Row(
                        children: [
                          SizedBox(width: 24, child: Icon(Icons.logout_rounded, size: 22, color: r.kritik)),
                          const SizedBox(width: KI.space4),
                          Text('Çıkış yap', style: KIFont.dugme.renk(r.kritik)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: KI.space5),
            Text(_surum, style: KIFont.altYazi.renk(r.metinSoluk)),
          ],
        ),
      ),
    );
  }

  Widget _profilKarti(KIRenk r, UygulamaDurumu durum) {
    final oturum = durum.oturum;
    if (oturum is OturumUye) {
      final benimIhbarlarim = durum.benimIhbarlarim.veri.length;
      final adSoyad = durum.profil?.adSoyad;
      return Kart(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: r.birincilYumusak, shape: BoxShape.circle),
              child: adSoyad == null
                  ? Icon(Icons.person_outline_rounded, size: 24, color: r.birincilMetin)
                  : Text(turkceBuyuk(adSoyad.characters.first), style: KIFont.baslik(18).renk(r.birincilMetin)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(adSoyad ?? 'Hoş geldin', style: KIFont.kartBasligi.renk(r.metin)),
                  const SizedBox(height: 2),
                  Text(oturum.telefon, style: KIFont.govdeKucuk.renk(r.metinIkincil)),
                ],
              ),
            ),
            Column(
              children: [
                Text('$benimIhbarlarim', style: KIFont.baslik(20).renk(r.birincilMetin)),
                Text('İhbarım', style: KIFont.altYazi.renk(r.metinIkincil)),
              ],
            ),
          ],
        ),
      );
    }
    return Kart(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: r.birincilYumusak, shape: BoxShape.circle),
                child: Icon(Icons.person_outline_rounded, size: 24, color: r.birincilMetin),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Misafir', style: KIFont.kartBasligi.renk(r.metin)),
                    const SizedBox(height: 2),
                    Text(
                      'İhbar oluşturmak ve takip etmek için giriş yap.',
                      style: KIFont.govdeKucuk.renk(r.metinIkincil),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KI.space4),
          BirincilDugme(baslik: 'Giriş yap', onPressed: () => DurumKapsami.oku(context).oturum = const OturumYok()),
        ],
      ),
    );
  }
}
