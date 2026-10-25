import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../state/cart_state.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import 'address_picker_screen.dart';
import 'business_screen.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Address> _addresses = [];
  Address? _address;
  String _payment = 'efectivo';
  final _cash = TextEditingController();
  final _notes = TextEditingController();
  final _coupon = TextEditingController();
  bool _checkingCoupon = false;
  bool _loadingAddresses = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadFees();
  }

  Future<void> _loadFees() async {
    try {
      final j = await Api.instance.get('/settings');
      if (mounted) context.read<CartState>().setServiceFee((j['service_fee'] as num).toDouble());
    } catch (_) {}
  }

  Future<void> _loadAddresses() async {
    try {
      final list = await Api.instance.get('/addresses') as List;
      _addresses = list.map((j) => Address.fromJson(j)).toList();
      _address ??= _addresses.isNotEmpty ? _addresses.first : null;
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _newAddress() async {
    final a = await Navigator.push<Address>(context, MaterialPageRoute(builder: (_) => const AddressPickerScreen()));
    if (a != null) {
      setState(() {
        _addresses.insert(0, a);
        _address = a;
      });
    }
  }

  Future<void> _applyCoupon() async {
    final cart = context.read<CartState>();
    final code = _coupon.text.trim();
    if (code.isEmpty) return;
    setState(() => _checkingCoupon = true);
    try {
      final j = await Api.instance.post('/coupons/check', {'code': code, 'business_id': cart.business!.id, 'subtotal': cart.subtotal});
      cart.applyCoupon(j['code'], j['description'], (j['discount'] as num).toDouble());
      _coupon.clear();
      if (mounted) showMessage(context, 'Cupón aplicado: -${money.format(cart.discount)}', error: false);
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _checkingCoupon = false);
    }
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartState>();
    if (_address == null) {
      showMessage(context, 'Agrega una dirección de entrega.');
      return;
    }
    final cash = double.tryParse(_cash.text.replaceAll(',', '.'));
    if (_payment == 'efectivo' && cash != null && cash < cart.total) {
      showMessage(context, 'El monto con el que pagas no cubre el total.');
      return;
    }
    setState(() => _sending = true);
    try {
      final j = await Api.instance.post('/orders', {
        'business_id': cart.business!.id,
        'address': _address!.address,
        'reference': _address!.reference,
        'lat': _address!.lat,
        'lng': _address!.lng,
        'payment_method': _payment,
        if (_payment == 'efectivo' && cash != null) 'cash_amount': cash,
        'notes': _notes.text.trim(),
        if (cart.couponCode != null) 'coupon_code': cart.couponCode,
        'items': [
          for (final l in cart.lines) {'product_id': l.product.id, 'quantity': l.quantity},
        ],
      });
      final order = Order.fromJson(j);
      cart.clear();
      if (!mounted) return;
      Navigator.of(context)
        ..popUntil((r) => r.isFirst)
        ..push(MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id, justPlaced: true)));
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cart = context.watch<CartState>();

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tu carrito')),
        body: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Tu carrito está vacío',
          message: 'Agrega productos de algún negocio para hacer tu pedido.',
          action: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Explorar negocios')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(cart.business!.name)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _sending ? null : _placeOrder,
            child: _sending
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text('Hacer pedido · ${money.format(cart.total)}'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _title('Productos'),
          Card(
            child: Column(
              children: [
                for (final l in cart.lines)
                  ListTile(
                    title: Text(l.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(money.format(l.subtotal)),
                    trailing: QtyStepper(
                      qty: l.quantity,
                      onMinus: () => cart.decrease(l.product.id),
                      onPlus: () => cart.add(cart.business!, l.product),
                    ),
                  ),
              ],
            ),
          ),
          _title('Entregar en'),
          if (_loadingAddresses)
            const Center(
              child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
            )
          else
            Card(
              child: RadioGroup<int>(
                groupValue: _address?.id,
                onChanged: (id) => setState(() => _address = _addresses.firstWhere((a) => a.id == id)),
                child: Column(
                  children: [
                    for (final a in _addresses)
                      RadioListTile<int>(
                        value: a.id!,
                        title: Text(a.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text([a.address, if (a.reference?.isNotEmpty ?? false) a.reference].join(' · ')),
                      ),
                    ListTile(
                      leading: Icon(Icons.add_location_alt_outlined, color: AppColors.primary),
                      title: Text(
                        'Agregar dirección',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                      onTap: _newAddress,
                    ),
                  ],
                ),
              ),
            ),
          _title('Método de pago'),
          Card(
            child: RadioGroup<String>(
              groupValue: _payment,
              onChanged: (v) => setState(() => _payment = v!),
              child: Column(
                children: [
                  const RadioListTile(value: 'efectivo', title: Text('Efectivo'), secondary: Icon(Icons.payments_outlined)),
                  if (_payment == 'efectivo')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _cash,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: '¿Con cuánto pagas? (opcional)', prefixText: '\$ ', isDense: true),
                      ),
                    ),
                  const RadioListTile(
                    value: 'transferencia',
                    title: Text('Transferencia'),
                    secondary: Icon(Icons.account_balance_outlined),
                  ),
                ],
              ),
            ),
          ),
          _title('Notas'),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Ej: sin cebolla, tocar el timbre...'),
          ),
          _title('Cupón'),
          if (cart.couponCode != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_offer_rounded, color: AppColors.accent),
                title: Text(cart.couponCode!, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                subtitle: Text(cart.couponDescription ?? 'Descuento aplicado'),
                trailing: IconButton(onPressed: cart.removeCoupon, icon: const Icon(Icons.close_rounded), tooltip: 'Quitar'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _coupon,
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _applyCoupon(),
                    decoration: const InputDecoration(hintText: 'Código de descuento', prefixIcon: Icon(Icons.local_offer_outlined)),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonal(
                  onPressed: _checkingCoupon ? null : _applyCoupon,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(96, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _checkingCoupon
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Aplicar'),
                ),
              ],
            ),
          _title('Resumen'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Subtotal', money.format(cart.subtotal)),
                  const SizedBox(height: 6),
                  _row('Envío', money.format(cart.deliveryFee)),
                  if (cart.serviceFee > 0) ...[
                    const SizedBox(height: 6),
                    _row('Tarifa de servicio', money.format(cart.serviceFee)),
                  ],
                  if (cart.discount > 0) ...[
                    const SizedBox(height: 6),
                    _row('Descuento', '-${money.format(cart.discount)}', style: t.bodyMedium?.copyWith(color: AppColors.accent)),
                  ],
                  const Divider(height: 24),
                  _row('Total', money.format(cart.total), bold: true, style: t.titleMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String s) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(s, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
  );

  Widget _row(String a, String b, {bool bold = false, TextStyle? style}) {
    final s = (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(fontWeight: bold ? FontWeight.w700 : null);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(a, style: s),
        Text(b, style: s),
      ],
    );
  }
}
