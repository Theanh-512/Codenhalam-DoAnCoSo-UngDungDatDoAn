import 'package:flutter/foundation.dart';
import 'menu_item_model.dart';

class CartItem {
  final MenuItemModel item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  double get subtotal => item.price * quantity;
}

/// Một giỏ singleton toàn app; thanh toán qua API — mỗi đơn chỉ một nhà hàng.
class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<CartItem> _items = [];
  final Map<String, String> _restaurantNamesById = {};

  List<CartItem> get items => List.unmodifiable(_items);

  String get restaurantId {
    if (_items.isEmpty) return '';
    return _items.first.item.restaurantId.trim();
  }

  String get restaurantName => _headerLabel();

  bool get isEmpty => _items.isEmpty;
  int get totalQuantity => _items.fold(0, (sum, e) => sum + e.quantity);

  double get subtotal => _items.fold(0.0, (sum, e) => sum + e.subtotal);
  double get deliveryFee => subtotal > 150000 ? 0 : 15000;
  double get total => subtotal + deliveryFee;

  bool get hasMultipleRestaurants {
    final ids = _items
        .map((e) => e.item.restaurantId.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    return ids.length > 1;
  }

  String? labelForRestaurant(String restaurantId) {
    final id = restaurantId.trim();
    if (id.isEmpty) return null;
    return _restaurantNamesById[id];
  }

  String _headerLabel() {
    if (_items.isEmpty) return '';
    final ids = <String>{};
    for (final e in _items) {
      final id = e.item.restaurantId.trim();
      if (id.isNotEmpty) ids.add(id);
    }
    if (ids.isEmpty) return 'Nhà hàng';
    if (ids.length == 1) {
      final id = ids.first;
      return _restaurantNamesById[id] ?? 'Nhà hàng';
    }
    return 'Nhiều nhà hàng';
  }

  void _syncRestaurantNames() {
    if (_items.isEmpty) {
      _restaurantNamesById.clear();
      return;
    }
    final used = _items
        .map((e) => e.item.restaurantId.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    _restaurantNamesById.removeWhere((id, _) => !used.contains(id));
  }

  void addItem(
    MenuItemModel item,
    String restaurantId,
    String restaurantName, {
    int quantity = 1,
  }) {
    if (quantity <= 0) return;

    final rid = restaurantId.trim();
    final name = restaurantName.trim();
    if (rid.isNotEmpty && name.isNotEmpty) {
      _restaurantNamesById[rid] = name;
    }

    final existing = _items.where((e) => e.item.id == item.id);
    if (existing.isNotEmpty) {
      existing.first.quantity += quantity;
    } else {
      _items.add(CartItem(item: item, quantity: quantity));
    }
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((e) => e.item.id == itemId);
    _syncRestaurantNames();
    notifyListeners();
  }

  void decreaseItem(String itemId) {
    final idx = _items.indexWhere((e) => e.item.id == itemId);
    if (idx == -1) return;
    if (_items[idx].quantity > 1) {
      _items[idx].quantity--;
    } else {
      _items.removeAt(idx);
    }
    _syncRestaurantNames();
    notifyListeners();
  }

  void increaseItem(String itemId) {
    final idx = _items.indexWhere((e) => e.item.id == itemId);
    if (idx == -1) return;
    _items[idx].quantity++;
    notifyListeners();
  }

  int quantityOf(String itemId) {
    final found = _items.where((e) => e.item.id == itemId);
    return found.isEmpty ? 0 : found.first.quantity;
  }

  void clear() {
    _items.clear();
    _restaurantNamesById.clear();
    notifyListeners();
  }

  static String formatPrice(double price) {
    if (price == 0) return 'Miễn phí';
    final formatted = price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted' 'đ';
  }
}
