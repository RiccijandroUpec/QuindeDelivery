import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import 'driver_order_screen.dart';

class MyDeliveriesScreen extends StatefulWidget {
  const MyDeliveriesScreen({super.key});

  @override
  State<MyDeliveriesScreen> createState() => MyDeliveriesScreenState();
}

class MyDeliveriesScreenState extends State<MyDeliveriesScreen> {
  List<Order>? _orders;
  String? _error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final j = await Api.instance.get('/driver/orders');
      if (mounted) {
        setState(() {
          _orders = (j['data'] as List).map((o) => Order.fromJson(o)).toList();
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders;
    final active = orders?.where((o) => o.isActive).toList() ?? [];
    final done = orders?.where((o) => !o.isActive).toList() ?? [];
    final earned = done.where((o) => o.status == 'entregado').fold(0.0, (s, o) => s + o.deliveryFee);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis entregas')),
      body: RefreshIndicator(
        onRefresh: load,
        child: orders == null
            ? (_error != null
                  ? ListView(
                      children: [EmptyState(icon: Icons.wifi_off_rounded, title: 'Sin conexión', message: _error)],
                    )
                  : const BirdLoader())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _stat('Entregas', '${done.where((o) => o.status == 'entregado').length}', Icons.check_circle_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _stat('Ganado en envíos', money.format(earned), Icons.savings_rounded)),
                    ],
                  ),
                  _title('En curso'),
                  if (active.isEmpty)
                    Text('No tienes entregas activas.', style: TextStyle(color: AppColors.muted))
                  else
                    for (final o in active) _tile(o),
                  _title('Historial'),
                  if (done.isEmpty)
                    Text('Aún no completas entregas.', style: TextStyle(color: AppColors.muted))
                  else
                    for (final o in done) _tile(o),
                ],
              ),
      ),
    );
  }

  Widget _title(String s) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(s, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
  );

  Widget _stat(String label, String value, IconData icon) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: PolyBackground(
        seed: label.length,
        cell: 45,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                value,
                style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              Text(label, style: t.bodySmall?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(Order o) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => DriverOrderScreen(initial: o)));
            load();
          },
          title: Text('#${o.id} · ${o.business?.name ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(DateFormat("d MMM, HH:mm", 'es').format(o.createdAt), style: t.bodySmall?.copyWith(color: AppColors.muted)),
              ],
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(o.status),
              const SizedBox(height: 4),
              Text(
                money.format(o.deliveryFee),
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
