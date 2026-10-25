import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthState>().login(_email.text.trim(), _password.text);
    } catch (e) {
      if (mounted) showMessage(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo(String email) {
    _email.text = email;
    _password.text = '123456';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: AuthLayout(
        title: 'Lo que quieras,\nvolando a tu puerta',
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Iniciar sesión', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Bienvenido de vuelta 👋', style: t.bodyMedium?.copyWith(color: AppColors.muted)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.mail_outline_rounded)),
                validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Entrar'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿No tienes cuenta?', style: t.bodyMedium),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Regístrate', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Cuentas de prueba', textAlign: TextAlign.center, style: t.labelSmall?.copyWith(color: AppColors.muted)),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.person_outline, size: 18),
                    label: const Text('Cliente'),
                    onPressed: () => _fillDemo('cliente@delivery.test'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.two_wheeler_rounded, size: 18),
                    label: const Text('Repartidor'),
                    onPressed: () => _fillDemo('repartidor@delivery.test'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.storefront_rounded, size: 18),
                    label: const Text('Negocio'),
                    onPressed: () => _fillDemo('negocio@delivery.test'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cabecera de polígonos + tarjeta blanca redondeada para login/registro.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.title, required this.child, this.showBack = false});

  final String title;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return LayoutBuilder(builder: (context, c) {
      final headerH = (c.maxHeight * .36).clamp(240.0, 340.0);
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Stack(
            children: [
              SizedBox(
                height: headerH + 40,
                width: double.infinity,
                child: PolyBackground(
                  seed: 11,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showBack)
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Wordmark(light: true, logoSize: 44, showLogo: false),
                                    const SizedBox(height: 10),
                                    Text(title,
                                        style: t.headlineSmall?.copyWith(
                                            color: Colors.white, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -.5)),
                                  ],
                                ),
                              ),
                              HoveringBird(size: (headerH * .34).clamp(80.0, 120.0)),
                            ],
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: headerH),
                constraints: BoxConstraints(minHeight: c.maxHeight - headerH),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(padding: const EdgeInsets.fromLTRB(24, 28, 24, 24), child: child),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
