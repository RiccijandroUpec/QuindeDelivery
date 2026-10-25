import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config.dart';

class RouteResult {
  const RouteResult(this.points, this.seconds, this.meters);

  final List<LatLng> points;
  final double seconds;
  final double meters;

  int get minutes => (seconds / 60).ceil();
  String get km => (meters / 1000).toStringAsFixed(1);
}

/// Rutas reales por calle con OSRM. Guarda en memoria las últimas consultas.
class RouteService {
  RouteService._();
  static final instance = RouteService._();

  final _cache = <String, RouteResult?>{};

  /// Ruta que pasa por [stops] en orden. Devuelve null si no hay conexión con OSRM.
  Future<RouteResult?> route(List<LatLng> stops) async {
    if (stops.length < 2) return null;
    // Redondeo a ~10 m para reutilizar la ruta mientras el repartidor casi no se mueve.
    final coords = stops.map((p) => '${p.longitude.toStringAsFixed(4)},${p.latitude.toStringAsFixed(4)}').join(';');
    if (_cache.containsKey(coords)) return _cache[coords];

    RouteResult? result;
    try {
      final res = await http
          .get(Uri.parse('${AppConfig.osrmUrl}/route/v1/driving/$coords?overview=full&geometries=geojson'))
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body);
      final route = (body['routes'] as List?)?.firstOrNull;
      if (route != null) {
        final line = (route['geometry']['coordinates'] as List)
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        result = RouteResult(line, (route['duration'] as num).toDouble(), (route['distance'] as num).toDouble());
      }
    } catch (_) {
      return null; // sin conexión: no se guarda, se reintenta la próxima vez
    }
    if (_cache.length > 50) _cache.remove(_cache.keys.first);
    _cache[coords] = result;
    return result;
  }
}
