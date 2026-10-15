import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kent_ihbar/ekranlar/asistan_robotu.dart';
import 'package:kent_ihbar/ekranlar/giris_ekrani.dart';
import 'package:kent_ihbar/ekranlar/sohbet_ekrani.dart';
import 'package:kent_ihbar/main.dart';
import 'package:kent_ihbar/model.dart';

void main() {
  group('Yardımcılar', () {
    test('telefon numarası 3-3-2-2 biçiminde, en çok 10 hane', () {
      expect(TelefonBicimleyici.bicimle('5324182705'), '532 418 27 05');
      expect(TelefonBicimleyici.bicimle('53241'), '532 41');
      expect(TelefonBicimleyici.bicimle('532-418-27-05-99'), '532 418 27 05');
    });

    test('Türkçe sayı biçimleri', () {
      expect(turkceOndalik(2.1), '2,1');
      expect(turkceSayi(1410), '1.410');
      expect(turkceBuyuk('Ni'), 'Nİ');
      expect(
        const Belediye(
          ad: 'Nilüfer Belediyesi',
          sehir: 'Bursa',
          ortalamaGun: 1,
          memnuniyet: 1,
          aylikCozum: 1,
          puan: 1,
        ).basHarfler,
        'Nİ',
      );
    });

    test('asistan anahtar kelimelere göre yanıtlar', () {
      expect(KentAsistani.yanit('Nasıl İHBAR ederim?'), contains('Bildir düğmesine'));
      expect(KentAsistani.yanit('Sıralama nasıl hesaplanıyor?'), contains('Bildir düğmesine'));
      expect(KentAsistani.yanit('puanlar'), contains('100 üzerinden'));
      expect(KentAsistani.yanit('xyz'), startsWith('Bunu henüz bilmiyorum'));
    });

    test('robot klipleri bekleme/hareket sırasıyla gelir, hareket art arda tekrarlanmaz', () {
      final s = KlipSecici();
      RobotKlibi? onceki;
      for (var i = 0; i < 40; i++) {
        final o = s.siradaki();
        final bekleme = i.isEven;
        final lo = o.bas < o.son ? o.bas : o.son;
        final hi = o.bas < o.son ? o.son : o.bas;
        final klip = RobotKlibi.values.firstWhere((k) => lo >= k.bas && hi <= k.son);
        expect(klip == RobotKlibi.bekleme1 || klip == RobotKlibi.bekleme2, bekleme);
        if (!bekleme) {
          expect(klip, isNot(onceki));
          onceki = klip;
        }
      }
    });
  });

  testWidgets('giriş → doğrulama → ana sayfa akışı', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final durum = UygulamaDurumu();
    await tester.pumpWidget(KentIhbarUygulamasi(durum: durum));
    await tester.pumpAndSettle();

    expect(find.text('Kent İhbar'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '5324182705');
    await tester.pump();
    expect(find.text('532 418 27 05'), findsOneWidget);

    await tester.tap(find.text('Kod gönder'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Doğrulama kodu'), findsOneWidget);
    expect(find.textContaining('+90 532 ••• •• 05'), findsOneWidget);

    // 000000 reddedilir
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Kod hatalı, tekrar dene.'), findsOneWidget);
    expect(durum.uyeMi, isFalse);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(durum.uyeMi, isTrue);
    expect(find.text('Sorun mu gördün?'), findsOneWidget);
    expect(find.text('Genel durum'), findsOneWidget);

    // Lottie ve zamanlayıcılar sonsuz döndüğü için ağacı kaldırarak bitir.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('misafir girişi profil sekmesinde "Misafir" gösterir', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final durum = UygulamaDurumu();
    await tester.pumpWidget(KentIhbarUygulamasi(durum: durum));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Misafir olarak devam et'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Profil'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Misafir'), findsOneWidget);
    expect(find.text('Giriş yap'), findsOneWidget);

    // Misafir "Bildir"e basınca giriş ekranına döner.
    await tester.tap(find.text('Bildir'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(durum.girisGerekli, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
