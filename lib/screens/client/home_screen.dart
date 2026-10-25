import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../state/auth_state.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/cart_bar.dart';
import 'business_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Category> _categories = [];
  List<Business> _businesses = [];
  int? _categoryId;
  String _search = '';
  bool _loading = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        if (_categories.isEmpty) Api.instance.get('/categories'),
        Api.instance.get('/businesses', {
          if (_categoryId != null) 'category_id': '$_categoryId',
          if (_search.isNotEmpty) 'search': _search,
        }),
      ]);
      if (!mounted) return;
      setState(() {
        if (results.length == 2) {
          _categories = (results.first as List).map((j) => Category.fromJson(j)).toList();
        }
        _businesses = (results.last as List).map((j) => Business.fromJson(j)).toList();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = v.trim();
      _load();
    });
  }

  void _open(Business b) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessScreen(businessId: b.id, preview: b)));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final user = context.watch<AuthState>().user;
    final featured = _businesses.where((b) => b.featured).toList();
    final showFeatured = featured.isNotEmpty && _categoryId == null && _search.isEmpty;

    return Scaffold(
      bottomNavigationBar: const CartBar(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PolyBackground(
                seed: 21,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const AppLogo(size: 32),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hola, ${user?.name.split(' ').first ?? ''} 👋',
                                      style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                                  Text('¿Qué se te antoja hoy?', style: t.bodySmall?.copyWith(color: Colors.white70)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          onChanged: _onSearch,
                          decoration: InputDecoration(
                            hintText: 'Buscar negocios o productos',
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_categories.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 112,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final c = _categories[i];
                      final selected = c.id == _categoryId;
                      final color = AppColors.fromHex(c.color);
                      return GestureDetector(
                        onTap: () {
                          setState(() => _categoryId = selected ? null : c.id);
                          _load();
                        },
                        child: SizedBox(
                          width: 72,
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: selected ? color : color.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(categoryIcon(c.icon), color: selected ? Colors.white : color, size: 28),
                              ),
                              const SizedBox(height: 6),
                              Text(c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.labelSmall?.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (_loading && _businesses.isEmpty)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Sin conexión',
                  message: _error,
                  action: OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
                ),
              )
            else ...[
              if (showFeatured) ...[
                _sectionTitle('Destacados ✨'),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: featured.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => SizedBox(width: 280, child: BusinessCard(business: featured[i], onTap: () => _open(featured[i]))),
                    ),
                  ),
                ),
              ],
              _sectionTitle(_search.isNotEmpty ? 'Resultados' : 'Todos los negocios'),
              if (_businesses.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(icon: Icons.search_off_rounded, title: 'No encontramos nada', message: 'Prueba con otra búsqueda o categoría.'),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisExtent: 200,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => BusinessCard(business: _businesses[i], onTap: () => _open(_businesses[i])),
                      childCount: _businesses.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
      );
}

class BusinessCard extends StatelessWidget {
  const BusinessCard({super.key, required this.business, required this.onTap});

  final Business business;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final b = business;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PolyImage(url: b.coverUrl ?? b.logoUrl, seed: b.id),
                  if (!b.isOpen)
                    Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: const Text('Cerrado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        const Icon(Icons.schedule_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(b.timeLabel, style: t.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          '${b.categoryName ?? ''} · Envío ${money.format(b.deliveryFee)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                  Text(b.rating.toStringAsFixed(1), style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
