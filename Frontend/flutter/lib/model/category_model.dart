import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_food_app/common/globs.dart';

class CategoryModel {
  final String name;
  final String imageUrl;
  final String itemsCount;

  CategoryModel({
    required this.name, 
    required this.imageUrl, 
    this.itemsCount = ""
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      itemsCount: json['items_count']?.toString() ?? '',
    );
  }

  static Future<List<CategoryModel>> fetchAll() async {
    try {
      final url = Uri.parse(Globs.categoriesUrl);
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => CategoryModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }
}
