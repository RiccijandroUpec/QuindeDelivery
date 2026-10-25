import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset('assets/logo.svg', width: size, height: size);
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.light = false, this.logoSize = 56, this.showLogo = true});

  final bool light;
  final double logoSize;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final size = logoSize * .5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showLogo) ...[AppLogo(size: logoSize), const SizedBox(width: 6)],
        Text('Colibrí',
            style: t.headlineSmall?.copyWith(
              fontSize: size,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -.5,
              color: light ? Colors.white : AppColors.ink,
            )),
        SizedBox(width: size * .22),
        // Píldora como la de "POS" en Quinde.
        Container(
          padding: EdgeInsets.symmetric(horizontal: size * .26, vertical: size * .08),
          decoration: BoxDecoration(
            color: light ? AppColors.primaryLight : AppColors.primary,
            borderRadius: BorderRadius.circular(size),
          ),
          child: Text('DELIVERY',
              style: t.labelSmall?.copyWith(
                fontSize: size * .34,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                height: 1.1,
                color: light ? AppColors.ink : Colors.white,
              )),
        ),
      ],
    );
  }
}

/// Fondo de triángulos (low-poly) como las plumas del colibrí.
class PolyPainter extends CustomPainter {
  PolyPainter({this.seed = 7, this.colors = AppColors.poly, this.cell = 70});

  final int seed;
  final List<Color> colors;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    final cols = (size.width / cell).ceil() + 1;
    final rows = (size.height / cell).ceil() + 1;
    final cw = size.width / (cols - 1);
    final ch = size.height / (rows - 1);

    final pts = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        final edgeX = c == 0 || c == cols - 1;
        final edgeY = r == 0 || r == rows - 1;
        final jx = edgeX ? 0.0 : (rnd.nextDouble() - .5) * cw * .8;
        final jy = edgeY ? 0.0 : (rnd.nextDouble() - .5) * ch * .8;
        return Offset(c * cw + jx, r * ch + jy);
      });
    });

    final paint = Paint()..isAntiAlias = true;
    for (var r = 0; r < rows - 1; r++) {
      for (var c = 0; c < cols - 1; c++) {
        final a = pts[r][c], b = pts[r][c + 1], d = pts[r + 1][c], e = pts[r + 1][c + 1];
        final flip = rnd.nextBool();
        final tris = flip ? [[a, b, e], [a, e, d]] : [[a, b, d], [b, e, d]];
        for (final t in tris) {
          final cx = (t[0].dx + t[1].dx + t[2].dx) / 3;
          final cy = (t[0].dy + t[1].dy + t[2].dy) / 3;
          // El color sigue un degradado diagonal con algo de ruido.
          final pos = ((cx / size.width) * .6 + (cy / size.height) * .4 + (rnd.nextDouble() - .5) * .35).clamp(0.0, .999);
          final scaled = pos * (colors.length - 1);
          final i = scaled.floor();
          final base = Color.lerp(colors[i], colors[min(i + 1, colors.length - 1)], scaled - i)!;
          final shade = (rnd.nextDouble() - .5) * .18;
          paint.color = shade > 0 ? Color.lerp(base, Colors.white, shade)! : Color.lerp(base, Colors.black, -shade)!;
          canvas.drawPath(Path()..addPolygon(t, true), paint);
          // Bordes finos para que se note el facetado.
          canvas.drawPath(
            Path()..addPolygon(t, true),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .6
              ..color = Colors.white.withValues(alpha: .06),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(PolyPainter old) => old.seed != seed || old.colors != colors || old.cell != cell;
}

class PolyBackground extends StatelessWidget {
  const PolyBackground({super.key, required this.child, this.seed = 7, this.colors = AppColors.poly, this.cell = 70});

  final Widget child;
  final int seed;
  final List<Color> colors;
  final double cell;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: PolyPainter(seed: seed, colors: colors, cell: cell),
        // Velo de luz: brillo cálido arriba a la derecha y sombra abajo para dar profundidad.
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(.9, -1.1),
              radius: 1.3,
              colors: [AppColors.accent.withValues(alpha: .16), Colors.transparent],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: .18)],
              ),
            ),
            child: child,
          ),
        ),
      );
}

/// El colibrí suspendido en el aire: flota, se inclina y vibra como si aleteara.
class HoveringBird extends StatefulWidget {
  const HoveringBird({super.key, this.size = 96, this.glow = true});

  final double size;
  final bool glow;

  @override
  State<HoveringBird> createState() => _HoveringBirdState();
}

