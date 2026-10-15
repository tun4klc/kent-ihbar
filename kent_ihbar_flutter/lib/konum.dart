import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Konum izni ve son bilinen konum.
class KonumYoneticisi extends ChangeNotifier with WidgetsBindingObserver {
  KonumYoneticisi() {
    WidgetsBinding.instance.addObserver(this);
    _yetkiyiOku();
  }

  LocationPermission _yetki = LocationPermission.unableToDetermine;
  LatLng? konum;

  bool get izinVar => _yetki == LocationPermission.whileInUse || _yetki == LocationPermission.always;
  bool get reddedildi => _yetki == LocationPermission.deniedForever;

  /// İzin isteğini sistem penceresiyle açar; reddedilmişse Ayarlar'a götürür.
  Future<void> izinIste() async {
    if (reddedildi) {
      await Geolocator.openAppSettings();
      return;
    }
    try {
      _yetki = await Geolocator.requestPermission();
    } catch (_) {
      return;
    }
    notifyListeners();
    if (izinVar) unawaited(_konumuAl());
  }

  /// Ayarlar'dan dönünce yetkiyi yeniden okur.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _yetkiyiOku();
  }

  Future<void> _yetkiyiOku() async {
    try {
      _yetki = await Geolocator.checkPermission();
    } catch (_) {
      return;
    }
    notifyListeners();
    if (izinVar && konum == null) unawaited(_konumuAl());
  }

  Future<void> _konumuAl() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      konum = LatLng(p.latitude, p.longitude);
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
