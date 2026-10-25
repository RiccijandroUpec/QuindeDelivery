import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models.dart';
import '../theme.dart';
import 'brand.dart';

TileLayer osmTiles() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.delivery.delivery_app',
    );

/// Mapa con el negocio, el destino y (si existe) el repartidor.
class OrderMap extends StatelessWidget {
  const OrderMap({super.key, required this.order, this.driver});

  final Order order;

  /// Posición del repartidor; si es null se usa la que reporta el pedido.
  final LatLng? driver;

  @override
  Widget build(BuildContext context) {
    final dest = LatLng(order.lat, order.lng);
    final b = order.business;
    final shop = (b?.lat != null && b?.lng != null) ? LatLng(b!.lat!, b.lng!) : null;
    final rider = driver ?? (order.driverLat != null ? LatLng(order.driverLat!, order.driverLng!) : null);
    final points = [dest, ?shop, ?rider];

    return FlutterMap(
      key: ValueKey('${order.id}-${rider?.latitude}-${rider?.longitude}'),
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
        if (rider != null)
          PolylineLayer(polylines: [
            Polyline(points: [rider, dest], color: AppColors.primary, strokeWidth: 4, pattern: StrokePattern.dashed(segments: const [10, 8])),
          ]),
        MarkerLayer(markers: [
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
                  border: Border.all(color: AppColors.primary, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                padding: const EdgeInsets.all(6),
                child: const AppLogo(size: 36),
              ),
            ),
        ]),
        const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap')]),
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
