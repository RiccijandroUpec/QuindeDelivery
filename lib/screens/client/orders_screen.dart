import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => OrdersScreenState();
}

class OrdersScreenState extends State<OrdersScreen> {
  List<Order>? _orders;
  String? _error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final j = await Api.instance.get('/orders');
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
    final t = Theme.of(context).textTheme;
    final orders = _orders;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: RefreshIndicator(
        onRefresh: load,
        child: orders == null
            ? (_error != null
                ? ListView(children: [EmptyState(icon: Icons.wifi_off_rounded, title: 'Sin conexión', message: _error)])
                : const BirdLoader())
            : orders.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    EmptyState(icon: Icons.receipt_long_outlined, title: 'Aún no tienes pedidos', message: 'Cuando pidas algo, aparecerá aquí.'),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final o = orders[i];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: o.id)));
                            load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 54,
                                    height: 54,
                                    child: PolyImage(url: o.business?.logoUrl, seed: o.business?.id ?? 0, iconSize: 22),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(o.business?.name ?? 'Pedido #${o.id}', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                      Text(
                                        '${DateFormat("d MMM, HH:mm", 'es').format(o.createdAt)} · ${o.itemCount} productos',
                                        style: t.bodySmall?.copyWith(color: AppColors.muted),
                                      ),
                                      const SizedBox(height: 6),
                                      StatusChip(o.status),
                                    ],
                                  ),
                                ),
                                Text(money.format(o.total), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
