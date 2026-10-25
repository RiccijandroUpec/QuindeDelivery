import 'package:flutter/foundation.dart';

import '../models.dart';

class CartLine {
  CartLine(this.product, this.quantity);

  final Product product;
  int quantity;

  double get subtotal => product.price * quantity;
}

class CartState extends ChangeNotifier {
  Business? business;
  final Map<int, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();
  bool get isEmpty => _lines.isEmpty;
  int get count => _lines.values.fold(0, (s, l) => s + l.quantity);
  double get subtotal => _lines.values.fold(0.0, (s, l) => s + l.subtotal);
  double get deliveryFee => business?.deliveryFee ?? 0;
  double get total => (subtotal + deliveryFee - discount).clamp(0, double.infinity);

  /// Cupón aplicado. Se quita si cambia el carrito, porque el descuento depende del subtotal.
  String? couponCode;
  String? couponDescription;
  double discount = 0;

  void applyCoupon(String code, String? description, double amount) {
    couponCode = code;
    couponDescription = description;
    discount = amount;
    notifyListeners();
  }

  void removeCoupon() {
    couponCode = null;
    couponDescription = null;
    discount = 0;
    notifyListeners();
  }

  /// Llena el carrito con los productos de un pedido anterior que sigan disponibles.
  /// Devuelve cuántos productos no se pudieron agregar.
  int repeat(Business b, List<OrderItem> items) {
    _lines.clear();
    _resetCoupon();
    business = b;
    var missing = 0;
    for (final item in items) {
      final product = b.products.where((p) => p.id == item.productId && p.available).firstOrNull;
      if (product == null) {
        missing++;
        continue;
      }
      _lines.update(product.id, (l) => l..quantity += item.quantity, ifAbsent: () => CartLine(product, item.quantity));
    }
    if (_lines.isEmpty) business = null;
    notifyListeners();
    return missing;
  }

  void _resetCoupon() {
    couponCode = null;
    couponDescription = null;
    discount = 0;
  }

  int quantityOf(int productId) => _lines[productId]?.quantity ?? 0;

  /// true si agregar este producto vaciaría un carrito de otro negocio.
  bool conflictsWith(Business b) => business != null && business!.id != b.id && !isEmpty;

  void add(Business b, Product p) {
    if (conflictsWith(b)) _lines.clear();
    business = b;
    _lines.update(p.id, (l) => l..quantity += 1, ifAbsent: () => CartLine(p, 1));
    _resetCoupon();
    notifyListeners();
  }

  void decrease(int productId) {
    final line = _lines[productId];
    if (line == null) return;
    line.quantity -= 1;
    if (line.quantity <= 0) _lines.remove(productId);
    if (_lines.isEmpty) business = null;
    _resetCoupon();
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    business = null;
    _resetCoupon();
    notifyListeners();
  }
}
