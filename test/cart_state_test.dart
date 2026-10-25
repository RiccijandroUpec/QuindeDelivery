import 'package:delivery_app/models.dart';
import 'package:delivery_app/state/cart_state.dart';
import 'package:flutter_test/flutter_test.dart';

Product product(int id, double price, {bool available = true}) =>
    Product(id: id, businessId: 1, name: 'P$id', section: 'General', price: price, available: available);

Business business(int id, {List<Product> products = const [], double fee = 1.5}) =>
    Business(id: id, name: 'Negocio $id', deliveryFee: fee, products: products);

void main() {
  test('suma subtotal, envío y total', () {
    final cart = CartState();
    final b = business(1);
    cart
      ..add(b, product(1, 2.5))
      ..add(b, product(1, 2.5))
      ..add(b, product(2, 4));
    expect(cart.count, 3);
    expect(cart.subtotal, 9);
    expect(cart.total, 10.5);
  });

  test('agregar de otro negocio vacía el carrito', () {
    final cart = CartState()..add(business(1), product(1, 2));
    expect(cart.conflictsWith(business(2)), isTrue);
    cart.add(business(2), product(9, 3));
    expect(cart.business?.id, 2);
    expect(cart.count, 1);
  });

  test('el cupón descuenta y se quita si cambia el carrito', () {
    final cart = CartState()..add(business(1), product(1, 10));
    cart.applyCoupon('COLIBRI2', '\$2 de descuento', 2);
    expect(cart.total, 9.5);

    cart.add(business(1), product(1, 10));
    expect(cart.couponCode, isNull);
    expect(cart.discount, 0);
  });

  test('la tarifa de servicio se suma al total', () {
    final cart = CartState()..add(business(1), product(1, 10));
    cart.setServiceFee(0.25);
    expect(cart.total, 11.75);
  });

  test('el total nunca es negativo', () {
    final cart = CartState()..add(business(1, fee: 0), product(1, 1));
    cart.applyCoupon('X', null, 5);
    expect(cart.total, 0);
  });

  test('repetir pedido agrega solo lo disponible', () {
    final b = business(1, products: [product(1, 3), product(2, 4, available: false)]);
    final items = [
      OrderItem(productId: 1, name: 'P1', price: 3, quantity: 2, subtotal: 6),
      OrderItem(productId: 2, name: 'P2', price: 4, quantity: 1, subtotal: 4),
      OrderItem(productId: 99, name: 'Borrado', price: 1, quantity: 1, subtotal: 1),
    ];
    final cart = CartState();
    final missing = cart.repeat(b, items);

    expect(missing, 2);
    expect(cart.quantityOf(1), 2);
    expect(cart.subtotal, 6);
  });

  test('vaciar el carrito borra negocio y cupón', () {
    final cart = CartState()..add(business(1), product(1, 5));
    cart.applyCoupon('X', null, 1);
    cart.clear();
    expect(cart.isEmpty, isTrue);
    expect(cart.business, isNull);
    expect(cart.couponCode, isNull);
  });
}
