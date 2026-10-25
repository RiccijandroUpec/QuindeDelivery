import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../state/auth_state.dart';
import '../../state/realtime.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';

/// Pedidos que el negocio tiene que atender: nuevos, en preparación y listos.
class BusinessOrdersScreen extends StatefulWidget {
  const BusinessOrdersScreen({super.key});

  @override
  State<BusinessOrdersScreen> createState() => _BusinessOrdersScreenState();
}

class _BusinessOrdersScreenState extends State<BusinessOrdersScreen> {
  List<Order>? _orders;
  String? _error;
  bool? _isOpen;
  int? _busy;
  Timer? _timer;
  StreamSubscription<void>? _live;
  // Pedidos nuevos ya vistos, para avisar solo de los que llegan.
  final _seen = <int>{};

  static const _rejectReasons = ['Sin stock', 'Mucha demanda', 'Estamos por cerrar', 'Fuera de zona de entrega'];

  @override
  void initState() {
    super.initState();
    _loadBusiness();
    _load();
    // Tiempo real: cada cambio llega al instante. El polling queda de respaldo.
    final businessId = context.read<AuthState>().user?.businessId;
    if (businessId != null) {
      _live = Realtime.instance.on('business.$businessId', 'order.changed').listen((_) => _load());
    }
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _live?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBusiness() async {
    try {
      final j = await Api.instance.get('/business');
      if (mounted) setState(() => _isOpen = j['is_open'] ?? true);
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final list = (await Api.instance.get('/business/orders', {'active': '1'}) as List).map((j) => Order.fromJson(j)).toList();
      if (!mounted) return;
      final incoming = list.where((o) => o.status == 'pendiente' && !_seen.contains(o.id)).toList();
      final firstLoad = _orders == null;
      _seen.addAll(incoming.map((o) => o.id));
      setState(() {
        _orders = list;
        _error = null;
      });
      if (!firstLoad && incoming.isNotEmpty) {
        SystemSound.play(SystemSoundType.alert);
        showMessage(
          context,
          incoming.length == 1 ? '¡Nuevo pedido #${incoming.first.id}!' : '¡${incoming.length} pedidos nuevos!',
          error: false,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _toggleOpen(bool v) async {
    setState(() => _isOpen = v);
    try {
      final j = await Api.instance.put('/business/open', {'is_open': v});
      if (mounted) setState(() => _isOpen = j['is_open']);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOpen = !v);
      showMessage(context, e);
    }
  }

  Future<void> _setStatus(Order o, String status, {String? reason}) async {
    setState(() => _busy = o.id);
    try {
      await Api.instance.post('/business/orders/${o.id}/status', {'status': status, 'reason': ?reason});
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _reject(Order o) async {
    final custom = TextEditingController();
    String? picked;
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => StatefulBuilder(
        builder: (c, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(c).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Por qué rechazas el pedido #${o.id}?',
                style: Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('El cliente verá este motivo.', style: Theme.of(c).textTheme.bodySmall?.copyWith(color: AppColors.muted)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in _rejectReasons)
                    ChoiceChip(
                      label: Text(r),
                      selected: picked == r,
                      onSelected: (_) => setSheet(() {
                        picked = r;
                        custom.clear();
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: custom,
                decoration: const InputDecoration(labelText: 'Otro motivo'),
                onChanged: (_) => setSheet(() => picked = null),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size.fromHeight(46)),
                onPressed: () {
                  final r = picked ?? custom.text.trim();
                  if (r.isNotEmpty) Navigator.pop(c, r);
                },
                child: const Text('Rechazar pedido'),
              ),
            ],
          ),
        ),
      ),
    );
    if (reason != null) await _setStatus(o, 'cancelado', reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final user = context.watch<AuthState>().user;
    final open = _isOpen ?? true;
    final orders = _orders;

    List<Order> by(List<String> s) => orders?.where((o) => s.contains(o.status)).toList() ?? [];
    final sections = [
      ('Nuevos', by(['pendiente'])),
      ('En preparación', by(['aceptado', 'preparando'])),
      ('Listos para recoger', by(['listo'])),
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PolyBackground(
                seed: open ? 41 : 42,
                colors: open ? AppColors.poly : const [Color(0xFF1E293B), Color(0xFF334155), Color(0xFF475569), Color(0xFF64748B)],
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
                                user?.businessName ?? user?.name ?? '',
                                style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                open ? 'Abierto · recibiendo pedidos' : 'Cerrado · no recibes pedidos nuevos',
                                style: t.bodySmall?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Switch(
                              value: open,
                              onChanged: _isOpen == null ? null : _toggleOpen,
                              activeThumbColor: Colors.white,
                              activeTrackColor: AppColors.accent,
                            ),
                            Text(open ? 'Abierto' : 'Cerrado', style: t.labelSmall?.copyWith(color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (orders == null)
              SliverFillRemaining(
                child: _error != null
                    ? EmptyState(icon: Icons.wifi_off_rounded, title: 'Sin conexión', message: _error)
                    : const BirdLoader(),
              )
            else if (orders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Sin pedidos por ahora',
                  message: open ? 'Te avisaremos aquí cuando llegue un pedido nuevo.' : 'Abre el negocio para empezar a recibir pedidos.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.list(
                  children: [
                    for (final (title, list) in sections)
                      if (list.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                          child: Text('$title (${list.length})', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        for (final o in list) Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(o)),
                      ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(Order o) {
    final t = Theme.of(context).textTheme;
    final muted = t.bodySmall?.copyWith(color: AppColors.muted);
    final busy = _busy == o.id;
    final mins = DateTime.now().difference(o.createdAt).inMinutes;

    return Card(
      shape: o.status == 'pendiente'
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.accent, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#${o.id}', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                StatusChip(o.status),
                const Spacer(),
                Text(mins < 1 ? 'Ahora' : 'Hace $mins min', style: muted),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text([o.clientName, o.clientPhone].whereType<String>().join(' · '), style: muted)),
                CallButton(phone: o.clientPhone, tooltip: 'Llamar al cliente'),
              ],
            ),
            const Divider(height: 20),
            for (final i in o.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i.quantity}x',
                      style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.name, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          if (i.notes?.isNotEmpty ?? false) Text(i.notes!, style: muted),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (o.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: .08), borderRadius: BorderRadius.circular(10)),
                child: Text('Nota: ${o.notes}', style: t.bodySmall),
              ),
            ],
            const Divider(height: 20),
            Row(
              children: [
                Icon(
                  o.paymentMethod == 'efectivo' ? Icons.payments_outlined : Icons.account_balance_outlined,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 6),
                Text(o.paymentMethod == 'efectivo' ? 'Efectivo' : 'Transferencia', style: muted),
                if (o.isTransfer) ...[
                  const SizedBox(width: 8),
                  o.transferProofUrl != null
                      ? InkWell(
                          onTap: () => _showProof(o),
                          child: Text(
                            'Ver comprobante',
                            style: t.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      : Text(
                          'Sin comprobante aún',
                          style: t.bodySmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
                        ),
                ],
                const Spacer(),
                Text(money.format(o.subtotal), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            if (o.driverName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.two_wheeler_rounded, size: 18, color: AppColors.cyan),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Repartidor: ${o.driverName}', style: t.bodySmall?.copyWith(color: AppColors.cyan)),
                  ),
                  CallButton(phone: o.driverPhone, tooltip: 'Llamar al repartidor'),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (busy)
              const Center(
                child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
              )
            else
              _actions(o),
          ],
        ),
      ),
    );
  }

  void _showProof(Order o) {
    showDialog<void>(
      context: context,
      builder: (c) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InteractiveViewer(child: Image.network(o.transferProofUrl!, fit: BoxFit.contain)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Comprobante · pedido #${o.id} · ${money.format(o.total)}',
                style: Theme.of(c).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(Order o) {
    const size = Size.fromHeight(46);
    final disabled = _busy != null;
    return switch (o.status) {
      'pendiente' => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: disabled ? null : () => _reject(o),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, minimumSize: size),
              child: const Text('Rechazar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: disabled ? null : () => _setStatus(o, 'aceptado'),
              style: FilledButton.styleFrom(minimumSize: size),
              child: const Text('Aceptar pedido'),
            ),
          ),
        ],
      ),
      'aceptado' => FilledButton.icon(
        onPressed: disabled ? null : () => _setStatus(o, 'preparando'),
        style: FilledButton.styleFrom(minimumSize: size, backgroundColor: AppColors.cyan),
        icon: const Icon(Icons.soup_kitchen_rounded),
        label: const Text('Empezar a preparar'),
      ),
      'preparando' => FilledButton.icon(
        onPressed: disabled ? null : () => _setStatus(o, 'listo'),
        style: FilledButton.styleFrom(minimumSize: size),
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text('Marcar como listo'),
      ),
      _ => Text(
        o.driverName != null ? 'Esperando que el repartidor lo recoja.' : 'Buscando repartidor…',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
      ),
    };
  }
}
