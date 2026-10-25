import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/order_map.dart';
import '../../widgets/order_summary.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId, this.justPlaced = false});

  final int orderId;
  final bool justPlaced;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Order? _order;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Consulta periódica del estado y la ubicación del repartidor.
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_order?.isActive ?? true) _load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final j = await Api.instance.get('/orders/${widget.orderId}');
      if (mounted) setState(() => _order = Order.fromJson(j));
    } catch (e) {
      if (mounted && _order == null) setState(() => _error = e.toString());
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Cancelar pedido?'),
        content: const Text('Solo puedes cancelar mientras el negocio no lo haya aceptado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sí, cancelar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final j = await Api.instance.post('/orders/${widget.orderId}/cancel');
      if (mounted) setState(() => _order = Order.fromJson(j));
    } catch (e) {
      if (mounted) showMessage(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = _order;

    return Scaffold(
      appBar: AppBar(title: Text('Pedido #${widget.orderId}')),
      body: o == null
          ? (_error != null
              ? EmptyState(icon: Icons.error_outline, title: 'No se pudo cargar', message: _error)
              : const BirdLoader())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  if (widget.justPlaced && o.status == 'pendiente')
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(child: Text('¡Pedido enviado! Esperando que ${o.business?.name ?? 'el negocio'} lo acepte.')),
                      ]),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(height: 240, child: OrderMap(order: o)),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(_headline(o.status), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                              StatusChip(o.status),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (o.status == 'cancelado')
                            Text(
                              o.cancelReason?.isNotEmpty ?? false ? 'Motivo: ${o.cancelReason}' : 'Este pedido fue cancelado.',
                              style: t.bodyMedium?.copyWith(color: AppColors.muted),
                            )
                          else
                            _Timeline(status: o.status),
                        ],
                      ),
                    ),
                  ),
                  if (o.driverName != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFECFDF5),
                          child: Icon(Icons.two_wheeler_rounded, color: AppColors.primary),
                        ),
                        title: Text(o.driverName!, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text([o.driverVehicle, o.driverPhone].whereType<String>().join(' · ')),
                        trailing: CallButton(phone: o.driverPhone, tooltip: 'Llamar al repartidor'),
                      ),
                    ),
                  ],
                  if (o.isTransfer && o.status != 'cancelado') ...[
                    const SizedBox(height: 12),
                    _TransferCard(order: o, onUpdated: (u) => setState(() => _order = u)),
                  ],
                  if (o.status == 'entregado') ...[
                    const SizedBox(height: 12),
                    _RatingCard(order: o, onUpdated: (u) => setState(() => _order = u)),
                  ],
                  const SizedBox(height: 12),
                  OrderSummary(order: o),
                  if (o.status == 'pendiente') ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _cancel,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cancelar pedido'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _headline(String s) => switch (s) {
        'pendiente' => 'Esperando confirmación',
        'aceptado' => 'El negocio aceptó tu pedido',
        'preparando' => 'Preparando tu pedido',
        'listo' => 'Listo, esperando al repartidor',
        'en_camino' => '¡Tu pedido va volando! 🛵',
        'entregado' => 'Pedido entregado 🎉',
        _ => 'Pedido cancelado',
      };
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // "listo" se muestra como parte de "preparando" en la línea de tiempo.
    final current = OrderStatus.steps.indexOf(status == 'listo' ? 'preparando' : status);
    const icons = [Icons.receipt_long_rounded, Icons.thumb_up_alt_rounded, Icons.soup_kitchen_rounded, Icons.two_wheeler_rounded, Icons.home_rounded];
    const labels = ['Recibido', 'Aceptado', 'Preparando', 'En camino', 'Entregado'];

    return Row(
      children: [
        for (var i = 0; i < OrderStatus.steps.length; i++) ...[
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: i <= current ? AppColors.primary : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: Icon(icons[i], size: 18, color: i <= current ? Colors.white : AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(labels[i],
                  style: t.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: i == current ? FontWeight.w700 : FontWeight.w400,
                    color: i <= current ? AppColors.ink : AppColors.muted,
                  )),
            ],
          ),
          if (i < OrderStatus.steps.length - 1)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 18),
                color: i < current ? AppColors.primary : AppColors.border,
              ),
            ),
        ],
      ],
    );
  }
}

/// Datos bancarios del negocio y subida del comprobante de transferencia.
class _TransferCard extends StatefulWidget {
  const _TransferCard({required this.order, required this.onUpdated});

  final Order order;
  final ValueChanged<Order> onUpdated;

  @override
  State<_TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<_TransferCard> {
  bool _uploading = false;

  Future<void> _upload() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final j = await Api.instance.upload('/orders/${widget.order.id}/proof', 'proof', await file.readAsBytes(), file.name);
      widget.onUpdated(Order.fromJson(j));
      if (mounted) showMessage(context, 'Comprobante enviado al negocio', error: false);
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = widget.order;
    final sent = o.transferProofUrl != null;
    final canUpload = o.isActive;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.account_balance_rounded, color: AppColors.cyan),
              const SizedBox(width: 10),
              Expanded(child: Text('Pago por transferencia', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
              if (sent)
                const Icon(Icons.verified_rounded, color: AppColors.primary)
              else
                Text(money.format(o.total), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            if (o.business?.bankInfo?.isNotEmpty ?? false)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                child: SelectableText(o.business!.bankInfo!, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 10),
            if (sent) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(o.transferProofUrl!, height: 140, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink()),
              ),
              const SizedBox(height: 8),
              Text('Comprobante enviado ✓', style: t.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ] else
              Text('Transfiere el total y sube la foto del comprobante para que el negocio lo verifique.',
                  style: t.bodySmall?.copyWith(color: AppColors.muted)),
            if (canUpload) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(sent ? Icons.refresh_rounded : Icons.upload_rounded),
                label: Text(sent ? 'Cambiar comprobante' : 'Subir comprobante'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Calificación del pedido una vez entregado.
class _RatingCard extends StatefulWidget {
  const _RatingCard({required this.order, required this.onUpdated});

  final Order order;
  final ValueChanged<Order> onUpdated;

  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  int _stars = 0;
  final _comment = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final j = await Api.instance.post('/orders/${widget.order.id}/rate', {
        'rating': _stars,
        if (_comment.text.trim().isNotEmpty) 'comment': _comment.text.trim(),
      });
      widget.onUpdated(Order.fromJson(j));
      if (mounted) showMessage(context, '¡Gracias por tu calificación!', error: false);
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = widget.order;

    if (o.rating != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            StarRating(value: o.rating!, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(o.ratingComment ?? 'Tu calificación', style: t.bodySmall?.copyWith(color: AppColors.muted))),
          ]),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text('¿Qué tal estuvo tu pedido?', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Califica a ${o.business?.name ?? 'el negocio'}', style: t.bodySmall?.copyWith(color: AppColors.muted)),
            const SizedBox(height: 12),
            StarRating(value: _stars, size: 38, onChanged: (v) => setState(() => _stars = v)),
            if (_stars > 0) ...[
              const SizedBox(height: 12),
              TextField(controller: _comment, decoration: const InputDecoration(hintText: 'Cuéntanos más (opcional)')),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Enviar calificación'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
