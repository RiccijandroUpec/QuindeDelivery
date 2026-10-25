import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../api.dart';

/// Envía la ubicación del repartidor al servidor mientras está en línea.
class LocationService {
  LocationService._();
  static final instance = LocationService._();

  final position = ValueNotifier<LatLng?>(null);
  final online = ValueNotifier<bool>(false);
  Timer? _timer;

  Future<String?> goOnline() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return 'Necesitamos tu ubicación para que los clientes vean dónde vas.';
    }
    online.value = true;
    await _tick();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _tick());
    return null;
  }

  void goOffline() {
    _timer?.cancel();
    online.value = false;
  }

  /// Fuerza un envío inmediato (por ejemplo al aceptar un pedido).
  Future<void> pushNow() => online.value ? _tick() : Future.value();

  Future<void> _tick() async {
    try {
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)));
      position.value = LatLng(p.latitude, p.longitude);
      await Api.instance.post('/driver/location', {'lat': p.latitude, 'lng': p.longitude});
    } catch (e) {
      debugPrint('Ubicación no enviada: $e');
    }
  }
}
