import 'package:shared_preferences/shared_preferences.dart';

/// Lưu người nhận + địa chỉ để lần sau không nhập lại (cả khi chưa đăng nhập).
class CheckoutPrefs {
  static const _kName = 'checkout_receiver_name';
  static const _kPhone = 'checkout_receiver_phone';
  static const _kAddress = 'checkout_delivery_address';
  static const _kLat = 'checkout_delivery_lat';
  static const _kLng = 'checkout_delivery_lng';

  static Future<void> save({
    required String name,
    required String phone,
    required String address,
    double? lat,
    double? lng,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name.trim());
    await p.setString(_kPhone, phone.trim().replaceAll(RegExp(r'\s+'), ''));
    await p.setString(_kAddress, address.trim());
    if (lat != null) {
      await p.setDouble(_kLat, lat);
    } else {
      await p.remove(_kLat);
    }
    if (lng != null) {
      await p.setDouble(_kLng, lng);
    } else {
      await p.remove(_kLng);
    }
  }

  static Future<Map<String, dynamic>> load() async {
    final p = await SharedPreferences.getInstance();
    final lat = p.getDouble(_kLat);
    final lng = p.getDouble(_kLng);
    return {
      'name': p.getString(_kName) ?? '',
      'phone': p.getString(_kPhone) ?? '',
      'address': p.getString(_kAddress) ?? '',
      'lat': lat,
      'lng': lng,
    };
  }

  static Future<void> clearAddressOnly() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAddress);
    await p.remove(_kLat);
    await p.remove(_kLng);
  }
}
