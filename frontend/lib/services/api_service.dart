import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  static Future<List<dynamic>> getTables() async {
    final res = await http.get(Uri.parse('${AppConfig.baseUrl}/tables'));
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat meja (${res.statusCode})');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }
}