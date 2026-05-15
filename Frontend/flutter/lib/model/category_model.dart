import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_food_app/common/globs.dart';

class CategoryModel {
  final int id;
  final String name;
  final String imageUrl;
  final int itemsCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.itemsCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'] ?? json['image'] ?? '').toString(),
      itemsCount: json['items_count'] is int
          ? json['items_count'] as int
          : int.tryParse('${json['items_count']}') ?? 0,
    );
  }

  /// Icon/emoji khi DB chưa có imageUrl.
  String get displayEmoji {
    final n = name.toLowerCase();
    if (n.contains('phở') || n.contains('bún')) return '🍜';
    if (n.contains('pizza') || n.contains('pasta') || n.contains('âu')) return '🍕';
    if (n.contains('nhanh') || n.contains('burger')) return '🍔';
    if (n.contains('việt')) return '🍲';
    if (n.contains('uống') || n.contains('cafe')) return '🥤';
    if (n.contains('cơm')) return '🍱';
    if (n.contains('tráng') || n.contains('ngọt')) return '🍰';
    if (n.contains('nhật') || n.contains('sushi')) return '🍣';
    return '🍽️';
  }

  static Future<List<CategoryModel>> fetchAll() async {
    try {
      final url = Uri.parse(Globs.categoriesUrl);
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .where((c) => c.name.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
