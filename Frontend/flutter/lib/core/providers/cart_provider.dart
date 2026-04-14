import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final int foodItemId;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.foodItemId,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(int foodItemId, String name, double price, String imageUrl) {
    final existingIndex = state.indexWhere((item) => item.foodItemId == foodItemId);
    if (existingIndex >= 0) {
      final newState = [...state];
      newState[existingIndex].quantity += 1;
      state = newState;
    } else {
      state = [...state, CartItem(foodItemId: foodItemId, name: name, price: price, imageUrl: imageUrl)];
    }
  }

  void updateQuantity(int foodItemId, int change) {
    final newState = [...state];
    final existingIndex = newState.indexWhere((item) => item.foodItemId == foodItemId);
    if (existingIndex >= 0) {
      newState[existingIndex].quantity += change;
      if (newState[existingIndex].quantity <= 0) {
        newState.removeAt(existingIndex);
      }
      state = newState;
    }
  }

  void clearCart() {
    state = [];
  }

  double get totalPrice {
    return state.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
