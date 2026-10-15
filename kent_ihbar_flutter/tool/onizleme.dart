// Geliştirme önizlemesi: belirli bir ekranı doğrudan açar (ekran görüntüsü almak için).
//   flutter run -t tool/onizleme.dart --dart-define=EKRAN=harita --dart-define=KOYU=true
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kent_ihbar/ekranlar/ana_kabuk.dart';
import 'package:kent_ihbar/ekranlar/giris_ekrani.dart';
import 'package:kent_ihbar/ekranlar/sohbet_ekrani.dart';
import 'package:kent_ihbar/ekranlar/yeni_ihbar_ekrani.dart';
import 'package:kent_ihbar/kapsam.dart';
import 'package:kent_ihbar/kimlik.dart';
import 'package:kent_ihbar/konum.dart';
import 'package:kent_ihbar/model.dart';
import 'package:kent_ihbar/tema.dart';

const _ekran = String.fromEnvironment('EKRAN', defaultValue: 'ana');
const _koyu = bool.fromEnvironment('KOYU');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final durum = UygulamaDurumu()..oturum = const OturumUye('+90 532 ••• •• 05');
  final sekme = switch (_ekran) {
    'harita' => Sekme.harita,
    'siralama' => Sekme.siralama,
    'profil' => Sekme.profil,
    _ => Sekme.anaSayfa,
  };
  final Widget ana = switch (_ekran) {
    'giris' => const GirisEkrani(),
    'dogrulama' => const DogrulamaEkrani(
      hedef: '+90 532 ••• •• 05',
      kodOturumu: KodOturumu(telefon: '+905324182705', dogrulamaId: 'onizleme'),
    ),
    _ => AnaKabuk(baslangicSekme: sekme),
  };
  runApp(
    DurumKapsami(
      durum: durum,
      child: KonumKapsami(
        konum: KonumYoneticisi(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: kiTema(Brightness.light),
          darkTheme: kiTema(Brightness.dark),
          themeMode: _koyu ? ThemeMode.dark : ThemeMode.light,
          locale: const Locale('tr', 'TR'),
          supportedLocales: const [Locale('tr', 'TR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) {
              if (_ekran == 'yeni' || _ekran == 'sohbet') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  tamEkranSayfa(
                    context,
                    _ekran == 'yeni' ? const YeniIhbarEkrani(baslangicKategori: Kategori.lamba) : const SohbetEkrani(),
                  );
                });
              }
              return ana;
            },
          ),
        ),
      ),
    ),
  );
}
