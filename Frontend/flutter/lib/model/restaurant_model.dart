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
    final type1 = json['type1']?.toString() ?? '';
    final open = json['is_open'];
    final isOpen = open == null
        ? true
        : (open == true || open == 1 || open == '1' || open == 'true');
    final dRaw = json['distance_km'];
    double? dkm;
    if (dRaw != null) {
      dkm = double.tryParse(dRaw.toString());
    }
    return RestaurantModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type1: type1,
      type2: json['type2'] ?? '',
      imageUrl: json['image'] ?? '',
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      reviewCount: int.tryParse(json['review_count'].toString()) ?? 0,
      category: json['category']?.toString() ?? type1,
      isOpen: isOpen,
      deliveryTime: json['delivery_time']?.toString() ?? '25–35 phút',
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? '') ??
          15000,
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

  /// [userLat] / [userLng]: vị trí khách — API tính Haversine và trả `distance_km`.
  static Future<List<RestaurantModel>> fetchAll({
    double? userLat,
    double? userLng,
  }) async {
    try {
      final base = Uri.parse('${Globs.baseUrl}/api/food/restaurants');
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
}