class _HoveringBirdState extends State<HoveringBird> with TickerProviderStateMixin {
  late final _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
  late final _wings = AnimationController(vsync: this, duration: const Duration(milliseconds: 90))..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    _wings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.3,
      height: s * 1.3,
      child: AnimatedBuilder(
        animation: Listenable.merge([_float, _wings]),
        builder: (context, child) {
          final f = Curves.easeInOut.transform(_float.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.glow)
                Container(
                  width: s * 1.12,
                  height: s * 1.12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: .7), width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 30, offset: const Offset(0, 12)),
                      BoxShadow(color: AppColors.quinde.withValues(alpha: .25 + f * .15), blurRadius: 40, spreadRadius: 2),
                    ],
                  ),
                ),
              Transform.translate(
                offset: Offset(0, (f - .5) * s * .14),
                child: Transform.rotate(
                  angle: (f - .5) * .12,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(1, 1 - _wings.value * .025, 1),
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        child: AppLogo(size: widget.glow ? s * .86 : s),
      ),
    );
  }
}

/// Indicador de carga con el colibrí.
class BirdLoader extends StatelessWidget {
  const BirdLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HoveringBird(size: 56, glow: false),
            if (message != null)
              Text(message!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted)),
          ],
        ),
      );
}

/// Abre el marcador del teléfono.
Future<void> callPhone(BuildContext context, String? phone) async {
  final number = phone?.replaceAll(RegExp(r'[^0-9+]'), '');
  if (number == null || number.isEmpty) {
    showMessage(context, 'No hay un número registrado.');
    return;
  }
  if (!await launchUrl(Uri(scheme: 'tel', path: number)) && context.mounted) {
    showMessage(context, 'No se pudo abrir el marcador.');
  }
}

/// Botón redondo para llamar.
class CallButton extends StatelessWidget {
  const CallButton({super.key, required this.phone, this.tooltip = 'Llamar'});

  final String? phone;
  final String tooltip;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primary.withValues(alpha: .1),
          foregroundColor: AppColors.primary,
        ),
        onPressed: phone == null ? null : () => callPhone(context, phone),
        icon: const Icon(Icons.call_rounded, size: 20),
      );
}

/// Estrellas de calificación (solo lectura o seleccionables).
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, this.size = 28, this.onChanged});

  final int value;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedScale(
                  scale: i <= value ? 1 : .88,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(i <= value ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: AppColors.gold),
                ),
              ),
            ),
        ],
      );
}

IconData categoryIcon(String name) => switch (name) {
      'restaurant' => Icons.restaurant_rounded,
      'pizza' => Icons.local_pizza_rounded,
      'burger' => Icons.lunch_dining_rounded,
      'coffee' => Icons.local_cafe_rounded,
      'pharmacy' => Icons.local_pharmacy_rounded,
      'market' => Icons.local_grocery_store_rounded,
      'liquor' => Icons.liquor_rounded,
      'pets' => Icons.pets_rounded,
      'dessert' => Icons.icecream_rounded,
      _ => Icons.storefront_rounded,
    };

/// Imagen de red con un placeholder de polígonos si no hay foto.
class PolyImage extends StatelessWidget {
  const PolyImage({super.key, this.url, required this.seed, this.icon = Icons.storefront_rounded, this.iconSize = 36});

  final String? url;
  final int seed;
  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final palettes = [
      AppColors.poly,
      const [Color(0xFF8C3A2E), Color(0xFFC4523F), Color(0xFFF2705E), Color(0xFFF59C8C), Color(0xFFF7B9A9)],
      const [Color(0xFF143F2B), Color(0xFF1F7A8C), Color(0xFF2E9E6B), Color(0xFF6CC79A), Color(0xFFA8E6C1)],
      const [Color(0xFF10231A), Color(0xFF1B5E3F), Color(0xFF2E9E6B), Color(0xFF6CC79A), Color(0xFFA8E6C1)],
    ];
    final placeholder = PolyBackground(
      seed: seed,
      cell: 40,
      colors: palettes[seed % palettes.length],
      child: Center(child: Icon(icon, color: Colors.white.withValues(alpha: .92), size: iconSize)),
    );
    if (url == null || url!.isEmpty) return SizedBox.expand(child: placeholder);
    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, _, _) => SizedBox.expand(child: placeholder),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.status(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(OrderStatus.label(status), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary.withValues(alpha: .14), AppColors.cyan.withValues(alpha: .08)],
                ),
              ),
              child: Icon(icon, size: 42, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, style: t.bodyMedium?.copyWith(color: AppColors.muted), textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

void showMessage(BuildContext context, Object message, {bool error = true}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message.toString()),
      backgroundColor: error ? const Color(0xFFDC2626) : AppColors.primaryDark,
    ));
}
