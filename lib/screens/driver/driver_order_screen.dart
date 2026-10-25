import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../api.dart';
import '../../models.dart';
import '../../state/location_service.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/order_map.dart';
import '../../widgets/order_summary.dart';

class DriverOrderScreen extends StatefulWidget {
  const DriverOrderScreen({super.key, required this.initial});

  final Order initial;

  @override
  State<DriverOrderScreen> createState() => _DriverOrderScreenState();
}

class _DriverOrderScreenState extends State<DriverOrderScreen> {
  late Order _order = widget.initial;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Mientras el negocio prepara, revisa si ya está listo.
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (['aceptado', 'preparando'].contains(_order.status)) _refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final j = await Api.instance.get('/driver/orders/${_order.id}');
      if (mounted) setState(() => _order = Order.fromJson(j));
    } catch (_) {}
  }

  Future<void> _setStatus(String status) async {
    if (status == 'entregado') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('¿Confirmas la entrega?'),
          content: Text(_order.paymentMethod == 'efectivo'
              ? 'Recuerda cobrar ${money.format(_order.total)} en efectivo.'
              : 'El pago fue por transferencia.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Aún no')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí, entregado')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    try {
      final j = await Api.instance.post('/driver/orders/${_order.id}/status', {'status': status});
      LocationService.instance.pushNow();
      if (!mounted) return;
      setState(() => _order = Order.fromJson(j));
      if (status == 'entregado') {
        showMessage(context, '¡Entrega completada! 🎉', error: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = _order;
    final change = (o.paymentMethod == 'efectivo' && o.cashAmount != null) ? o.cashAmount! - o.total : null;

    String? action;
    String? label;
    if (o.status == 'listo') {
      action = 'en_camino';
      label = 'Ya lo recogí · Ir al cliente';
    } else if (o.status == 'en_camino') {
      action = 'entregado';
      label = 'Marcar como entregado';
    }

    return Scaffold(
      appBar: AppBar(title: Text('Entrega #${o.id}'), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))]),
      bottomNavigationBar: action == null
          ? (['aceptado', 'preparando'].contains(o.status)
              ? SafeArea(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.cyan.withValues(alpha: .08), borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Icon(Icons.soup_kitchen_rounded, color: AppColors.cyan),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('El negocio está preparando el pedido. Podrás recogerlo cuando lo marque como listo.',
                            style: t.bodySmall?.copyWith(color: AppColors.cyan, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                )
              : null)
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: _busy ? null : () => _setStatus(action!),
                  style: action == 'entregado' ? FilledButton.styleFrom(backgroundColor: AppColors.accent) : null,
                  child: _busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(label!),
                ),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 260,
              child: ValueListenableBuilder<LatLng?>(
                valueListenable: LocationService.instance.position,
                builder: (_, me, _) => OrderMap(order: o, driver: me),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(o.status == 'en_camino' ? 'Lleva el pedido al cliente' : 'Recoge el pedido en el negocio',
                          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    StatusChip(o.status),
                  ]),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(backgroundColor: AppColors.accent, child: Icon(Icons.storefront_rounded, color: Colors.white)),
                    title: Text(o.business?.name ?? ''),
                    subtitle: Text([o.business?.address, o.business?.phone].whereType<String>().join(' · ')),
                    trailing: CallButton(phone: o.business?.phone, tooltip: 'Llamar al negocio'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(backgroundColor: AppColors.primaryDark, child: Icon(Icons.person_rounded, color: Colors.white)),
                    title: Text(o.clientName ?? 'Cliente'),
                    subtitle: Text([o.clientPhone, o.address, o.reference].whereType<String>().where((s) => s.isNotEmpty).join(' · ')),
                    trailing: CallButton(phone: o.clientPhone, tooltip: 'Llamar al cliente'),
                  ),
                ],
              ),
            ),
          ),
          if (o.paymentMethod == 'efectivo') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: .1), borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                const Icon(Icons.payments_rounded, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cobrar ${money.format(o.total)} en efectivo'
                    '${change != null && change > 0 ? '\nLleva cambio de ${money.format(change)} (paga con ${money.format(o.cashAmount)})' : ''}',
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          OrderSummary(order: o),
        ],
      ),
    );
  }
}
