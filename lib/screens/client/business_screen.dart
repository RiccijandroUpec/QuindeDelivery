import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../state/cart_state.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/cart_bar.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key, required this.businessId, this.preview});

  final int businessId;

  /// Datos ya conocidos para pintar la cabecera mientras carga el menú.
  final Business? preview;

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  Business? _business;
  String? _error;

  @override
  void initState() {
    super.initState();
    _business = widget.preview;
    _load();
  }

  Future<void> _load() async {
    try {
      final j = await Api.instance.get('/businesses/${widget.businessId}');
      if (mounted) setState(() => _business = Business.fromJson(j));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _add(Product p) async {
    final cart = context.read<CartState>();
    final b = _business!;
    if (cart.conflictsWith(b)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('¿Empezar un carrito nuevo?'),
          content: Text('Tu carrito tiene productos de ${cart.business!.name}. Si continúas, se vaciará.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Vaciar y agregar'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    cart.add(b, p);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final b = _business;
    final sections = <String, List<Product>>{};
    for (final p in b?.products ?? <Product>[]) {
      sections.putIfAbsent(p.section, () => []).add(p);
    }

    return Scaffold(
      bottomNavigationBar: const CartBar(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: AppColors.ink, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: b == null ? null : PolyImage(url: b.coverUrl, seed: b.id, iconSize: 0),
            ),
          ),
          if (b == null)
            SliverFillRemaining(
              child: _error != null
                  ? EmptyState(icon: Icons.error_outline, title: 'No se pudo cargar', message: _error)
                  : const BirdLoader(),
            )
          else ...[
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: PolyImage(url: b.logoUrl, seed: b.id + 1, iconSize: 26),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.name, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                                    if (b.categoryName != null) Text(b.categoryName!, style: t.bodySmall?.copyWith(color: AppColors.muted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (b.description != null) ...[
                            const SizedBox(height: 10),
                            Text(b.description!, style: t.bodyMedium?.copyWith(color: AppColors.muted)),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _info(
                                Icons.star_rounded,
                                b.rating.toStringAsFixed(1),
                                b.ratingCount > 0 ? '${b.ratingCount} reseñas' : 'Calificación',
                                AppColors.gold,
                              ),
                              _info(Icons.schedule_rounded, b.timeLabel, 'Entrega', AppColors.primary),
                              _info(Icons.two_wheeler_rounded, money.format(b.deliveryFee), 'Envío', AppColors.cyan),
                            ],
                          ),
                          if (!b.isOpen) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                              child: const Text('Este negocio está cerrado ahora.', style: TextStyle(color: Color(0xFFB91C1C))),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            for (final entry in sections.entries) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(entry.key, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
              SliverList.separated(
                itemCount: entry.value.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (_, i) => _ProductTile(product: entry.value[i], enabled: b.isOpen, onAdd: _add),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }

  Widget _info(IconData icon, String value, String label, Color color) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(value, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        Text(label, style: t.labelSmall?.copyWith(color: AppColors.muted)),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.enabled, required this.onAdd});

  final Product product;
  final bool enabled;
  final Future<void> Function(Product) onAdd;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cart = context.watch<CartState>();
    final qty = cart.quantityOf(product.id);
    final p = product;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                if (p.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    p.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  money.format(p.price),
                  style: t.titleSmall?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 96,
                    height: 72,
                    child: PolyImage(url: p.imageUrl, seed: p.id, icon: Icons.fastfood_rounded, iconSize: 26),
                  ),
                ),
                const SizedBox(height: 8),
                if (qty == 0)
                  SizedBox(
                    height: 34,
                    width: 96,
                    child: OutlinedButton(
                      onPressed: enabled ? () => onAdd(p) : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                      ),
                      child: const Text('Agregar', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  )
                else
                  QtyStepper(qty: qty, onMinus: () => cart.decrease(p.id), onPlus: () => onAdd(p)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.qty, required this.onMinus, required this.onPlus});

  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(qty == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded, onMinus),
          SizedBox(
            width: 24,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          _btn(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: SizedBox(width: 34, height: 34, child: Icon(icon, color: Colors.white, size: 18)),
  );
}
