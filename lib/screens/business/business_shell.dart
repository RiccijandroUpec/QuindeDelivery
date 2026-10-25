import 'package:flutter/material.dart';

import '../profile_screen.dart';
import 'business_history_screen.dart';
import 'business_menu_screen.dart';
import 'business_orders_screen.dart';

class BusinessShell extends StatefulWidget {
  const BusinessShell({super.key});

  @override
  State<BusinessShell> createState() => _BusinessShellState();
}

class _BusinessShellState extends State<BusinessShell> {
  int _tab = 0;
  final _historyKey = GlobalKey<BusinessHistoryScreenState>();

  void _goTo(int i) {
    setState(() => _tab = i);
    if (i == 2) _historyKey.currentState?.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const BusinessOrdersScreen(),
          const BusinessMenuScreen(),
          BusinessHistoryScreen(key: _historyKey),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Pedidos'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu_rounded), label: 'Menú'),
          NavigationDestination(icon: Icon(Icons.history_rounded), selectedIcon: Icon(Icons.history_rounded), label: 'Historial'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}
