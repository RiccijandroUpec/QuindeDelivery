import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';

/// El negocio marca productos como agotados y ajusta precios.
class BusinessMenuScreen extends StatefulWidget {
  const BusinessMenuScreen({super.key});

  @override
  State<BusinessMenuScreen> createState() => _BusinessMenuScreenState();
}

class _BusinessMenuScreenState extends State<BusinessMenuScreen> {
  List<Product>? _products;
  String? _error;
  final _saving = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await Api.instance.get('/business/products') as List;
      if (mounted) {
        setState(() {
          _products = list.map((j) => Product.fromJson(j)).toList();
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _update(Product p, Map<String, dynamic> data) async {
    setState(() => _saving.add(p.id));
    try {
      final updated = Product.fromJson(await Api.instance.patch('/business/products/${p.id}', data));
      if (mounted) setState(() => _products = [for (final x in _products!) x.id == p.id ? updated : x]);
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _saving.remove(p.id));
    }
  }

  Future<void> _editPrice(Product p) async {
    final ctrl = TextEditingController(text: p.price.toStringAsFixed(2));
    final price = await showDialog<double>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(p.name),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null && v > 0) Navigator.pop(c, v);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (price != null) await _update(p, {'price': price});
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final products = _products;
    final sections = <String, List<Product>>{};
    for (final p in products ?? <Product>[]) {
      sections.putIfAbsent(p.section, () => []).add(p);
    }
    final soldOut = products?.where((p) => !p.available).length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi menú')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: products == null
            ? (_error != null
                ? ListView(children: [EmptyState(icon: Icons.wifi_off_rounded, title: 'Sin conexión', message: _error)])
                : const BirdLoader())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Text(
                    soldOut == 0 ? 'Todo disponible. Apaga un producto cuando se agote.' : '$soldOut producto(s) agotado(s), los clientes no los ven.',
                    style: t.bodySmall?.copyWith(color: soldOut == 0 ? AppColors.muted : AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                  for (final entry in sections.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
                      child: Text(entry.key.toUpperCase(),
                          style: t.labelMedium?.copyWith(color: AppColors.muted, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
                    ),
                    Card(
                      child: Column(
                        children: [
                          for (final (i, p) in entry.value.indexed) ...[
                            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                              title: Text(p.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: p.available ? AppColors.ink : AppColors.muted,
                                    decoration: p.available ? null : TextDecoration.lineThrough,
                                  )),
                              subtitle: InkWell(
                                onTap: () => _editPrice(p),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(children: [
                                    Text(money.format(p.price), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit_rounded, size: 14, color: AppColors.muted),
                                  ]),
                                ),
                              ),
                              trailing: _saving.contains(p.id)
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                    )
                                  : Switch(value: p.available, onChanged: (v) => _update(p, {'available': v})),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
