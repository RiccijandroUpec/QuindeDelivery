import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _vehicle = TextEditingController();
  final _password = TextEditingController();
  String _role = 'cliente';
  bool _loading = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final pending = await context.read<AuthState>().register({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'password': _password.text,
        'role': _role,
        if (_role == 'repartidor') 'vehicle': _vehicle.text.trim(),
      });
      if (!mounted) return;
      if (pending != null) {
        await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            icon: const HoveringBird(size: 64, glow: false),
            title: const Text('Solicitud enviada'),
            content: Text(pending, textAlign: TextAlign.center),
            actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Entendido'))],
          ),
        );
      }
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.card,
      body: AuthLayout(
        title: 'Crea tu cuenta\nen segundos',
        showBack: true,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Registro', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cliente', label: Text('Quiero pedir'), icon: Icon(Icons.shopping_bag_outlined)),
                  ButtonSegment(value: 'repartidor', label: Text('Quiero repartir'), icon: Icon(Icons.two_wheeler_rounded)),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary.withValues(alpha: .12),
                  selectedForegroundColor: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.trim().length < 3) ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline_rounded)),
                validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Celular', prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) => (v == null || v.trim().length < 9) ? 'Ingresa tu número' : null,
              ),
              if (_role == 'repartidor') ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _vehicle,
                  decoration: const InputDecoration(labelText: 'Vehículo y placa', prefixIcon: Icon(Icons.two_wheeler_rounded)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Ej: Moto PBA-123' : null,
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline_rounded)),
                validator: (v) => (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Crear cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
