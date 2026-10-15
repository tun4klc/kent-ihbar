import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kent_ihbar/api.dart';
import 'package:kent_ihbar/ekranlar/asistan_robotu.dart';
import 'package:kent_ihbar/ekranlar/giris_ekrani.dart';
import 'package:kent_ihbar/ekranlar/sohbet_ekrani.dart';
import 'package:kent_ihbar/kimlik.dart';
import 'package:kent_ihbar/main.dart';
import 'package:kent_ihbar/model.dart';

/// Firebase yerine: her kod geçerli, `000000` hatalı.
class SahteKimlik implements KimlikSaglayici {
  @override
  String? telefon;

  @override
  Future<KodOturumu> kodGonder(String telefon, {int? yenidenGonderme}) async =>
      KodOturumu(telefon: telefon, dogrulamaId: 'dogrulama-1');

  @override
  Future<String> kodDogrula(KodOturumu oturum, String kod) async {
    if (kod == '000000') throw const KimlikHatasi('Kod hatalı, tekrar dene.', kodHatali: true);
    telefon = oturum.telefon;
    return 'firebase-id-token';
  }

  @override
  Future<String?> idToken({bool yenile = false}) async => telefon == null ? null : 'firebase-id-token';

  @override
  Future<void> cikis() async => telefon = null;
}

http.Response _json(Object govde, [int durum = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(govde)), durum, headers: {'content-type': 'application/json'});

