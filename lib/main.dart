import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/business/business_shell.dart';
import 'screens/client/client_shell.dart';
import 'screens/driver/driver_shell.dart';
import 'state/auth_state.dart';
import 'state/cart_state.dart';
import 'state/theme_state.dart';
import 'theme.dart';
import 'widgets/brand.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()..init()),
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProvider(create: (_) => ThemeState()..init()),
      ],
      child: const DeliveryApp(),
    ),
  );
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeState>().mode;
    return MaterialApp(
      title: 'Colibrí Delivery',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      // Los widgets leen AppColors directamente: se actualiza la paleta y se reconstruye todo al cambiar de tema.
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        AppColors.palette = AppPalette.of(brightness);
        return KeyedSubtree(key: ValueKey(brightness), child: child!);
      },
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AuthGate(),
    );
  }
}

/// Decide qué ver según la sesión y el rol del usuario.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.ready) return const SplashScreen();
    if (!auth.loggedIn) return const LoginScreen();
    final user = auth.user!;
    if (user.isBusiness) return BusinessShell(key: ValueKey('business-${user.id}'));
    return user.isDriver ? DriverShell(key: ValueKey('driver-${user.id}')) : ClientShell(key: ValueKey('client-${user.id}'));
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(offset: Offset(0, (1 - v) * 16), child: child),
          ),
          child: Container(
            width: 340,
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HoveringBird(size: 120, glow: false),
                const Wordmark(logoSize: 84, showLogo: false),
                const SizedBox(height: 10),
                Text('Lo que quieras, volando a tu puerta', style: t.bodyLarge?.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
