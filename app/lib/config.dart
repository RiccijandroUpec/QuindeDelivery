import 'package:flutter/foundation.dart';

class AppConfig {
  static const appName = 'Quinde';

  /// Se puede sobreescribir con: flutter run --dart-define=API_URL=http://192.168.1.10:8000/api
  static const _envUrl = String.fromEnvironment('API_URL');

  static String get apiUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (kIsWeb) return 'http://localhost:8000/api';
    // El emulador de Android ve la PC en 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api';
  }

  /// Servidor de tiempo real (Laravel Reverb). Por defecto usa el mismo host que la API.
  /// En producción: --dart-define=REVERB_HOST=ws.midominio.com --dart-define=REVERB_PORT=443 --dart-define=REVERB_KEY=...
  static const _reverbHost = String.fromEnvironment('REVERB_HOST');
  static const reverbPort = int.fromEnvironment('REVERB_PORT', defaultValue: 8080);
  static const reverbKey = String.fromEnvironment('REVERB_KEY', defaultValue: '796fe56d84a34b86d891');

  static String get reverbHost => _reverbHost.isNotEmpty ? _reverbHost : Uri.parse(apiUrl).host;
  static String get reverbScheme => Uri.parse(apiUrl).scheme == 'https' ? 'wss' : 'ws';

  /// Rutas por calle (OSRM). El servidor de demostración sirve para pruebas; en producción usa uno propio.
  static const osrmUrl = String.fromEnvironment('OSRM_URL', defaultValue: 'https://router.project-osrm.org');

  /// Centro por defecto del mapa (Quito).
  static const defaultLat = -0.1807;
  static const defaultLng = -78.4678;
}
