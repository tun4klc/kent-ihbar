import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// SMS kodu gönderildikten sonra doğrulama için gereken bilgiler.
class KodOturumu {
  const KodOturumu({required this.telefon, required this.dogrulamaId, this.yenidenGonderme, this.otomatik = false});

  /// E.164 biçiminde, örn. `+905324182705`.
  final String telefon;
  final String dogrulamaId;
  final int? yenidenGonderme;

  /// Android kodu SMS'ten kendisi okuyup girişi tamamladıysa true; kod sormaya gerek yok.
  final bool otomatik;
}

class KimlikHatasi implements Exception {
  const KimlikHatasi(this.mesaj, {this.kodHatali = false});

  final String mesaj;
  final bool kodHatali;

  @override
  String toString() => 'KimlikHatasi: $mesaj';
}

/// Telefonla giriş. Uygulamada Firebase, testlerde sahte sağlayıcı kullanılır.
abstract class KimlikSaglayici {
  /// Giriş yapmış kullanıcının telefonu; yoksa null.
  String? get telefon;

  Future<KodOturumu> kodGonder(String telefon, {int? yenidenGonderme});

  /// Kodu doğrular, Firebase ID token'ı döner.
  Future<String> kodDogrula(KodOturumu oturum, String kod);

  /// Giriş yapmış kullanıcının ID token'ı; oturum yoksa null.
  Future<String?> idToken({bool yenile = false});

  Future<void> cikis();
}

/// Firebase Auth (proje `kent-66a81`) ile telefon doğrulaması.
class FirebaseKimlik implements KimlikSaglayici {
  FirebaseAuth get _auth {
    if (Firebase.apps.isEmpty) {
      throw const KimlikHatasi('Firebase bu platform için yapılandırılmamış. firebase_options.dart dosyasına bak.');
    }
    return FirebaseAuth.instance;
  }

  @override
  String? get telefon => Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.phoneNumber;

  @override
  Future<KodOturumu> kodGonder(String telefon, {int? yenidenGonderme}) {
    final sonuc = Completer<KodOturumu>();
    _auth
        .verifyPhoneNumber(
          phoneNumber: telefon,
          forceResendingToken: yenidenGonderme,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (kimlik) async {
            if (sonuc.isCompleted) return;
            try {
              await _auth.signInWithCredential(kimlik);
              sonuc.complete(KodOturumu(telefon: telefon, dogrulamaId: kimlik.verificationId ?? '', otomatik: true));
            } on FirebaseAuthException catch (e) {
              sonuc.completeError(_cevir(e));
            }
          },
          verificationFailed: (e) {
            if (!sonuc.isCompleted) sonuc.completeError(_cevir(e));
          },
          codeSent: (id, token) {
            if (!sonuc.isCompleted) {
              sonuc.complete(KodOturumu(telefon: telefon, dogrulamaId: id, yenidenGonderme: token));
            }
          },
          codeAutoRetrievalTimeout: (_) {},
        )
        .catchError((Object e) {
          if (!sonuc.isCompleted) sonuc.completeError(e is FirebaseAuthException ? _cevir(e) : e);
        });
    return sonuc.future;
  }

  @override
  Future<String> kodDogrula(KodOturumu oturum, String kod) async {
    try {
      final kimlik = PhoneAuthProvider.credential(verificationId: oturum.dogrulamaId, smsCode: kod);
      final giris = await _auth.signInWithCredential(kimlik);
      final token = await giris.user?.getIdToken();
      if (token == null) throw const KimlikHatasi('Giriş tamamlanamadı, tekrar dene.');
      return token;
    } on FirebaseAuthException catch (e) {
      throw _cevir(e);
    }
  }

  @override
  Future<String?> idToken({bool yenile = false}) async {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.getIdToken(yenile);
  }

  @override
  Future<void> cikis() async {
    if (Firebase.apps.isNotEmpty) await FirebaseAuth.instance.signOut();
  }

  static KimlikHatasi _cevir(FirebaseAuthException e) => switch (e.code) {
    'invalid-verification-code' => const KimlikHatasi('Kod hatalı, tekrar dene.', kodHatali: true),
    'session-expired' || 'code-expired' => const KimlikHatasi('Kodun süresi doldu. Yeni kod iste.'),
    'invalid-phone-number' => const KimlikHatasi('Telefon numarası geçersiz.'),
    'too-many-requests' => const KimlikHatasi('Çok fazla deneme yapıldı. Bir süre sonra tekrar dene.'),
    'network-request-failed' => const KimlikHatasi('İnternet bağlantını kontrol et.'),
    _ => KimlikHatasi('Doğrulama başarısız (${e.code}). ${e.message ?? ''}'.trim()),
  };
}
