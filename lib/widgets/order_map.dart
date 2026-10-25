import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models.dart';
import '../state/route_service.dart';
import '../theme.dart';
import 'brand.dart';

TileLayer osmTiles() =>
    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.delivery.delivery_app');

/// Paradas que le faltan al pedido: repartidor → negocio (si aún no recoge) → cliente.
List<LatLng> routeStopsFor(Order order, LatLng? rider) {
  final dest = LatLng(order.lat, order.lng);
  final b = order.business;
  final shop = (b?.lat != null && b?.lng != null) ? LatLng(b!.lat!, b.lng!) : null;
  final pickedUp = order.status == 'en_camino' || order.status == 'entregado';
  return [?rider, if (!pickedUp) ?shop, dest];
}

/// Mapa con el negocio, el destino, el repartidor y la ruta real por calle.
class OrderMap extends StatefulWidget {
  const OrderMap({super.key, required this.order, this.driver});

  final Order order;

  /// Posición del repartidor; si es null se usa la que reporta el pedido.
  final LatLng? driver;

  @override
  State<OrderMap> createState() => _OrderMapState();
}

class _OrderMapState extends State<OrderMap> {
  RouteResult? _route;
  String? _routeKey;
  String? _routeStatus;
  DateTime _lastFetch = DateTime(2000);

  LatLng? get _rider => widget.driver ?? (widget.order.driverLat != null ? LatLng(widget.order.driverLat!, widget.order.driverLng!) : null);

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  @override
  void didUpdateWidget(OrderMap old) {
    super.didUpdateWidget(old);
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    if (!widget.order.isActive) return;
    final stops = routeStopsFor(widget.order, _rider);
    final key = stops.map((p) => '${p.latitude.toStringAsFixed(4)},${p.longitude.toStringAsFixed(4)}').join('|');
    if (key == _routeKey) return;
    // Mientras el repartidor se mueve, recalcula como máximo cada 20 s (salvo que cambie el estado).
    final sameStatus = _routeStatus == widget.order.status;
    if (sameStatus && DateTime.now().difference(_lastFetch) < const Duration(seconds: 20)) return;
    _routeKey = key;
    _routeStatus = widget.order.status;
    _lastFetch = DateTime.now();
    final r = await RouteService.instance.route(stops);
    if (mounted && key == _routeKey) setState(() => _route = r);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final dest = LatLng(order.lat, order.lng);
    final b = order.business;
    final shop = (b?.lat != null && b?.lng != null) ? LatLng(b!.lat!, b.lng!) : null;
    final rider = _rider;
    final points = [dest, ?shop, ?rider];

    return FlutterMap(
      key: ValueKey('${order.id}-${order.status}'),
      options: MapOptions(
        initialCameraFit: points.length > 1
            ? CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(56), maxZoom: 16)
            : null,
        initialCenter: dest,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        osmTiles(),
        if (_route != null && order.isActive)
          PolylineLayer(
            polylines: [
              // Borde blanco y línea de marca, como en las apps de delivery.
              Polyline(points: _route!.points, color: Colors.white, strokeWidth: 8),
              Polyline(points: _route!.points, color: AppColors.primary, strokeWidth: 5),
            ],
          )
        else if (rider != null && order.isActive)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [rider, dest],
                color: AppColors.primary,
                strokeWidth: 4,
                pattern: StrokePattern.dashed(segments: const [10, 8]),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (shop != null) _pin(shop, Icons.storefront_rounded, AppColors.accent),
            _pin(dest, Icons.home_rounded, AppColors.primaryDark),
            if (rider != null)
              Marker(
                point: rider,
                width: 54,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.quinde, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const AppLogo(size: 36),
                ),
              ),
          ],
        ),
        const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap'), TextSourceAttribution('OSRM')]),
      ],
    );
  }

  Marker _pin(LatLng p, IconData icon, Color color) => Marker(
    point: p,
    width: 44,
    height: 44,
    child: Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

/// Tiempo estimado que muestra el seguimiento del pedido.
class EtaBadge extends StatefulWidget {
  const EtaBadge({super.key, required this.order});

  final Order order;

  @override
  State<EtaBadge> createState() => _EtaBadgeState();
}

class _EtaBadgeState extends State<EtaBadge> {
  RouteResult? _route;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(EtaBadge old) {
    super.didUpdateWidget(old);
    if (old.order.driverLat != widget.order.driverLat || old.order.status != widget.order.status) _load();
  }

  Future<void> _load() async {
    final o = widget.order;
    final rider = o.driverLat != null ? LatLng(o.driverLat!, o.driverLng!) : null;
    if (!o.isActive || rider == null) return;
    final r = await RouteService.instance.route(routeStopsFor(o, rider));
    if (mounted) setState(() => _route = r);
  }

  @override
  Widget build(BuildContext context) {
    final r = _route;
    if (r == null || !widget.order.isActive || widget.order.driverLat == null) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    final label = widget.order.status == 'en_camino' ? 'Llega en ~${r.minutes} min' : 'Repartidor a ~${r.minutes} min';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(30), boxShadow: AppColors.softShadow),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text('  ·  ${r.km} km', style: t.labelMedium?.copyWith(color: AppColors.muted)),
        ],
      ),
    );
  }
}