/// Kent API'nin sahte hali; [profilTamam] `/auth/verify` yanıtını belirler.
MockClient _sahteSunucu({bool profilTamam = true, List<String>? istekler}) => MockClient((istek) async {
  istekler?.add('${istek.method} ${istek.url.path}');
  return switch ('${istek.method} ${istek.url.path}') {
    'POST /v1/auth/verify' => _json({'token': 'jwt', 'profileCompleted': profilTamam}),
    'POST /v1/users/complete-profile' => _json({'firstName': 'Ayşe', 'lastName': 'Yılmaz', 'phone': '+905324182705'}),
    'GET /v1/users/me' => _json({'firstName': 'Ayşe', 'lastName': 'Yılmaz', 'phone': '+905324182705'}),
    'GET /v1/reports/mine' => _json({
      'content': [
        {
          'id': 'r1',
          'category': 'BROKEN_LIGHT',
          'status': 'PENDING',
          'lat': 38.46,
          'lng': 27.22,
          'address': 'Erzene Mah., Ankara Cd.',
          'createdAt': '2026-10-15T10:00:00Z',
        },
      ],
      'totalElements': 1,
      'totalPages': 1,
      'size': 50,
      'number': 0,
    }),
    _ => _json({'code': 'NOT_FOUND', 'message': 'yok'}, 404),
  };
});

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
      expect(const Belediye(ad: 'Nilüfer Belediyesi', sehir: 'Bursa', aylikCozum: 1, puan: 1).basHarfler, 'Nİ');
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

  group('API modelleri', () {
    test('harita pini ve durum eşlemesi', () {
      final pin = Ihbar.fromJson({
        'id': 'a',
        'lat': 38.4,
        'lng': 27.2,
        'category': 'FIRE',
        'status': 'ASSIGNED',
        'priority': false,
        'title': 'Yangın',
      });
      expect(pin.kategori, Kategori.yangin);
      expect(pin.durum, Durum.kritik, reason: 'acil kategori açıkken kritik');
      expect(pin.tarih, isNull);

      expect(Durum.apidan('PENDING'), Durum.beklemede);
      expect(Durum.apidan('PENDING', oncelikli: true), Durum.kritik);
      expect(Durum.apidan('RESOLVED'), Durum.cozuldu);
      expect(Durum.apidan('UNRATED'), Durum.cozuldu);
      expect(Durum.apidan('REJECTED'), Durum.reddedildi);
      expect(Kategori.apidan('BILINMEYEN'), Kategori.diger);
    });

    test('sıralama satırı: veri yoksa ortalama süre ve memnuniyet boş', () {
      final b = Belediye.fromJson({
        'municipalityId': 'm1',
        'name': 'Bornova Belediyesi',
        'city': 'İzmir',
        'score': 0.0,
        'satisfactionScore': 0.0,
        'avgResolutionHours': null,
        'monthlyResolved': 0,
      });
      expect(b.kisaAd, 'Bornova');
      expect(b.ortalamaGun, isNull);
      expect(b.memnuniyet, isNull);
      expect(Belediye.fromJson({'name': 'X', 'avgResolutionHours': 48}).ortalamaGun, 2);
    });
  });

  group('KentApi', () {
    test('sunucu hata mesajını ApiHatasi olarak verir', () async {
      final api = KentApi(istemci: MockClient((_) async => _json({'code': 'INVALID_BBOX', 'message': 'bbox'}, 400)));
      await expectLater(
        api.haritaPinleri(const Sinirlar(minLat: 0, maxLat: 1, minLng: 0, maxLng: 1)),
        throwsA(isA<ApiHatasi>().having((e) => e.kod, 'kod', 'INVALID_BBOX').having((e) => e.mesaj, 'mesaj', 'bbox')),
      );
    });

    test('401 gelince token yenilenip istek bir kez tekrarlanır', () async {
      final basliklar = <String?>[];
      final api = KentApi(
        istemci: MockClient((istek) async {
          basliklar.add(istek.headers['Authorization']);
          return istek.headers['Authorization'] == 'Bearer yeni'
              ? _json({'firstName': 'Ayşe'})
              : _json({'code': 'UNAUTHORIZED', 'message': 'expired'}, 401);
        }),
      )..token = 'eski';
      api.tokenYenile = () async => api.token = 'yeni';
      expect((await api.ben()).ad, 'Ayşe');
      expect(basliklar, ['Bearer eski', 'Bearer yeni']);
    });

    test('harita sorgusu bbox ve includeResolved gönderir', () async {
      late Uri adres;
      final api = KentApi(
        istemci: MockClient((istek) async {
          adres = istek.url;
          return _json([]);
        }),
      );
      await api.haritaPinleri(const Sinirlar(minLat: 38, maxLat: 39, minLng: 27, maxLng: 28));
      expect(adres.path, '/v1/reports/map');
      expect(adres.queryParameters, {
        'minLat': '38.0',
        'maxLat': '39.0',
        'minLng': '27.0',
        'maxLng': '28.0',
        'includeResolved': 'true',
      });
    });
  });

  Future<void> girisYap(WidgetTester tester, UygulamaDurumu durum, {required String kod}) async {
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
    await tester.enterText(find.byType(TextField), kod);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('giriş → doğrulama → /auth/verify → ana sayfada ihbarlarım', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final istekler = <String>[];
    final durum = UygulamaDurumu(
      api: KentApi(istemci: _sahteSunucu(istekler: istekler)),
      kimlik: SahteKimlik(),
    );

    // 000000 reddedilir
    await girisYap(tester, durum, kod: '000000');
    expect(find.text('Kod hatalı, tekrar dene.'), findsOneWidget);
    expect(durum.uyeMi, isFalse);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(durum.uyeMi, isTrue);
    expect(durum.api.token, 'jwt');
    expect(istekler, containsAll(['POST /v1/auth/verify', 'GET /v1/users/me', 'GET /v1/reports/mine']));
    expect(find.text('Sorun mu gördün?'), findsOneWidget);
    expect(find.text('Erzene Mah., Ankara Cd.'), findsOneWidget);

    // Lottie ve zamanlayıcılar sonsuz döndüğü için ağacı kaldırarak bitir.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('profil eksikse form açılır, tamamlanınca oturum açılır', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final istekler = <String>[];
    final durum = UygulamaDurumu(
      api: KentApi(istemci: _sahteSunucu(profilTamam: false, istekler: istekler)),
      kimlik: SahteKimlik(),
    );
    await girisYap(tester, durum, kod: '123456');
    await tester.pumpAndSettle();
    expect(find.text('Profilini tamamla'), findsOneWidget);
    expect(durum.uyeMi, isFalse);

    await tester.enterText(find.byType(TextField).at(0), 'Ayşe');
    await tester.enterText(find.byType(TextField).at(1), 'Yılmaz');
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.tap(find.text('Devam et'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(istekler, contains('POST /v1/users/complete-profile'));
    expect(durum.uyeMi, isTrue);
    expect(durum.profil?.adSoyad, 'Ayşe Yılmaz');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('misafir girişi profil sekmesinde "Misafir" gösterir', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final durum = UygulamaDurumu(api: KentApi(istemci: _sahteSunucu()), kimlik: SahteKimlik());
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
