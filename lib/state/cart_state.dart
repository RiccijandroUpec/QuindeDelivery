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
  double get total => subtotal + deliveryFee;

  int quantityOf(int productId) => _lines[productId]?.quantity ?? 0;

  /// true si agregar este producto vaciaría un carrito de otro negocio.
  bool conflictsWith(Business b) => business != null && business!.id != b.id && !isEmpty;

  void add(Business b, Product p) {
    if (conflictsWith(b)) _lines.clear();
    business = b;
    _lines.update(p.id, (l) => l..quantity += 1, ifAbsent: () => CartLine(p, 1));
    notifyListeners();
  }

  void decrease(int productId) {
    final line = _lines[productId];
    if (line == null) return;
    line.quantity -= 1;
    if (line.quantity <= 0) _lines.remove(productId);
    if (_lines.isEmpty) business = null;
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    business = null;
    notifyListeners();
  }
}
