import 'package:delivery_app/models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> orderJson({String status = 'pendiente', Map<String, dynamic> extra = const {}}) => {
      'id': 7,
      'status': status,
      'address': 'Av. Amazonas',
      'lat': '-0.1700000',
      'lng': -78.48,
      'subtotal': '12.50',
      'delivery_fee': 1.5,
      'discount': '2.00',
      'coupon_code': 'QUINDE2',
      'total': 12,
      'payment_method': 'transferencia',
      'created_at': '2026-10-24T15:00:00.000000Z',
      'business': {'id': 1, 'name': 'Sabor Serrano', 'lat': -0.18, 'lng': -78.49, 'open_now': false, 'is_open': true},
      'items': [
        {'product_id': 3, 'name': 'Churrasco', 'price': '8.50', 'quantity': 1, 'subtotal': 8.5},
        {'product_id': 5, 'name': 'Yaguarlocro', 'price': 2, 'quantity': 2, 'subtotal': 4},
      ],
      'driver': {'name': 'Repartidor Demo', 'phone': '0987654321', 'vehicle': 'Moto'},
      'user': {'name': 'Cliente Demo', 'phone': '0991234567'},
      ...extra,
    };

void main() {
  group('Order.fromJson', () {
    test('convierte números que llegan como texto', () {
      final o = Order.fromJson(orderJson());
      expect(o.lat, -0.17);
      expect(o.subtotal, 12.5);
      expect(o.discount, 2);
      expect(o.couponCode, 'QUINDE2');
      expect(o.items.first.price, 8.5);
      expect(o.items.first.productId, 3);
    });

    test('cuenta productos y detecta transferencia', () {
      final o = Order.fromJson(orderJson());
      expect(o.itemCount, 3);
      expect(o.isTransfer, isTrue);
      expect(o.clientName, 'Cliente Demo');
      expect(o.driverPhone, '0987654321');
    });

    test('isActive es falso solo para entregado y cancelado', () {
      for (final s in ['pendiente', 'aceptado', 'preparando', 'listo', 'en_camino']) {
        expect(Order.fromJson(orderJson(status: s)).isActive, isTrue, reason: s);
      }
      expect(Order.fromJson(orderJson(status: 'entregado')).isActive, isFalse);
      expect(Order.fromJson(orderJson(status: 'cancelado')).isActive, isFalse);
    });

    test('reparto del dinero; pedidos viejos sin driver_earning usan el envío', () {
      final o = Order.fromJson(orderJson(extra: {'service_fee': '0.25', 'commission': 1.25, 'driver_earning': '1.20'}));
      expect(o.serviceFee, .25);
      expect(o.commission, 1.25);
      expect(o.driverEarning, 1.2);
      expect(Order.fromJson(orderJson()).driverEarning, 1.5);
    });

    test('withDriverAt conserva todo y mueve al repartidor', () {
      final o = Order.fromJson(orderJson()).withDriverAt(-0.175, -78.485);
      expect(o.driverLat, -0.175);
      expect(o.driverLng, -78.485);
      expect(o.items.length, 2);
      expect(o.business?.name, 'Sabor Serrano');
    });
  });

  group('Business.fromJson', () {
    test('respeta el horario: open_now manda sobre is_open', () {
      final b = Business.fromJson({'id': 1, 'name': 'X', 'is_open': true, 'open_now': false});
      expect(b.isOpen, isFalse);
    });

    test('etiqueta de horario', () {
      final b = Business.fromJson({'id': 1, 'name': 'X', 'opens_at': '08:00:00', 'closes_at': '22:30:00'});
      expect(b.hoursLabel, '08:00 – 22:30');
      expect(Business.fromJson({'id': 1, 'name': 'X'}).hoursLabel, isNull);
    });
  });

  group('User', () {
    test('roles', () {
      final negocio = User.fromJson({'id': 4, 'name': 'Sabor', 'email': 'n@x', 'role': 'negocio', 'business_id': 1, 'business': {'name': 'Sabor Serrano'}});
      expect(negocio.isBusiness, isTrue);
      expect(negocio.isDriver, isFalse);
      expect(negocio.roleLabel, 'Negocio');
      expect(negocio.businessName, 'Sabor Serrano');
    });

    test('toJson y fromJson ida y vuelta (sesión guardada)', () {
      final u = User.fromJson({'id': 4, 'name': 'Sabor', 'email': 'n@x', 'role': 'negocio', 'business_id': 1, 'business': {'name': 'Sabor Serrano'}});
      final back = User.fromJson(u.toJson());
      expect(back.businessId, 1);
      expect(back.businessName, 'Sabor Serrano');
      expect(back.role, 'negocio');
    });
  });
}
