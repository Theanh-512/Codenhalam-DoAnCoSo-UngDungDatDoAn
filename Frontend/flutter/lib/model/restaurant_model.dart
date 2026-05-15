import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_food_app/common/globs.dart';

class RestaurantModel {
  final String id;
  final String name;
  final String type1;
  final String type2;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String category;
  final bool isOpen;
  final String deliveryTime;
  final double deliveryFee;
  /// Khoảng cách (km) từ vị trí khách — server tính khi gọi API kèm lat/lng.
  final double? distanceKm;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.type1,
    required this.type2,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    this.category = '',
    this.isOpen = true,
    this.deliveryTime = '25–35 phút',
    this.deliveryFee = 15000,
    this.distanceKm,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    // Xử lý linh hoạt PascalCase và camelCase từ .NET
    final name = (json['name'] ?? json['Name'] ?? '').toString();
    final id = (json['id'] ?? json['Id'] ?? '').toString();
    final type1 = (json['type1'] ?? json['Type1'] ?? json['description'] ?? json['Description'] ?? '').toString();
    final img = (json['imageUrl'] ?? json['ImageUrl'] ?? json['image'] ?? json['Image'] ?? '').toString();
    
    final ratingRaw = json['rating'] ?? json['Rating'];
    final revRaw = json['reviewCount'] ?? json['ReviewCount'] ?? json['review_count'] ?? json['Review_count'];

    final open = json['isOpen'] ?? json['IsOpen'] ?? json['isActive'] ?? json['IsActive'];
    final isOpen = open == null ? true : (open == true || open == 1 || open == '1' || open == 'true');
    
    final dRaw = json['distanceKm'] ?? json['DistanceKm'] ?? json['distance_km'];
    double? dkm;
    if (dRaw != null) {
      dkm = double.tryParse(dRaw.toString());
    }

    return RestaurantModel(
      id: id,
      name: name,
      type1: type1,
      type2: (json['type2'] ?? json['Type2'] ?? '').toString(),
      imageUrl: img,
      rating: double.tryParse(ratingRaw?.toString() ?? '') ?? 
              (4.0 + (id.hashCode % 10) / 10.0),
      reviewCount: int.tryParse(revRaw?.toString() ?? '') ?? 
              (50 + (id.hashCode % 450)),
      category: (json['category'] ?? json['Category'] ?? type1).toString(),
      isOpen: isOpen,
      deliveryTime: (json['deliveryTime'] ?? json['DeliveryTime'] ?? '25–35 phút').toString(),
      deliveryFee: double.tryParse((json['deliveryFee'] ?? json['DeliveryFee'] ?? '15000').toString()) ?? 15000,
      distanceKm: dkm,
    );
  }

  /// Nhãn rõ cho `type1` / `type2` trên UI (dòng món + kiểu ẩm thực).
  String get typeTagsDisplayLine =>
      RestaurantModel.formatTypeTagsDisplay(type1, type2);

  static String formatTypeTagsDisplay(String? t1, String? t2) {
    final a = (t1 ?? '').trim();
    final b = (t2 ?? '').trim();
    if (a.isEmpty && b.isEmpty) return '';
    if (a.isEmpty) return 'Kiểu ẩm thực: $b';
    if (b.isEmpty) return 'Dòng món: $a';
    return 'Dòng món: $a  ·  Kiểu ẩm thực: $b';
  }

  static Future<List<RestaurantModel>> fetchAll({
    double? userLat,
    double? userLng,
  }) async {
    try {
      final base = Uri.parse(Globs.restaurantsUrl);
      final Uri url;
      if (userLat != null && userLng != null) {
        url = base.replace(queryParameters: {
          'lat': userLat.toString(),
          'lng': userLng.toString(),
        });
      } else {
        url = base;
      }
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<RestaurantModel>> search(String q) async {
    final query = q.trim();
    if (query.isEmpty) return [];
    try {
      final url = Uri.parse(Globs.searchUrl).replace(
        queryParameters: {'q': query},
      );
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        final List restList = data['restaurants'] ?? data['Restaurants'] ?? [];
        return restList
            .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
            .where((r) => r.name.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Tab Ưu đãi: thử GPS rồi tải danh sách có khoảng cách.
  static Future<List<RestaurantModel>> fetchAllWithBestEffortLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return fetchAll();
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));
      return fetchAll(userLat: p.latitude, userLng: p.longitude);
    } catch (_) {
      return fetchAll();
    }
  }

  static Future<List<RestaurantModel>> fetchByCategory(String categoryName) async {
    try {
      final url = Uri.parse('${Globs.baseUrl}/api/Restaurants/by-category/${Uri.encodeComponent(categoryName)}');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }
}
