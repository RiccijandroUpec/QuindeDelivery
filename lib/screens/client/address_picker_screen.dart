import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../api.dart';
import '../../config.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/order_map.dart';

/// Mueve el mapa para ubicar el pin y guarda la dirección.
class AddressPickerScreen extends StatefulWidget {
  const AddressPickerScreen({super.key});

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  final _map = MapController();
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _reference = TextEditingController();
  String _label = 'Casa';
  LatLng _center = const LatLng(AppConfig.defaultLat, AppConfig.defaultLng);
  bool _saving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _locate(silent: true);
  }

  Future<void> _locate({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw ApiException('Permiso de ubicación denegado.');
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 10)));
      _center = LatLng(pos.latitude, pos.longitude);
      _map.move(_center, 17);
    } catch (e) {
      if (!silent && mounted) showMessage(context, 'No pudimos obtener tu ubicación. Mueve el mapa manualmente.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final j = await Api.instance.post('/addresses', {
        'label': _label,
        'address': _address.text.trim(),
        'reference': _reference.text.trim(),
        'lat': _center.latitude,
        'lng': _center.longitude,
      });
      if (mounted) Navigator.pop(context, Address.fromJson(j));
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva dirección')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 15,
                    onPositionChanged: (camera, _) => _center = camera.center,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  ),
                  children: [osmTiles()],
                ),
                // Pin fijo en el centro: el usuario mueve el mapa debajo.
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 48,
                        color: AppColors.accent,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    onPressed: _locating ? null : _locate,
                    child: _locating
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.my_location_rounded, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.card,
            child: SafeArea(
              top: false,
              child: Form(
                key: _form,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Mueve el mapa hasta el punto exacto de entrega', style: t.bodySmall?.copyWith(color: AppColors.muted)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final l in ['Casa', 'Trabajo', 'Otro'])
                            ChoiceChip(label: Text(l), selected: _label == l, onSelected: (_) => setState(() => _label = l)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _address,
                        decoration: const InputDecoration(labelText: 'Calle principal y secundaria', isDense: true),
                        validator: (v) => (v == null || v.trim().length < 4) ? 'Ingresa la dirección' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _reference,
                        decoration: const InputDecoration(labelText: 'Referencia (casa, piso, color...)', isDense: true),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Text('Guardar dirección'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
