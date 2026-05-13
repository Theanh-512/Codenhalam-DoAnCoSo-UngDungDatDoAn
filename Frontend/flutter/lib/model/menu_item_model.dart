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
    return MenuItemModel(
      id: json['id'] ?? '',
      restaurantId: json['restaurant_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      category: json['category'] ?? '',
      emoji: json['emoji'] ?? '',
      imageUrl: json['image'] ?? '',
      isAvailable: true,
      isBestSeller: json['is_best_seller'] ?? false,
    );
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

  static Future<List<MenuItemModel>> fetchByRestaurant(String restaurantId) async {
    try {
      final url = Uri.parse('${Globs.itemsUrl}?restaurantId=$restaurantId');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => MenuItemModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<MenuItemModel>> fetchByCategory(String category) async {
    try {
      final url = Uri.parse('${Globs.itemsUrl}?category=$category');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => MenuItemModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<MenuItemModel>> search(String q) async {
    try {
      final url = Uri.parse(Globs.searchUrl).replace(
        queryParameters: {'q': q},
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => MenuItemModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}
