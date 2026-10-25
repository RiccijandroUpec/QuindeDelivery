import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Detalle de productos, dirección y totales de un pedido.
class OrderSummary extends StatelessWidget {
  const OrderSummary({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = order;
    final muted = t.bodySmall?.copyWith(color: AppColors.muted);

    Widget row(String a, String b, {bool bold = false}) {
      final s = (bold ? t.titleSmall : t.bodyMedium)?.copyWith(fontWeight: bold ? FontWeight.w700 : null);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(a, style: s),
            Text(b, style: s),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(o.business?.name ?? 'Pedido', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            for (final i in o.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(6)),
                      child: Text('${i.quantity}x', style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(i.name)),
                    Text(money.format(i.subtotal)),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(child: Text([o.address, if (o.reference?.isNotEmpty ?? false) o.reference].join(' · '), style: muted)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  o.paymentMethod == 'efectivo' ? Icons.payments_outlined : Icons.account_balance_outlined,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  o.paymentMethod == 'efectivo'
                      ? 'Efectivo${o.cashAmount != null ? ' · paga con ${money.format(o.cashAmount)}' : ''}'
                      : 'Transferencia',
                  style: muted,
                ),
              ],
            ),
            if (o.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.sticky_note_2_outlined, size: 18, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(o.notes!, style: muted)),
                ],
              ),
            ],
            const Divider(height: 24),
            row('Subtotal', money.format(o.subtotal)),
            row('Envío', money.format(o.deliveryFee)),
            if (o.discount > 0) row('Descuento${o.couponCode != null ? ' (${o.couponCode})' : ''}', '-${money.format(o.discount)}'),
            row('Total', money.format(o.total), bold: true),
          ],
        ),
      ),
    );
  }
}
