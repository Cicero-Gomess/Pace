import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class PaceSession {
  PaceSession._();

  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('access_token');
  }

  static Future<Map<String, dynamic>> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('usuarioLogado');

    Map<String, dynamic> fallback = {};
    if (saved != null && saved.isNotEmpty) {
      try {
        fallback = Map<String, dynamic>.from(jsonDecode(saved) as Map);
      } catch (_) {}
    }

    final accessToken = await token();
    if (accessToken == null || accessToken.isEmpty) return fallback;

    try {
      final response = await http
          .get(
            ApiConfig.uri('/profile/me'),
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
        await prefs.setString('usuarioLogado', jsonEncode(data));
        return data;
      }
    } catch (_) {}

    return fallback;
  }

  static String username(Map<String, dynamic> user) {
    final value = user['username']?.toString().trim();
    return value == null || value.isEmpty ? 'Meu perfil' : value;
  }

  static String? avatar(Map<String, dynamic> user) {
    final value = user['foto_perfil'] ?? user['foto'] ?? user['avatar'];
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
