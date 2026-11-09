import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static String? token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request();
    } catch (_) {
      throw ApiException('Tidak dapat terhubung ke server. Pastikan backend menyala.');
    }
    final data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    final msg = (data is Map && data['message'] != null)
        ? data['message'].toString()
        : 'Terjadi kesalahan (${res.statusCode})';
    throw ApiException(msg);
  }

  static Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  static Future<dynamic> get(String path) =>
      _send(() => http.get(_uri(path), headers: _headers));

  static Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  static Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send(() => http.put(_uri(path), headers: _headers, body: jsonEncode(body)));

  // ---- Auth ----
  static Future<Map<String, dynamic>> register(String name, String phone) async =>
      Map<String, dynamic>.from(
          await post('/auth/register', {'full_name': name, 'phone': phone}));

  static Future<Map<String, dynamic>> login(String phone) async =>
      Map<String, dynamic>.from(await post('/auth/login', {'phone': phone}));

  static Future<Map<String, dynamic>> verifyOtp(String phone, String code) async =>
      Map<String, dynamic>.from(
          await post('/auth/verify-otp', {'phone': phone, 'code': code}));

  // ---- Meja ----
  static Future<List<dynamic>> getTables({String? area}) async {
    final path = area == null ? '/tables' : '/tables?area=${Uri.encodeQueryComponent(area)}';
    return (await get(path)) as List<dynamic>;
  }

  // Ketersediaan semua meja pada tanggal (YYYY-MM-DD) dan jam (HH:MM) tertentu
  static Future<List<dynamic>> getAvailability(String date, String time) async {
    final path = '/reservations/availability'
        '?date=${Uri.encodeQueryComponent(date)}&time=${Uri.encodeQueryComponent(time)}';
    return (await get(path)) as List<dynamic>;
  }

  // ---- Menu ----
  static Future<List<dynamic>> getMenu({String? category}) async {
    final path =
        category == null ? '/menu' : '/menu?category=${Uri.encodeQueryComponent(category)}';
    return (await get(path)) as List<dynamic>;
  }
}