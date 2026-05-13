import 'dart:convert';
import 'package:flutter/foundation.dart';

class Globs {
  static const String loopbackHost = '127.0.0.1';
  static const String androidEmulatorHost = '10.0.2.2';
  static const String port = '5149';

  static const String _apiHostOverride = String.fromEnvironment(
    'API_HOST',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_apiHostOverride.isNotEmpty) {
      return 'http://$_apiHostOverride:$port';
    }
    if (kIsWeb) {
      return 'http://$loopbackHost:$port';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$androidEmulatorHost:$port';
    }
    return 'http://$loopbackHost:$port';
  }

  static String get loginUrl => '$baseUrl/api/Users/login';
  static String get registerUrl => '$baseUrl/api/Users/register';
  static String get socialLoginUrl => '$baseUrl/api/Users/social';
  static String get profileUrl => '$baseUrl/api/Users/profile';
  static String get forgotPasswordUrl => '$baseUrl/api/Users/forgot-password';
  static String get resetPasswordUrl => '$baseUrl/api/Users/reset-password';

  static String get restaurantsUrl => '$baseUrl/api/Restaurants';
  static String get itemsUrl => '$baseUrl/api/FoodItems';
  static String get searchUrl => '$baseUrl/api/Search';
  static String get categoriesUrl => '$baseUrl/api/Categories';

  static String get publicVouchersUrl => '$baseUrl/api/Vouchers';
  static String get checkoutUrl => '$baseUrl/api/Orders';
  static String get myOrdersUrl => '$baseUrl/api/Orders/user';

  static String get adminOrdersUrl => '$baseUrl/api/admin/orders';
  static String adminOrderPatchUrl(int id) => '$baseUrl/api/admin/orders/$id';
  static String get adminRestaurantsUrl => '$baseUrl/api/admin/restaurants';
  static String adminRestaurantUrl(String id) =>
      '$baseUrl/api/admin/restaurants/$id';
  static String get adminCategoriesUrl => '$baseUrl/api/admin/categories';
  static String adminCategoryUrl(String id) =>
      '$baseUrl/api/admin/categories/$id';
  static String get adminItemsUrl => '$baseUrl/api/admin/items';
  static String adminItemUrl(String id) => '$baseUrl/api/admin/items/$id';
  static String get adminVouchersUrl => '$baseUrl/api/admin/vouchers';
  static String adminVoucherDetailUrl(String code) =>
      '$baseUrl/api/admin/vouchers/${Uri.encodeComponent(code)}';
  static String get adminUsersUrl => '$baseUrl/api/admin/users';
  static String adminUserPatchUrl(int id) => '$baseUrl/api/admin/users/$id';

  static String apiErrorMessage(String body, {String fallback = 'Lỗi'}) {
    final t = body.trim();
    if (t.isEmpty) return fallback;
    try {
      final data = jsonDecode(t);
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}
    return t.length > 200 ? fallback : t;
  }
}
