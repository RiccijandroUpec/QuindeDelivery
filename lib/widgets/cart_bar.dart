import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/client/checkout_screen.dart';
import '../state/cart_state.dart';
import '../theme.dart';

/// Barra flotante "Ver carrito" que aparece cuando hay productos.
class CartBar extends StatelessWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    if (cart.isEmpty) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18),
          elevation: 6,
          shadowColor: AppColors.primary.withValues(alpha: .4),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      '${cart.count}',
                      style: t.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ver carrito · ${cart.business?.name ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    money.format(cart.subtotal),
                    style: t.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
