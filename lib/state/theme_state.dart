import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema de la app: el del sistema, claro u oscuro. Se recuerda entre sesiones.
class ThemeState extends ChangeNotifier {
  ThemeMode mode = ThemeMode.system;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    mode = ThemeMode.values.asNameMap()[prefs.getString('theme_mode')] ?? ThemeMode.system;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    mode = m;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', m.name);
  }
}
