import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? user;

  bool get isLoggedIn => ApiService.token != null && user != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    ApiService.token = prefs.getString('token');
    final saved = prefs.getString('user');
    user = saved != null ? jsonDecode(saved) as Map<String, dynamic> : null;
    notifyListeners();
  }

  Future<void> setSession(String token, Map<String, dynamic> u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(u));
    ApiService.token = token;
    user = u;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    ApiService.token = null;
    user = null;
    notifyListeners();
  }
}