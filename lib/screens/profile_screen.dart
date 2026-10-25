import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../state/cart_state.dart';
import '../state/theme_state.dart';
import '../theme.dart';
import '../widgets/brand.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _edit(BuildContext context) async {
    final auth = context.read<AuthState>();
    final u = auth.user!;
    final name = TextEditingController(text: u.name);
    final phone = TextEditingController(text: u.phone);
    final vehicle = TextEditingController(text: u.vehicle);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(c).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Celular'),
              keyboardType: TextInputType.phone,
            ),
            if (u.isDriver) ...[
              const SizedBox(height: 12),
              TextField(
                controller: vehicle,
                decoration: const InputDecoration(labelText: 'Vehículo y placa'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await auth.updateProfile({'name': name.text.trim(), 'phone': phone.text.trim(), if (u.isDriver) 'vehicle': vehicle.text.trim()});
      if (context.mounted) showMessage(context, 'Perfil actualizado', error: false);
    } catch (e) {
      if (context.mounted) showMessage(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final user = context.watch<AuthState>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          PolyBackground(
            seed: 5,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: t.headlineSmall?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          Text(user.email, style: t.bodySmall?.copyWith(color: Colors.white70)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              user.roleLabel,
                              style: t.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  if (user.isBusiness)
                    ListTile(
                      leading: const Icon(Icons.storefront_rounded),
                      title: const Text('Negocio'),
                      subtitle: Text(user.businessName ?? '—'),
                    ),
                  ListTile(leading: const Icon(Icons.phone_outlined), title: const Text('Celular'), subtitle: Text(user.phone ?? '—')),
                  if (user.isDriver)
                    ListTile(
                      leading: const Icon(Icons.two_wheeler_rounded),
                      title: const Text('Vehículo'),
                      subtitle: Text(user.vehicle ?? '—'),
                    ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        const Icon(Icons.dark_mode_outlined),
                        const SizedBox(width: 16),
                        const Expanded(child: Text('Tema')),
                        SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
                          segments: const [
                            ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded, size: 18), tooltip: 'Sistema'),
                            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 18), tooltip: 'Claro'),
                            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 18), tooltip: 'Oscuro'),
                          ],
                          selected: {context.watch<ThemeState>().mode},
                          onSelectionChanged: (s) => context.read<ThemeState>().setMode(s.first),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Editar perfil'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _edit(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.red),
                    title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      context.read<CartState>().clear();
                      context.read<AuthState>().logout();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Center(child: Wordmark(logoSize: 40)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
