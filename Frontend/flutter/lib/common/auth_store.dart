import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lưu JWT sau đăng nhập; gửi kèm API (profile, đặt hàng, lịch sử đơn).
class AuthStore {
  static const _kToken = 'auth_jwt';
  static const _kRole = 'auth_role';
  static const _kUserId = 'auth_user_id';
  static const _kEmail = 'auth_email';
  static const _kFullName = 'auth_full_name';

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
      await p.setString(_kRole, role.toLowerCase());
    }
  }

  static Future<String?> getRole() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRole);
  }

  static Future<bool> isAdmin() async => (await getRole()) == 'admin';

  static Future<int?> getUserId() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kUserId);
  }

  static Future<String?> getEmail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kEmail);
  }

  static Future<String?> getFullName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kFullName);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kRole);
    await p.remove(_kUserId);
    await p.remove(_kEmail);
    await p.remove(_kFullName);
  }

  /// Lưu JWT + role + thông tin cơ bản từ response của login/register.
  /// Backend mới trả `token` (JWT thật). Phòng khi backend cũ chỉ trả email,
  /// vẫn fallback lưu email làm token để khỏi vỡ luồng.
  static Future<void> saveTokenFromResponseBody(String body) async {
    try {
      final m = jsonDecode(body);
      if (m is! Map<String, dynamic>) return;

      final p = await SharedPreferences.getInstance();

      final token = (m['token'] ?? m['accessToken']) as String?;
      if (token != null && token.isNotEmpty) {
        await p.setString(_kToken, token);
      } else if (m['email'] != null) {
        // Fallback cũ — KHÔNG dùng cho production.
        await p.setString(_kToken, m['email'].toString());
      }

      final id = m['id'];
      if (id is int) {
        await p.setInt(_kUserId, id);
      } else if (id is String) {
        final v = int.tryParse(id);
        if (v != null) await p.setInt(_kUserId, v);
      }

      if (m['email'] != null) {
        await p.setString(_kEmail, m['email'].toString());
      }
      final fn = m['fullName'] ?? m['fullname'];
      if (fn != null) {
        await p.setString(_kFullName, fn.toString());
      }

      // role: ưu tiên 'role' (Admin/User/Shipper), fallback 'userRole'.
      final rawRole = (m['role'] ?? m['userRole'] ?? '').toString();
      if (rawRole.isNotEmpty) {
        await p.setString(_kRole, rawRole.toLowerCase());
      } else {
        // Fallback hiếm gặp khi backend không trả role.
        final email = (m['email'] ?? '').toString().toLowerCase();
        await p.setString(
          _kRole,
          email == 'admin@gmail.com' || email == 'admin@foodapp.com' ? 'admin' : 'user',
        );
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
