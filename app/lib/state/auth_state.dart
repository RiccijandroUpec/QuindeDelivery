import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';
import '../models.dart';
import 'realtime.dart';

class AuthState extends ChangeNotifier {
  User? user;
  bool ready = false;

  bool get loggedIn => user != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final cached = prefs.getString('user');
    if (token != null && cached != null) {
      Api.instance.token = token;
      user = User.fromJson(jsonDecode(cached));
      Realtime.instance.connect(token);
      // Refresca los datos en segundo plano; si el token ya no sirve, cierra sesión.
      Api.instance.get('/me').then((j) => _save(token, User.fromJson(j))).catchError((e) {
        if (e is ApiException && e.statusCode == 401) _clear();
      });
    }
    ready = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final res = await Api.instance.post('/login', {'email': email, 'password': password});
    await _save(res['token'], User.fromJson(res['user']));
  }

  /// Devuelve un mensaje si la cuenta queda en revisión (repartidores).
  Future<String?> register(Map<String, dynamic> data) async {
    final res = await Api.instance.post('/register', data);
    if (res['pending'] == true) return res['message'] as String;
    await _save(res['token'], User.fromJson(res['user']));
    return null;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final res = await Api.instance.put('/me', data);
    await _save(Api.instance.token!, User.fromJson(res));
  }

  Future<void> logout() async {
    try {
      await Api.instance.post('/logout');
    } catch (_) {}
    await _clear();
  }

  Future<void> _save(String token, User u) async {
    Api.instance.token = token;
    Realtime.instance.connect(token);
    user = u;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(u.toJson()));
    notifyListeners();
  }

  Future<void> _clear() async {
    Api.instance.token = null;
    Realtime.instance.disconnect();
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }
}
