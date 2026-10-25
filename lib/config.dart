import 'package:flutter/foundation.dart';

class AppConfig {
  static const appName = 'Colibrí';

  /// Se puede sobreescribir con: flutter run --dart-define=API_URL=http://192.168.1.10:8000/api
  static const _envUrl = String.fromEnvironment('API_URL');

  static String get apiUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (kIsWeb) return 'http://localhost:8000/api';
    // El emulador de Android ve la PC en 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000/api';
    return 'http://localhost:8000/api';
  }

  /// Centro por defecto del mapa (Quito).
  static const defaultLat = -0.1807;
  static const defaultLng = -78.4678;
}
