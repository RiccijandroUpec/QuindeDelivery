import 'package:delivery_app/models.dart';
import 'package:delivery_app/theme.dart';
import 'package:delivery_app/widgets/brand.dart';
import 'package:delivery_app/widgets/order_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'models_test.dart' show orderJson;

// Sin buildTheme() para no descargar fuentes de Google en los tests.
Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('StatusChip muestra el nombre del estado', (tester) async {
    await tester.pumpWidget(wrap(const StatusChip('en_camino')));
    expect(find.text('En camino'), findsOneWidget);
  });

  testWidgets('StarRating responde al toque', (tester) async {
    var value = 0;
    await tester.pumpWidget(wrap(StatefulBuilder(
      builder: (context, setState) => StarRating(value: value, onChanged: (v) => setState(() => value = v)),
    )));
    expect(find.byIcon(Icons.star_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(3));
    await tester.pump();
    expect(value, 4);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
  });

  testWidgets('OrderSummary muestra el descuento del cupón', (tester) async {
    await tester.pumpWidget(wrap(SingleChildScrollView(child: OrderSummary(order: Order.fromJson(orderJson())))));
    expect(find.text('Descuento (COLIBRI2)'), findsOneWidget);
    expect(find.text('-\$2.00'), findsOneWidget);
    expect(find.text('Churrasco'), findsOneWidget);
  });

  testWidgets('EmptyState muestra título y mensaje', (tester) async {
    await tester.pumpWidget(wrap(const EmptyState(icon: Icons.inbox, title: 'Nada aquí', message: 'Vuelve luego')));
    expect(find.text('Nada aquí'), findsOneWidget);
    expect(find.text('Vuelve luego'), findsOneWidget);
  });

  testWidgets('el colibrí animado se dibuja y se puede desmontar', (tester) async {
    await tester.pumpWidget(wrap(const HoveringBird(size: 60)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AppLogo), findsOneWidget);
    await tester.pumpWidget(wrap(const SizedBox()));
  });

  test('colores por estado y paletas', () {
    AppColors.palette = AppPalette.light;
    expect(AppColors.status('pendiente'), AppColors.accent);
    expect(AppColors.status('cancelado'), const Color(0xFFDC2626));

    AppColors.palette = AppPalette.dark;
    expect(AppColors.isDark, isTrue);
    expect(AppColors.bg, AppPalette.dark.bg);
    AppColors.palette = AppPalette.light;
  });

  test('formato de dinero', () {
    expect(money.format(1.5), '\$1.50');
    expect(money.format(1234), '\$1,234.00');
  });
}
