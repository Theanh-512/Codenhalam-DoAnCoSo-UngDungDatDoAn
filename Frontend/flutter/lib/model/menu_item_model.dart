import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_food_app/common/globs.dart';

class MenuItemModel {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String category; // "Món chính", "Khai vị", "Tráng miệng", "Đồ uống"
  final String emoji;
  final String imageUrl;
  final bool isAvailable;
  final bool isBestSeller;

  MenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.emoji,
    required this.imageUrl,
    this.isAvailable = true,
    this.isBestSeller = false,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    // Xử lý linh hoạt PascalCase và camelCase từ .NET
    final name = (json['name'] ?? json['Name'] ?? '').toString();
    final desc = (json['description'] ?? json['Description'] ?? '').toString();
    final priceRaw = json['price'] ?? json['Price'] ?? 0;
    final img = (json['imageUrl'] ?? json['ImageUrl'] ?? json['image'] ?? '').toString();
    final id = (json['id'] ?? json['Id'] ?? '').toString();
    final rId = (json['restaurantId'] ?? json['RestaurantId'] ?? '').toString();
    final avail = json['isAvailable'] ?? json['IsAvailable'] ?? true;
    final best = json['isBestSeller'] ?? json['IsBestSeller'] ?? false;

    // Xử lý Category Name
    String catName = "Món chính";
    final catObj = json['category'] ?? json['Category'];
    if (catObj != null) {
      if (catObj is Map) {
        catName = (catObj['name'] ?? catObj['Name'] ?? "Món chính").toString();
      } else {
        catName = catObj.toString();
      }
    }

    return MenuItemModel(
      id: id,
      restaurantId: rId,
      name: name,
      description: desc,
      price: double.tryParse(priceRaw.toString()) ?? 0.0,
      category: catName,
      emoji: _getEmojiForCategory(catName),
      imageUrl: img,
      isAvailable: avail == true || avail == 1 || avail == "true",
      isBestSeller: best == true || best == 1 || best == "true",
    );
  }

  static String _getEmojiForCategory(String cat) {
    if (cat.contains('Phở')) return '🍜';
    if (cat.contains('Bún')) return '🍲';
    if (cat.contains('Cơm')) return '🍚';
    if (cat.contains('Bánh')) return '🥖';
    if (cat.contains('Nước') || cat.contains('Uống')) return '🥤';
    return '🍱';
  }

  static List<String> categoriesOf(List<MenuItemModel> items) {
    final seen = <String>{};
    final out = <String>[];
    for (final m in items) {
      if (m.category.isEmpty) continue;
      if (seen.add(m.category)) out.add(m.category);
    }
    return out;
  }

  static Future<List<MenuItemModel>> fetchByRestaurant(dynamic restaurantId) async {
    try {
      final cleanId = restaurantId.toString();
      final url = Uri.parse('${Globs.baseUrl}/api/Restaurants/$cleanId/menu');
      print("🔍 Đang tải thực đơn từ: $url");
      
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        print("✅ Đã tải được ${data.length} món ăn.");
        return data.map((e) => MenuItemModel.fromJson(e)).toList();
      } else {
        print("❌ Lỗi API Menu: ${res.statusCode}");
      }
    } catch (e) {
      print("❌ Lỗi kết nối Menu: $e");
    }
    return [];
  }

  static Future<List<MenuItemModel>> search(String q) async {
    final query = q.trim();
    if (query.isEmpty) return [];
    try {
      final url = Uri.parse(Globs.searchUrl).replace(
        queryParameters: {'q': query},
      );
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List foodList = data['foodItems'] ?? data['FoodItems'] ?? [];
        return foodList
            .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
            .where((m) => m.name.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<MenuItemModel>> fetchByCategory(String categoryName) async {
    try {
      final response = await http.get(Uri.parse("${Globs.baseUrl}/api/Restaurants/by-category/$categoryName"));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((m) => MenuItemModel.fromJson(m)).toList();
      }
    } catch (e) {
      print("fetchByCategory error: $e");
    }
    return [];
  }
}
