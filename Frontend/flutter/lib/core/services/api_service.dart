import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import '../constants.dart';

class ApiService {
  Future<List<Restaurant>> getRestaurants() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.restaurants));
      
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Restaurant.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load restaurants');
      }
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'Đăng nhập thất bại';
      }
    } catch (e) {
      throw 'Lỗi kết nối: $e';
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String fullName, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email, 
          'password': password,
          'fullName': fullName,
          'phoneNumber': phone
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw error['message'] ?? 'Đăng ký thất bại';
      }
    } catch (e) {
      throw 'Lỗi kết nối: $e';
    }
  }

  Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/users'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Lỗi khi tải danh sách người dùng');
      }
    } catch (e) {
      throw 'Lỗi kết nối: $e';
    }
  }
}
