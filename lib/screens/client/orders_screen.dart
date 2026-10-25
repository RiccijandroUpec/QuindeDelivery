import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../state/cart_state.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import 'checkout_screen.dart';
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

  int? _repeating;

  Future<void> _repeat(Order o) async {
    final cart = context.read<CartState>();
    if (!cart.isEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('¿Reemplazar tu carrito?'),
          content: const Text('Se quitarán los productos que tienes ahora.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí, reemplazar')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _repeating = o.id);
    try {
      final b = Business.fromJson(await Api.instance.get('/businesses/${o.business!.id}'));
      if (!b.isOpen) throw ApiException('${b.name} está cerrado en este momento.');
      final missing = cart.repeat(b, o.items);
      if (!mounted) return;
      if (cart.isEmpty) {
        showMessage(context, 'Ninguno de esos productos está disponible ahora.');
        return;
      }
      if (missing > 0) showMessage(context, '$missing producto(s) ya no están disponibles.', error: false);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _repeating = null);
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
                  ? ListView(
                      children: [EmptyState(icon: Icons.wifi_off_rounded, title: 'Sin conexión', message: _error)],
                    )
                  : const BirdLoader())
            : orders.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Aún no tienes pedidos',
                    message: 'Cuando pidas algo, aparecerá aquí.',
                  ),
                ],
              )
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(money.format(o.total), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                if (!o.isActive && o.business != null) ...[
                                  const SizedBox(height: 6),
                                  TextButton.icon(
                                    onPressed: _repeating != null ? null : () => _repeat(o),
                                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                    icon: _repeating == o.id
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.replay_rounded, size: 18),
                                    label: const Text('Repetir'),
                                  ),
                                ],
                              ],
                            ),
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
