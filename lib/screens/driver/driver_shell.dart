import 'package:flutter/material.dart';

import '../../state/location_service.dart';
import '../profile_screen.dart';
import 'available_orders_screen.dart';
import 'my_deliveries_screen.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _tab = 0;
  final _deliveriesKey = GlobalKey<MyDeliveriesScreenState>();

  @override
  void dispose() {
    LocationService.instance.goOffline();
    super.dispose();
  }

  void _goTo(int i) {
    setState(() => _tab = i);
    if (i == 1) _deliveriesKey.currentState?.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          AvailableOrdersScreen(onAccepted: () => _goTo(1)),
          MyDeliveriesScreen(key: _deliveriesKey),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.radar_outlined), selectedIcon: Icon(Icons.radar_rounded), label: 'Disponibles'),
          NavigationDestination(icon: Icon(Icons.two_wheeler_outlined), selectedIcon: Icon(Icons.two_wheeler_rounded), label: 'Mis entregas'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}
