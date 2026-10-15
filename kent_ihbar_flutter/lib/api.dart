import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'model.dart';

/// API'den dönen ya da bağlantıda oluşan hata. [mesaj] kullanıcıya gösterilebilir.
class ApiHatasi implements Exception {
  const ApiHatasi(this.mesaj, {this.durumKodu, this.kod});

  final String mesaj;
  final int? durumKodu;
  final String? kod;

  bool get yetkisiz => durumKodu == 401;

  @override
  String toString() => 'ApiHatasi($durumKodu, $kod): $mesaj';
}

/// Kent API istemcisi (`mobil-api.md`). Swagger: https://kent-api.onrender.com/swagger-ui.html
class KentApi {
  KentApi({http.Client? istemci, String? taban})
    : _istemci = istemci ?? http.Client(),
      taban = taban ?? varsayilanTaban;

  /// Başka bir ortam için: `--dart-define=API_BASE_URL=https://.../v1`
  static const varsayilanTaban = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://kent-api.onrender.com/v1',
  );

  /// Sunucu ücretsiz planda uyuyor; ilk istek dakikalar sürebiliyor.
  static const zamanAsimi = Duration(seconds: 90);

  final http.Client _istemci;
  final String taban;

  /// `/auth/verify`'dan alınan backend JWT'si (24 saat geçerli).
  String? token;

  /// 401 alınınca yeni JWT üretir (Firebase idToken → `/auth/verify`). Null dönerse oturum kapanmıştır.
  Future<String?> Function()? tokenYenile;

  Uri _adres(String yol, [Map<String, Object?>? sorgu]) {
    final temiz = <String, String>{
      for (final e in (sorgu ?? const {}).entries)
        if (e.value != null) e.key: e.value.toString(),
    };
    return Uri.parse('$taban$yol').replace(queryParameters: temiz.isEmpty ? null : temiz);
  }

  /// `/v1/media/files/...` gibi göreli medya adreslerini tam adrese çevirir.
  String medyaAdresi(String adres) {
    if (adres.startsWith('http')) return adres;
    final kok = Uri.parse(taban);
    return kok.replace(path: adres.startsWith('/') ? adres : '${kok.path}/$adres', query: null).toString();
  }

  Future<dynamic> _istek(
    String yontem,
    String yol, {
    Map<String, Object?>? sorgu,
    Object? govde,
    bool yetkili = false,
    bool yenidenDene = true,
  }) async {
    final basliklar = {
      'Accept': 'application/json',
      if (govde != null) 'Content-Type': 'application/json',
      if (yetkili && token != null) 'Authorization': 'Bearer $token',
    };
    final istek = http.Request(yontem, _adres(yol, sorgu))..headers.addAll(basliklar);
    if (govde != null) istek.body = jsonEncode(govde);

    final http.Response yanit;
    try {
      yanit = await http.Response.fromStream(await _istemci.send(istek).timeout(zamanAsimi));
    } on TimeoutException {
      throw const ApiHatasi('Sunucu yanıt vermedi. Biraz sonra tekrar dene.');
    } on http.ClientException {
      throw const ApiHatasi('Sunucuya ulaşılamadı. İnternet bağlantını kontrol et.');
    }

    if (yanit.statusCode == 401 && yetkili && yenidenDene && tokenYenile != null) {
      if (await tokenYenile!() != null) {
        return _istek(yontem, yol, sorgu: sorgu, govde: govde, yetkili: true, yenidenDene: false);
      }
    }

    final metin = utf8.decode(yanit.bodyBytes);
    final veri = metin.isEmpty ? null : _jsonCoz(metin);
    if (yanit.statusCode >= 200 && yanit.statusCode < 300) return veri;

    final hata = veri is Map ? veri : const {};
    throw ApiHatasi(
      (hata['message'] as String?) ?? 'Beklenmeyen bir hata oluştu (${yanit.statusCode}).',
      durumKodu: yanit.statusCode,
      kod: hata['code'] as String?,
    );
  }

  static dynamic _jsonCoz(String metin) {
    try {
      return jsonDecode(metin);
    } on FormatException {
      return null;
    }
  }

  static List<Map<String, dynamic>> _liste(dynamic v) => [
    for (final e in (v as List? ?? const [])) Map<String, dynamic>.from(e as Map),
  ];

  // MARK: Kimlik

  /// Firebase idToken → backend JWT. [token]'ı da günceller.
  Future<({String token, bool profilTamam})> dogrula(String idToken) async {
    final j = await _istek('POST', '/auth/verify', govde: {'idToken': idToken}, yenidenDene: false) as Map;
    token = j['token'] as String;
    return (token: token!, profilTamam: j['profileCompleted'] as bool? ?? false);
  }

  Future<void> cikis() async {
    try {
      await _istek('POST', '/auth/logout', yetkili: true, yenidenDene: false);
    } finally {
      token = null;
    }
  }

  Future<Kullanici> ben() async => Kullanici.fromJson(await _istek('GET', '/users/me', yetkili: true) as Map);

  Future<Kullanici> profilTamamla({
    required String ad,
    required String soyad,
    String? eposta,
    required bool sozlesmeler,
    bool pazarlama = false,
  }) async {
    final j = await _istek(
      'POST',
      '/users/complete-profile',
      yetkili: true,
      govde: {
        'firstName': ad,
        'lastName': soyad,
        if (eposta != null && eposta.isNotEmpty) 'email': eposta,
        'kvkkAccepted': sozlesmeler,
        'privacyPolicyAccepted': sozlesmeler,
        'termsAccepted': sozlesmeler,
        'marketingAccepted': pazarlama,
      },
    );
    return Kullanici.fromJson(j as Map);
  }

  // MARK: İhbarlar

  /// Haritadaki pinler (token gerekmez).
  Future<List<Ihbar>> haritaPinleri(Sinirlar s, {bool cozulenlerDahil = true}) async {
    final j = await _istek(
      'GET',
      '/reports/map',
      sorgu: {
        'minLat': s.minLat,
        'maxLat': s.maxLat,
        'minLng': s.minLng,
        'maxLng': s.maxLng,
        'includeResolved': cozulenlerDahil,
      },
    );
    return _liste(j).map(Ihbar.fromJson).toList();
  }

  Future<List<Ihbar>> ihbarlarim({int sayfa = 0, int boyut = 50}) async {
    final j = await _istek('GET', '/reports/mine', yetkili: true, sorgu: {'page': sayfa, 'size': boyut}) as Map;
    return _liste(j['content']).map((e) => Ihbar.fromJson(e, benim: true)).toList();
  }

  /// Tek ihbarın ayrıntısı (token gerekmez).
  Future<Ihbar> ihbar(String id) async => Ihbar.fromJson(
    Map<String, dynamic>.from(await _istek('GET', '/reports/public/${Uri.encodeComponent(id)}') as Map),
  );

  Future<Ihbar> ihbarOlustur({
    required Kategori kategori,
    required double lat,
    required double lng,
    required String belediyeId,
    String? baslik,
    String? aciklama,
    String? adres,
    String? sehir,
    String? ilce,
    String? belediyeAdi,
    List<String> medyaAnahtarlari = const [],
  }) async {
    final j = await _istek(
      'POST',
      '/reports',
      yetkili: true,
      govde: {
        'category': kategori.api,
        'lat': lat,
        'lng': lng,
        'municipalityId': belediyeId,
        'isAnonymous': false,
        'title': ?baslik,
        'description': ?aciklama,
        'address': ?adres,
        'city': ?sehir,
        'district': ?ilce,
        'municipalityName': ?belediyeAdi,
        'mediaKeys': medyaAnahtarlari,
      },
    );
    return Ihbar.fromJson(Map<String, dynamic>.from(j as Map), benim: true);
  }

  // MARK: Medya

  /// Fotoğrafı geçici olarak yükler ve ihbara eklenecek anahtarı döner.
  /// İhbar oluşturulunca dosya kalıcı hale gelir.
  Future<String> fotoYukle(Uint8List veri, {String icerikTuru = 'image/jpeg'}) async {
    final j = await _istek(
      'POST',
      '/media/upload-url',
      yetkili: true,
      govde: {'purpose': 'REPORT', 'contentType': icerikTuru, 'count': 1},
    );
    final yuva = _liste(j).first;
    final hedef = Uri.parse(medyaAdresi(yuva['uploadUrl'] as String));
    final kendiSunucumuz = hedef.host == Uri.parse(taban).host;
    final http.Response yanit;
    try {
      yanit = await _istemci
          .put(
            hedef,
            headers: {
              'Content-Type': icerikTuru,
              if (kendiSunucumuz && token != null) 'Authorization': 'Bearer $token',
            },
            body: veri,
          )
          .timeout(zamanAsimi);
    } on TimeoutException {
      throw const ApiHatasi('Fotoğraf yüklenemedi: sunucu yanıt vermedi.');
    } on http.ClientException {
      throw const ApiHatasi('Fotoğraf yüklenemedi. İnternet bağlantını kontrol et.');
    }
    if (yanit.statusCode < 200 || yanit.statusCode >= 300) {
      throw ApiHatasi('Fotoğraf yüklenemedi (${yanit.statusCode}).', durumKodu: yanit.statusCode);
    }
    return yuva['key'] as String;
  }

  // MARK: Belediyeler

  Future<Sayfa<Belediye>> siralama({
    required String olcut,
    String? sehir,
    String? arama,
    int sayfa = 0,
    int boyut = 50,
  }) async {
    final j = await _istek(
      'GET',
      '/leaderboard',
      sorgu: {
        'sort': olcut,
        'city': sehir,
        if (arama != null && arama.isNotEmpty) 'q': arama,
        'page': sayfa,
        'size': boyut,
      },
    ) as Map;
    return Sayfa(
      ogeler: _liste(j['content']).map(Belediye.fromJson).toList(),
      toplam: (j['totalElements'] as num?)?.toInt() ?? 0,
      sayfa: (j['number'] as num?)?.toInt() ?? sayfa,
      sayfaSayisi: (j['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  /// Belediye listesi. Sunucu sayfa boyutunu en çok 100 ile sınırlıyor.
  Future<Sayfa<BelediyeKaydi>> belediyeler({String? arama, String? sehir, int sayfa = 0, int boyut = 100}) async {
    final j = await _istek(
      'GET',
      '/municipalities',
      sorgu: {if (arama != null && arama.isNotEmpty) 'q': arama, 'city': sehir, 'page': sayfa, 'size': boyut},
    ) as Map;
    return Sayfa(
      ogeler: _liste(j['content']).map(BelediyeKaydi.fromJson).toList(),
      toplam: (j['totalElements'] as num?)?.toInt() ?? 0,
      sayfa: (j['number'] as num?)?.toInt() ?? sayfa,
      sayfaSayisi: (j['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  /// Bütün belediyeler (1407 kayıt, 100'erli sayfalar paralel çekilir).
  Future<List<BelediyeKaydi>> tumBelediyeler() async {
    final ilk = await belediyeler();
    final kalan = await Future.wait([for (var s = 1; s < ilk.sayfaSayisi; s++) belediyeler(sayfa: s)]);
    return [...ilk.ogeler, for (final s in kalan) ...s.ogeler];
  }
}

class Sayfa<T> {
  const Sayfa({required this.ogeler, required this.toplam, required this.sayfa, required this.sayfaSayisi});

  final List<T> ogeler;
  final int toplam;
  final int sayfa;
  final int sayfaSayisi;

  bool get sonSayfa => sayfa + 1 >= sayfaSayisi;
}
