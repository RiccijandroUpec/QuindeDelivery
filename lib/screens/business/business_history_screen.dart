import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/order_summary.dart';

/// Últimos pedidos del negocio con el resumen del día.
class BusinessHistoryScreen extends StatefulWidget {
  const BusinessHistoryScreen({super.key});

  @override
  State<BusinessHistoryScreen> createState() => BusinessHistoryScreenState();
}

class BusinessHistoryScreenState extends State<BusinessHistoryScreen> {
  List<Order>? _orders;
  String? _error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final j = await Api.instance.get('/business/orders');
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

  void _open(Order o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
        builder: (c, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Row(children: [
              Text('Pedido #${o.id}', style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              StatusChip(o.status),
            ]),
            if (o.status == 'cancelado' && (o.cancelReason?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text('Motivo: ${o.cancelReason}', style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            OrderSummary(order: o),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final orders = _orders;
    final now = DateTime.now();
    final today = orders?.where((o) => DateUtils.isSameDay(o.createdAt, now) && o.status != 'cancelado').toList() ?? [];
    final sales = today.fold(0.0, (s, o) => s + o.subtotal);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: RefreshIndicator(
        onRefresh: load,
        child: orders == null
            ? (_error != null
                ? ListView(children: [EmptyState(icon: Icons.wifi_off_rounded, title: 'Sin conexión', message: _error)])
                : const BirdLoader())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(children: [
                    Expanded(child: _stat('Pedidos hoy', '${today.length}', Icons.receipt_long_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _stat('Ventas hoy', money.format(sales), Icons.attach_money_rounded)),
                  ]),
                  const SizedBox(height: 16),
                  if (orders.isEmpty)
                    const EmptyState(icon: Icons.history_rounded, title: 'Aún no tienes pedidos')
                  else
                    for (final o in orders)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => _open(o),
                          title: Text('#${o.id} · ${o.clientName ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${DateFormat('d MMM, HH:mm', 'es').format(o.createdAt)} · ${o.itemCount} productos'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(money.format(o.subtotal), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              StatusChip(o.status),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(value, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: t.bodySmall?.copyWith(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
