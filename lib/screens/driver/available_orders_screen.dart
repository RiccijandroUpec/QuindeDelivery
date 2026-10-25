import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../state/auth_state.dart';
import '../../state/location_service.dart';
import '../../state/realtime.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import 'driver_order_screen.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  List<Order>? _orders;
  String? _error;
  Timer? _timer;
  StreamSubscription<void>? _live;
  int? _accepting;
  final _loc = LocationService.instance;

  @override
  void initState() {
    super.initState();
    _load();
    _live = Realtime.instance.on('drivers', 'order.changed').listen((_) {
      if (_loc.online.value) _load();
    });
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_loc.online.value) _load();
    });
  }

  @override
  void dispose() {
    _live?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await Api.instance.get('/driver/orders/available') as List;
      if (mounted) {
        setState(() {
          _orders = list.map((j) => Order.fromJson(j)).toList();
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _toggleOnline(bool v) async {
    if (v) {
      final err = await _loc.goOnline();
      if (err != null && mounted) showMessage(context, err);
      _load();
    } else {
      _loc.goOffline();
    }
  }

  Future<void> _accept(Order o) async {
    setState(() => _accepting = o.id);
    try {
      final j = await Api.instance.post('/driver/orders/${o.id}/accept');
      _loc.pushNow();
      if (!mounted) return;
      showMessage(context, '¡Pedido #${o.id} es tuyo! Ve a recogerlo.', error: false);
      widget.onAccepted();
      Navigator.push(context, MaterialPageRoute(builder: (_) => DriverOrderScreen(initial: Order.fromJson(j))));
      _load();
    } catch (e) {
      if (mounted) showMessage(context, e);
      _load();
    } finally {
      if (mounted) setState(() => _accepting = null);
    }
  }

  String? _distance(Order o) {
    final me = _loc.position.value;
    final b = o.business;
    if (me == null || b?.lat == null) return null;
    final km = const Distance().as(LengthUnit.Meter, me, LatLng(b!.lat!, b.lng!)) / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final name = context.watch<AuthState>().user?.name.split(' ').first ?? '';

    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: _loc.online,
        builder: (context, online, _) => RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PolyBackground(
                  seed: online ? 31 : 32,
                  colors: online ? AppColors.poly : const [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569), Color(0xFF64748B)],
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hola, $name',
                                  style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  online ? 'Estás en línea · compartiendo ubicación' : 'Estás desconectado',
                                  style: t.bodySmall?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Switch(
                                value: online,
                                onChanged: _toggleOnline,
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppColors.accent,
                              ),
                              Text(online ? 'En línea' : 'Fuera', style: t.labelSmall?.copyWith(color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!online)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.power_settings_new_rounded,
                    title: 'Conéctate para recibir pedidos',
                    message: 'Activa el interruptor de arriba para ver pedidos cercanos y compartir tu ubicación.',
                  ),
                )
              else if (_orders == null)
                SliverFillRemaining(
                  child: _error != null
                      ? EmptyState(icon: Icons.wifi_off_rounded, title: 'Sin conexión', message: _error)
                      : const BirdLoader(),
                )
              else if (_orders!.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.hourglass_empty_rounded,
                    title: 'No hay pedidos por ahora',
                    message: 'Te mostraremos aquí los nuevos pedidos listos para recoger.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.separated(
                    itemCount: _orders!.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _card(_orders![i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Order o) {
    final t = Theme.of(context).textTheme;
    final dist = _distance(o);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#${o.id}', style: t.titleSmall?.copyWith(color: AppColors.muted)),
                const SizedBox(width: 8),
                StatusChip(o.status),
                const Spacer(),
                Text(
                  money.format(o.deliveryFee),
                  style: t.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _stop(Icons.storefront_rounded, AppColors.accent, o.business?.name ?? '', o.business?.address, trailing: dist),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Container(width: 2, height: 16, color: AppColors.border),
            ),
            _stop(Icons.home_rounded, AppColors.primaryDark, o.address, o.reference),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  o.paymentMethod == 'efectivo' ? Icons.payments_outlined : Icons.account_balance_outlined,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  '${o.itemCount} productos · Cobrar ${money.format(o.paymentMethod == 'efectivo' ? o.total : 0)}',
                  style: t.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _accepting != null ? null : () => _accept(o),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              child: _accepting == o.id
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Aceptar pedido'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stop(IconData icon, Color color, String title, String? sub, {String? trailing}) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color,
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (sub?.isNotEmpty ?? false) Text(sub!, style: t.bodySmall?.copyWith(color: AppColors.muted)),
            ],
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: t.labelMedium?.copyWith(color: AppColors.cyan, fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}
