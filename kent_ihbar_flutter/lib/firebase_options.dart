// Kent API'nin Firebase projesi: kent-66a81.
// Android değerleri projenin google-services.json dosyasından alındı.
// iOS için Firebase konsolunda iOS uygulaması eklenip `flutterfire configure` çalıştırılmalı.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// Bu platform yapılandırılmamışsa null; uygulama açılır ama telefonla giriş çalışmaz.
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      _ => null,
    };
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBUChtZOW8WFZCV2gDZCGuQIJzxHB7vBsI',
    appId: '1:324246946708:android:970e3b1e5301e633c28581',
    messagingSenderId: '324246946708',
    projectId: 'kent-66a81',
    storageBucket: 'kent-66a81.firebasestorage.app',
  );
}
