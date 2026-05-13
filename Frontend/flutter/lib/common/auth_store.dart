import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lưu JWT sau đăng nhập; gửi kèm API (profile, đặt hàng, lịch sử đơn).
class AuthStore {
  static const _kToken = 'auth_jwt';
  static const _kRole = 'auth_role';

  static Future<void> setToken(String? token) async {
    final p = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await p.remove(_kToken);
    } else {
      await p.setString(_kToken, token);
    }
  }

  static Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kToken);
  }

  static Future<void> setRole(String? role) async {
    final p = await SharedPreferences.getInstance();
    if (role == null || role.isEmpty) {
      await p.remove(_kRole);
    } else {
      await p.setString(_kRole, role);
    }
  }

  static Future<String?> getRole() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRole);
  }

  static Future<bool> isAdmin() async => (await getRole()) == 'admin';

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kRole);
  }

  static Future<void> saveTokenFromResponseBody(String body) async {
    try {
      final m = jsonDecode(body);
      if (m is! Map<String, dynamic>) return;
      
      // Save ID and Email (acting as token for now, .NET does not return JWT yet)
      if (m['email'] != null) {
        await setToken(m['email'].toString());
        
        // Determine role
        if (m['email'].toString().toLowerCase() == 'admin@foodapp.com') {
          await setRole('admin');
        } else {
          await setRole('user');
        }
      }
    } catch (_) {}
  }

  static Future<Map<String, String>> authHeaders({
    bool jsonContent = false,
  }) async {
    final h = <String, String>{};
    if (jsonContent) {
      h['Content-Type'] = 'application/json';
    }
    final t = await getToken();
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
    return h;
  }
}
